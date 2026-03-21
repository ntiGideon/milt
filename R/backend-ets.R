# ETS (Error-Trend-Seasonality) backend via the forecast package

MiltEts <- R6::R6Class(
  classname = "MiltEts",
  inherit   = MiltModelBase,

  public = list(
    #' @param model ETS model type string (e.g. `"ZZZ"`, `"AAN"`, `"MAM"`).
    #'   `"ZZZ"` (default) lets the algorithm select automatically.
    #' @param damped Logical or `NULL`. Force a damped trend? `NULL` = auto.
    #' @param ... Additional arguments forwarded to [forecast::ets()].
    initialize = function(model  = "ZZZ",
                          damped = NULL,
                          ...) {
      super$initialize(name = "ets", model = model, damped = damped, ...)
    },

    fit = function(series, ...) {
      check_installed_backend("forecast", "ets")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort(
          "ets requires a univariate {.cls MiltSeries}.",
          class = "milt_error_not_univariate"
        )
      }

      ts_obj <- series$as_ts()
      params <- private$.params
      args   <- c(
        list(y = ts_obj, model = params$model %||% "ZZZ"),
        if (!is.null(params$damped)) list(damped = params$damped)
      )
      fit <- do.call(forecast::ets, args)

      private$.backend_model   <- fit
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      fct <- forecast::forecast(private$.backend_model, h = horizon, level = level)
      .ts_forecast_to_miltforecast(fct, private$.training_series, "ets")
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

.onLoad_ets <- function() {
  register_milt_model(
    "ets", MiltEts,
    description = "Exponential smoothing state-space model via forecast::ets().",
    supports    = list(probabilistic = TRUE)
  )
}
