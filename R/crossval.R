# Time-series-aware cross-validation

#' Time series cross-validation
#'
#' A convenience wrapper around [milt_backtest()] that automatically computes
#' a stride so that exactly `folds` evaluation folds are produced.  The
#' training window expands fold by fold (expanding window) — no future data is
#' ever used in training.
#'
#' @param model An unfitted `MiltModel` created with [milt_model()].
#' @param series A `MiltSeries` object.
#' @param folds Positive integer. Number of evaluation folds. Default `5L`.
#' @param horizon Positive integer. Forecast horizon per fold. Default `1L`.
#' @param initial_window Positive integer or `NULL`. Size of the first
#'   training window.  Defaults to `floor(n * (folds / (folds + 1)))`.
#' @param metrics Character vector of metric names. Supported: `"MAE"`,
#'   `"RMSE"`, `"MSE"`, `"MAPE"`, `"SMAPE"`. Default `c("MAE", "RMSE", "MAPE")`.
#' @return A `MiltBacktest` object (same as [milt_backtest()]).
#'
#' @details
#' The stride is computed so that fold cut-points are approximately evenly
#' spaced across the remaining data: \cr
#' `stride = max(1, floor((n - horizon - initial_window) / (folds - 1)))`
#'
#' When `folds = 1`, the stride is irrelevant and a single evaluation window is
#' used (from `initial_window` to `n - horizon`).
#'
#' @seealso [milt_backtest()], [milt_compare()]
#' @family model
#' @examples
#' \donttest{
#' s  <- milt_series(AirPassengers)
#' cv <- milt_cv(milt_model("naive"), s, folds = 5L, horizon = 12L)
#' print(cv)
#' }
#' @export
milt_cv <- function(model,
                     series,
                     folds          = 5L,
                     horizon        = 1L,
                     initial_window = NULL,
                     metrics        = c("MAE", "RMSE", "MAPE")) {
  .assert_milt_model(model)
  assert_milt_series(series)

  folds   <- as.integer(folds)
  horizon <- as.integer(horizon)

  if (folds < 1L) {
    milt_abort("{.arg folds} must be a positive integer.",
               class = "milt_error_invalid_arg")
  }
  assert_positive_integer(horizon, "horizon")

  n <- series$n_timesteps()

  if (is.null(initial_window)) {
    # Reserve the last (1/(folds+1)) fraction for evaluation
    initial_window <- as.integer(floor(n * (folds / (folds + 1L))))
    # Must leave at least horizon steps after initial_window
    initial_window <- min(initial_window, n - horizon)
  }
  initial_window <- as.integer(initial_window)

  if (initial_window + horizon > n) {
    milt_abort(
      c(
        "Not enough data for {folds} fold{?s} with horizon {horizon}.",
        "i" = "Series length: {n}. initial_window: {initial_window}."
      ),
      class = "milt_error_insufficient_data"
    )
  }

  # Stride that spaces folds evenly across available test range
  avail  <- n - horizon - initial_window
  stride <- if (folds <= 1L) avail + 1L else max(1L, as.integer(floor(avail / (folds - 1L))))

  milt_backtest(
    model          = model,
    series         = series,
    horizon        = horizon,
    initial_window = initial_window,
    stride         = stride,
    method         = "expanding",
    metrics        = metrics
  )
}
