# Theta method backend via the forecast package

MiltTheta <- R6::R6Class(
  classname = "MiltTheta",
  inherit   = MiltModelBase,

  public = list(
    #' @param ... Additional arguments forwarded to [forecast::thetaf()].
    initialize = function(...) {
      super$initialize(name = "theta", ...)
    },

    fit = function(series, ...) {
      check_installed_backend("forecast", "theta")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort(
          "theta requires a univariate {.cls MiltSeries}.",
          class = "milt_error_not_univariate"
        )
      }
      # thetaf() fits + forecasts in one call, so we store the series only
      private$.backend_model   <- list(ts_obj = series$as_ts())
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      fct <- forecast::thetaf(
        private$.backend_model$ts_obj,
        h     = horizon,
        level = level
      )
      .ts_forecast_to_miltforecast(fct, private$.training_series, "theta")
    },

    predict = function(series = NULL, ...) {
      # thetaf does not expose fitted values directly; approximate with
      # one-step-ahead forecasts using a simple re-fit on training sub-series
      v <- private$.training_series$values()
      n <- length(v)
      # Return the fitted values from a thetaf run with h=1 on rolling windows
      # (expensive for large series; return NA vector with a warning instead)
      milt_warn("In-sample predictions are not available for the theta method.")
      rep(NA_real_, n)
    },

    residuals = function(...) {
      milt_warn("Residuals are not available for the theta method.")
      rep(NA_real_, private$.training_series$n_timesteps())
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_theta <- function() {
  register_milt_model(
    "theta", MiltTheta,
    description = "Theta forecasting method via forecast::thetaf().",
    supports    = list(probabilistic = TRUE)
  )
}
