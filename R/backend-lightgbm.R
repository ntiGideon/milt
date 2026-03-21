# LightGBM backend (requires lightgbm package)

MiltLightGBM <- R6::R6Class(
  classname = "MiltLightGBM",
  inherit   = MiltModelBase,

  private = list(
    .lags        = NULL,
    .last_values = NULL,
    .residuals   = NULL
  ),

  public = list(

    #' @param lags Integer vector of lag indices used as features. Default `1:12`.
    #' @param num_iterations Integer. Number of boosting rounds. Default `100L`.
    #' @param learning_rate Numeric. Learning rate. Default `0.1`.
    #' @param num_leaves Integer. Max number of leaves. Default `31L`.
    #' @param num_threads Integer. Number of threads. Default `1L`.
    #' @param ... Additional parameters forwarded to [lightgbm::lgb.train()].
    initialize = function(lags           = 1:12,
                          num_iterations = 100L,
                          learning_rate  = 0.1,
                          num_leaves     = 31L,
                          num_threads    = 1L,
                          ...) {
      super$initialize(
        name           = "lightgbm",
        lags           = lags,
        num_iterations = as.integer(num_iterations),
        learning_rate  = learning_rate,
        num_leaves     = as.integer(num_leaves),
        num_threads    = as.integer(num_threads),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("lightgbm", "lightgbm")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("lightgbm requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p     <- private$.params
      lags  <- as.integer(p$lags %||% 1:12)
      vals  <- series$values()
      built <- .ml_build_lag_features(vals, lags)

      dtrain <- lightgbm::lgb.Dataset(
        data  = built$X,
        label = built$y
      )
      lgb_params <- list(
        objective     = "regression",
        learning_rate = p$learning_rate %||% 0.1,
        num_leaves    = p$num_leaves    %||% 31L,
        num_threads   = p$num_threads   %||% 1L,
        verbose       = -1L
      )
      fit <- lightgbm::lgb.train(
        params  = lgb_params,
        data    = dtrain,
        nrounds = p$num_iterations %||% 100L
      )

      fitted_vals <- predict(fit, built$X)

      private$.backend_model <- fit
      private$.lags          <- lags
      private$.last_values   <- utils::tail(vals, max(lags))
      private$.residuals     <- built$y - fitted_vals
      private$.fitted        <- TRUE
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      horizon   <- as.integer(horizon)
      history   <- as.numeric(private$.last_values)
      lags      <- private$.lags
      fit       <- private$.backend_model
      forecasts <- numeric(horizon)

      for (h in seq_len(horizon)) {
        x_row <- matrix(.compute_lags(history, lags)[length(history), ],
                        nrow = 1L)
        colnames(x_row) <- paste0(".lag_", lags)
        pt    <- predict(fit, x_row)
        forecasts[h] <- pt
        history      <- c(history, pt)
      }

      training_series <- private$.training_series
      times           <- .future_times(training_series, horizon)
      pt_tbl          <- tibble::tibble(time = times, value = forecasts)
      pi              <- .ml_pi_from_residuals(
        private$.residuals, forecasts, times, level
      )

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "lightgbm",
        horizon         = horizon,
        training_end    = training_series$end_time(),
        training_series = training_series
      )
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      lags  <- private$.lags
      vals  <- if (is.null(series)) {
        private$.training_series$values()
      } else {
        assert_milt_series(series)
        series$values()
      }
      built <- .ml_build_lag_features(vals, lags)
      preds <- predict(private$.backend_model, built$X)
      c(rep(NA_real_, max(lags)), preds)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      c(rep(NA_real_, max(private$.lags)), private$.residuals)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_lightgbm <- function() {
  register_milt_model("lightgbm", MiltLightGBM)
}
