# Time series manipulation: splitting, windowing, resampling, concatenation

# ── Splitting ─────────────────────────────────────────────────────────────────

#' Split a MiltSeries into train and test sets
#'
#' Splits by proportion of total observations. For multi-series, the split
#' ratio applies per group.
#'
#' @param series A `MiltSeries` object.
#' @param ratio A number strictly between 0 and 1. The fraction of observations
#'   used for training. Default `0.8`.
#' @return A named list with elements `train` and `test`, each a `MiltSeries`.
#' @seealso [milt_split_at()], [milt_window()]
#' @family series
#' @examples
#' s      <- milt_series(AirPassengers)
#' splits <- milt_split(s, ratio = 0.8)
#' splits$train
#' splits$test
#' @export
milt_split <- function(series, ratio = 0.8) {
  assert_milt_series(series)
  assert_proportion(ratio)

  tbl <- series$as_tibble()
  p   <- series$.__enclos_env__$private
  tc  <- p$.time_col
  gc  <- p$.group_col

  if (is.null(gc)) {
    n       <- nrow(tbl)
    n_train <- floor(n * ratio)
    list(
      train = series$clone_with(tbl[seq_len(n_train), ]),
      test  = series$clone_with(tbl[seq(n_train + 1L, n), ])
    )
  } else {
    # Apply per group, preserving order
    groups <- unique(tbl[[gc]])
    train_rows <- integer(0L)
    test_rows  <- integer(0L)
    for (g in groups) {
      idx     <- which(tbl[[gc]] == g)
      n_train <- floor(length(idx) * ratio)
      train_rows <- c(train_rows, idx[seq_len(n_train)])
      test_rows  <- c(test_rows,  idx[seq(n_train + 1L, length(idx))])
    }
    list(
      train = series$clone_with(tbl[train_rows, ]),
      test  = series$clone_with(tbl[test_rows,  ])
    )
  }
}

#' Split a MiltSeries at a specific time point
#'
#' Everything strictly before `time` goes to `train`; `time` and after go to
#' `test`.
#'
#' @param series A `MiltSeries` object.
#' @param time A scalar `Date` or `POSIXct` value marking the split point.
#' @return A named list with elements `train` and `test`.
#' @seealso [milt_split()], [milt_window()]
#' @family series
#' @examples
#' s      <- milt_series(AirPassengers)
#' splits <- milt_split_at(s, as.Date("1957-01-01"))
#' @export
milt_split_at <- function(series, time) {
  assert_milt_series(series)
  if (length(time) != 1L) {
    milt_abort(
      "{.arg time} must be a single date/time value.",
      class = "milt_error_invalid_time"
    )
  }

  tbl <- series$as_tibble()
  tc  <- series$.__enclos_env__$private$.time_col
  times_col <- tbl[[tc]]

  list(
    train = series$clone_with(tbl[times_col <  time, ]),
    test  = series$clone_with(tbl[times_col >= time, ])
  )
}

# ── Windowing ─────────────────────────────────────────────────────────────────

#' Subset a MiltSeries to a time window
#'
#' Returns only observations within `[start, end]` (both inclusive). Either
#' bound may be `NULL` to impose no limit on that side.
#'
#' @param series A `MiltSeries` object.
#' @param start Start of the window (`Date`, `POSIXct`, or `NULL`).
#' @param end   End of the window (`Date`, `POSIXct`, or `NULL`).
#' @param group Optional group value for grouped series. When supplied, only
#'   observations from that group are retained before applying the time window.
#' @return A `MiltSeries` containing only the windowed observations.
#' @seealso [milt_split()], [milt_split_at()]
#' @family series
#' @examples
#' s <- milt_series(AirPassengers)
#' milt_window(s, start = as.Date("1953-01-01"), end = as.Date("1956-12-01"))
#' @export
milt_window <- function(series, start = NULL, end = NULL, group = NULL) {
  assert_milt_series(series)
  if (is.null(start) && is.null(end) && is.null(group)) {
    milt_warn("Both {.arg start} and {.arg end} are NULL; returning series unchanged.")
    return(series)
  }

  tbl <- series$as_tibble()
  p   <- series$.__enclos_env__$private
  tc  <- p$.time_col
  gc  <- p$.group_col
  t   <- tbl[[tc]]

  mask <- rep(TRUE, nrow(tbl))
  if (!is.null(group)) {
    if (is.null(gc)) {
      milt_abort(
        "{.arg group} can only be used with grouped {.cls MiltSeries} objects.",
        class = "milt_error_invalid_arg"
      )
    }
    mask <- mask & (tbl[[gc]] == group)
  }
  if (!is.null(start)) mask <- mask & (t >= start)
  if (!is.null(end))   mask <- mask & (t <= end)

  if (!any(mask)) {
    milt_abort(
      "No observations fall within the specified window.",
      class = "milt_error_empty_window"
    )
  }

  series$clone_with(tbl[mask, ])
}

# ── Resampling ────────────────────────────────────────────────────────────────

