#' Create a MiltSeries object
#'
#' The main entry point for constructing time series objects in milt. Accepts
#' a wide variety of input formats and returns a consistent `MiltSeries`.
#'
#' @param x Input data. One of:
#'   - A `ts` or `mts` object
#'   - An `xts` object
#'   - A `zoo` object
#'   - A `tsibble`
#'   - A `data.frame` or `tibble`
#'   - A numeric vector (requires `frequency` and `start`)
#' @param time_col Name of the time column when `x` is a data frame or tibble.
#'   Auto-detected when `NULL`.
#' @param value_cols Character vector of value column names. Auto-detected when
#'   `NULL` (all non-time, non-group columns).
#' @param group_col Name of the grouping column for multi-series data frames.
#'   `NULL` for single series.
#' @param frequency Frequency label (`"monthly"`, `"quarterly"`, `"daily"`,
#'   etc.) or a numeric value. Auto-detected from the time index when `NULL`.
#' @param start For numeric vector input only: a length-2 integer vector
#'   `c(year, period)`, matching the convention of [stats::ts()].
#' @param value_col Convenience alias for `value_cols` when creating a
#'   single-component series.
#' @param ... Additional arguments passed to underlying conversion methods.
#'
#' @return A `MiltSeries` object.
#'
#' @seealso [milt_split()], [milt_window()], [milt_fill_gaps()],
#'   [milt_diagnose()]
#' @family series
#'
#' @examples
#' # From a base R ts object
#' s <- milt_series(AirPassengers)
#' print(s)
#'
#' # From a data.frame
#' df <- data.frame(
#'   date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
#'   sales = cumsum(rnorm(24, 100, 10))
#' )
#' s2 <- milt_series(df, time_col = "date", value_cols = "sales")
#'
#' # From a numeric vector
#' s3 <- milt_series(as.numeric(AirPassengers), frequency = 12,
#'                   start = c(1949, 1))
#'
#' @export
milt_series <- function(x,
                         time_col   = NULL,
                         value_cols = NULL,
                         group_col  = NULL,
                         frequency  = NULL,
                         start      = c(1L, 1L),
                         value_col  = NULL,
                         ...) {

  # value_col is a convenience alias for value_cols
  if (!is.null(value_col) && is.null(value_cols)) value_cols <- value_col

  # Dispatch to as_milt_series() S3 methods in utils-conversions.R
  # Important: base `ts` objects are also numeric vectors, so the numeric
  # fallback must come after structured time-series dispatch.
  if (inherits(x, "tbl_ts")) {
    # tsibble
    as_milt_series.tbl_ts(
      x,
      value_cols = value_cols,
      group_col  = group_col,
      ...
    )
  } else if (inherits(x, c("data.frame", "tbl_df"))) {
    # data.frame / tibble
    as_milt_series.data.frame(
      x,
      time_col   = time_col,
      value_cols = value_cols,
      group_col  = group_col,
      frequency  = frequency,
      ...
    )
  } else if (is.numeric(x) && is.null(dim(x)) && !stats::is.ts(x)) {
    # Plain numeric vector path — needs frequency and start
    as_milt_series.numeric(
      x,
      frequency = frequency,
      start     = start,
      value_col = value_cols %||% "value",
      ...
    )
  } else {
    # ts, mts, xts, zoo, MiltSeries — dispatch on class
    as_milt_series(x, value_col = value_cols %||% value_col %||% "value", ...)
  }
}
