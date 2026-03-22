# Type conversion helpers — convert external formats to/from MiltSeries

# ── Internal generic ──────────────────────────────────────────────────────────

# Dispatches on the class of `x` to build a MiltSeriesR6 object.
# Called internally by milt_series(); not exported directly.
#' @keywords internal
as_milt_series <- function(x, ...) {
  UseMethod("as_milt_series")
}

# ── as_milt_series methods ────────────────────────────────────────────────────

#' @keywords internal
#' @exportS3Method
as_milt_series.MiltSeries <- function(x, ...) x

#' @keywords internal
#' @exportS3Method
as_milt_series.ts <- function(x, value_col = "value", ...) {
  freq <- stats::frequency(x)
  start_year <- stats::start(x)[1L]
  start_per  <- stats::start(x)[2L]

  n <- length(x)
  times <- .ts_times(start_year, start_per, freq, n)
  freq_label <- .ts_freq_label(freq)

  tbl <- tibble::tibble(time = times, !!value_col := as.numeric(x))
  MiltSeriesR6$new(
    data      = tbl,
    time_col  = "time",
    value_cols = value_col,
    frequency = freq_label
  )
}

#' @keywords internal
#' @exportS3Method
as_milt_series.mts <- function(x, ...) {
  freq <- stats::frequency(x)
  start_year <- stats::start(x)[1L]
  start_per  <- stats::start(x)[2L]

  n <- nrow(x)
  times <- .ts_times(start_year, start_per, freq, n)
  freq_label <- .ts_freq_label(freq)

  col_names <- colnames(x) %||% paste0("V", seq_len(ncol(x)))
  tbl <- tibble::as_tibble(x)
  colnames(tbl) <- col_names
  tbl <- tibble::add_column(tbl, time = times, .before = 1L)

  MiltSeriesR6$new(
    data       = tbl,
    time_col   = "time",
    value_cols = col_names,
    frequency  = freq_label
  )
}

#' @keywords internal
#' @exportS3Method
as_milt_series.xts <- function(x, value_col = NULL, ...) {
  check_installed_backend("xts", "xts input")
  times <- zoo::index(x)
  mat   <- zoo::coredata(x)
  if (is.null(dim(mat))) dim(mat) <- c(length(mat), 1L)
  col_names <- colnames(mat) %||%
    if (ncol(mat) == 1L) (value_col %||% "value") else paste0("V", seq_len(ncol(mat)))
  tbl <- tibble::as_tibble(mat)
  colnames(tbl) <- col_names
  tbl <- tibble::add_column(tbl, time = times, .before = 1L)
  freq_label <- .guess_frequency(times)
  MiltSeriesR6$new(
    data       = tbl,
    time_col   = "time",
    value_cols = col_names,
    frequency  = freq_label
  )
}

#' @keywords internal
#' @exportS3Method
as_milt_series.zoo <- function(x, value_col = NULL, ...) {
  check_installed_backend("zoo", "zoo input")
  times <- zoo::index(x)
  mat   <- zoo::coredata(x)
  if (is.null(dim(mat))) dim(mat) <- c(length(mat), 1L)
  col_names <- colnames(mat) %||%
    if (ncol(mat) == 1L) (value_col %||% "value") else paste0("V", seq_len(ncol(mat)))
  tbl <- tibble::as_tibble(mat)
  colnames(tbl) <- col_names
  tbl <- tibble::add_column(tbl, time = times, .before = 1L)
  freq_label <- .guess_frequency(times)
  MiltSeriesR6$new(
    data       = tbl,
    time_col   = "time",
    value_cols = col_names,
    frequency  = freq_label
  )
}

#' @keywords internal
#' @exportS3Method
as_milt_series.tbl_ts <- function(x, value_cols = NULL, group_col = NULL, ...) {
  # tbl_ts = tsibble class
  key_vars  <- tsibble::key_vars(x)
  idx_var   <- tsibble::index_var(x)
  freq_obj  <- tsibble::interval(x)
  freq_label <- .tsibble_interval_label(freq_obj)

  tbl <- tibble::as_tibble(x)

  if (is.null(value_cols)) {
    exclude  <- c(idx_var, key_vars)
    value_cols <- setdiff(names(tbl), exclude)
  }

  group_col <- group_col %||% if (length(key_vars) == 1L) key_vars else NULL

  MiltSeriesR6$new(
    data       = tbl,
    time_col   = idx_var,
    value_cols = value_cols,
    group_col  = group_col,
    frequency  = freq_label
  )
}

