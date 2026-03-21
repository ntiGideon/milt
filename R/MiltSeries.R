# R6 class backing MiltSeries + all S3 method registrations

# ── R6 class ──────────────────────────────────────────────────────────────────

#' @title MiltSeries — core time series object
#' @description
#' The foundational data structure for the milt package. Every model, detector,
#' and pipeline operates on `MiltSeries` objects. Create one with
#' [milt_series()].
#'
#' @export
MiltSeriesR6 <- R6::R6Class(
  classname = "MiltSeries",
  cloneable = TRUE,

  private = list(
    .data        = NULL,  # tibble: time col + value col(s) [+ group col]
    .time_col    = NULL,  # character scalar
    .value_cols  = NULL,  # character vector (length >= 1)
    .group_col   = NULL,  # character scalar or NULL
    .frequency   = NULL,  # character or numeric label
    .static_covs = NULL,  # tibble or NULL
    .past_covs   = NULL,  # tibble or NULL
    .future_covs = NULL,  # tibble or NULL
    .metadata    = NULL   # named list
  ),

  public = list(

    #' @description Create a new MiltSeries.
    #' @param data A tibble containing time + value columns.
    #' @param time_col Name of the time column.
    #' @param value_cols Character vector of value column names.
    #' @param group_col Optional name of the grouping column (multi-series).
    #' @param frequency Frequency label (e.g. `"monthly"`, `"daily"`) or
    #'   numeric. Auto-detected when `NULL`.
    #' @param metadata Named list of arbitrary metadata.
    initialize = function(data,
                          time_col,
                          value_cols,
                          group_col  = NULL,
                          frequency  = NULL,
                          metadata   = list()) {

      if (!tibble::is_tibble(data)) data <- tibble::as_tibble(data)

      # ── validate columns ──────────────────────────────────────────────────
      if (!is_scalar_character(time_col)) {
        milt_abort(
          "{.arg time_col} must be a single string.",
          class = "milt_error_invalid_series"
        )
      }
      if (!time_col %in% names(data)) {
        milt_abort(
          "Column {.val {time_col}} (time_col) not found in data.",
          class = "milt_error_invalid_series"
        )
      }
      missing_vals <- setdiff(value_cols, names(data))
      if (length(missing_vals) > 0L) {
        milt_abort(
          c(
            "value_col{?s} not found in data: {.val {missing_vals}}.",
            "i" = "Available columns: {.val {setdiff(names(data), time_col)}}."
          ),
          class = "milt_error_invalid_series"
        )
      }
      if (!is.null(group_col)) {
        if (!is_scalar_character(group_col)) {
          milt_abort(
            "{.arg group_col} must be a single string or NULL.",
            class = "milt_error_invalid_series"
          )
        }
        if (!group_col %in% names(data)) {
          milt_abort(
            "Column {.val {group_col}} (group_col) not found in data.",
            class = "milt_error_invalid_series"
          )
        }
      }

      private$.data        <- data
      private$.time_col    <- time_col
      private$.value_cols  <- value_cols
      private$.group_col   <- group_col
      private$.frequency   <- frequency %||% .guess_frequency(data[[time_col]])
      private$.metadata    <- metadata
    },

    # ── Dimension accessors ────────────────────────────────────────────────

    #' @description Number of time steps (rows per series).
    n_timesteps = function() {
      n <- nrow(private$.data)
      if (self$is_multi_series()) n %/% self$n_series() else n
    },

    #' @description Number of value columns (components).
    n_components = function() length(private$.value_cols),

    #' @description Number of individual series (groups).
    n_series = function() {
      if (is.null(private$.group_col)) return(1L)
      length(unique(private$.data[[private$.group_col]]))
    },

    #' @description First timestamp.
    start_time = function() min(private$.data[[private$.time_col]], na.rm = TRUE),

    #' @description Last timestamp.
    end_time   = function() max(private$.data[[private$.time_col]], na.rm = TRUE),

    #' @description Frequency label.
    freq = function() private$.frequency,

    #' @description `TRUE` if there is exactly one value column.
    is_univariate   = function() length(private$.value_cols) == 1L,

    #' @description `TRUE` if there are multiple value columns.
    is_multivariate = function() length(private$.value_cols) > 1L,

    #' @description `TRUE` if a group column is set.
    is_multi_series = function() !is.null(private$.group_col),

    # ── Gap detection ──────────────────────────────────────────────────────

    #' @description `TRUE` if the time index contains gaps.
    has_gaps = function() nrow(self$gaps()) > 0L,

    #' @description Return a tibble describing each gap.
    gaps = function() {
      tc    <- private$.time_col
      times <- sort(unique(private$.data[[tc]]))
      empty <- tibble::tibble(
        gap_start = times[integer(0L)],
        gap_end   = times[integer(0L)]
      )
      if (length(times) < 2L) return(empty)

      diffs    <- diff(as.numeric(times))
      expected <- min(diffs)
      gap_idx  <- which(diffs > expected * 1.5)
      if (length(gap_idx) == 0L) return(empty)

      tibble::tibble(
        gap_start = times[gap_idx],
        gap_end   = times[gap_idx + 1L]
      )
    },

    # ── Data extraction ────────────────────────────────────────────────────

    #' @description Extract values as a numeric vector (univariate) or matrix.
    values = function() {
      mat <- as.matrix(private$.data[, private$.value_cols, drop = FALSE])
      if (ncol(mat) == 1L) as.numeric(mat[, 1L]) else mat
    },

    #' @description Extract the time column as a vector.
    times = function() private$.data[[private$.time_col]],

    #' @description Return the underlying data as a tibble.
    as_tibble = function() private$.data,

    #' @description Convert to a tsibble.
    as_tsibble = function() {
      rlang::check_installed("tsibble", reason = "to convert a MiltSeries to tsibble.")
      tc  <- rlang::sym(private$.time_col)
      tbl <- private$.data
      if (is.null(private$.group_col)) {
        tsibble::as_tsibble(tbl, index = !!tc)
      } else {
        gc <- rlang::sym(private$.group_col)
        tsibble::as_tsibble(tbl, index = !!tc, key = !!gc)
      }
    },

    #' @description Convert to a base `ts` object (univariate only).
    as_ts = function() {
      if (!self$is_univariate()) {
        milt_abort(
          c(
            "Only univariate {.cls MiltSeries} objects can be converted to
             {.cls ts}.",
            "i" = "Use {.fn milt_to_tibble} for multivariate series."
          ),
          class = "milt_error_not_univariate"
        )
      }
      vals  <- self$values()
      freq  <- .freq_label_to_numeric(as.character(private$.frequency))
      start <- .date_to_ts_start(self$start_time(), as.integer(freq))
      stats::ts(vals, frequency = freq, start = start)
    },

    #' @description Create a new `MiltSeries` with the same metadata but
    #'   different underlying data.
    #' @param data A tibble with the same column structure.
    clone_with = function(data) {
      MiltSeriesR6$new(
        data       = data,
        time_col   = private$.time_col,
        value_cols = private$.value_cols,
        group_col  = private$.group_col,
        frequency  = private$.frequency,
        metadata   = private$.metadata
      )
    }
  )
)

