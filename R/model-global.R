# Global multi-series model — the counterpart to MiltLocalModel (model-multi.R).
#
# Where MiltLocalModel fits one independent model PER group, MiltGlobalModel
# fits ONE shared model ACROSS all groups: every group's lag-feature rows are
# stacked into a single training matrix (tagged with a one-hot group-id
# column, plus any static covariates as constant-per-group columns), and one
# regression model is fit on the pooled data — genuine cross-series weight
# sharing, mirroring darts' "global" TorchForecastingModel / SKLearnModel
# behavior of accepting Sequence[TimeSeries].
#
# Reuses .ml_build_lag_features()/.ml_next_lag_row()/.ml_pi_from_residuals()
# (backend-xgboost.R) and .knn_predict_single() (backend-knn.R) — the same
# primitives the per-series backends already use — rather than duplicating
# xgboost/knn fitting code, to keep the two supported methods' numerics
# identical to their single-series counterparts.

#' @title MiltGlobalModel — one shared "global" model across all groups
#' @description
#' Wraps a lag-based regression method (`"knn"` or `"xgboost"`) and fits ONE
#' model across every group of a multi-series `MiltSeries`, pooling every
#' group's lag-feature rows (tagged with a one-hot group indicator and any
#' static covariates) into a single training matrix. Produced by
#' [milt_global_model()] — the counterpart to [milt_local_model()], which
#' fits one independent model per group instead.
#'
#' @keywords internal
#' @noRd
MiltGlobalModel <- R6::R6Class(
  classname = "MiltGlobalModel",
  inherit   = MiltModelBase,

  private = list(
    .lags          = NULL,  # integer vector
    .groups        = NULL,  # character vector of group ids seen at fit time
    .group_series  = NULL,  # named list: per-group MiltSeries (for times/end_time)
    .group_history = NULL,  # named list: last max(lags) training values per group
    .group_static  = NULL,  # named list: numeric vector of static covariate values per group
    .static_names  = NULL,  # character vector of static covariate column names
    .feat_mean     = NULL,  # numeric vector, KNN feature scaling only
    .feat_sd       = NULL,  # numeric vector, KNN feature scaling only
    .y_all         = NULL,  # pooled training targets (fit-time row order)
    .residuals     = NULL,  # pooled training residuals (same order)

    # Build one row of features in the SAME column order used at fit time:
    # [lags..., one-hot group indicators..., static covariates...].
    .build_row = function(history, group) {
      lag_row <- .ml_next_lag_row(history, private$.lags)

      onehot <- matrix(0, nrow = 1L, ncol = length(private$.groups))
      colnames(onehot) <- paste0(".group_", private$.groups)
      onehot[, paste0(".group_", group)] <- 1

      static_names <- private$.static_names
      if (length(static_names) > 0L) {
        static_row <- matrix(private$.group_static[[group]], nrow = 1L)
        colnames(static_row) <- static_names
      } else {
        static_row <- matrix(nrow = 1L, ncol = 0L)
      }

      cbind(lag_row, onehot, static_row)
    },

    .predict_row = function(x_row) {
      method <- private$.params$method
      bm     <- private$.backend_model
      if (method == "knn") {
        x_scaled <- (x_row - private$.feat_mean) / private$.feat_sd
        .knn_predict_single(bm$X, bm$y, x_scaled, bm$k, bm$weights)
      } else {
        stats::predict(bm, xgboost::xgb.DMatrix(data = x_row))
      }
    },

    .forecast_one = function(group, horizon, level) {
      horizon <- as.integer(horizon)
      history <- private$.group_history[[group]]
      preds   <- numeric(horizon)

      for (h in seq_len(horizon)) {
        x_row     <- private$.build_row(history, group)
        pt        <- private$.predict_row(x_row)
        preds[[h]] <- pt
        history   <- c(history, pt)
      }

      g_series <- private$.group_series[[group]]
      times    <- .future_times(g_series, horizon)
      pi       <- .ml_pi_from_residuals(private$.residuals, preds, times, level)
      method   <- private$.params$method
      tag      <- if (group == "__single__") "" else paste0(" [", group, "]")

      MiltForecastR6$new(
        point_forecast  = tibble::tibble(time = times, value = preds),
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = paste0("global_", method, tag),
        horizon         = horizon,
        training_end    = g_series$end_time(),
        training_series = g_series
      )
    }
  ),

  public = list(

    #' @param method Character. `"knn"` (pure R) or `"xgboost"`.
    #' @param lags Integer vector of lag indices used as features. Default `1:12`.
    #' @param k,weights KNN hyperparameters (see `milt_model("knn")`).
    #' @param nrounds,max_depth,eta XGBoost hyperparameters.
    #' @param ... Additional hyperparameters stored for the chosen method.
    initialize = function(method    = "knn",
                          lags      = 1:12,
                          k         = 5L,
                          weights   = "uniform",
                          nrounds   = 100L,
                          max_depth = 6L,
                          eta       = 0.1,
                          ...) {
      super$initialize(
        name      = paste0("global_", method),
        method    = method,
        lags      = as.integer(lags),
        k         = as.integer(k),
        weights   = weights,
        nrounds   = as.integer(nrounds),
        max_depth = as.integer(max_depth),
        eta       = eta,
        ...
      )
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("{.fn milt_global_model} requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p       <- private$.params
      method  <- p$method
      if (!method %in% c("knn", "xgboost")) {
        milt_abort("Unsupported {.arg method}: {.val {method}}.",
                   class = "milt_error_invalid_arg")
      }
      lags    <- as.integer(p$lags)
      max_lag <- max(lags)

      sp  <- series$.__enclos_env__$private
      gc  <- sp$.group_col
      vc  <- sp$.value_cols[[1L]]
      tbl <- series$as_tibble()

      if (is.null(gc)) {
        groups <- "__single__"
        tbl[[".global_group__"]] <- "__single__"
        gc <- ".global_group__"
      } else {
        groups <- as.character(unique(tbl[[gc]]))
      }

      static_covs  <- milt_get_covariates(series, "static")
      static_names <- if (!is.null(static_covs)) setdiff(names(static_covs), gc) else character(0)

      X_blocks <- list(); y_blocks <- list()
      group_series <- list(); group_history <- list(); group_static <- list()

      for (g in groups) {
        g_rows <- tbl[as.character(tbl[[gc]]) == g, ]
        vals   <- g_rows[[vc]]
        if (length(vals) <= max_lag) {
          milt_abort(
            c("Group {.val {g}} has too few observations for the requested lags.",
              "i" = "Need more than {max_lag} observations."),
            class = "milt_error_insufficient_data"
          )
        }

        built  <- .ml_build_lag_features(vals, lags)
        n_rows <- nrow(built$X)

        onehot <- matrix(0, nrow = n_rows, ncol = length(groups))
        colnames(onehot) <- paste0(".group_", groups)
        onehot[, paste0(".group_", g)] <- 1

        if (length(static_names) > 0L) {
          match_row   <- as.character(static_covs[[gc]]) == g
          static_vals <- as.numeric(static_covs[match_row, static_names, drop = FALSE][1L, ])
          static_mat  <- matrix(static_vals, nrow = n_rows, ncol = length(static_names), byrow = TRUE)
          colnames(static_mat) <- static_names
        } else {
          static_vals <- numeric(0)
          static_mat  <- matrix(nrow = n_rows, ncol = 0L)
        }

        X_blocks[[g]] <- cbind(built$X, onehot, static_mat)
        y_blocks[[g]] <- built$y

        group_history[[g]] <- utils::tail(vals, max_lag)
        group_static[[g]]  <- static_vals
        group_series[[g]]  <- MiltSeriesR6$new(
          data       = g_rows[, setdiff(names(g_rows), gc), drop = FALSE],
          time_col   = sp$.time_col,
          value_cols = vc,
          frequency  = series$freq()
        )
      }

      X_all <- do.call(rbind, X_blocks)
      y_all <- do.call(c, y_blocks)

      if (method == "knn") {
        feat_mean <- colMeans(X_all)
        feat_sd   <- apply(X_all, 2L, stats::sd)
        feat_sd[is.na(feat_sd) | feat_sd < 1e-10] <- 1
        X_scaled  <- scale(X_all, center = feat_mean, scale = feat_sd)

        private$.feat_mean <- feat_mean
        private$.feat_sd   <- feat_sd
        private$.backend_model <- list(
          X = X_scaled, y = y_all, k = p$k %||% 5L, weights = p$weights %||% "uniform"
        )
        fitted_vals <- vapply(seq_len(nrow(X_scaled)), function(i) {
          .knn_predict_single(X_scaled, y_all, X_scaled[i, ], p$k %||% 5L, p$weights %||% "uniform")
        }, numeric(1L))
      } else {
        check_installed_backend("xgboost", "milt_global_model (xgboost)")
        dtrain <- xgboost::xgb.DMatrix(data = X_all, label = y_all)
        fit <- xgboost::xgb.train(
          params = list(
            objective = "reg:squarederror",
            max_depth = p$max_depth %||% 6L,
            eta       = p$eta       %||% 0.1
          ),
          data    = dtrain,
          nrounds = p$nrounds %||% 100L,
          verbose = 0L
        )
        private$.backend_model <- fit
        fitted_vals <- stats::predict(fit, dtrain)
      }

      private$.lags          <- lags
      private$.groups         <- groups
      private$.group_series   <- group_series
      private$.group_history  <- group_history
      private$.group_static   <- group_static
      private$.static_names   <- static_names
      private$.y_all          <- y_all
      private$.residuals      <- y_all - fitted_vals
      private$.training_series <- series
      invisible(self)
    },

    #' @description Forecast a single group (the first fitted group when
    #'   `group` is not supplied). Use `forecast_all()` for every group.
    forecast = function(horizon, level = c(80, 95), group = NULL, ...) {
      .assert_is_fitted(self)
      groups <- private$.groups
      if (is.null(group)) {
        if (length(groups) > 1L) {
          milt_info(
            "Multiple groups were fitted; forecasting {.val {groups[[1L]]}}. \\
             Pass {.arg group} or call {.fn forecast_all} for the rest."
          )
        }
        group <- groups[[1L]]
      } else if (!group %in% groups) {
        milt_abort("Unknown group {.val {group}}.", class = "milt_error_invalid_arg")
      }
      private$.forecast_one(group, horizon, level)
    },

    #' @description Forecast every group fitted, returning a named list of
    #'   `MiltForecast` objects (one per group).
    forecast_all = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      stats::setNames(
        lapply(private$.groups, function(g) private$.forecast_one(g, horizon, level)),
        private$.groups
      )
    },

    #' @description Pooled in-sample fitted values, in the row order the
    #'   groups were stacked during `fit()`. See `forecast_all()` for
    #'   per-group forecasts.
    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      private$.y_all - private$.residuals
    },

    #' @description Pooled in-sample residuals (see `predict()`).
    residuals = function(...) {
      .assert_is_fitted(self)
      private$.residuals
    },

    #' @description Character vector of group ids seen during `fit()`.
    groups = function() private$.groups
  )
)

