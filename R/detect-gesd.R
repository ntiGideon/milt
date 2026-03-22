# GESD (Generalized Extreme Studentized Deviate) anomaly detector
#
# An iterative test for up to max_anoms outliers in a (approximately) normal
# dataset.  At each step the observation with the largest studentised deviation
# from the current mean is identified; it is flagged as an anomaly if its test
# statistic exceeds the critical lambda value derived from the t-distribution.
#
# Reference: Rosner (1983) "Percentage Points for a Generalized ESD
# Many-Outlier Procedure". Technometrics 25(2).

#' @keywords internal
#' @noRd
MiltDetectorGESD <- R6::R6Class(
  classname = "MiltDetectorGESD",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param max_anoms Integer. Maximum number of anomalies to test for.
    #'   Default `10L`.
    #' @param alpha Numeric. Significance level. Default `0.05`.
    initialize = function(max_anoms = 10L, alpha = 0.05) {
      super$initialize(
        name      = "gesd",
        max_anoms = as.integer(max_anoms),
        alpha     = as.numeric(alpha)
      )
    },

    detect = function(series, ...) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("GESD detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      vals      <- series$values()
      n         <- length(vals)
      max_anoms <- min(private$.params$max_anoms, floor(n / 2L))
      alpha     <- private$.params$alpha

      # Iterative GESD
      remaining   <- vals
      rem_idx     <- seq_len(n)   # indices still in play
      flagged_idx <- integer(0L)  # indices confirmed as outliers

      gesd_stats   <- numeric(max_anoms)
      gesd_lambdas <- numeric(max_anoms)

      for (r in seq_len(max_anoms)) {
        mu  <- mean(remaining, na.rm = TRUE)
        sig <- stats::sd(remaining, na.rm = TRUE)
        if (is.na(sig) || sig < 1e-12) break

        devs    <- abs(remaining - mu) / sig
        max_pos <- which.max(devs)
        gesd_stats[[r]] <- devs[[max_pos]]

        # Critical value lambda_r
        p       <- 1 - alpha / (2 * (n - r + 1))
        t_crit  <- stats::qt(p, df = n - r - 1)
        lambda  <- ((n - r) * t_crit) /
          sqrt((n - r - 1 + t_crit ^ 2) * (n - r + 1))
        gesd_lambdas[[r]] <- lambda

        # Remove the candidate regardless; confirm at the end
        flagged_idx <- c(flagged_idx, rem_idx[[max_pos]])
        remaining   <- remaining[-max_pos]
        rem_idx     <- rem_idx[-max_pos]
      }

      # The number of outliers is the largest r for which G_r > lambda_r
      n_confirmed <- 0L
      for (r in rev(seq_len(max_anoms))) {
        if (!is.na(gesd_stats[[r]]) && gesd_stats[[r]] > gesd_lambdas[[r]]) {
          n_confirmed <- r
          break
        }
      }

      confirmed   <- if (n_confirmed > 0L) flagged_idx[seq_len(n_confirmed)] else integer(0L)
      is_anomaly  <- logical(n)
      is_anomaly[confirmed] <- TRUE

      # Score: studentised deviation from overall mean
      overall_sd    <- stats::sd(vals, na.rm = TRUE)
      if (is.na(overall_sd) || overall_sd < 1e-12) overall_sd <- 1
      anomaly_score <- abs(vals - mean(vals, na.rm = TRUE)) / overall_sd

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = anomaly_score,
        method        = "gesd"
      )
    }
  )
)
