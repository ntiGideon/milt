# Rolling-window feature engineering step

# ── Internal helper ────────────────────────────────────────────────────────────

.rolling_fn <- function(x, window, fn_name) {
  n   <- length(x)
  out <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    if (i < window) next
    chunk <- x[(i - window + 1L):i]
    out[[i]] <- switch(fn_name,
      mean   = mean(chunk,   na.rm = TRUE),
      sd     = stats::sd(chunk,     na.rm = TRUE),
      median = stats::median(chunk, na.rm = TRUE),
      min    = min(chunk,    na.rm = TRUE),
      max    = max(chunk,    na.rm = TRUE),
      sum    = sum(chunk,    na.rm = TRUE),
      NA_real_
    )
  }
  out
}

# ── milt_step_rolling ─────────────────────────────────────────────────────────

#' Add rolling-window summary features to a MiltSeries
#'
#' For each combination of `windows` and `fns`, appends one column named
#' `.rolling_<fn>_<window>` to the series tibble.  The first `max(windows) - 1`
#' rows (where the window is incomplete) are dropped.
#'
#' @param series A univariate `MiltSeries`.
#' @param windows Integer vector of window sizes (in number of observations).
#'   Default `c(7L, 14L, 30L)`.
#' @param fns Character vector of summary functions to apply within each window.
#'   Supported: `"mean"`, `"sd"`, `"median"`, `"min"`, `"max"`, `"sum"`.
#'   Default `c("mean", "sd")`.
#' @return An augmented `MiltSeries` with additional rolling-feature columns
#'   and `max(windows) - 1` fewer rows.  Attribute `"milt_step_rolling"`
#'   stores the step specification.
#' @seealso [milt_step_lag()], [milt_step_fourier()], [milt_step_calendar()]
#' @family features
#' @examples
#' s     <- milt_series(AirPassengers)
#' s_rol <- milt_step_rolling(s, windows = c(3L, 6L), fns = "mean")
#' head(s_rol$as_tibble())
#' @export
milt_step_rolling <- function(series,
                               windows = c(7L, 14L, 30L),
                               fns     = c("mean", "sd")) {
  assert_milt_series(series)
  windows <- as.integer(windows)
  fns     <- match.arg(fns,
                        choices    = c("mean", "sd", "median", "min", "max", "sum"),
                        several.ok = TRUE)

  if (length(windows) == 0L || any(windows < 1L)) {
    milt_abort("{.arg windows} must be a non-empty vector of positive integers.",
               class = "milt_error_invalid_arg")
  }
  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_step_rolling} currently supports univariate series only.",
      class = "milt_error_not_univariate"
    )
  }

  vals       <- series$values()
  n          <- length(vals)
  max_window <- max(windows)

  if (n < max_window) {
    milt_abort(
      c(
        "Series is too short for the requested window size.",
        "i" = "Need at least {max_window} observations; series has {n}."
      ),
      class = "milt_error_insufficient_data"
    )
  }

  tbl <- series$as_tibble()

  for (w in windows) {
    for (fn in fns) {
      col_name    <- paste0(".rolling_", fn, "_", w)
      tbl[[col_name]] <- .rolling_fn(vals, w, fn)
    }
  }

  # Drop incomplete rows (first max_window - 1)
  drop_n <- max_window - 1L
  tbl    <- tbl[(drop_n + 1L):nrow(tbl), ]
  tbl    <- tibble::as_tibble(tbl)

  result <- series$clone_with(tbl)
  attr(result, "milt_step_rolling") <- list(
    windows     = windows,
    fns         = fns,
    last_values = utils::tail(vals, max_window - 1L)
  )
  result
}
