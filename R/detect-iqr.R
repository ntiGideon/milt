# IQR-based anomaly detector
#
# Flags observations below Q1 - k * IQR or above Q3 + k * IQR.
# Works for any series regardless of frequency.

#' @keywords internal
#' @noRd
MiltDetectorIQR <- R6::R6Class(
  classname = "MiltDetectorIQR",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param k Numeric. IQR multiplier for the fence. Default `1.5`
    #'   (Tukey's fence). Use `3` for extreme outliers only.
    initialize = function(k = 1.5) {
      super$initialize(name = "iqr", k = as.numeric(k))
    },

    detect = function(series, ...) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("IQR detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      vals <- series$values()
      k    <- private$.params$k

      q1   <- stats::quantile(vals, 0.25, na.rm = TRUE)
      q3   <- stats::quantile(vals, 0.75, na.rm = TRUE)
      iqr  <- q3 - q1

      lo <- q1 - k * iqr
      hi <- q3 + k * iqr

      is_anomaly    <- vals < lo | vals > hi
      # Score: distance from nearest fence, normalised by IQR
      fence_dist    <- pmax(lo - vals, vals - hi, 0) / max(iqr, 1e-10)

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = fence_dist,
        method        = "iqr"
      )
    }
  )
)