#' @keywords internal
#' @exportS3Method
as_milt_series.data.frame <- function(x,
                                       time_col   = NULL,
                                       value_cols = NULL,
                                       group_col  = NULL,
                                       frequency  = NULL,
                                       ...) {
  tbl <- tibble::as_tibble(x)
  .build_miltseries_from_tibble(tbl, time_col, value_cols, group_col, frequency)
}

#' @keywords internal
#' @exportS3Method
as_milt_series.tbl_df <- as_milt_series.data.frame

#' @keywords internal
#' @exportS3Method
as_milt_series.numeric <- function(x,
                                    frequency = NULL,
                                    start     = c(1L, 1L),
                                    value_col = "value",
                                    ...) {
  n <- length(x)
  if (is.null(frequency)) {
    milt_abort(
      c(
        "Must supply {.arg frequency} when creating a {.cls MiltSeries} from a
         numeric vector.",
        "i" = 'Example: {.code milt_series(x, frequency = 12, start = c(1949, 1))}'
      ),
      class = "milt_error_missing_frequency"
    )
  }

  freq_num  <- if (is.character(frequency)) .period_to_frequency(frequency) else frequency
  freq_label <- if (is.character(frequency)) frequency else .ts_freq_label(freq_num)
  times     <- .ts_times(start[1L], start[2L], freq_num, n)

  tbl <- tibble::tibble(time = times, !!value_col := x)
  MiltSeriesR6$new(
    data       = tbl,
    time_col   = "time",
    value_cols = value_col,
    frequency  = freq_label
  )
}

# ── Exported converters ───────────────────────────────────────────────────────

#' Convert a MiltSeries to a base R ts object
#'
#' @param series A `MiltSeries` object. Must be univariate.
#' @return A `ts` object.
#' @export
milt_to_ts <- function(series) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort(
      "Only univariate {.cls MiltSeries} objects can be converted to {.cls ts}.",
      class = "milt_error_not_univariate"
    )
  }
  tbl  <- series$as_tibble()
  vals <- tbl[[series$.__enclos_env__$private$.value_cols]]
  freq <- .freq_label_to_numeric(series$freq())
  stats::ts(vals, frequency = freq)
}

#' Convert a MiltSeries to a tsibble
#'
#' @param series A `MiltSeries` object.
#' @return A `tsibble`.
#' @export
milt_to_tsibble <- function(series) {
  assert_milt_series(series)
  series$as_tsibble()
}

#' Convert a MiltSeries to a tibble
#'
#' @param series A `MiltSeries` object.
#' @return A `tibble`.
#' @export
milt_to_tibble <- function(series) {
  assert_milt_series(series)
  series$as_tibble()
}

# ── Internal helpers ──────────────────────────────────────────────────────────

.build_miltseries_from_tibble <- function(tbl,
                                           time_col,
                                           value_cols,
                                           group_col,
                                           frequency) {
  if (is.null(time_col)) {
    # Guess: first Date/POSIXct column
    date_cols <- names(tbl)[vapply(tbl, function(col) {
      inherits(col, c("Date", "POSIXct", "POSIXt"))
    }, logical(1L))]
    if (length(date_cols) == 0L) {
      milt_abort(
        c(
          "Could not automatically detect a time column in the data.",
          "i" = "Supply {.arg time_col} explicitly."
        ),
        class = "milt_error_no_time_col"
      )
    }
    time_col <- date_cols[1L]
    milt_info("Using {.val {time_col}} as the time column.")
  }

  if (!time_col %in% names(tbl)) {
    milt_abort(
      "Column {.val {time_col}} not found in data.",
      class = "milt_error_no_time_col"
    )
  }

  if (is.null(value_cols)) {
    exclude    <- c(time_col, group_col)
    value_cols <- setdiff(names(tbl), exclude)
    if (length(value_cols) == 0L) {
      milt_abort(
        "No value columns found after excluding the time and group columns.",
        class = "milt_error_no_value_cols"
      )
    }
  }

  freq_label <- frequency %||% .guess_frequency(tbl[[time_col]])

  MiltSeriesR6$new(
    data       = tbl,
    time_col   = time_col,
    value_cols = value_cols,
    group_col  = group_col,
    frequency  = freq_label
  )
}

