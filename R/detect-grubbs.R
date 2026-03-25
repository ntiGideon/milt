# Grubbs test anomaly detector
#
# Flags the single most extreme outlier (max |x - mean| / sd) when its
# Grubbs statistic exceeds the critical value at the specified significance
# level.  Optionally iterates to find multiple outliers (sequential Grubbs).

#' @keywords internal
#' @noRd
MiltDetectorGrubbs <- R6::R6Class(
  classname = "MiltDetectorGrubbs",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param alpha Numeric. Significance level for each test. Default `0.05`.
    #' @param max_iter Integer. Maximum number of sequential Grubbs tests.
    #'   Set to `1L` (the default) for the classic single-outlier test.
    initialize = function(alpha = 0.05, max_iter = 1L) {
      super$initialize(
        name     = "grubbs",
        alpha    = as.numeric(alpha),
        max_iter = as.integer(max_iter)
      )
    },

    detect = function(series, ...) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("Grubbs detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      vals     <- series$values()
      n        <- length(vals)
      alpha    <- private$.params$alpha
      max_iter <- min(private$.params$max_iter, floor(n / 2L) - 1L)

      remaining   <- vals
      rem_idx     <- seq_len(n)
      flagged_idx <- integer(0L)

      for (i in seq_len(max_iter)) {
        ni  <- length(remaining)
        if (ni < 3L) break

        mu  <- mean(remaining, na.rm = TRUE)
        sig <- stats::sd(remaining, na.rm = TRUE)
        if (is.na(sig) || sig < 1e-12) break

        devs    <- abs(remaining - mu) / sig
        g_stat  <- max(devs, na.rm = TRUE)
        max_pos <- which.max(devs)

        # Critical value
        t_crit  <- stats::qt(alpha / (2 * ni), df = ni - 2L, lower.tail = FALSE)
        g_crit  <- ((ni - 1) / sqrt(ni)) *
          sqrt(t_crit ^ 2 / (ni - 2 + t_crit ^ 2))

        if (g_stat > g_crit) {
          flagged_idx <- c(flagged_idx, rem_idx[[max_pos]])
          remaining   <- remaining[-max_pos]
          rem_idx     <- rem_idx[-max_pos]
        } else {
          break   # no more outliers at this alpha
        }
      }

      is_anomaly <- logical(n)
      if (length(flagged_idx) > 0L) is_anomaly[flagged_idx] <- TRUE

      overall_mu  <- mean(vals, na.rm = TRUE)
      overall_sig <- stats::sd(vals, na.rm = TRUE)
      if (is.na(overall_sig) || overall_sig < 1e-12) overall_sig <- 1
      anomaly_score <- abs(vals - overall_mu) / overall_sig

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = anomaly_score,
        method        = "grubbs"
      )
    }
  )
)
