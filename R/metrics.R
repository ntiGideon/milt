# Forecast accuracy metrics — point, scaled, and probabilistic

# ── Internal validators ───────────────────────────────────────────────────────

.check_numeric_vectors <- function(actual, predicted,
                                   arg_a = "actual",
                                   arg_p = "predicted") {
  if (!is.numeric(actual)) {
    milt_abort("{.arg {arg_a}} must be a numeric vector.",
               class = "milt_error_invalid_metric_input")
  }
  if (!is.numeric(predicted)) {
    milt_abort("{.arg {arg_p}} must be a numeric vector.",
               class = "milt_error_invalid_metric_input")
  }
  if (length(actual) != length(predicted)) {
    milt_abort(
      c(
        "{.arg {arg_a}} and {.arg {arg_p}} must have the same length.",
        "i" = "Lengths: {.val {length(actual)}} vs {.val {length(predicted)}}."
      ),
      class = "milt_error_length_mismatch"
    )
  }
  if (length(actual) == 0L) {
    milt_abort("Inputs must not be empty.", class = "milt_error_invalid_metric_input")
  }
  invisible(NULL)
}

.check_training_series <- function(training, season, context) {
  if (!is.numeric(training)) {
    milt_abort(
      "{.arg training} must be a numeric vector of in-sample values for {context}.",
      class = "milt_error_invalid_metric_input"
    )
  }
  if (!is_scalar_integer(season) || season < 1L) {
    milt_abort(
      "{.arg season} must be a positive integer (seasonal period).",
      class = "milt_error_invalid_metric_input"
    )
  }
  if (length(training) <= season) {
    milt_abort(
      c(
        "Training series has fewer observations than {.arg season}.",
        "i" = "Provide at least {season + 1} training observations for {context}."
      ),
      class = "milt_error_insufficient_data"
    )
  }
  invisible(NULL)
}

# ── Point forecast metrics ────────────────────────────────────────────────────

#' Mean Absolute Error
#'
#' @param actual Numeric vector of observed values.
#' @param predicted Numeric vector of predicted values.
#' @return A single numeric value.
#' @family metrics
#' @export
milt_mae <- function(actual, predicted) {
  .check_numeric_vectors(actual, predicted)
  mean(abs(actual - predicted), na.rm = TRUE)
}

#' Mean Squared Error
#'
#' @inheritParams milt_mae
#' @return A single numeric value.
#' @family metrics
#' @export
milt_mse <- function(actual, predicted) {
  .check_numeric_vectors(actual, predicted)
  mean((actual - predicted)^2, na.rm = TRUE)
}

#' Root Mean Squared Error
#'
#' @inheritParams milt_mae
#' @return A single numeric value.
#' @family metrics
#' @export
milt_rmse <- function(actual, predicted) {
  sqrt(milt_mse(actual, predicted))
}

#' Mean Absolute Percentage Error
#'
#' Returns `Inf` when any `actual` value is zero and emits a warning.
#'
#' @inheritParams milt_mae
#' @return A single numeric value (percentage expressed as a fraction, e.g.
#'   `0.05` = 5 %).
#' @family metrics
#' @export
milt_mape <- function(actual, predicted) {
  .check_numeric_vectors(actual, predicted)
  if (any(actual == 0, na.rm = TRUE)) {
    milt_warn(
      c(
        "{.arg actual} contains zero(s); MAPE will be infinite.",
        "i" = "Consider {.fn milt_smape} as an alternative."
      )
    )
  }
  mean(abs((actual - predicted) / actual), na.rm = TRUE)
}

#' Symmetric Mean Absolute Percentage Error
#'
#' Uses the definition `2 * |A - F| / (|A| + |F|)`, which is bounded between
#' 0 and 2 and avoids division by zero when both values are non-zero.
#'
#' @inheritParams milt_mae
#' @return A single numeric value in `[0, 2]`.
#' @family metrics
#' @export
milt_smape <- function(actual, predicted) {
  .check_numeric_vectors(actual, predicted)
  denom <- (abs(actual) + abs(predicted))
  zero_mask <- denom == 0
  if (any(zero_mask, na.rm = TRUE)) {
    milt_warn("Some (actual, predicted) pairs are both zero; those terms are set to 0.")
  }
  vals <- ifelse(zero_mask, 0, 2 * abs(actual - predicted) / denom)
  mean(vals, na.rm = TRUE)
}