# Generate a Date sequence matching ts() start/frequency conventions
.ts_times <- function(start_year, start_per, freq, n) {
  if (freq == 12L) {
    # Monthly
    start_date <- lubridate::ymd(
      paste0(start_year, "-", sprintf("%02d", start_per), "-01")
    )
    seq(start_date, by = "month", length.out = n)
  } else if (freq == 4L) {
    # Quarterly
    start_month <- (start_per - 1L) * 3L + 1L
    start_date  <- lubridate::ymd(
      paste0(start_year, "-", sprintf("%02d", start_month), "-01")
    )
    seq(start_date, by = "quarter", length.out = n)
  } else if (freq == 1L) {
    # Annual
    as.Date(paste0(start_year + seq_len(n) - 1L, "-01-01"))
  } else if (freq == 52L) {
    # Weekly
    start_date <- as.Date(
      paste0(start_year, "-01-01")
    ) + (start_per - 1L) * 7L
    seq(start_date, by = "week", length.out = n)
  } else {
    # Generic: use fractional index as numeric (fallback)
    seq(0, by = 1 / freq, length.out = n)
  }
}

.ts_freq_label <- function(freq) {
  switch(as.character(freq),
    "1"   = "annual",
    "4"   = "quarterly",
    "12"  = "monthly",
    "52"  = "weekly",
    "365" = "daily",
    as.character(freq)
  )
}

.freq_label_to_numeric <- function(label) {
  lookup <- c(
    annual    = 1,
    yearly    = 1,
    quarterly = 4,
    monthly   = 12,
    weekly    = 52,
    daily     = 365
  )
  if (label %in% names(lookup)) lookup[[label]] else as.numeric(label)
}

.tsibble_interval_label <- function(interval) {
  # interval is a tsibble interval object
  if (interval$year   > 0L) return("annual")
  if (interval$quarter > 0L) return("quarterly")
  if (interval$month  > 0L) return("monthly")
  if (interval$week   > 0L) return("weekly")
  if (interval$day    > 0L) return("daily")
  if (interval$hour   > 0L) return("hourly")
  if (interval$minute > 0L) return("minutely")
  "unknown"
}

# Convert a Date and numeric frequency to a ts() start = c(year, period) vector
.date_to_ts_start <- function(t, freq) {
  if (!inherits(t, "Date")) return(c(1L, 1L))
  year <- as.integer(format(t, "%Y"))
  period <- if (freq == 12L) {
    as.integer(format(t, "%m"))
  } else if (freq == 4L) {
    ceiling(as.integer(format(t, "%m")) / 3L)
  } else if (freq == 52L) {
    max(1L, as.integer(format(t, "%U")))
  } else {
    1L
  }
  c(year, period)
}

# Generate future Date/POSIXct timestamps following a MiltSeries's frequency
.future_times <- function(series, horizon) {
  freq  <- as.character(series$freq())
  end_t <- series$end_time()

  by_unit <- switch(tolower(freq),
    monthly   = "month",
    quarterly = "quarter",
    annual    = , yearly = "year",
    weekly    = "week",
    daily     = "day",
    hourly    = "hour",
    minutely  = "minute",
    NULL
  )

  if (!is.null(by_unit) && inherits(end_t, c("Date", "POSIXct", "POSIXt"))) {
    return(seq(end_t, by = by_unit, length.out = horizon + 1L)[-1L])
  }

  # Fallback: infer step from last two observations
  times <- series$times()
  n     <- length(times)
  if (n >= 2L) {
    step <- as.numeric(times[[n]]) - as.numeric(times[[n - 1L]])
    if (inherits(end_t, "Date")) {
      return(end_t + seq_len(horizon) * as.integer(round(step)))
    }
    return(seq(end_t + step, by = step, length.out = horizon))
  }
  seq_len(horizon) + as.numeric(end_t)
}
