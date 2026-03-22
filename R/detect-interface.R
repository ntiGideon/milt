# Anomaly detector interface
#
# milt_detector(name, ...) — create a detector configuration object.
# milt_detect(detector, series) — run detection, return MiltAnomalies.
#
# Every detector backend inherits from MiltDetectorBase and overrides detect().

# ── Base detector class ───────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltDetectorBase <- R6::R6Class(
  classname = "MiltDetector",
  cloneable = TRUE,

  private = list(
    .name   = NULL,   # character
    .params = NULL    # list of hyperparameters
  ),

  public = list(

    initialize = function(name = NULL, ...) {
      private$.name   <- name %||% class(self)[[1L]]
      private$.params <- list(...)
    },

    # Run detection on a MiltSeries. Override in each backend.
    detect = function(series, ...) {
      milt_abort(
        "Backend {.cls {class(self)[[1L]]}} must implement {.fn detect}.",
        class = "milt_error_not_implemented"
      )
    },

    # Return the detector name string.
    name = function() private$.name,

    # Return the detector hyperparameter list.
    get_params = function() private$.params
  )
)

#' @export
print.MiltDetector <- function(x, ...) {
  p <- x$.__enclos_env__$private
  cat(glue::glue("# A MiltDetector <{p$.name}>\n"))
  if (length(p$.params) > 0L) {
    param_str <- paste(
      names(p$.params), "=",
      vapply(p$.params, function(v) paste(as.character(v), collapse = ", "),
             character(1L)),
      collapse = "; "
    )
    cat(glue::glue("# Params: {param_str}\n"))
  }
  invisible(x)
}

# ── Public verbs ──────────────────────────────────────────────────────────────

#' Create an anomaly detector
#'
#' Returns an unfitted detector object.  Pass it to [milt_detect()] along
#' with a `MiltSeries` to run detection.
#'
#' @param name Character. Detector name: `"stl"`, `"iqr"`, `"gesd"`,
#'   `"grubbs"`, `"iforest"`, `"lof"`, `"autoencoder"`, or `"ensemble"`.
#' @param ... Hyperparameters forwarded to the detector constructor.
#' @return A `MiltDetector` object.
#' @seealso [milt_detect()]
#' @family anomaly
#' @examples
#' d <- milt_detector("iqr", k = 1.5)
#' @export
milt_detector <- function(name, ...) {
  if (!is_scalar_character(name)) {
    milt_abort(
      "{.arg name} must be a single character string.",
      class = "milt_error_invalid_arg"
    )
  }
  cls <- switch(name,
    "stl"         = MiltDetectorSTL,
    "iqr"         = MiltDetectorIQR,
    "gesd"        = MiltDetectorGESD,
    "grubbs"      = MiltDetectorGrubbs,
    "iforest"     = MiltDetectorIForest,
    "lof"         = MiltDetectorLOF,
    "autoencoder" = MiltDetectorAutoencoder,
    "ensemble"    = MiltDetectorEnsemble,
    milt_abort(
      c(
        "Unknown detector {.val {name}}.",
        "i" = "Available: {.val stl}, {.val iqr}, {.val gesd}, {.val grubbs},",
        "i" = "           {.val iforest}, {.val lof}, {.val autoencoder}, {.val ensemble}."
      ),
      class = "milt_error_unknown_detector"
    )
  )
  cls$new(...)
}

#' Detect anomalies in a time series
#'
#' Runs the detector's algorithm on `series` and returns a `MiltAnomalies`
#' object containing binary labels and continuous anomaly scores.
#'
#' @param detector A `MiltDetector` created by [milt_detector()].
#' @param series A `MiltSeries` object (univariate).
#' @param ... Additional arguments forwarded to the detector's `detect()`
#'   method.
#' @return A `MiltAnomalies` object.
#' @seealso [milt_detector()]
#' @family anomaly
#' @examples
#' s <- milt_series(AirPassengers)
#' d <- milt_detector("iqr", k = 1.5)
#' a <- milt_detect(d, s)
#' @export
milt_detect <- function(detector, series, ...) {
  if (!inherits(detector, "MiltDetector")) {
    milt_abort(
      "{.arg detector} must be a {.cls MiltDetector} created by {.fn milt_detector}.",
      class = "milt_error_not_milt_detector"
    )
  }
  assert_milt_series(series)
  detector$detect(series, ...)
}
