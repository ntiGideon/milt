# TimeSeries operations mirroring darts.TimeSeries: arithmetic, stacking,
# datetime-attribute components, and a binary holidays component.

# ── Arithmetic operations ─────────────────────────────────────────────────────

#' Arithmetic operators for MiltSeries
#'
#' Supports `+`, `-`, `*`, `/`, and `^` between two `MiltSeries` objects (which
#' must share an identical time index and value columns) or between a
#' `MiltSeries` and a numeric scalar/vector.
#'
#' @param e1,e2 A `MiltSeries` and/or a numeric value.
#' @return A `MiltSeries` with the operation applied element-wise to every
#'   value column.
#' @examples
#' s  <- milt_series(AirPassengers)
#' s2 <- s * 1.05          # a 5% bump
#' s3 <- s2 - s            # the (constant, up to rounding) absolute bump
#' @export
Ops.MiltSeries <- function(e1, e2) {
  op <- .Generic
  if (!op %in% c("+", "-", "*", "/", "^")) {
    milt_abort(
      "{.code {op}} is not supported for {.cls MiltSeries} objects.",
      class = "milt_error_unsupported_op"
    )
  }
  fn <- get(op, mode = "function")

  is_e1_series <- inherits(e1, "MiltSeries")
  is_e2_series <- inherits(e2, "MiltSeries")

  if (is_e1_series && is_e2_series) {
    if (!identical(e1$times(), e2$times())) {
      milt_abort(
        "Arithmetic between two {.cls MiltSeries} requires an identical time index.",
        class = "milt_error_incompatible_series"
      )
    }
    vc1 <- e1$.__enclos_env__$private$.value_cols
    vc2 <- e2$.__enclos_env__$private$.value_cols
    if (!identical(vc1, vc2)) {
      milt_abort(
        "Arithmetic between two {.cls MiltSeries} requires the same value columns.",
        class = "milt_error_incompatible_series"
      )
    }
    tbl1 <- e1$as_tibble()
    tbl2 <- e2$as_tibble()
    out  <- tbl1
    for (col in vc1) out[[col]] <- fn(tbl1[[col]], tbl2[[col]])
    return(e1$clone_with(out))
  }

  series <- if (is_e1_series) e1 else e2
  scalar <- if (is_e1_series) e2 else e1
  if (!is.numeric(scalar)) {
    milt_abort(
      "{.cls MiltSeries} arithmetic requires the other operand to be numeric.",
      class = "milt_error_invalid_arg"
    )
  }

  vc  <- series$.__enclos_env__$private$.value_cols
  tbl <- series$as_tibble()
  for (col in vc) {
    tbl[[col]] <- if (is_e1_series) fn(tbl[[col]], scalar) else fn(scalar, tbl[[col]])
  }
  series$clone_with(tbl)
}

# ── Stacking ───────────────────────────────────────────────────────────────────

#' Stack MiltSeries into one multivariate series
#'
#' Combines two or more `MiltSeries` sharing an identical time index into a
#' single multivariate `MiltSeries`, placing each input's value column(s)
#' side by side as new components. Unlike [milt_concat()] (which concatenates
#' *rows*/time steps), stacking concatenates *columns*.
#'
#' @param ... Two or more `MiltSeries` objects with identical time indices.
#' @return A multivariate `MiltSeries`. Value column names are taken as-is
#'   when unique across inputs, and suffixed with the input's position
#'   (`_2`, `_3`, ...) otherwise.
#' @seealso [milt_concat()], [milt_add_datetime_component()]
#' @family series
#' @examples
#' s   <- milt_series(AirPassengers)
#' sma <- milt_filter(s, "moving_average", window = 12L)
#' stacked <- milt_stack(s, sma)   # components "value", "value_2"
#' stacked$n_components()
#' @export
milt_stack <- function(...) {
  series_list <- list(...)
  if (length(series_list) < 2L) {
    milt_abort("{.fn milt_stack} requires at least two {.cls MiltSeries} objects.",
               class = "milt_error_invalid_arg")
  }
  for (i in seq_along(series_list)) {
    assert_milt_series(series_list[[i]], arg = paste0("series[[", i, "]]"))
  }

  ref   <- series_list[[1L]]
  p_ref <- ref$.__enclos_env__$private
  times <- ref$times()

  for (i in seq(2L, length(series_list))) {
    if (!identical(series_list[[i]]$times(), times)) {
      milt_abort("All series must share an identical time index to stack.",
                 class = "milt_error_incompatible_series")
    }
  }

  out_tbl <- tibble::tibble(.rows = length(times))
  out_tbl[[p_ref$.time_col]] <- times
  new_vcols <- character(0)

  for (i in seq_along(series_list)) {
    s     <- series_list[[i]]
    s_tbl <- s$as_tibble()
    vcols <- s$.__enclos_env__$private$.value_cols
    for (col in vcols) {
      nm <- if (col %in% names(out_tbl) || col %in% new_vcols) paste0(col, "_", i) else col
      out_tbl[[nm]] <- s_tbl[[col]]
      new_vcols <- c(new_vcols, nm)
    }
  }

  MiltSeriesR6$new(
    data       = out_tbl,
    time_col   = p_ref$.time_col,
    value_cols = new_vcols,
    frequency  = p_ref$.frequency
  )
}

