# Local Outlier Factor (LOF) anomaly detector (requires dbscan package)
#
# Computes the LOF score for each observation based on its neighbours in the
# (value, time-index) feature space.  Scores substantially > 1 indicate
# local density anomalies.

#' @keywords internal
#' @noRd
MiltDetectorLOF <- R6::R6Class(
  classname = "MiltDetectorLOF",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param k Integer. Number of nearest neighbours. Default `5L`.
    #' @param threshold Numeric. LOF score above which a point is flagged.
    #'   Default `1.5` (scores much greater than 1 are outliers).
    #' @param use_time Logical. Include the time index as a feature alongside
    #'   the observed value. Default `FALSE`.
    initialize = function(k         = 5L,
                          threshold = 1.5,
                          use_time  = FALSE) {
      super$initialize(
        name      = "lof",
        k         = as.integer(k),
        threshold = as.numeric(threshold),
        use_time  = as.logical(use_time)
      )
    },

    detect = function(series, ...) {
      check_installed_backend("dbscan", "lof detector")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("LOF detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      vals <- series$values()
      n    <- length(vals)

      # Feature matrix
      if (p$use_time) {
        X <- matrix(c(seq_len(n) / n, vals), ncol = 2L,
                    dimnames = list(NULL, c("t_norm", "value")))
      } else {
        X <- matrix(vals, ncol = 1L, dimnames = list(NULL, "value"))
      }

      k_use  <- min(p$k, n - 1L)
      scores <- dbscan::lof(X, minPts = k_use)
      scores[is.infinite(scores) | is.nan(scores)] <- 0

      is_anomaly <- scores > p$threshold

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = scores,
        method        = "lof"
      )
    }
  )
)