#' Mean Absolute Scaled Error
#'
#' Scales the MAE by the in-sample naive seasonal forecast error (Hyndman &
#' Koehler 2006). Values < 1 indicate better-than-naive performance.
#'
#' @inheritParams milt_mae
#' @param training Numeric vector of in-sample (training) values used to
#'   compute the scaling denominator.
#' @param season Seasonal period. Use `1` for non-seasonal scaling (random
#'   walk naive benchmark).
#' @return A single numeric value.
#' @family metrics
#' @export
milt_mase <- function(actual, predicted, training, season = 1L) {
  .check_numeric_vectors(actual, predicted)
  .check_training_series(training, season, "MASE")
  season <- as.integer(season)
  diffs  <- training[(season + 1L):length(training)] -
            training[seq_len(length(training) - season)]
  scale  <- mean(abs(diffs), na.rm = TRUE)
  if (scale == 0) {
    milt_warn("Naive scaling denominator is zero (constant training series); MASE = NaN.")
    return(NaN)
  }
  milt_mae(actual, predicted) / scale
}

#' Root Mean Squared Scaled Error
#'
#' The RMSE analogue of [milt_mase()].
#'
#' @inheritParams milt_mase
#' @return A single numeric value.
#' @family metrics
#' @export
milt_rmsse <- function(actual, predicted, training, season = 1L) {
  .check_numeric_vectors(actual, predicted)
  .check_training_series(training, season, "RMSSE")
  season <- as.integer(season)
  diffs  <- training[(season + 1L):length(training)] -
            training[seq_len(length(training) - season)]
  scale  <- mean(diffs^2, na.rm = TRUE)
  if (scale == 0) {
    milt_warn("Naive scaling denominator is zero; RMSSE = NaN.")
    return(NaN)
  }
  sqrt(milt_mse(actual, predicted) / scale)
}

#' Mean Relative Absolute Error
#'
#' Measures performance relative to a benchmark forecast.
#'
#' @inheritParams milt_mae
#' @param benchmark Numeric vector of benchmark forecast values (same length as
#'   `actual`).
#' @return A single numeric value. Values < 1 mean the model outperforms the
#'   benchmark.
#' @family metrics
#' @export
milt_mrae <- function(actual, predicted, benchmark) {
  .check_numeric_vectors(actual, predicted)
  .check_numeric_vectors(actual, benchmark, "actual", "benchmark")
  benchmark_err <- abs(actual - benchmark)
  if (any(benchmark_err == 0, na.rm = TRUE)) {
    milt_warn("Benchmark has perfect predictions at some steps; those MRAE terms are Inf.")
  }
  mean(abs(actual - predicted) / benchmark_err, na.rm = TRUE)
}

#' Coefficient of Determination (R²)
#'
#' @inheritParams milt_mae
#' @return A numeric value, typically in `(-Inf, 1]`. A value of 1 is perfect;
#'   0 means the model is no better than predicting the mean; negative values
#'   indicate the model is worse than the mean.
#' @family metrics
#' @export
milt_r_squared <- function(actual, predicted) {
  .check_numeric_vectors(actual, predicted)
  ss_res <- sum((actual - predicted)^2, na.rm = TRUE)
  ss_tot <- sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)
  if (ss_tot == 0) {
    milt_warn("Total sum of squares is zero (constant actual); R² is undefined.")
    return(NaN)
  }
  1 - ss_res / ss_tot
}

# ── Probabilistic forecast metrics ───────────────────────────────────────────

#' Continuous Ranked Probability Score (CRPS)
#'
#' Computes the empirical CRPS from a matrix of forecast samples using the
#' energy-score formulation:
#' `CRPS = E|X - y| - 0.5 * E|X - X'|`
#'
#' @param actual Numeric vector of observed values (length `n`).
#' @param forecast_dist Numeric matrix of forecast samples with `n` rows and
#'   `S` columns (one column per sample path).
#' @return Mean CRPS across all time steps (lower is better).
#' @family metrics
#' @export
milt_crps <- function(actual, forecast_dist) {
  if (!is.numeric(actual)) {
    milt_abort("{.arg actual} must be a numeric vector.",
               class = "milt_error_invalid_metric_input")
  }
  if (!is.matrix(forecast_dist) || !is.numeric(forecast_dist)) {
    milt_abort(
      c(
        "{.arg forecast_dist} must be a numeric matrix.",
        "i" = "Rows = time steps, columns = forecast samples."
      ),
      class = "milt_error_invalid_metric_input"
    )
  }
  if (nrow(forecast_dist) != length(actual)) {
    milt_abort(
      "Number of rows in {.arg forecast_dist} must equal length of {.arg actual}.",
      class = "milt_error_length_mismatch"
    )
  }

  n_steps   <- length(actual)
  n_samples <- ncol(forecast_dist)

  crps_per_step <- vapply(seq_len(n_steps), function(i) {
    y  <- actual[i]
    xs <- forecast_dist[i, ]
    e1 <- mean(abs(xs - y))
    # E|X - X'| = 2 * mean of lower triangle differences (faster than double sum)
    e2 <- mean(abs(outer(xs, xs, "-")))
    e1 - 0.5 * e2
  }, numeric(1L))

  mean(crps_per_step, na.rm = TRUE)
}

