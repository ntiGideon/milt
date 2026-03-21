# MiltAnomalies R6 class + S3 methods
#
# Returned by milt_detect().  Stores the original series alongside binary
# anomaly labels, continuous anomaly scores, and the detection method name.

# ── R6 class ──────────────────────────────────────────────────────────────────

MiltAnomaliesR6 <- R6::R6Class(
  classname = "MiltAnomalies",
  cloneable = FALSE,

  private = list(
    .series        = NULL,   # MiltSeries
    .is_anomaly    = NULL,   # logical vector (length = n_timesteps)
    .anomaly_score = NULL,   # numeric vector (higher = more anomalous)
    .method        = NULL    # character: detector name
  ),

  public = list(

    initialize = function(series, is_anomaly, anomaly_score, method) {
      private$.series        <- series
      private$.is_anomaly    <- as.logical(is_anomaly)
      private$.anomaly_score <- as.numeric(anomaly_score)
      private$.method        <- as.character(method)
    },

    #' @return The original `MiltSeries`.
    series = function() private$.series,

    #' @return Logical vector: `TRUE` where an anomaly was detected.
    is_anomaly = function() private$.is_anomaly,

    #' @return Numeric vector of anomaly scores (higher = more anomalous).
    anomaly_score = function() private$.anomaly_score,

    #' @return Character: the name of the detection method.
    method = function() private$.method,

    #' @return Integer: number of detected anomalies.
    n_anomalies = function() sum(private$.is_anomaly, na.rm = TRUE),

    #' @return A tibble with columns `time`, `value`, `.is_anomaly`,
    #'   `.anomaly_score`.
    as_tibble = function() {
      s   <- private$.series
      tbl <- s$as_tibble()
      val_col <- s$.__enclos_env__$private$.value_cols[[1L]]
      tibble::tibble(
        time           = tbl[[s$.__enclos_env__$private$.time_col]],
        value          = tbl[[val_col]],
        .is_anomaly    = private$.is_anomaly,
        .anomaly_score = private$.anomaly_score
      )
    }
  )
)

# ── Constructor (internal) ────────────────────────────────────────────────────

.new_milt_anomalies <- function(series, is_anomaly, anomaly_score, method) {
  obj <- MiltAnomaliesR6$new(series, is_anomaly, anomaly_score, method)
  class(obj) <- c("MiltAnomalies", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' Print a MiltAnomalies object
#'
#' @param x A `MiltAnomalies` object.
#' @param ... Ignored.
#' @export
print.MiltAnomalies <- function(x, ...) {
  s   <- x$series()
  n   <- s$n_timesteps()
  na  <- x$n_anomalies()
  pct <- round(100 * na / n, 1)
  cat(glue::glue(
    "# MiltAnomalies [{x$method()}]\n",
    "# Series    : {n} observations  {s$start_time()} \u2014 {s$end_time()}\n",
    "# Anomalies : {na} / {n} ({pct}%)\n"
  ))
  tbl <- x$as_tibble()
  if (na > 0L) {
    cat("# Anomalous times:\n")
    print(tbl[tbl$.is_anomaly, c("time", "value", ".anomaly_score")],
          n = min(na, 10L))
  }
  invisible(x)
}

#' Summarise a MiltAnomalies object
#'
#' @param object A `MiltAnomalies` object.
#' @param ... Ignored.
#' @export
summary.MiltAnomalies <- function(object, ...) {
  print(object)
}

#' Convert MiltAnomalies to tibble
#'
#' @param x A `MiltAnomalies` object.
#' @param ... Ignored.
#' @return A [tibble::tibble()] with columns `time`, `value`, `.is_anomaly`,
#'   `.anomaly_score`.
#' @export
as_tibble.MiltAnomalies <- function(x, ...) {
  x$as_tibble()
}

#' Plot a MiltAnomalies object
#'
#' Draws the time series with anomalous points highlighted in red.
#'
#' @param x A `MiltAnomalies` object.
#' @param ... Ignored.
#' @return A `ggplot2` plot object.
#' @export
plot.MiltAnomalies <- function(x, ...) {
  tbl    <- x$as_tibble()
  anom   <- tbl[tbl$.is_anomaly, ]
  normal <- tbl[!tbl$.is_anomaly, ]

  ggplot2::ggplot(tbl, ggplot2::aes(x = .data$time, y = .data$value)) +
    ggplot2::geom_line(colour = "#4472C4", linewidth = 0.6) +
    ggplot2::geom_point(data = anom,
                        ggplot2::aes(x = .data$time, y = .data$value),
                        colour = "#E05C5C", size = 3, shape = 21,
                        fill = "#E05C5C", alpha = 0.8) +
    ggplot2::labs(
      title    = paste0("Anomaly Detection [", x$method(), "]"),
      subtitle = paste0(x$n_anomalies(), " anomalies detected"),
      x        = "Time",
      y        = "Value"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
}

#' @export
autoplot.MiltAnomalies <- function(object, ...) plot.MiltAnomalies(object, ...)