# ── S3 methods ────────────────────────────────────────────────────────────────

#' Print a MiltSeries
#'
#' @param x A `MiltSeries` object.
#' @param n Number of rows to preview. Default 6.
#' @param ... Ignored.
#' @export
print.MiltSeries <- function(x, n = 6L, ...) {
  p     <- x$.__enclos_env__$private
  freq  <- as.character(x$freq() %||% "unknown")
  n_ts  <- x$n_timesteps()
  n_cmp <- x$n_components()
  n_ser <- x$n_series()

  # Header line
  header <- if (x$is_multi_series()) {
    glue::glue("# A MiltSeries: {n_ts} x {n_cmp} [{freq}] | {n_ser} series")
  } else {
    glue::glue("# A MiltSeries: {n_ts} x {n_cmp} [{freq}]")
  }

  # Time range
  t_start <- .format_time_label(x$start_time(), freq)
  t_end   <- .format_time_label(x$end_time(), freq)
  time_range <- glue::glue("# Time range : {t_start} \u2014 {t_end}")

  # Components
  comps <- paste(p$.value_cols, collapse = ", ")
  comp_line <- glue::glue("# Components : {comps}")

  # Group
  group_line <- if (x$is_multi_series()) {
    glue::glue("# Groups     : {p$.group_col} ({n_ser} series)")
  } else {
    NULL
  }

  # Gaps
  gap_line <- if (x$has_gaps()) {
    n_gaps <- nrow(x$gaps())
    glue::glue("# Gaps       : {n_gaps} detected \u2014 use milt_fill_gaps()")
  } else {
    "# Gaps       : none"
  }

  cat(header, "\n", sep = "")
  cat(time_range, "\n", sep = "")
  cat(comp_line,  "\n", sep = "")
  if (!is.null(group_line)) cat(group_line, "\n", sep = "")
  cat(gap_line,   "\n", sep = "")

  # Data preview via tibble print
  tbl    <- x$as_tibble()
  n_show <- min(n, nrow(tbl))
  print(tbl[seq_len(n_show), ], n = n_show, ...)

  if (nrow(tbl) > n_show) {
    cat(glue::glue("# \u2026 with {nrow(tbl) - n_show} more rows\n"))
  }

  invisible(x)
}

