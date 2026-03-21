# Isolation Forest anomaly detector (requires isotree package)
#
# Builds an isolation forest on the raw values (and optionally their lags).
# Anomaly scores are the isolation forest outlier scores in [0, 1]; higher
# values indicate more anomalous observations.

MiltDetectorIForest <- R6::R6Class(
  classname = "MiltDetectorIForest",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param n_trees Integer. Number of trees in the forest. Default `100L`.
    #' @param sample_size Integer or `NULL`. Subsample size per tree.
    #'   `NULL` uses the isotree default. Default `NULL`.
    #' @param threshold Numeric in `(0, 1)`. Score threshold above which a
    #'   point is flagged as anomalous. Default `0.6`.
    #' @param n_lags Integer. Number of lag features added before scoring.
    #'   `0L` uses only the raw value. Default `0L`.
    initialize = function(n_trees    = 100L,
                          sample_size = NULL,
                          threshold  = 0.6,
                          n_lags     = 0L) {
      super$initialize(
        name        = "iforest",
        n_trees     = as.integer(n_trees),
        sample_size = sample_size,
        threshold   = as.numeric(threshold),
        n_lags      = as.integer(n_lags)
      )
    },

    detect = function(series, ...) {
      check_installed_backend("isotree", "iforest detector")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("iforest detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      vals <- series$values()
      n    <- length(vals)

      # Build feature matrix (raw value + optional lags)
      X <- matrix(vals, ncol = 1L,
                  dimnames = list(NULL, "value"))
      if (p$n_lags > 0L) {
        lag_mat <- matrix(NA_real_, nrow = n, ncol = p$n_lags)
        for (k in seq_len(p$n_lags)) {
          lag_mat[(k + 1L):n, k] <- vals[seq_len(n - k)]
        }
        X <- cbind(X, lag_mat)
      }

      iso_args <- list(
        data    = as.data.frame(X),
        ntrees  = p$n_trees,
        ndim    = 1L,
        nthreads = 1L
      )
      if (!is.null(p$sample_size)) {
        iso_args$sample_size <- as.integer(p$sample_size)
      }
      model <- do.call(isotree::isolation.forest, iso_args)

      scores     <- predict(model, as.data.frame(X), type = "score")
      is_anomaly <- scores > p$threshold

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = scores,
        method        = "iforest"
      )
    }
  )
)
