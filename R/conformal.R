# Conformal prediction — model-agnostic, calibrated prediction intervals.
#
# Wraps any MiltModel (even ones with no native probabilistic output) with
# split-conformal prediction intervals: historical walk-forward forecast
# errors are used to compute empirical quantiles of the absolute error at
# each horizon step, which become a distribution-free margin around a new
# forecast. Mirrors darts.models.forecasting.conformal_models.

#' Wrap a milt model with conformal prediction intervals
#'
#' Calibrates model-agnostic prediction intervals using split-conformal
#' prediction. The model is refit on a series of walk-forward calibration
#' folds (same fold structure as [milt_backtest()]); the resulting
#' per-horizon-step absolute forecast errors give empirical quantiles that
#' are applied as a `point ± margin` interval around the final forecast —
#' regardless of whether the underlying model natively produces prediction
#' intervals.
#'
#' @param model An unfitted `MiltModel` (created with [milt_model()]). It is
#'   cloned and refit from scratch on each calibration fold, then refit once
#'   more on the full `series` for the final forecast; the original object
#'   passed in is not modified.
#' @param series A `MiltSeries` used both for calibration folds and as the
#'   training data for the final forecast.
#' @param horizon Positive integer. Forecast horizon.
#' @param level Numeric vector of confidence levels, e.g. `c(80, 95)`.
#' @param initial_window Positive integer. Size of the first calibration
#'   training window. Defaults to `max(floor(n * 0.5), horizon + 1L)`.
#' @param stride Positive integer. Steps between calibration folds. Default
#'   `1L`.
#' @param method Character scalar: `"expanding"` or `"sliding"` calibration
#'   window, same semantics as [milt_backtest()].
#' @param window Positive integer. Only used when `method = "sliding"`.
#' @return A `MiltForecast` object whose prediction intervals are
#'   conformal-calibrated rather than model-native. The point forecast is
#'   unchanged from the underlying model.
#' @seealso [milt_backtest()], [milt_forecast()]
#' @family model
#' @examples
#' \donttest{
#' s   <- milt_series(AirPassengers)
#' fct <- milt_conformal(milt_model("naive"), s, horizon = 12)
#' plot(fct)
#' }
#' @export
milt_conformal <- function(model,
                            series,
                            horizon,
                            level          = c(80, 95),
                            initial_window = NULL,
                            stride         = 1L,
                            method         = c("expanding", "sliding"),
                            window         = NULL) {
  .assert_milt_model(model)
  assert_milt_series(series)
  assert_positive_integer(horizon, "horizon")

  method  <- match.arg(method)
  horizon <- as.integer(horizon)
  stride  <- as.integer(stride)
  if (stride < 1L) {
    milt_abort("{.arg stride} must be a positive integer.", class = "milt_error_invalid_arg")
  }

  n <- series$n_timesteps()
  if (is.null(initial_window)) initial_window <- max(floor(n * 0.5), horizon + 1L)
  initial_window <- as.integer(initial_window)
  if (initial_window < 2L) {
    milt_abort("{.arg initial_window} must be at least 2.", class = "milt_error_invalid_arg")
  }

  if (method == "sliding") {
    if (is.null(window)) window <- initial_window
    window <- as.integer(window)
    if (window < 2L) {
      milt_abort("{.arg window} must be at least 2 for method = 'sliding'.",
                 class = "milt_error_invalid_arg")
    }
  }

  if (initial_window + horizon > n) {
    milt_abort(
      c(
        "Not enough data to calibrate conformal intervals.",
        "i" = "Need at least {initial_window + horizon} observations; series has {n}.",
        "i" = "Decrease {.arg initial_window} or {.arg horizon}."
      ),
      class = "milt_error_insufficient_data"
    )
  }

  fold_ends <- seq(initial_window, n - horizon, by = stride)
  if (length(fold_ends) == 0L) {
    milt_abort(
      c("Calibration produces zero folds.",
        "i" = "Increase series length, decrease {.arg horizon}, or decrease {.arg stride}."),
      class = "milt_error_insufficient_data"
    )
  }

  model_name_str <- model$.__enclos_env__$private$.name %||% class(model)[[1L]]
  milt_info(
    "Calibrating conformal intervals ({length(fold_ends)} fold{?s}): {model_name_str}, h={horizon}"
  )

  full_tbl   <- series$as_tibble()
  abs_errors <- vector("list", horizon)

  for (k in seq_along(fold_ends)) {
    train_end  <- fold_ends[[k]]
    train_start <- if (method == "expanding") 1L else max(1L, train_end - window + 1L)
    test_start <- train_end + 1L
    test_end   <- min(train_end + horizon, n)
    actual_h   <- test_end - train_end

    tryCatch({
      train_series <- series$clone_with(full_tbl[seq(train_start, train_end), ])
      test_vals    <- series$clone_with(full_tbl[seq(test_start, test_end), ])$values()

      m   <- model$clone()
      m$fit(train_series)
      fct <- m$forecast(actual_h)
      err <- abs(test_vals - fct$as_tibble()$.mean)

      for (h in seq_len(actual_h)) {
        abs_errors[[h]] <- c(abs_errors[[h]], err[[h]])
      }
    }, error = function(e) {
      milt_warn("Calibration fold {k} failed: {conditionMessage(e)}")
    })
  }

  pooled <- unlist(abs_errors, use.names = FALSE)
  if (length(pooled) == 0L) {
    milt_abort("All calibration folds failed; cannot compute conformal intervals.",
               class = "milt_error_fit_failed")
  }

  # Final forecast: refit on the full series
  final_model <- model$clone()
  final_model$fit(series)
  fct <- final_model$forecast(horizon)
  pt  <- fct$as_tibble()

  # Per-horizon-step quantile of absolute error, falling back to the pooled
  # (all-horizon) sample when a step has too few calibration observations to
  # give a stable quantile.
  min_h_obs <- 5L
  lower <- upper <- list()
  for (l in level) {
    margins <- vapply(seq_len(horizon), function(h) {
      errs <- if (length(abs_errors[[h]]) >= min_h_obs) abs_errors[[h]] else pooled
      stats::quantile(errs, probs = l / 100, names = FALSE, type = 7)
    }, numeric(1L))
    nm <- as.character(l)
    lower[[nm]] <- tibble::tibble(time = pt$time, value = pt$.mean - margins)
    upper[[nm]] <- tibble::tibble(time = pt$time, value = pt$.mean + margins)
  }

  MiltForecastR6$new(
    point_forecast  = tibble::tibble(time = pt$time, value = pt$.mean),
    lower           = lower,
    upper           = upper,
    samples         = NULL,
    model_name      = paste0(model_name_str, "+conformal"),
    horizon         = horizon,
    training_end    = series$end_time(),
    training_series = series
  )
}
