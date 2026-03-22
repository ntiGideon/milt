# Internal utilities and validation helpers

# Null-default operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# ── Scalar type checks ────────────────────────────────────────────────────────

is_scalar_character <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

is_scalar_numeric <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x)
}

is_scalar_logical <- function(x) {
  is.logical(x) && length(x) == 1L && !is.na(x)
}

is_scalar_integer <- function(x) {
  (is.integer(x) || (is.numeric(x) && x == floor(x))) &&
    length(x) == 1L && !is.na(x)
}

# ── Object assertions ─────────────────────────────────────────────────────────

#' Assert that an object is a MiltSeries
#'
#' @param x Object to check.
#' @param arg Name of the argument (for error messages).
#' @noRd
assert_milt_series <- function(x, arg = "series") {
  if (!inherits(x, "MiltSeries")) {
    milt_abort(
      c(
        "{.arg {arg}} must be a {.cls MiltSeries} object.",
        "i" = "Create one with {.fn milt_series}."
      ),
      class = "milt_error_not_milt_series"
    )
  }
  invisible(x)
}

#' Assert that a value is a positive integer
#'
#' @param x Value to check.
#' @param arg Name of the argument (for error messages).
#' @noRd
assert_positive_integer <- function(x, arg = "n") {
  if (!is_scalar_integer(x) || x < 1L) {
    milt_abort(
      "{.arg {arg}} must be a positive integer, not {.val {x}}.",
      class = "milt_error_invalid_integer"
    )
  }
  invisible(x)
}

#' Assert that a value is a non-negative integer
#'
#' @param x Value to check.
#' @param arg Name of the argument (for error messages).
#' @noRd
assert_non_negative_integer <- function(x, arg = "n") {
  if (!is_scalar_integer(x) || x < 0L) {
    milt_abort(
      "{.arg {arg}} must be a non-negative integer, not {.val {x}}.",
      class = "milt_error_invalid_integer"
    )
  }
  invisible(x)
}

#' Assert that a value is a number in the interval `[0, 1]`
#'
#' @param x Value to check.
#' @param arg Name of the argument (for error messages).
#' @noRd
assert_proportion <- function(x, arg = "ratio") {
  if (!is_scalar_numeric(x) || x <= 0 || x >= 1) {
    milt_abort(
      "{.arg {arg}} must be a number strictly between 0 and 1, not {.val {x}}.",
      class = "milt_error_invalid_proportion"
    )
  }
  invisible(x)
}

# ── Frequency helpers ─────────────────────────────────────────────────────────

# Map human-readable period strings to numeric frequency
.period_to_frequency <- function(period) {
  lookup <- c(
    "daily"     = 365,
    "weekly"    = 52,
    "monthly"   = 12,
    "quarterly" = 4,
    "annual"    = 1,
    "yearly"    = 1,
    "hourly"    = 8760,
    "minutely"  = 525600
  )
  freq <- lookup[tolower(period)]
  if (is.na(freq)) {
    milt_abort(
      "Unknown period {.val {period}}. Use one of: {.val {names(lookup)}}.",
      class = "milt_error_unknown_period"
    )
  }
  unname(freq)
}

# Guess frequency from a time vector (Date or POSIXct)
.guess_frequency <- function(times) {
  if (length(times) < 2L) return(NA_real_)

  diffs <- as.numeric(diff(times), units = "secs")
  med_diff <- stats::median(diffs, na.rm = TRUE)

  # Map median gap to a named frequency
  if (med_diff < 90) return("secondly")          # < 1.5 min
  if (med_diff < 5400) return("minutely")        # < 1.5 hr
  if (med_diff < 43200) return("hourly")         # < 12 hr
  if (med_diff < 86400 * 3) return("daily")      # ~1-3 days
  if (med_diff < 86400 * 10) return("weekly")    # ~1 week
  if (med_diff < 86400 * 45) return("monthly")   # ~1 month
  if (med_diff < 86400 * 120) return("quarterly")
  "annual"
}
