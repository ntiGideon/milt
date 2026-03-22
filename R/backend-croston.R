# Croston backend (requires forecast package)
#
# Croston's method for intermittent demand forecasting.
# Separately models inter-arrival times and demand sizes.

#' @keywords internal
#' @noRd
MiltCroston <- R6::R6Class(
  classname = "MiltCroston",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  public = list(

    #' @param alpha Numeric in `(0, 1]`. Smoothing parameter. Default `0.1`.
    initialize = function(alpha = 0.1) {
      super$initialize(name = "croston", alpha = as.numeric(alpha))
    },

    fit = function(series) {
      check_installed_backend("forecast", "croston")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("Croston requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      ts_obj <- series$as_ts()
      private$.backend_model <- tryCatch(
        forecast::croston(ts_obj, alpha = private$.params$alpha),
        error = function(e) {
          milt_abort(c("Croston fitting failed.", "x" = conditionMessage(e)),
                     class = "milt_error_fit_failed")
        }
      )
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      # croston() returns a forecast object directly (model + forecast combined)
      # We rerun it with h = horizon
      ts_obj <- private$.training_series$as_ts()
      fc     <- forecast::croston(ts_obj, h = as.integer(horizon),
                                  alpha = private$.params$alpha)

      .ts_forecast_to_miltforecast(fc, private$.training_series, "croston")
    },

    predict = function(series = NULL) {
      as.numeric(private$.backend_model$fitted)
    },

    residuals = function() {
      as.numeric(private$.backend_model$residuals)
    }
  )
)

.onLoad_croston <- function() {
  register_milt_model(
    name        = "croston",
    class       = MiltCroston,
    description = "Croston's method for intermittent demand forecasting (forecast pkg)",
    supports    = list(
      multivariate  = FALSE,
      probabilistic = TRUE,
      covariates    = FALSE,
      multi_series  = FALSE
    )
  )
}
