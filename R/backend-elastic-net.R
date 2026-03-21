# Elastic-net (glmnet) backend

MiltElasticNet <- R6::R6Class(
  classname = "MiltElasticNet",
  inherit   = MiltModelBase,

  private = list(
    .lags        = NULL,
    .last_values = NULL,
    .residuals   = NULL,
    .lambda      = NULL   # selected by cv.glmnet
  ),

  public = list(

    #' @param lags Integer vector of lag indices. Default `1:12`.
    #' @param alpha Numeric in `[0, 1]`. Elastic-net mixing parameter.
    #'   `0` = ridge, `1` = lasso. Default `0.5`.
    #' @param lambda Numeric or `NULL`. Regularisation strength.
    #'   `NULL` (default) selects via 5-fold cross-validation.
    #' @param ... Additional arguments forwarded to [glmnet::glmnet()] or
    #'   [glmnet::cv.glmnet()].
    initialize = function(lags   = 1:12,
                          alpha  = 0.5,
                          lambda = NULL,
                          ...) {
      super$initialize(
        name   = "elastic_net",
        lags   = lags,
        alpha  = alpha,
        lambda = lambda,
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("glmnet", "elastic_net")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("elastic_net requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p     <- private$.params
      lags  <- as.integer(p$lags %||% 1:12)
      alpha <- p$alpha %||% 0.5
      vals  <- series$values()
      built <- .ml_build_lag_features(vals, lags)

      if (is.null(p$lambda)) {
        cv_fit <- glmnet::cv.glmnet(
          x      = built$X,
          y      = built$y,
          alpha  = alpha,
          nfolds = 5L
        )
        lambda_sel <- cv_fit$lambda.min
        fit        <- cv_fit$glmnet.fit
      } else {
        lambda_sel <- p$lambda
        fit <- glmnet::glmnet(
          x      = built$X,
          y      = built$y,
          alpha  = alpha,
          lambda = lambda_sel
        )
      }

      fitted_vals <- as.numeric(predict(fit, newx = built$X, s = lambda_sel))

      private$.backend_model <- fit
      private$.lags          <- lags
      private$.lambda        <- lambda_sel
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
      lambda    <- private$.lambda
      forecasts <- numeric(horizon)

      for (h in seq_len(horizon)) {
        x_row <- matrix(.compute_lags(history, lags)[length(history), ],
                        nrow = 1L)
        colnames(x_row) <- paste0(".lag_", lags)
        pt    <- as.numeric(predict(fit, newx = x_row, s = lambda))
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
        model_name      = "elastic_net",
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
      preds <- as.numeric(
        predict(private$.backend_model, newx = built$X, s = private$.lambda)
      )
      c(rep(NA_real_, max(lags)), preds)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      c(rep(NA_real_, max(private$.lags)), private$.residuals)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_elastic_net <- function() {
  register_milt_model("elastic_net", MiltElasticNet)
}