#' Fit one shared model across every group of a multi-series MiltSeries
#'
#' The "global" counterpart to [milt_local_model()]: instead of training one
#' independent model per group, every group's lag-feature rows are pooled
#' into a single training matrix (tagged with a one-hot group indicator, plus
#' any static covariates attached via [milt_add_covariates()] as
#' constant-per-group columns) and **one** shared model is fit across all of
#' them — genuine cross-series weight sharing, the way darts' global
#' forecasting models work.
#'
#' @param method Character. `"knn"` (pure R, no dependency) or `"xgboost"`.
#' @param lags Integer vector of lag indices used as features. Default `1:12`.
#' @param k,weights Hyperparameters for `method = "knn"`.
#' @param nrounds,max_depth,eta Hyperparameters for `method = "xgboost"`.
#' @param ... Additional hyperparameters.
#' @return An unfitted `MiltModel`. Fit it with [milt_fit()] on a grouped
#'   `MiltSeries`; forecast a single group with `$forecast()` or every group
#'   at once with `$forecast_all()`.
#' @seealso [milt_local_model()], [milt_add_covariates()]
#' @family model
#' @examples
#' \donttest{
#' tbl <- data.frame(
#'   date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 36), 3),
#'   value = c(cumsum(rnorm(36, 1)), cumsum(rnorm(36, 2)), cumsum(rnorm(36, 0.5))),
#'   store = rep(c("A", "B", "C"), each = 36)
#' )
#' s <- milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")
#'
#' gm <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(s)
#' forecasts <- gm$forecast_all(horizon = 6)
#' forecasts[["A"]]
#' }
#' @export
milt_global_model <- function(method    = c("knn", "xgboost"),
                               lags      = 1:12,
                               k         = 5L,
                               weights   = "uniform",
                               nrounds   = 100L,
                               max_depth = 6L,
                               eta       = 0.1,
                               ...) {
  method <- match.arg(method)
  MiltGlobalModel$new(
    method = method, lags = lags, k = k, weights = weights,
    nrounds = nrounds, max_depth = max_depth, eta = eta, ...
  )
}