#' Prediction Interval Coverage
#'
#' Proportion of actual observations that fall within the prediction interval
#' `[lower, upper]`.
#'
#' @param actual Numeric vector of observed values.
#' @param lower Numeric vector of lower interval bounds.
#' @param upper Numeric vector of upper interval bounds.
#' @return A numeric value in `[0, 1]`. For a nominal `(1-alpha)*100%` interval
#'   the target coverage is `1 - alpha`.
#' @family metrics
#' @export
milt_coverage <- function(actual, lower, upper) {
  .check_numeric_vectors(actual, lower, "actual", "lower")
  .check_numeric_vectors(actual, upper, "actual", "upper")
  if (any(lower > upper, na.rm = TRUE)) {
    milt_warn("Some {.arg lower} values exceed {.arg upper}.")
  }
  mean(actual >= lower & actual <= upper, na.rm = TRUE)
}

#' Pinball Loss (Quantile Score)
#'
#' Evaluates quantile forecast quality across one or more quantile levels.
#'
#' @param actual Numeric vector of observed values (length `n`).
#' @param quantiles Numeric matrix of predicted quantiles: `n` rows, one column
#'   per quantile level in `taus`.
#' @param taus Numeric vector of quantile levels in `(0, 1)` (same length as
#'   columns in `quantiles`).
#' @return Mean pinball loss across all steps and quantile levels (lower is
#'   better).
#' @family metrics
#' @export
milt_pinball <- function(actual, quantiles, taus) {
  if (!is.numeric(actual)) {
    milt_abort("{.arg actual} must be a numeric vector.",
               class = "milt_error_invalid_metric_input")
  }
  if (!is.matrix(quantiles) || !is.numeric(quantiles)) {
    milt_abort("{.arg quantiles} must be a numeric matrix (n rows × length(taus) cols).",
               class = "milt_error_invalid_metric_input")
  }
  if (!is.numeric(taus) || any(taus <= 0 | taus >= 1, na.rm = TRUE)) {
    milt_abort("{.arg taus} must be numeric values strictly between 0 and 1.",
               class = "milt_error_invalid_metric_input")
  }
  if (ncol(quantiles) != length(taus)) {
    milt_abort(
      "Number of columns in {.arg quantiles} must equal length of {.arg taus}.",
      class = "milt_error_length_mismatch"
    )
  }
  if (nrow(quantiles) != length(actual)) {
    milt_abort(
      "Number of rows in {.arg quantiles} must equal length of {.arg actual}.",
      class = "milt_error_length_mismatch"
    )
  }

  losses <- matrix(NA_real_, nrow = length(actual), ncol = length(taus))
  for (j in seq_along(taus)) {
    tau <- taus[j]
    q   <- quantiles[, j]
    err <- actual - q
    losses[, j] <- ifelse(err >= 0, tau * err, (tau - 1) * err)
  }
  mean(losses, na.rm = TRUE)
}

