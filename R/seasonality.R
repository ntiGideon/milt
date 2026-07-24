# Seasonality inspection — mirrors darts.utils.statistics.check_seasonality().

#' Check whether a series has a significant seasonal period
#'
#' Searches the ACF for the strongest local maximum among the significant
#' lags (per Bartlett's formula for the standard error of the ACF under a
#' white-noise null) and reports it as the detected seasonal period.
#'
#' @param series A univariate `MiltSeries` object.
#' @param max_lag Positive integer. Largest lag to examine. Default `24L`.
#' @param alpha Significance level for the Bartlett bound. Default `0.05`.
#' @return A list with:
#'   * `is_seasonal` — logical.
#'   * `period` — integer lag of the strongest significant local maximum, or
#'     `NA_integer_` when none is found.
#' @seealso [milt_eda()], [milt_diagnose()]
#' @family series
#' @examples
#' s <- milt_series(AirPassengers)
#' milt_check_seasonality(s)
#' @export
milt_check_seasonality <- function(series, max_lag = 24L, alpha = 0.05) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort("{.fn milt_check_seasonality} requires a univariate {.cls MiltSeries}.",
               class = "milt_error_not_univariate")
  }
  v <- series$values()
  n <- length(v)
  max_lag <- min(as.integer(max_lag), n - 1L)
  if (max_lag < 2L) {
    milt_abort("Series is too short to inspect seasonality.",
               class = "milt_error_insufficient_data")
  }

  acf_vals <- stats::acf(v, lag.max = max_lag, plot = FALSE, na.action = stats::na.pass)$acf[-1L]
  n_lags   <- length(acf_vals)

  # Bartlett's formula: SE of the ACF at lag k under a white-noise null,
  # accounting for all shorter significant lags.
  bartlett_se <- sqrt((1 + 2 * cumsum(acf_vals^2)) / n)
  z <- stats::qnorm(1 - alpha / 2)
  significant <- abs(acf_vals) > z * bartlett_se

  is_local_max <- logical(n_lags)
  for (i in seq(2L, n_lags - 1L)) {
    is_local_max[[i]] <- acf_vals[[i]] > acf_vals[[i - 1L]] && acf_vals[[i]] > acf_vals[[i + 1L]]
  }

  candidates <- which(is_local_max & significant)
  if (length(candidates) == 0L) {
    return(list(is_seasonal = FALSE, period = NA_integer_))
  }

  best <- candidates[[which.max(acf_vals[candidates])]]
  list(is_seasonal = TRUE, period = as.integer(best))
}
