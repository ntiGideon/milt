# XGBoost backend (requires xgboost package)

# ── Shared ML helpers ─────────────────────────────────────────────────────────

# Build a lag feature matrix + target vector from a numeric vector.
# Returns list(X = matrix, y = numeric, lags = integer).
.ml_build_lag_features <- function(values, lags) {
  lag_mat <- .compute_lags(values, lags)   # from features-lags.R
  max_lag <- max(lags)
  keep    <- (max_lag + 1L):length(values)
  X       <- lag_mat[keep, , drop = FALSE]
  y       <- values[keep]
  list(X = X, y = y, lags = lags, max_lag = max_lag)
}

.ml_next_lag_row <- function(history, lags) {
  x_row <- matrix(history[length(history) - lags + 1L], nrow = 1L)
  colnames(x_row) <- paste0(".lag_", lags)
  x_row
}

# Given a fitted ML model and the last `max_lag` values of the training series,
# generate a recursive h-step-ahead forecast.
# `.predict_fn(model, X_row)` must return a single numeric prediction.
.ml_recursive_forecast <- function(predict_fn,
                                    last_values,
                                    lags,
                                    horizon,
                                    training_series,
                                    model_name,
                                    level = c(80, 95)) {
  max_lag   <- max(lags)
  history   <- as.numeric(last_values)    # growing buffer
  forecasts <- numeric(horizon)

  for (h in seq_len(horizon)) {
    x_row        <- .ml_next_lag_row(history, lags)
    pt           <- predict_fn(x_row)
    forecasts[h] <- pt
    history      <- c(history, pt)
  }

  # Build simple normal-approximation prediction intervals from training RMSE
  # (stored externally; fall back to flat intervals when unavailable)
  times   <- .future_times(training_series, horizon)
  pt_tbl  <- tibble::tibble(time = times, value = forecasts)

  # Flat intervals (no residual info available in this minimal helper)
  make_pi <- function(z) {
    tibble::tibble(time = times, value = forecasts)
  }
  lower <- stats::setNames(lapply(level, make_pi), as.character(level))
  upper <- stats::setNames(lapply(level, make_pi), as.character(level))

  MiltForecastR6$new(
    point_forecast  = pt_tbl,
    lower           = lower,
    upper           = upper,
    model_name      = model_name,
    horizon         = horizon,
    training_end    = training_series$end_time(),
    training_series = training_series
  )
}

# Build prediction intervals from in-sample residuals.
# Returns list(lower = named list, upper = named list).
.ml_pi_from_residuals <- function(residuals, forecasts, times, level) {
  sigma <- stats::sd(residuals, na.rm = TRUE)
  if (is.na(sigma) || !is.finite(sigma)) {
    sigma <- 0
  }
  lower <- stats::setNames(
    lapply(level, function(l) {
      z <- stats::qnorm(1 - (1 - l / 100) / 2)
      tibble::tibble(time = times, value = forecasts - z * sigma)
    }),
    as.character(level)
  )
  upper <- stats::setNames(
    lapply(level, function(l) {
      z <- stats::qnorm(1 - (1 - l / 100) / 2)
      tibble::tibble(time = times, value = forecasts + z * sigma)
    }),
    as.character(level)
  )
  list(lower = lower, upper = upper)
}

# ── XGBoost ───────────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltXGBoost <- R6::R6Class(
  classname = "MiltXGBoost",
  inherit   = MiltModelBase,

  private = list(
    .lags        = NULL,
    .last_values = NULL,
    .residuals   = NULL
  ),

  public = list(

    #' @param lags Integer vector of lag indices used as features.
    #'   Default `1:12`.
    #' @param nrounds Integer. Number of boosting rounds. Default `100L`.
    #' @param max_depth Integer. Maximum tree depth. Default `6L`.
    #' @param eta Numeric. Learning rate. Default `0.1`.
    #' @param nthread Integer. Number of threads. Default `1L`.
    #' @param ... Additional arguments forwarded to `xgboost::xgb.train()`.
    initialize = function(lags     = 1:12,
                          nrounds  = 100L,
                          max_depth = 6L,
                          eta      = 0.1,
                          nthread  = 1L,
                          ...) {
      super$initialize(
        name      = "xgboost",
        lags      = lags,
        nrounds   = as.integer(nrounds),
        max_depth = as.integer(max_depth),
        eta       = eta,
        nthread   = as.integer(nthread),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("xgboost", "xgboost")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("xgboost requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p     <- private$.params
      lags  <- as.integer(p$lags %||% 1:12)
      vals  <- series$values()
      built <- .ml_build_lag_features(vals, lags)

      dtrain <- xgboost::xgb.DMatrix(
        data  = built$X,
        label = built$y
      )
      xgb_params <- list(
        objective = "reg:squarederror",
        max_depth = p$max_depth %||% 6L,
        eta       = p$eta       %||% 0.1,
        nthread   = p$nthread   %||% 1L
      )
      fit <- xgboost::xgb.train(
        params  = xgb_params,
        data    = dtrain,
        nrounds = p$nrounds %||% 100L,
        verbose = 0L
      )

      private$.backend_model <- fit
      private$.lags          <- lags
      private$.last_values   <- utils::tail(vals, max(lags))
      private$.residuals     <- built$y - predict(fit, dtrain)
      private$.fitted        <- TRUE
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      horizon    <- as.integer(horizon)
      history    <- as.numeric(private$.last_values)
      lags       <- private$.lags
      fit        <- private$.backend_model
      forecasts  <- numeric(horizon)

      for (h in seq_len(horizon)) {
        x_row <- .ml_next_lag_row(history, lags)
        dmat  <- xgboost::xgb.DMatrix(data = x_row)
        pt    <- predict(fit, dmat)
        forecasts[h] <- pt
        history      <- c(history, pt)
      }

      training_series <- private$.training_series
      times           <- .future_times(training_series, horizon)
      pt_tbl          <- tibble::tibble(time = times, value = forecasts)
      pi              <- .ml_pi_from_residuals(
        private$.residuals, forecasts, times, level
      )

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "xgboost",
        horizon         = horizon,
        training_end    = training_series$end_time(),
        training_series = training_series
      )
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      lags  <- private$.lags
      vals  <- if (is.null(series)) {
        private$.training_series$values()
      } else {
        assert_milt_series(series)
        series$values()
      }
      built <- .ml_build_lag_features(vals, lags)
      dmat  <- xgboost::xgb.DMatrix(data = built$X)
      preds <- predict(private$.backend_model, dmat)
      # Prepend NAs for the dropped rows
      c(rep(NA_real_, max(lags)), preds)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      c(rep(NA_real_, max(private$.lags)), private$.residuals)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_xgboost <- function() {
  register_milt_model("xgboost", MiltXGBoost)
}
