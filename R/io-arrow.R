# Parquet I/O for MiltSeries data via the `arrow` package.
#
# Unlike milt_save()/milt_load() (which serialise any milt object, including
# fitted models, to an RDS-based .milt file), these functions read and write
# the tabular *data* of a MiltSeries to/from the columnar Parquet format —
# useful for large or multi-series datasets shared with non-R tools.

#' Write a MiltSeries to a Parquet file
#'
#' @param series A `MiltSeries` object.
#' @param path Character. Destination file path.
#' @param ... Additional arguments forwarded to [arrow::write_parquet()].
#' @return `path` (invisibly).
#' @seealso [milt_read_parquet()]
#' @family series
#' @examples
#' \donttest{
#' if (requireNamespace("arrow", quietly = TRUE)) {
#'   s   <- milt_series(AirPassengers)
#'   tmp <- tempfile(fileext = ".parquet")
#'   milt_write_parquet(s, tmp)
#'   s2  <- milt_read_parquet(tmp, time_col = "time", value_cols = "value",
#'                             frequency = "monthly")
#' }
#' }
#' @export
milt_write_parquet <- function(series, path, ...) {
  check_installed_backend("arrow", "milt_write_parquet")
  assert_milt_series(series)

  tryCatch(
    arrow::write_parquet(series$as_tibble(), path, ...),
    error = function(e) {
      milt_abort(
        c("Failed to write Parquet file to {.file {path}}.", "x" = conditionMessage(e)),
        class = "milt_error_io"
      )
    }
  )
  milt_info("Wrote {.file {path}}.")
  invisible(path)
}

#' Read a MiltSeries from a Parquet file
#'
#' @param path Character. Path to a Parquet file.
#' @param time_col Name of the time column. Auto-detected when `NULL`.
#' @param value_cols Character vector of value column names. Auto-detected
#'   when `NULL`.
#' @param group_col Name of the grouping column for multi-series data.
#'   `NULL` for single series.
#' @param frequency Frequency label (`"monthly"`, `"quarterly"`, etc.) or a
#'   numeric value. Auto-detected from the time index when `NULL`.
#' @param ... Additional arguments forwarded to [arrow::read_parquet()].
#' @return A `MiltSeries` object.
#' @seealso [milt_write_parquet()]
#' @family series
#' @export
milt_read_parquet <- function(path,
                               time_col   = NULL,
                               value_cols = NULL,
                               group_col  = NULL,
                               frequency  = NULL,
                               ...) {
  check_installed_backend("arrow", "milt_read_parquet")
  if (!file.exists(path)) {
    milt_abort("File not found: {.file {path}}.", class = "milt_error_io")
  }

  tbl <- tryCatch(
    arrow::read_parquet(path, ...),
    error = function(e) {
      milt_abort(
        c("Failed to read Parquet file from {.file {path}}.", "x" = conditionMessage(e)),
        class = "milt_error_io"
      )
    }
  )

  milt_series(
    tbl,
    time_col   = time_col,
    value_cols = value_cols,
    group_col  = group_col,
    frequency  = frequency
  )
}
