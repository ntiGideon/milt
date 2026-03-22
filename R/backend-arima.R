# Auto-ARIMA backend (requires the forecast package)

# ── Shared helper for all forecast-package backends ───────────────────────────

# Converts a forecast-package forecast object to a MiltForecast.
# Used by backend-arima.R, backend-ets.R, backend-theta.R, backend-stl.R.
.ts_forecast_to_miltforecast <- function(fct_obj,
                                          training_series,
                                          model_name) {
  horizon <- length(fct_obj$mean)
  times   <- .future_times(training_series, horizon)
  lvls    <- fct_obj$level   # numeric vector e.g. c(80, 95)

  pt <- tibble::tibble(time = times, value = as.numeric(fct_obj$mean))

  lower <- stats::setNames(
    lapply(seq_along(lvls), function(i) {
      tibble::tibble(time = times, value = as.numeric(fct_obj$lower[, i]))
    }),
    as.character(lvls)
  )
  upper <- stats::setNames(
    lapply(seq_along(lvls), function(i) {
      tibble::tibble(time = times, value = as.numeric(fct_obj$upper[, i]))
    }),
    as.character(lvls)
  )

  MiltForecastR6$new(
    point_forecast  = pt,
    lower           = lower,
    upper           = upper,
    model_name      = model_name,
    horizon         = horizon,
    training_end    = training_series$end_time(),
    training_series = training_series
  )
}

# ── Auto-ARIMA ────────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltAutoArima <- R6::R6Class(
  classname = "MiltAutoArima",
  inherit   = MiltModelBase,

  public = list(
    #' @param stepwise Logical. Use stepwise search? Default `TRUE` (faster).
    #' @param approximation Logical. Use approximations for large series?
    #'   Default `NULL` (auto).
    #' @param seasonal Logical. Include seasonal component? Default `TRUE`.
    #' @param ... Additional arguments forwarded to [forecast::auto.arima()].
    initialize = function(stepwise     = TRUE,
                          approximation = NULL,
                          seasonal      = TRUE,
                          ...) {
      super$initialize(name = "auto_arima",
                       stepwise = stepwise,
                       approximation = approximation,
                       seasonal = seasonal, ...)
    },

    fit = function(series, ...) {
      check_installed_backend("forecast", "auto_arima")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort(
          "auto_arima requires a univariate {.cls MiltSeries}.",
          class = "milt_error_not_univariate"
        )
      }

      ts_obj <- series$as_ts()
      params <- private$.params
      args   <- c(
        list(x = ts_obj, seasonal = params$seasonal %||% TRUE),
        if (!is.null(params$stepwise))     list(stepwise = params$stepwise),
        if (!is.null(params$approximation)) list(approximation = params$approximation)
      )
      fit <- do.call(forecast::auto.arima, args)

      private$.backend_model   <- fit
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      fct <- forecast::forecast(private$.backend_model, h = horizon, level = level)
      .ts_forecast_to_miltforecast(fct, private$.training_series, "auto_arima")
    },

    predict = function(series = NULL, ...) {
      as.numeric(stats::fitted(private$.backend_model))
    },

    residuals = function(...) {
      as.numeric(stats::residuals(private$.backend_model))
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_arima <- function() {
  register_milt_model(
    "auto_arima", MiltAutoArima,
    description = "Automatic ARIMA model selection via forecast::auto.arima().",
    supports    = list(probabilistic = TRUE, covariates = TRUE)
  )
}