#' Summarise a MiltSeries
#'
#' Returns descriptive statistics for each value column.
#'
#' @param object A `MiltSeries` object.
#' @param ... Ignored.
#' @export
summary.MiltSeries <- function(object, ...) {
  p    <- object$.__enclos_env__$private
  tbl  <- object$as_tibble()
  cat(glue::glue(
    "MiltSeries: {object$n_timesteps()} observations",
    " | frequency: {object$freq()}",
    " | {object$n_components()} component(s)\n\n"
  ))
  stats_tbl <- do.call(rbind, lapply(p$.value_cols, function(col) {
    v <- tbl[[col]]
    data.frame(
      component = col,
      min       = min(v, na.rm = TRUE),
      q1        = stats::quantile(v, 0.25, na.rm = TRUE),
      median    = stats::median(v, na.rm = TRUE),
      mean      = mean(v, na.rm = TRUE),
      q3        = stats::quantile(v, 0.75, na.rm = TRUE),
      max       = max(v, na.rm = TRUE),
      nas       = sum(is.na(v)),
      row.names = NULL
    )
  }))
  print(stats_tbl)
  invisible(stats_tbl)
}

# plot.MiltSeries and autoplot.MiltSeries are defined in R/series-plot.R

#' @export
as.data.frame.MiltSeries <- function(x, ...) as.data.frame(x$as_tibble())

#' @export
as_tibble.MiltSeries <- function(x, ...) x$as_tibble()

#' @export
length.MiltSeries <- function(x) x$n_timesteps()

#' @export
dim.MiltSeries <- function(x) c(x$n_timesteps(), x$n_components())

#' Subset a MiltSeries by row index
#'
#' @param x A `MiltSeries` object.
#' @param i Integer index, logical vector, or a length-2 Date/POSIXct vector
#'   specifying `c(start, end)`.
#' @param ... Ignored.
#' @export
`[.MiltSeries` <- function(x, i, ...) {
  tbl <- x$as_tibble()
  tc  <- x$.__enclos_env__$private$.time_col

  if (inherits(i, c("Date", "POSIXct", "POSIXt"))) {
    if (length(i) == 2L) {
      mask <- tbl[[tc]] >= i[1L] & tbl[[tc]] <= i[2L]
      return(x$clone_with(tbl[mask, ]))
    }
  }
  x$clone_with(tbl[i, ])
}

#' @export
head.MiltSeries <- function(x, n = 6L, ...) {
  tbl <- x$as_tibble()
  x$clone_with(utils::head(tbl, n))
}

#' @export
tail.MiltSeries <- function(x, n = 6L, ...) {
  tbl <- x$as_tibble()
  x$clone_with(utils::tail(tbl, n))
}

# ── Internal print helper ─────────────────────────────────────────────────────

.format_time_label <- function(t, freq) {
  freq <- tolower(as.character(freq))
  if (inherits(t, "Date")) {
    fmt <- switch(freq,
      monthly   = "%Y %b",
      quarterly = "%Y Q%q",
      annual    = , yearly = "%Y",
      "%Y-%m-%d"
    )
    # %q is not a standard strftime format — handle manually
    if (freq == "quarterly") {
      q <- ceiling(as.integer(format(t, "%m")) / 3L)
      return(paste0(format(t, "%Y"), " Q", q))
    }
    return(format(t, fmt))
  }
  as.character(t)
}
