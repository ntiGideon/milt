# Calendar feature engineering step

# ── Internal helpers ───────────────────────────────────────────────────────────

.add_calendar_cols <- function(tbl, time_col, freq_str) {
  t <- tbl[[time_col]]
  is_date    <- inherits(t, "Date")
  is_posixct <- inherits(t, c("POSIXct", "POSIXt"))

  if (!is_date && !is_posixct) {
    # Integer / numeric index — only year-like index possible
    tbl[[".calendar_index"]] <- seq_len(nrow(tbl))
    return(tbl)
  }

  freq_lower <- tolower(freq_str)

  # Always add for Date and POSIXct
  tbl[[".year"]]       <- as.integer(format(t, "%Y"))
  tbl[[".month"]]      <- as.integer(format(t, "%m"))
  tbl[[".quarter"]]    <- (as.integer(format(t, "%m")) - 1L) %/% 3L + 1L
  tbl[[".week"]]       <- as.integer(format(t, "%V"))  # ISO week
  tbl[[".day_of_week"]] <- as.integer(format(t, "%u")) # ISO: 1=Mon, 7=Sun
  tbl[[".is_weekend"]] <- as.integer(tbl[[".day_of_week"]] >= 6L)

  # Day of month (only for sub-monthly data)
  if (freq_lower %in% c("daily", "hourly", "minutely")) {
    tbl[[".day_of_month"]] <- as.integer(format(t, "%d"))
  }

  # Hour (only for sub-daily data)
  if (is_posixct && freq_lower %in% c("hourly", "minutely")) {
    tbl[[".hour"]] <- as.integer(format(t, "%H"))
  }

  # Minute (only for minute-level data)
  if (is_posixct && freq_lower == "minutely") {
    tbl[[".minute"]] <- as.integer(format(t, "%M"))
  }

  tbl
}

# ── milt_step_calendar ────────────────────────────────────────────────────────

#' Add calendar features to a MiltSeries
#'
#' Appends date/time decomposition columns (year, month, quarter, week,
#' day-of-week, weekend indicator, and sub-daily components as appropriate).
#' No rows are dropped — calendar features are defined for every time step.
#'
#' The set of columns added adapts automatically to the series frequency:
#'
#' | Frequency | Columns added |
#' |---|---|
#' | monthly, quarterly, annual | `.year`, `.month`, `.quarter`, `.week`, `.day_of_week`, `.is_weekend` |
#' | daily | + `.day_of_month` |
#' | hourly | + `.hour` |
#' | minutely | + `.minute` |
#'
#' @param series A `MiltSeries` with `Date` or `POSIXct` time index.
#' @return An augmented `MiltSeries` with calendar columns appended.
#'   Attribute `"milt_step_calendar"` stores the step specification.
#' @seealso [milt_step_lag()], [milt_step_rolling()], [milt_step_fourier()]
#' @family features
#' @examples
#' s     <- milt_series(AirPassengers)
#' s_cal <- milt_step_calendar(s)
#' head(s_cal$as_tibble())
#' @export
milt_step_calendar <- function(series) {
  assert_milt_series(series)

  p        <- series$.__enclos_env__$private
  tbl      <- series$as_tibble()
  freq_str <- as.character(series$freq())
  tbl      <- .add_calendar_cols(tbl, p$.time_col, freq_str)
  tbl      <- tibble::as_tibble(tbl)

  result <- series$clone_with(tbl)
  attr(result, "milt_step_calendar") <- list(
    freq     = freq_str,
    time_col = p$.time_col
  )
  result
}
