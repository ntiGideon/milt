# Changepoint detection
#
# milt_changepoints() wraps the `changepoint` package (Killick & Eckley 2014).
# Returns a MiltChangepoints object with print / plot / as_tibble methods.

# ── R6 result class ───────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltChangepointsR6 <- R6::R6Class(
  classname = "MiltChangepoints",
  cloneable = FALSE,

  private = list(
    .series   = NULL,   # MiltSeries
    .indices  = NULL,   # integer: 0-based positions of changepoints
    .method   = NULL,   # character
    .stat     = NULL    # character: "mean", "variance", or "meanvar"
  ),

  public = list(

    initialize = function(series, indices, method, stat) {
      private$.series  <- series
      private$.indices <- as.integer(indices)
      private$.method  <- as.character(method)
      private$.stat    <- as.character(stat)
    },

    #' @return The original `MiltSeries`.
    series = function() private$.series,

    #' @return Integer vector of changepoint indices (1-based position).
    indices = function() private$.indices,

    #' @return Integer: number of changepoints detected.
    n_changepoints = function() length(private$.indices),

    #' @return Character: detection method name.
    method = function() private$.method,

    #' @return A tibble with columns `index` and `time`.
    as_tibble = function() {
      s     <- private$.series
      times <- s$times()
      tibble::tibble(
        index = private$.indices,
        time  = times[private$.indices]
      )
    }
  )
)

# ── Constructor wrapper ───────────────────────────────────────────────────────

.new_milt_changepoints <- function(series, indices, method, stat) {
  obj <- MiltChangepointsR6$new(series, indices, method, stat)
  class(obj) <- c("MiltChangepoints", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltChangepoints <- function(x, ...) {
  s  <- x$series()
  nc <- x$n_changepoints()
  cat(glue::glue(
    "# MiltChangepoints [{x$method()}]\n",
    "# Series      : {s$n_timesteps()} obs  {s$start_time()} \u2014 {s$end_time()}\n",
    "# Changepoints: {nc}\n"
  ))
  if (nc > 0L) {
    cat("# Locations:\n")
    print(x$as_tibble())
  }
  invisible(x)
}

#' @export
summary.MiltChangepoints <- function(object, ...) print(object)

#' @export
as_tibble.MiltChangepoints <- function(x, ...) x$as_tibble()

#' @export
plot.MiltChangepoints <- function(x, ...) {
  s     <- x$series()
  tbl   <- s$as_tibble()
  val_col  <- s$.__enclos_env__$private$.value_cols[[1L]]
  time_col <- s$.__enclos_env__$private$.time_col

  cp_tbl <- x$as_tibble()

  p <- ggplot2::ggplot(tbl, ggplot2::aes(x = .data[[time_col]],
                                          y = .data[[val_col]])) +
    ggplot2::geom_line(colour = "#4472C4", linewidth = 0.6) +
    ggplot2::labs(
      title = paste0("Changepoint Detection [", x$method(), "]"),
      subtitle = paste0(x$n_changepoints(), " changepoint(s)"),
      x = "Time", y = "Value"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))

  if (x$n_changepoints() > 0L) {
    p <- p + ggplot2::geom_vline(
      data       = cp_tbl,
      ggplot2::aes(xintercept = .data$time),
      colour     = "#E05C5C",
      linetype   = "dashed",
      linewidth  = 0.8
    )
  }
  p
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Detect changepoints in a time series
#'
#' Wraps the `changepoint` package to identify structural breaks in the mean,
#' variance, or both.
#'
#' @param series A `MiltSeries` object (univariate).
#' @param method Character. Search method: `"pelt"` (default), `"binseg"`, or
#'   `"amoc"` (at-most-one-changepoint).
#' @param stat Character. Test statistic: `"mean"` (default), `"variance"`,
#'   or `"meanvar"`.
#' @param penalty Character. Penalty type passed to the `changepoint` package.
#'   Default `"BIC"`.
#' @param n_cpts Integer or `NA`. Maximum number of changepoints for
#'   `"binseg"`. Ignored for other methods. Default `NA`.
#' @param ... Additional arguments forwarded to the `changepoint` function.
#' @return A `MiltChangepoints` object.
#' @seealso [milt_detector()], [milt_detect()]
#' @family anomaly
#' @examples
#' \donttest{
#' s  <- milt_series(AirPassengers)
#' cp <- milt_changepoints(s, method = "pelt", stat = "mean")
#' plot(cp)
#' }
#' @export
milt_changepoints <- function(series,
                               method  = "pelt",
                               stat    = "mean",
                               penalty = "BIC",
                               n_cpts  = NA,
                               ...) {
  check_installed_backend("changepoint", "milt_changepoints")
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_changepoints} requires a univariate {.cls MiltSeries}.",
      class = "milt_error_not_univariate"
    )
  }

  method <- match.arg(method, c("pelt", "binseg", "amoc", "segneigh"))
  stat   <- match.arg(stat,   c("mean", "variance", "meanvar"))

  vals <- series$values()

  # Select the changepoint function + stat
  cp_fn <- switch(stat,
    "mean"    = changepoint::cpt.mean,
    "variance" = changepoint::cpt.var,
    "meanvar" = changepoint::cpt.meanvar
  )

  cp_method <- switch(
    method,
    pelt = "PELT",
    binseg = "BinSeg",
    amoc = "AMOC",
    segneigh = "SegNeigh"
  )

  args <- list(data = vals, method = cp_method, penalty = penalty, ...)
  if (method %in% c("binseg", "segneigh") && !is.na(n_cpts)) {
    args$Q <- as.integer(n_cpts)
  }

  cp_obj <- tryCatch(
    do.call(cp_fn, args),
    error = function(e) {
      milt_abort(
        c("Changepoint detection failed.", "x" = conditionMessage(e)),
        class = "milt_error_detection_failed"
      )
    }
  )

  # Extract 1-based indices (changepoint package returns them as integers)
  raw_cpts <- changepoint::cpts(cp_obj)
  # The last index (= n) is always returned for some methods; remove it
  indices  <- raw_cpts[raw_cpts < length(vals)]

  .new_milt_changepoints(
    series  = series,
    indices = as.integer(indices),
    method  = method,
    stat    = stat
  )
}
