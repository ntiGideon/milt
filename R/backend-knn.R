# KNN regression backend (no external package required)
#
# Fits a k-nearest-neighbours regression on auto-generated lag features.
# Prediction: weighted average of the k nearest training observations.

# ── Internal KNN predictor ────────────────────────────────────────────────────

# Euclidean-distance kNN predict for a single query row.
.knn_predict_single <- function(X_train, y_train, x_query, k, weights) {
  dists <- sqrt(rowSums((X_train - matrix(x_query, nrow = nrow(X_train),
                                          ncol = ncol(X_train),
                                          byrow = TRUE)) ^ 2))
  knn_idx <- order(dists)[seq_len(min(k, length(dists)))]
  knn_d   <- dists[knn_idx]
  knn_y   <- y_train[knn_idx]

  if (weights == "uniform" || all(knn_d < 1e-12)) {
    mean(knn_y)
  } else {
    w <- 1 / (knn_d + 1e-10)
    sum(w * knn_y) / sum(w)
  }
}

# ── R6 class ──────────────────────────────────────────────────────────────────

MiltKNN <- R6::R6Class(
  classname = "MiltKNN",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  public = list(

    #' @param k Integer. Number of nearest neighbours. Default `5L`.
    #' @param lags Integer vector. Lag indices used as features. Default `1:12`.
    #' @param weights Character. `"uniform"` (default) or `"distance"`.
    initialize = function(k       = 5L,
                          lags    = 1:12,
                          weights = "uniform") {
      super$initialize(
        name    = "knn",
        k       = as.integer(k),
        lags    = as.integer(lags),
        weights = match.arg(weights, c("uniform", "distance"))
      )
    },

    fit = function(series) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("KNN requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      vals <- series$values()
      feat <- .ml_build_lag_features(vals, p$lags)

      private$.X_train     <- feat$X
      private$.y_train     <- feat$y
      private$.feat        <- feat
      private$.train_vals  <- as.numeric(vals)
      private$.backend_model <- list(k = p$k, weights = p$weights,
                                      lags = p$lags)
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      p       <- private$.params
      history <- private$.train_vals
      X_tr    <- private$.X_train
      y_tr    <- private$.y_train
      preds   <- numeric(as.integer(horizon))

      for (h in seq_len(horizon)) {
        # Build query row from the last `max(lags)` history values
        x_q <- .compute_lags(history, p$lags)[length(history), ]
        pt  <- .knn_predict_single(X_tr, y_tr, x_q, p$k, p$weights)
        preds[h] <- pt
        # Append predicted value for recursive forecasting
        history <- c(history, pt)
        x_new   <- matrix(x_q, nrow = 1L)
        colnames(x_new) <- colnames(X_tr)
        X_tr    <- rbind(X_tr, x_new)
        y_tr    <- c(y_tr, pt)
      }

      ts  <- private$.training_series
      tms <- .future_times(ts, horizon)
      pi  <- .ml_pi_from_residuals(self$residuals(), preds, tms, level)

      MiltForecastR6$new(
        point_forecast  = tibble::tibble(time = tms, value = preds),
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "knn",
        horizon         = as.integer(horizon),
        training_end    = ts$end_time(),
        training_series = ts
      )
    },

    predict = function(series = NULL) {
      p   <- private$.params
      prd <- vapply(seq_len(nrow(private$.X_train)), function(i) {
        .knn_predict_single(private$.X_train, private$.y_train,
                            private$.X_train[i, ], p$k, p$weights)
      }, numeric(1L))
      c(rep(NA_real_, private$.feat$max_lag), prd)
    },

    residuals = function() {
      private$.train_vals - self$predict()
    }
  ),

  private = list(
    .X_train    = NULL,
    .y_train    = NULL,
    .feat       = NULL,
    .train_vals = NULL
  )
)

.onLoad_knn <- function() {
  register_milt_model(
    name        = "knn",
    class       = MiltKNN,
    description = "K-Nearest Neighbours regression with lag features (no external package)",
    supports    = list(
      multivariate  = FALSE,
      probabilistic = TRUE,
      covariates    = FALSE,
      multi_series  = FALSE
    )
  )
}
