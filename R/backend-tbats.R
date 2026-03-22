# TBATS backend (requires forecast package)
#
# TBATS: Trigonometric seasonality, Box-Cox transformation, ARMA errors,
# Trend, and Seasonal components. Handles multiple/complex seasonality.

#' @keywords internal
#' @noRd
MiltTBATS <- R6::R6Class(
  classname = "MiltTBATS",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  public = list(

    #' @param use_box_cox Logical or `NULL`. Use Box-Cox transformation?
    #'   `NULL` (default) auto-selects.
    #' @param use_trend Logical or `NULL`. Include a trend component?
    #'   `NULL` auto-selects.
    #' @param use_damped_trend Logical or `NULL`. Damp the trend?
    #'   `NULL` auto-selects.
    #' @param seasonal_periods Numeric vector or `NULL`. Override detected
    #'   seasonal periods.
    #' @param use_arma_errors Logical. Include ARMA errors? Default `TRUE`.
    initialize = function(use_box_cox      = NULL,
                          use_trend        = NULL,
                          use_damped_trend = NULL,
                          seasonal_periods = NULL,
                          use_arma_errors  = TRUE) {
      super$initialize(
        name             = "tbats",
        use_box_cox      = use_box_cox,
        use_trend        = use_trend,
        use_damped_trend = use_damped_trend,
        seasonal_periods = seasonal_periods,
        use_arma_errors  = as.logical(use_arma_errors)
      )
    },

    fit = function(series) {
      check_installed_backend("forecast", "tbats")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("TBATS requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p      <- private$.params
      ts_obj <- series$as_ts()

      args <- list(y = ts_obj, use.arma.errors = p$use_arma_errors)
      if (!is.null(p$use_box_cox))      args$use.box.cox      <- p$use_box_cox
      if (!is.null(p$use_trend))        args$use.trend        <- p$use_trend
      if (!is.null(p$use_damped_trend)) args$use.damped.trend <- p$use_damped_trend
      if (!is.null(p$seasonal_periods)) args$seasonal.periods <- p$seasonal_periods

      private$.backend_model <- tryCatch(
        do.call(forecast::tbats, args),
        error = function(e) {
          milt_abort(c("TBATS fitting failed.", "x" = conditionMessage(e)),
                     class = "milt_error_fit_failed")
        }
      )
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      fc <- forecast::forecast(private$.backend_model, h = as.integer(horizon),
                               level = level)
      .ts_forecast_to_miltforecast(fc, private$.training_series, "tbats")
    },

    predict = function(series = NULL) {
      as.numeric(private$.backend_model$fitted.values)
    },

    residuals = function() {
      as.numeric(residuals(private$.backend_model))
    }
  )
)

.onLoad_tbats <- function() {
  register_milt_model(
    name        = "tbats",
    class       = MiltTBATS,
    description = "TBATS: Trigonometric seasonality, Box-Cox, ARMA errors, Trend and Seasonal (forecast pkg)",
    supports    = list(
      multivariate  = FALSE,
      probabilistic = TRUE,
      covariates    = FALSE,
      multi_series  = FALSE
    )
  )
}
