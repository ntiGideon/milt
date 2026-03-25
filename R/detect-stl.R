# STL-based anomaly detector
#
# Decomposes the series with stats::stl() and applies a z-score threshold to
# the remainder component.  Points whose |z| > threshold are flagged.

#' @keywords internal
#' @noRd
MiltDetectorSTL <- R6::R6Class(
  classname = "MiltDetectorSTL",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param threshold Numeric. Z-score threshold for the STL remainder.
    #'   Default `3`.
    #' @param s_window Integer or `"periodic"`. STL seasonal window. Default
    #'   `"periodic"`.
    #' @param robust Logical. Use robust STL fitting. Default `TRUE`.
    initialize = function(threshold = 3,
                          s_window  = "periodic",
                          robust    = TRUE) {
      super$initialize(
        name      = "stl",
        threshold = as.numeric(threshold),
        s_window  = s_window,
        robust    = as.logical(robust)
      )
    },

    detect = function(series, ...) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("STL detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p        <- private$.params
      freq     <- series$freq()
      freq_num <- .freq_label_to_numeric(as.character(freq))

      if (is.na(freq_num) || freq_num <= 1) {
        milt_abort(
          c(
            "STL decomposition requires a seasonal series (frequency > 1).",
            "i" = "This series has frequency {freq}.",
            "i" = "Use {.val iqr} or {.val gesd} for non-seasonal series."
          ),
          class = "milt_error_insufficient_data"
        )
      }

      ts_obj  <- series$as_ts()
      stl_fit <- tryCatch(
        stats::stl(ts_obj, s.window = p$s_window, robust = p$robust),
        error = function(e) {
          milt_abort(
            c(
              "STL decomposition failed.",
              "i" = conditionMessage(e),
              "i" = "Ensure the series has at least two full seasonal periods."
            ),
            class = "milt_error_insufficient_data"
          )
        }
      )
      remainder <- as.numeric(stl_fit$time.series[, "remainder"])

      # Z-score of remainder
      mu  <- mean(remainder, na.rm = TRUE)
      sig <- stats::sd(remainder, na.rm = TRUE)
      if (is.na(sig) || sig < 1e-10) sig <- 1
      z_scores <- abs((remainder - mu) / sig)

      is_anomaly <- z_scores > p$threshold

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = z_scores,
        method        = "stl"
      )
    }
  )
)