#' Winkler Score
#'
#' Evaluates prediction interval sharpness and coverage jointly. A smaller
#' score is better. Penalises observations outside the interval by
#' `2 / alpha * distance_to_interval`.
#'
#' @param actual Numeric vector of observed values.
#' @param lower Numeric vector of lower interval bounds.
#' @param upper Numeric vector of upper interval bounds.
#' @param alpha Nominal miscoverage rate (e.g. `0.05` for a 95 % interval).
#' @return Mean Winkler score across all steps.
#' @family metrics
#' @export
milt_winkler <- function(actual, lower, upper, alpha) {
  .check_numeric_vectors(actual, lower, "actual", "lower")
  .check_numeric_vectors(actual, upper, "actual", "upper")
  if (!is_scalar_numeric(alpha) || alpha <= 0 || alpha >= 1) {
    milt_abort("{.arg alpha} must be a number strictly between 0 and 1.",
               class = "milt_error_invalid_metric_input")
  }
  interval_width <- upper - lower
  penalty <- dplyr::case_when(
    actual < lower ~ (2 / alpha) * (lower - actual),
    actual > upper ~ (2 / alpha) * (actual - upper),
    TRUE           ~ 0
  )
  mean(interval_width + penalty, na.rm = TRUE)
}

# ── Convenience wrapper ───────────────────────────────────────────────────────

#' Compute multiple forecast accuracy metrics at once
#'
#' Returns a tidy tibble of metric names and values. When `metrics = "auto"`,
#' selects point metrics only (probabilistic metrics require additional
#' arguments supplied via `...`).
#'
#' @param actual Numeric vector of observed values. Also accepts a `MiltSeries`
#'   object, in which case values are extracted automatically.
#' @param predicted Numeric vector of point forecast values.
#' @param training Numeric vector of training values (required for MASE and
#'   RMSSE). Optional for all other metrics.
#' @param season Seasonal period for MASE/RMSSE. Default `1`.
#' @param metrics Character vector of metric names to compute, or one of:
#'   - `"auto"` — all metrics computable from `actual` and `predicted`
#'   - `"all"`  — same as `"auto"` (alias)
#'   - `"point"` — point metrics only (excludes MASE/RMSSE if training missing)
#' @return A tibble with columns `metric` (character) and `value` (numeric).
#' @seealso [milt_mae()], [milt_rmse()], [milt_mase()]
#' @family metrics
#' @examples
#' actual    <- c(100, 120, 130, 125, 140)
#' predicted <- c(105, 115, 135, 120, 145)
#' milt_accuracy(actual, predicted)
#' @export
milt_accuracy <- function(actual,
                           predicted,
                           training = NULL,
                           season   = 1L,
                           metrics  = "auto") {

  # Accept MiltSeries for actual
  if (inherits(actual, "MiltSeries")) {
    if (!actual$is_univariate()) {
      milt_abort(
        "{.fn milt_accuracy} currently supports univariate series only.",
        class = "milt_error_not_univariate"
      )
    }
    actual <- actual$values()
  }
  if (inherits(predicted, "MiltSeries")) {
    predicted <- predicted$values()
  }

  .check_numeric_vectors(actual, predicted)

  # Resolve metric set
  point_metrics <- c("MAE", "MSE", "RMSE", "MAPE", "sMAPE", "R2")
  scaled_metrics <- c("MASE", "RMSSE")
  all_point <- if (!is.null(training)) {
    c(point_metrics, scaled_metrics)
  } else {
    point_metrics
  }

  selected <- switch(
    metrics[[1L]],
    auto  = , all = all_point,
    point = point_metrics,
    # else: treat as explicit vector of metric names
    toupper(metrics)
  )

  results <- list()

  if ("MAE"   %in% selected) results[["MAE"]]   <- milt_mae(actual, predicted)
  if ("MSE"   %in% selected) results[["MSE"]]   <- milt_mse(actual, predicted)
  if ("RMSE"  %in% selected) results[["RMSE"]]  <- milt_rmse(actual, predicted)
  if ("MAPE"  %in% selected) {
    results[["MAPE"]] <- tryCatch(
      milt_mape(actual, predicted),
      warning = function(w) suppressWarnings(milt_mape(actual, predicted))
    )
  }
  if ("SMAPE" %in% selected) results[["sMAPE"]] <- milt_smape(actual, predicted)
  if ("R2"    %in% selected) results[["R2"]]    <- milt_r_squared(actual, predicted)

  if (!is.null(training)) {
    if ("MASE"  %in% selected) {
      results[["MASE"]]  <- tryCatch(
        milt_mase(actual, predicted, training, season),
        warning = function(w) NaN
      )
    }
    if ("RMSSE" %in% selected) {
      results[["RMSSE"]] <- tryCatch(
        milt_rmsse(actual, predicted, training, season),
        warning = function(w) NaN
      )
    }
  }

  tibble::tibble(
    metric = names(results),
    value  = unlist(results, use.names = FALSE)
  )
}
