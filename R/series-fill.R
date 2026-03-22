# Gap detection and imputation for MiltSeries

#' Fill gaps in a MiltSeries
#'
#' Identifies missing time steps, inserts rows with `NA` values for them, then
#' imputes using the chosen method.
#'
#' @param series A `MiltSeries` object.
#' @param method Imputation method. One of:
#'   - `"linear"` — linear interpolation (default)
#'   - `"spline"` — cubic spline interpolation
#'   - `"locf"`   — last observation carried forward
#'   - `"nocb"`   — next observation carried backward
#'   - `"mean"`   — column mean
#'   - `"zero"`   — replace with 0
#' @return A `MiltSeries` with no gaps.
#' @seealso [milt_diagnose()]
#' @family series
#' @examples
#' s <- milt_series(AirPassengers)
#' # Artificially introduce a gap
#' tbl <- s$as_tibble()[-c(10, 11), ]
#' s_gap <- milt_series(tbl, time_col = "time", value_cols = "value",
#'                       frequency = "monthly")
#' s_filled <- milt_fill_gaps(s_gap, method = "linear")
#' @export
milt_fill_gaps <- function(series, method = "linear") {
  assert_milt_series(series)
  valid_methods <- c("linear", "spline", "locf", "nocb", "mean", "zero")
  if (!is_scalar_character(method) || !method %in% valid_methods) {
    milt_abort(
      c(
        "{.arg method} must be one of {.val {valid_methods}}, not {.val {method}}."
      ),
      class = "milt_error_invalid_method"
    )
  }

  if (!series$has_gaps()) {
    milt_info("Series has no gaps; returning unchanged.")
    return(series)
  }

  p   <- series$.__enclos_env__$private
  tc  <- p$.time_col
  vcs <- p$.value_cols
  gc  <- p$.group_col
  tbl <- series$as_tibble()

  if (is.null(gc)) {
    filled <- .fill_single_series(tbl, tc, vcs, series$freq(), method)
  } else {
    groups <- unique(tbl[[gc]])
    filled <- dplyr::bind_rows(lapply(groups, function(g) {
      sub <- tbl[tbl[[gc]] == g, ]
      res <- .fill_single_series(sub, tc, vcs, series$freq(), method)
      res[[gc]] <- g
      res
    }))
    filled <- dplyr::arrange(filled, dplyr::across(tidyr::all_of(c(tc, gc))))
  }

  series$clone_with(filled)
}

# ── Internal helpers ──────────────────────────────────────────────────────────

# Fills a single-group tibble (no group column)
.fill_single_series <- function(tbl, tc, vcs, freq, method) {
  complete_times <- .complete_time_sequence(tbl[[tc]], freq)

  # Create a shell with all time steps
  shell <- tibble::tibble(!!tc := complete_times)

  # Left join to insert NAs at the missing steps
  full <- dplyr::left_join(shell, tbl, by = tc)

  # Impute each value column
  for (col in vcs) {
    full[[col]] <- .impute(full[[col]], method)
  }

  full
}

# Generate a complete regular time sequence between min and max observed times
.complete_time_sequence <- function(times, freq) {
  times <- sort(unique(times))
  t_min <- min(times)
  t_max <- max(times)

  by_unit <- switch(tolower(as.character(freq)),
    annual    = , yearly = "year",
    quarterly = "quarter",
    monthly   = "month",
    weekly    = "week",
    daily     = "day",
    hourly    = "hour",
    minutely  = "minute",
    NULL
  )

  if (!is.null(by_unit) && inherits(t_min, "Date")) {
    return(seq(t_min, t_max, by = by_unit))
  }
  if (!is.null(by_unit) && inherits(t_min, c("POSIXct", "POSIXt"))) {
    return(seq(t_min, t_max, by = by_unit))
  }

  # Fallback: infer step from minimum observed difference
  diffs <- diff(as.numeric(times))
  step  <- min(diffs[diffs > 0])

  if (inherits(t_min, "Date")) {
    n <- round((as.numeric(t_max) - as.numeric(t_min)) / step) + 1L
    seq(t_min, by = step, length.out = n)
  } else if (inherits(t_min, c("POSIXct", "POSIXt"))) {
    seq(t_min, t_max, by = step)
  } else {
    seq(t_min, t_max, by = step)
  }
}

# Impute a vector of values using the chosen method
.impute <- function(x, method) {
  n <- length(x)
  switch(method,
    linear = {
      idx <- seq_len(n)
      stats::approx(idx[!is.na(x)], x[!is.na(x)], xout = idx,
                    method = "linear", rule = 2)$y
    },
    spline = {
      idx <- seq_len(n)
      if (sum(!is.na(x)) < 3L) {
        # Not enough points for spline — fall back to linear
        stats::approx(idx[!is.na(x)], x[!is.na(x)], xout = idx,
                      method = "linear", rule = 2)$y
      } else {
        stats::spline(idx[!is.na(x)], x[!is.na(x)], xout = idx,
                      method = "natural")$y
      }
    },
    locf = .locf(x),
    nocb = rev(.locf(rev(x))),
    mean = {
      m <- mean(x, na.rm = TRUE)
      x[is.na(x)] <- m
      x
    },
    zero = {
      x[is.na(x)] <- 0
      x
    }
  )
}

# Last observation carried forward
.locf <- function(x) {
  last_val <- NA_real_
  for (i in seq_along(x)) {
    if (!is.na(x[i])) {
      last_val <- x[i]
    } else {
      x[i] <- last_val
    }
  }
  x
}
