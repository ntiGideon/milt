# Hyperparameter search — mirrors darts' backtest-driven gridsearch examples
# (e.g. searching Theta method variants), generalised to any registered model.

#' Grid search over a model's hyperparameters via backtesting
#'
#' Backtests every combination of `param_grid` (via [milt_backtest()]) and
#' ranks them by a chosen metric. Works with any registered backend, not just
#' the Theta method — e.g. sweep `theta` over `season_mode`, or `xgboost`
#' over `nrounds`/`max_depth`.
#'
#' @param model_name Character. Registered backend name (see
#'   [list_milt_models()]).
#' @param param_grid Named list of parameter value vectors. Every combination
#'   (the full Cartesian product) is tried.
#' @param series A `MiltSeries` used for backtesting.
#' @param horizon Positive integer forecast horizon, forwarded to
#'   [milt_backtest()].
#' @param metric Character scalar. Metric to rank by (must be one of
#'   `"MAE"`, `"RMSE"`, `"MSE"`, `"MAPE"`, `"SMAPE"`). Default `"MAE"`.
#' @param ... Additional arguments forwarded to [milt_backtest()] (e.g.
#'   `initial_window`, `stride`, `method`).
#' @return A tibble with one row per combination, its mean backtest `metric`
#'   value, and rows ordered best-first (`NA` for combinations that errored).
#' @seealso [milt_backtest()], [milt_compare()]
#' @family model
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' milt_grid_search(
#'   "theta",
#'   param_grid = list(theta = c(1, 2, 3)),
#'   series = s, horizon = 12,
#'   initial_window = 120L, stride = 12L
#' )
#' }
#' @export
milt_grid_search <- function(model_name, param_grid, series, horizon,
                              metric = "MAE", ...) {
  assert_milt_series(series)
  if (!is_scalar_character(model_name)) {
    milt_abort("{.arg model_name} must be a single string.",
               class = "milt_error_invalid_arg")
  }
  if (!is.list(param_grid) || length(param_grid) == 0L || is.null(names(param_grid)) ||
      any(names(param_grid) == "")) {
    milt_abort("{.arg param_grid} must be a non-empty named list of parameter value vectors.",
               class = "milt_error_invalid_arg")
  }
  metric <- match.arg(metric, c("MAE", "RMSE", "MSE", "MAPE", "SMAPE"))

  combos <- expand.grid(param_grid, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  milt_info("Grid search over {nrow(combos)} combination{?s} of {.val {model_name}}")

  metric_vals <- vapply(seq_len(nrow(combos)), function(i) {
    params <- as.list(combos[i, , drop = FALSE])
    tryCatch({
      m    <- do.call(milt_model, c(list(name = model_name), params))
      bt   <- milt_backtest(m, series, horizon = horizon, metrics = metric, ...)
      smry <- bt$summary_tbl()
      smry$mean[smry$metric == metric][[1L]]
    }, error = function(e) NA_real_)
  }, numeric(1L))

  out <- tibble::as_tibble(combos)
  out[[metric]] <- metric_vals
  out[order(out[[metric]]), ]
}
