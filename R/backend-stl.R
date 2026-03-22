# STL decomposition + ETS/ARIMA remainder model via the forecast package

#' @keywords internal
#' @noRd
MiltStl <- R6::R6Class(
  classname = "MiltStl",
  inherit   = MiltModelBase,

  public = list(
    #' @param method Remainder model: `"ets"` (default) or `"arima"`.
    #' @param s.window STL seasonal window. `"periodic"` (default) or a
    #'   positive odd integer.
    #' @param robust Logical. Use robust STL fitting? Default `FALSE`.
    #' @param ... Additional arguments forwarded to [forecast::stlf()].
    initialize = function(method   = "ets",
                          s.window = "periodic",
                          robust   = FALSE,
                          ...) {
      valid_methods <- c("ets", "arima")
      if (!method %in% valid_methods) {
        milt_abort(
          "{.arg method} must be one of {.val {valid_methods}}, not {.val {method}}.",
          class = "milt_error_invalid_arg"
        )
      }
      super$initialize(name = "stl", method = method,
                       s.window = s.window, robust = robust, ...)
    },

    fit = function(series, ...) {
      check_installed_backend("forecast", "stl")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort(
          "stl requires a univariate {.cls MiltSeries}.",
          class = "milt_error_not_univariate"
        )
      }
      ts_obj <- series$as_ts()
      freq   <- stats::frequency(ts_obj)
      if (freq <= 1L) {
        milt_abort(
          c(
            "STL decomposition requires a seasonal series (frequency > 1).",
            "i" = "This series has frequency {freq}. Try {.val auto_arima} or {.val ets} instead."
          ),
          class = "milt_error_invalid_frequency"
        )
      }
      # Store the ts for use in forecast(); stlf() combines fit + forecast
      private$.backend_model   <- list(ts_obj = ts_obj)
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      params <- private$.params
      fct <- forecast::stlf(
        private$.backend_model$ts_obj,
        h        = horizon,
        level    = level,
        method   = params$method   %||% "ets",
        s.window = params$s.window %||% "periodic",
        robust   = params$robust   %||% FALSE
      )
      .ts_forecast_to_miltforecast(fct, private$.training_series, "stl")
    },

    predict = function(series = NULL, ...) {
      # stlf does not separately expose fitted values; warn and return NA
      milt_warn("In-sample fitted values are not directly available for stl.")
      rep(NA_real_, private$.training_series$n_timesteps())
    },

    residuals = function(...) {
      milt_warn("Residuals are not directly available for stl.")
      rep(NA_real_, private$.training_series$n_timesteps())
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_stl <- function() {
  register_milt_model(
    "stl", MiltStl,
    description = paste0("STL decomposition + ETS/ARIMA remainder ",
                         "via forecast::stlf()."),
    supports    = list(probabilistic = TRUE)
  )
}