#' Change the temporal resolution of a MiltSeries
#'
#' Aggregates the series to a lower frequency by applying `agg_fn` within each
#' period bucket.
#'
#' @param series A `MiltSeries` object.
#' @param period Target period as a string: `"daily"`, `"weekly"`,
#'   `"monthly"`, `"quarterly"`, or `"annual"`.
#' @param agg_fn Aggregation function. Default `mean`. Must accept a numeric
#'   vector and return a scalar (e.g., `sum`, `median`, `max`).
#' @return A `MiltSeries` at the new frequency.
#' @family series
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' # Already monthly — upsample not supported, but annual works
#' milt_resample(s, "annual", sum)
#' }
#' @export
milt_resample <- function(series, period, agg_fn = mean) {
  assert_milt_series(series)
  if (!is_scalar_character(period)) {
    milt_abort(
      "{.arg period} must be a single string such as {.val monthly}.",
      class = "milt_error_invalid_period"
    )
  }
  if (!is.function(agg_fn)) {
    milt_abort("{.arg agg_fn} must be a function.", class = "milt_error_invalid_arg")
  }

  p   <- series$.__enclos_env__$private
  tc  <- p$.time_col
  vcs <- p$.value_cols
  gc  <- p$.group_col
  tbl <- series$as_tibble()

  # Build the bucket key from lubridate::floor_date
  unit <- .period_to_floor_unit(period)
  tbl[[".__bucket__"]] <- lubridate::floor_date(
    lubridate::as_datetime(tbl[[tc]]),
    unit = unit
  )
  # Convert back to Date when the original was Date
  if (inherits(tbl[[tc]], "Date")) {
    tbl[[".__bucket__"]] <- as.Date(tbl[[".__bucket__"]])
  }

  grp_vars <- c(".__bucket__", gc)

  agg <- dplyr::summarise(
    dplyr::group_by(tbl, dplyr::across(tidyr::all_of(grp_vars))),
    dplyr::across(tidyr::all_of(vcs), agg_fn),
    .groups = "drop"
  )
  agg <- dplyr::rename(agg, !!tc := ".__bucket__")
  agg <- dplyr::arrange(agg, dplyr::across(tidyr::all_of(c(tc, gc))))

  MiltSeriesR6$new(
    data       = agg,
    time_col   = tc,
    value_cols = vcs,
    group_col  = gc,
    frequency  = period
  )
}

# ── head / tail ───────────────────────────────────────────────────────────────

#' Return the first n observations of a MiltSeries
#'
#' @param series A `MiltSeries` object.
#' @param n Number of observations to return. Default 6.
#' @return A `MiltSeries`.
#' @family series
#' @export
milt_head <- function(series, n = 6L) {
  assert_milt_series(series)
  assert_positive_integer(n, "n")
  head(series, n)
}

#' Return the last n observations of a MiltSeries
#'
#' @param series A `MiltSeries` object.
#' @param n Number of observations to return. Default 6.
#' @return A `MiltSeries`.
#' @family series
#' @export
milt_tail <- function(series, n = 6L) {
  assert_milt_series(series)
  assert_positive_integer(n, "n")
  tail(series, n)
}

# ── Concatenation ─────────────────────────────────────────────────────────────

#' Concatenate MiltSeries objects along the time axis
#'
#' Binds two or more `MiltSeries` objects that share the same columns and
#' frequency into a single series. Rows are sorted by time after binding.
#'
#' @param ... Two or more `MiltSeries` objects.
#' @return A `MiltSeries` spanning the union of all time points.
#' @family series
#' @examples
#' s      <- milt_series(AirPassengers)
#' splits <- milt_split(s)
#' s_back <- milt_concat(splits$train, splits$test)
#' @export
milt_concat <- function(...) {
  series_list <- list(...)
  if (length(series_list) < 2L) {
    milt_abort(
      "{.fn milt_concat} requires at least two {.cls MiltSeries} objects.",
      class = "milt_error_invalid_arg"
    )
  }
  for (i in seq_along(series_list)) {
    assert_milt_series(series_list[[i]], arg = paste0("series[[", i, "]]"))
  }

  # Use first series as the template; check structural compatibility
  ref <- series_list[[1L]]
  p   <- ref$.__enclos_env__$private
  tc  <- p$.time_col
  vcs <- p$.value_cols
  gc  <- p$.group_col

  for (i in seq(2L, length(series_list))) {
    s <- series_list[[i]]
    sp <- s$.__enclos_env__$private
    if (!identical(sort(sp$.value_cols), sort(vcs))) {
      milt_abort(
        "All series must have the same value columns to concatenate.",
        class = "milt_error_incompatible_series"
      )
    }
    if (!identical(sp$.time_col, tc)) {
      milt_abort(
        "All series must share the same time column name to concatenate.",
        class = "milt_error_incompatible_series"
      )
    }
  }

  combined <- dplyr::bind_rows(lapply(series_list, function(s) s$as_tibble()))
  combined <- dplyr::arrange(combined, dplyr::across(tidyr::all_of(c(tc, gc))))
  combined <- dplyr::distinct(combined, dplyr::across(tidyr::all_of(c(tc, gc))),
                               .keep_all = TRUE)

  ref$clone_with(combined)
}

# ── Internal helpers ──────────────────────────────────────────────────────────

.period_to_floor_unit <- function(period) {
  switch(tolower(period),
    daily     = "day",
    weekly    = "week",
    monthly   = "month",
    quarterly = "quarter",
    annual    = , yearly = "year",
    hourly    = "hour",
    minutely  = "minute",
    milt_abort(
      "Unknown period {.val {period}} for resampling.",
      class = "milt_error_unknown_period"
    )
  )
}
