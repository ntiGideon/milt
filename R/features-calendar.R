# Calendar feature engineering step

# Internal helpers

.add_calendar_cols <- function(tbl, time_col, freq_str) {
  t <- tbl[[time_col]]
  is_date <- inherits(t, "Date")
  is_posixct <- inherits(t, c("POSIXct", "POSIXt"))

  if (!is_date && !is_posixct) {
    # Integer / numeric index: only an index counter can be added.
    tbl[[".calendar_index"]] <- seq_len(nrow(tbl))
    return(tbl)
  }

  freq_lower <- tolower(freq_str)

  # Always add for Date and POSIXct.
  tbl[[".year"]] <- as.integer(format(t, "%Y"))
  tbl[[".month"]] <- as.integer(format(t, "%m"))
  tbl[[".quarter"]] <- (as.integer(format(t, "%m")) - 1L) %/% 3L + 1L
  tbl[[".week"]] <- as.integer(format(t, "%V"))
  tbl[[".day_of_week"]] <- as.integer(format(t, "%u"))
  tbl[[".is_weekend"]] <- as.integer(tbl[[".day_of_week"]] >= 6L)

  if (freq_lower %in% c("daily", "hourly", "minutely")) {
    tbl[[".day_of_month"]] <- as.integer(format(t, "%d"))
  }

  if (is_posixct && freq_lower %in% c("hourly", "minutely")) {
    tbl[[".hour"]] <- as.integer(format(t, "%H"))
  }

  if (is_posixct && freq_lower == "minutely") {
    tbl[[".minute"]] <- as.integer(format(t, "%M"))
  }

  tbl
}

#' Add calendar features to a MiltSeries
#'
#' Appends date/time decomposition columns (year, month, quarter, week,
#' day-of-week, weekend indicator, and sub-daily components as appropriate).
#' No rows are dropped: calendar features are defined for every time step.
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
#' @param features Optional character vector of calendar feature names to keep.
#'   By default, all supported features for the series frequency are added.
#' @return An augmented `MiltSeries` with calendar columns appended.
#'   Attribute `"milt_step_calendar"` stores the step specification.
#' @seealso [milt_step_lag()], [milt_step_rolling()], [milt_step_fourier()]
#' @family features
#' @examples
#' s <- milt_series(AirPassengers)
#' s_cal <- milt_step_calendar(s)
#' head(s_cal$as_tibble())
#' @export
milt_step_calendar <- function(series, features = NULL) {
  assert_milt_series(series)

  p <- series$.__enclos_env__$private
  original_tbl <- series$as_tibble()
  tbl <- original_tbl
  freq_str <- as.character(series$freq())
  tbl <- .add_calendar_cols(tbl, p$.time_col, freq_str)

  if (!is.null(features)) {
    allowed <- grep("^\\.", names(tbl), value = TRUE)
    requested <- paste0(".", gsub("^\\.", "", as.character(features)))
    missing_features <- setdiff(requested, allowed)
    if (length(missing_features) > 0L) {
      milt_abort(
        c(
          "{.arg features} contains unsupported calendar feature name{?s}.",
          "i" = "Unknown: {.val {missing_features}}.",
          "i" = "Available: {.val {allowed}}."
        ),
        class = "milt_error_invalid_arg"
      )
    }
    keep <- c(names(original_tbl), requested)
    tbl <- tbl[, unique(keep), drop = FALSE]
  }

  tbl <- tibble::as_tibble(tbl)

  result <- series$clone_with(tbl)
  attr(result, "milt_step_calendar") <- list(
    freq = freq_str,
    time_col = p$.time_col,
    features = features
  )
  result
}
