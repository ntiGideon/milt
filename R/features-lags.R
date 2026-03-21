# Lag feature engineering step

# ── Internal helper ────────────────────────────────────────────────────────────

# Compute lag features on a numeric vector, returning a matrix.
# Row k of the output contains c(x[k-lags[1]], x[k-lags[2]], ...).
.compute_lags <- function(x, lags) {
  n  <- length(x)
  out <- matrix(NA_real_, nrow = n, ncol = length(lags))
  colnames(out) <- paste0(".lag_", lags)
  for (i in seq_along(lags)) {
    l <- lags[[i]]
    if (l >= n) next
    out[(l + 1L):n, i] <- x[seq_len(n - l)]
  }
  out
}

# ── milt_step_lag ─────────────────────────────────────────────────────────────

#' Add lag features to a MiltSeries
#'
#' Appends one column per lag value to the series tibble. Rows where any lag
#' column is `NA` (the first `max(lags)` rows) are dropped. The original value
#' column is retained unchanged.
#'
#' The returned `MiltSeries` carries a `"milt_step_lag"` attribute that records
#' which lags were used and the last `max(lags)` training values needed to
#' generate lag features for future observations.
#'
#' @param series A univariate `MiltSeries`.
#' @param lags Integer vector of lag values. Default `1:12`.
#' @return An augmented `MiltSeries` with additional columns `.lag_1`,
#'   `.lag_2`, … (one per element of `lags`) and `max(lags)` fewer rows.
#'   The attribute `"milt_step_lag"` stores the step specification.
#' @seealso [milt_step_rolling()], [milt_step_fourier()], [milt_step_calendar()]
#' @family features
#' @examples
#' s      <- milt_series(AirPassengers)
#' s_lag  <- milt_step_lag(s, lags = 1:3)
#' head(s_lag$as_tibble())
#' @export
milt_step_lag <- function(series, lags = 1:12) {
  assert_milt_series(series)
  lags <- as.integer(lags)
  if (length(lags) == 0L || any(lags < 1L)) {
    milt_abort("{.arg lags} must be a non-empty vector of positive integers.",
               class = "milt_error_invalid_arg")
  }
  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_step_lag} currently supports univariate series only.",
      class = "milt_error_not_univariate"
    )
  }

  vals    <- series$values()
  n       <- length(vals)
  max_lag <- max(lags)

  if (n <= max_lag) {
    milt_abort(
      c(
        "Series is too short for {.arg lags}.",
        "i" = "Need more than {max_lag} observations; series has {n}."
      ),
      class = "milt_error_insufficient_data"
    )
  }

  lag_mat <- .compute_lags(vals, lags)
  tbl     <- series$as_tibble()

  # Bind lag columns
  lag_tbl <- as.data.frame(lag_mat, stringsAsFactors = FALSE)
  tbl     <- cbind(tbl, lag_tbl)

  # Drop rows with NA lags (first max_lag rows)
  tbl <- tbl[(max_lag + 1L):nrow(tbl), ]
  tbl <- tibble::as_tibble(tbl)

  result <- series$clone_with(tbl)
  attr(result, "milt_step_lag") <- list(
    lags        = lags,
    last_values = utils::tail(vals, max_lag)  # for re-application to new data
  )
  result
}