# ── Datetime-attribute component ──────────────────────────────────────────────

.extract_datetime_attribute <- function(times, attribute) {
  switch(
    attribute,
    year      = lubridate::year(times),
    month     = lubridate::month(times),
    quarter   = lubridate::quarter(times),
    week      = lubridate::isoweek(times),
    day       = lubridate::day(times),
    dayofweek = lubridate::wday(times, week_start = 1L),
    dayofyear = lubridate::yday(times),
    hour      = lubridate::hour(times),
    milt_abort(
      c("Unsupported {.arg attribute}: {.val {attribute}}.",
        "i" = "Use one of {.val year}, {.val month}, {.val quarter}, {.val week},
              {.val day}, {.val dayofweek}, {.val dayofyear}, {.val hour}."),
      class = "milt_error_invalid_arg"
    )
  )
}

.datetime_attribute_period <- function(attribute) {
  period <- switch(
    attribute,
    month = 12, quarter = 4, week = 52, day = 31,
    dayofweek = 7, dayofyear = 365, hour = 24,
    NA_real_
  )
  if (is.na(period)) {
    milt_abort(
      "{.arg attribute} = {.val {attribute}} has no natural cyclic period; use {.code cyclic = FALSE}.",
      class = "milt_error_invalid_arg"
    )
  }
  period
}

#' Add a datetime attribute as a new series component
#'
#' Extracts a calendar attribute (month, quarter, day of week, ...) from the
#' time index and appends it as a new value column, turning a univariate
#' series multivariate. Mirrors darts' `datetime_attribute_timeseries()`
#' followed by stacking onto the original series.
#'
#' @param series A `MiltSeries` object.
#' @param attribute Character. One of `"year"`, `"month"`, `"quarter"`,
#'   `"week"`, `"day"`, `"dayofweek"`, `"dayofyear"`, `"hour"`.
#' @param cyclic Logical. When `TRUE`, encodes the attribute as a sin/cos pair
#'   (two new components, `<attribute>_sin` / `<attribute>_cos`) instead of a
#'   single raw integer column. Default `FALSE`.
#' @param name Optional character. Name for the new column (raw mode only).
#'   Defaults to `attribute`.
#' @return A multivariate `MiltSeries` with the new component(s) appended.
#' @seealso [milt_add_holidays()], [milt_step_calendar()], [milt_step_fourier()]
#' @family series
#' @examples
#' s   <- milt_series(AirPassengers)
#' s2  <- milt_add_datetime_component(s, "month")
#' s3  <- milt_add_datetime_component(s, "month", cyclic = TRUE)
#' @export
milt_add_datetime_component <- function(series, attribute, cyclic = FALSE, name = NULL) {
  assert_milt_series(series)
  p     <- series$.__enclos_env__$private
  tbl   <- series$as_tibble()
  tc    <- p$.time_col
  times <- tbl[[tc]]

  vals <- .extract_datetime_attribute(times, attribute)

  if (isTRUE(cyclic)) {
    period <- .datetime_attribute_period(attribute)
    nm_sin <- paste0(attribute, "_sin")
    nm_cos <- paste0(attribute, "_cos")
    tbl[[nm_sin]] <- sin(2 * pi * vals / period)
    tbl[[nm_cos]] <- cos(2 * pi * vals / period)
    new_vcols <- c(p$.value_cols, nm_sin, nm_cos)
  } else {
    nm <- name %||% attribute
    tbl[[nm]] <- vals
    new_vcols <- c(p$.value_cols, nm)
  }

  MiltSeriesR6$new(
    data       = tbl,
    time_col   = tc,
    value_cols = new_vcols,
    group_col  = p$.group_col,
    frequency  = p$.frequency,
    metadata   = p$.metadata
  )
}

# ── Binary holidays component ─────────────────────────────────────────────────

.nth_weekday_of_month <- function(year, month, weekday, n) {
  d1     <- as.Date(sprintf("%d-%02d-01", year, month))
  wdays  <- lubridate::wday(d1 + 0:6, week_start = 1L)
  first  <- d1 + (which(wdays == weekday)[[1L]] - 1L)
  first + (n - 1L) * 7L
}

.last_weekday_of_month <- function(year, month, weekday) {
  d1    <- as.Date(sprintf("%d-%02d-01", year, month))
  d_end <- lubridate::ceiling_date(d1, "month") - 1L
  wdays <- lubridate::wday(d_end - 0:6, week_start = 1L)
  d_end - (which(wdays == weekday)[[1L]] - 1L)
}

.us_federal_holidays <- function(year) {
  c(
    as.Date(sprintf("%d-01-01", year)),          # New Year's Day
    .nth_weekday_of_month(year, 1L, 1L, 3L),      # Martin Luther King Jr. Day
    .nth_weekday_of_month(year, 2L, 1L, 3L),      # Washington's Birthday
    .last_weekday_of_month(year, 5L, 1L),         # Memorial Day
    as.Date(sprintf("%d-06-19", year)),          # Juneteenth
    as.Date(sprintf("%d-07-04", year)),          # Independence Day
    .nth_weekday_of_month(year, 9L, 1L, 1L),      # Labor Day
    .nth_weekday_of_month(year, 11L, 4L, 4L),     # Thanksgiving Day
    as.Date(sprintf("%d-12-25", year))           # Christmas Day
  )
}

.country_holidays <- function(country, times) {
  if (toupper(country) != "US") {
    milt_abort(
      c("Built-in holiday calendars are only available for {.val US}.",
        "i" = "Pass a {.arg dates} vector of {.cls Date} objects for other calendars."),
      class = "milt_error_invalid_arg"
    )
  }
  years <- unique(lubridate::year(times))
  do.call(c, lapply(years, .us_federal_holidays))
}

#' Add a binary holidays component
#'
#' Appends a `0`/`1` column flagging whether each timestamp falls on a
#' holiday, turning a univariate series multivariate. Mirrors darts'
#' `holidays_timeseries()`.
#'
#' @param series A `MiltSeries` object.
#' @param dates Optional vector of `Date` holidays. Takes precedence over
#'   `country` when both are supplied.
#' @param country Optional character. Built-in calendar to use when `dates`
#'   is not supplied. Currently only `"US"` (federal holidays) is built in;
#'   use `dates` directly for any other calendar.
#' @param name Character. Name for the new column. Default `"is_holiday"`.
#' @return A multivariate `MiltSeries` with the holiday indicator appended.
#' @seealso [milt_add_datetime_component()]
#' @family series
#' @examples
#' s  <- milt_series(AirPassengers)
#' s2 <- milt_add_holidays(s, country = "US")
#' @export
milt_add_holidays <- function(series, dates = NULL, country = NULL, name = "is_holiday") {
  assert_milt_series(series)
  if (is.null(dates) && is.null(country)) {
    milt_abort("Supply either {.arg dates} or {.arg country}.",
               class = "milt_error_invalid_arg")
  }

  p     <- series$.__enclos_env__$private
  tbl   <- series$as_tibble()
  tc    <- p$.time_col
  times <- tbl[[tc]]

  holiday_dates <- dates %||% .country_holidays(country, times)
  tbl[[name]]   <- as.integer(as.Date(times) %in% as.Date(holiday_dates))

  MiltSeriesR6$new(
    data       = tbl,
    time_col   = tc,
    value_cols = c(p$.value_cols, name),
    group_col  = p$.group_col,
    frequency  = p$.frequency,
    metadata   = p$.metadata
  )
}
