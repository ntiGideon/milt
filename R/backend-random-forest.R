# Random Forest backend (requires ranger package)

#' @keywords internal
#' @noRd
MiltRandomForest <- R6::R6Class(
  classname = "MiltRandomForest",
  inherit   = MiltModelBase,

  private = list(
    .lags        = NULL,
    .last_values = NULL,
    .residuals   = NULL
  ),

  public = list(

    #' @param lags Integer vector of lag indices used as features.
    #'   Default `1:12`.
    #' @param num.trees Integer. Number of trees. Default `500L`.
    #' @param mtry Integer or `NULL`. Number of variables tried at each split.
    #'   `NULL` uses ranger's default (`floor(sqrt(p))`).
    #' @param min.node.size Integer. Minimum node size. Default `5L`.
    #' @param num.threads Integer. Number of threads. Default `1L`.
    #' @param importance Character. Variable-importance mode. Default `"impurity"`.
    #' @param ... Additional arguments forwarded to `ranger::ranger()`.
    initialize = function(lags          = 1:12,
                          num.trees     = 500L,
                          mtry          = NULL,
                          min.node.size = 5L,
                          num.threads   = 1L,
                          importance    = "impurity",
                          ...) {
      super$initialize(
        name          = "random_forest",
        lags          = lags,
        num.trees     = as.integer(num.trees),
        mtry          = mtry,
        min.node.size = as.integer(min.node.size),
        num.threads   = as.integer(num.threads),
        importance    = importance,
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("ranger", "random_forest")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("random_forest requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p     <- private$.params
      lags  <- as.integer(p$lags %||% 1:12)
      vals  <- series$values()
      built <- .ml_build_lag_features(vals, lags)

      train_df        <- as.data.frame(built$X)
      train_df$.target <- built$y

      ranger_args <- list(
        formula      = .target ~ .,
        data         = train_df,
        num.trees    = p$num.trees    %||% 500L,
        min.node.size = p$min.node.size %||% 5L,
        num.threads  = p$num.threads  %||% 1L,
        importance   = p$importance   %||% "impurity"
      )
      if (!is.null(p$mtry)) ranger_args$mtry <- as.integer(p$mtry)

      fit <- do.call(ranger::ranger, ranger_args)

      private$.backend_model <- fit
      private$.lags          <- lags
      private$.last_values   <- utils::tail(vals, max(lags))
      private$.residuals     <- built$y - fit$predictions
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
        x_row <- .ml_next_lag_row(history, lags)
        df_row  <- as.data.frame(x_row)
        pt      <- predict(fit, data = df_row)$predictions
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
        model_name      = "random_forest",
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
      built   <- .ml_build_lag_features(vals, lags)
      df      <- as.data.frame(built$X)
      preds   <- predict(private$.backend_model, data = df)$predictions
      c(rep(NA_real_, max(lags)), preds)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      c(rep(NA_real_, max(private$.lags)), private$.residuals)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_random_forest <- function() {
  register_milt_model("random_forest", MiltRandomForest)
}
