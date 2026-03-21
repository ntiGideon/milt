# Ensemble anomaly detector
#
# Combines the outputs of multiple MiltDetector objects.
# Supports two aggregation strategies:
#   "majority" — flag a point when more than half of the detectors do
#   "mean"     — flag a point when the mean anomaly score exceeds threshold

MiltDetectorEnsemble <- R6::R6Class(
  classname = "MiltDetectorEnsemble",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param detectors A list of `MiltDetector` objects created by
    #'   [milt_detector()].
    #' @param method Character. Aggregation method: `"majority"` (default) or
    #'   `"mean"`.
    #' @param threshold Numeric. For `method = "mean"`: normalised score
    #'   threshold. Default `0.5`.
    initialize = function(detectors, method = "majority", threshold = 0.5) {
      if (!is.list(detectors) || length(detectors) == 0L) {
        milt_abort(
          "{.arg detectors} must be a non-empty list of {.cls MiltDetector} objects.",
          class = "milt_error_invalid_arg"
        )
      }
      if (!all(vapply(detectors, inherits, logical(1L), "MiltDetector"))) {
        milt_abort(
          "All elements of {.arg detectors} must be {.cls MiltDetector} objects.",
          class = "milt_error_invalid_arg"
        )
      }
      method <- match.arg(method, c("majority", "mean"))
      super$initialize(
        name      = "ensemble",
        method    = method,
        threshold = as.numeric(threshold)
      )
      private$.detectors <- detectors
    },

    detect = function(series, ...) {
      assert_milt_series(series)
      p   <- private$.params
      n   <- series$n_timesteps()

      # Run each member detector
      results <- lapply(private$.detectors, function(d) {
        tryCatch(
          d$detect(series, ...),
          error = function(e) {
            milt_warn("Detector {.val {d$name()}} failed: {conditionMessage(e)}")
            NULL
          }
        )
      })
      results <- Filter(Negate(is.null), results)

      if (length(results) == 0L) {
        milt_abort("All member detectors failed.", class = "milt_error_detection_failed")
      }

      # Collect binary labels and scores
      label_mat <- matrix(
        unlist(lapply(results, function(r) as.integer(r$is_anomaly()))),
        nrow = n
      )
      # Normalise scores to [0,1] per detector then average
      score_mat <- matrix(
        unlist(lapply(results, function(r) {
          sc <- r$anomaly_score()
          rng <- range(sc, na.rm = TRUE)
          if (diff(rng) < 1e-10) return(sc * 0)
          (sc - rng[1L]) / diff(rng)
        })),
        nrow = n
      )

      mean_score <- rowMeans(score_mat, na.rm = TRUE)

      is_anomaly <- if (p$method == "majority") {
        rowMeans(label_mat, na.rm = TRUE) > 0.5
      } else {
        mean_score > p$threshold
      }

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = mean_score,
        method        = "ensemble"
      )
    }
  ),

  private = list(
    .detectors = NULL
  )
)
