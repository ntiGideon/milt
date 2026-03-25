# In-sample prediction and residual verbs
# These are thin public wrappers over MiltModelBase$predict() / $residuals().

#' In-sample predictions from a fitted milt model
#'
#' Returns fitted values for the training series, or applies the fitted model
#' to a new `MiltSeries` for one-step-ahead predictions.
#'
#' @param model A fitted `MiltModel` created by [milt_model()] and trained with
#'   [milt_fit()].
#' @param series Optional `MiltSeries`. When `NULL` (default), returns the
#'   in-sample fitted values for the original training data. When supplied,
#'   the model is applied to this series instead.
#' @param ... Additional arguments forwarded to the backend's `predict()`
#'   method.
#' @return A numeric vector of fitted/predicted values with the same length as
#'   the target series.
#' @seealso [milt_fit()], [milt_forecast()], [milt_residuals()]
#' @family model
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' m <- milt_model("naive") |> milt_fit(s)
#' fitted_vals <- milt_predict(m)
#' length(fitted_vals) == length(s)  # TRUE
#' }
#' @export
milt_predict <- function(model, series = NULL, ...) {
  .assert_milt_model(model)
  .assert_is_fitted(model)
  if (!is.null(series)) assert_milt_series(series, "series")
  model$predict(series, ...)
}

#' Residuals from a fitted milt model
#'
#' Returns the vector of training residuals (actual minus fitted) from a fitted
#' model. Useful for residual diagnostics and assumption checking.
#'
#' @param model A fitted `MiltModel`.
#' @param ... Additional arguments forwarded to the backend's `residuals()`
#'   method.
#' @return A numeric vector of residuals with the same length as the training
#'   series.
#' @seealso [milt_predict()], [milt_diagnose()]
#' @family model
#' @examples
#' \donttest{
#' s   <- milt_series(AirPassengers)
#' m   <- milt_model("naive") |> milt_fit(s)
#' res <- milt_residuals(m)
#' mean(res, na.rm = TRUE)  # close to 0 for well-specified models
#' }
#' @export
milt_residuals <- function(model, ...) {
  .assert_milt_model(model)
  .assert_is_fitted(model)
  model$residuals(...)
}
