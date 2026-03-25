# ML model explainability
#
# milt_explain() computes feature importance and (optionally) SHAP values
# for a fitted ML-backed MiltModel.  Supported backends: xgboost, random_forest,
# elastic_net, lightgbm.  Results are returned as a MiltExplanation object.

# ── Result class ──────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltExplanationR6 <- R6::R6Class(
  classname = "MiltExplanation",
  cloneable = FALSE,

  private = list(
    .model       = NULL,   # fitted MiltModel
    .importance  = NULL,   # tibble: feature, importance
    .shap        = NULL,   # tibble or NULL: feature, shap_mean_abs (optional)
    .method      = NULL    # character: backend name
  ),

  public = list(

    initialize = function(model, importance, shap = NULL, method = "unknown") {
      private$.model      <- model
      private$.importance <- importance
      private$.shap       <- shap
      private$.method     <- as.character(method)
    },

    #' @return The fitted `MiltModel`.
    model = function() private$.model,

    #' @return Character: backend name.
    method = function() private$.method,

    #' @return Tibble with columns `feature` and `importance` (sorted descending).
    importance = function() private$.importance,

    #' @return Tibble with columns `feature` and `shap_mean_abs`, or `NULL`.
    shap = function() private$.shap,

    #' @return Combined tibble (importance + shap if available).
    as_tibble = function() {
      tbl <- private$.importance
      if (!is.null(private$.shap)) {
        tbl <- dplyr::left_join(tbl, private$.shap, by = "feature")
      }
      tbl
    }
  )
)

.new_milt_explanation <- function(model, importance, shap = NULL, method = "unknown") {
  obj <- MiltExplanationR6$new(model, importance, shap, method)
  class(obj) <- c("MiltExplanation", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltExplanation <- function(x, ...) {
  cat(glue::glue(
    "# MiltExplanation [{x$method()}]\n",
    "# Features: {nrow(x$importance())}\n"
  ))
  cat("# Top feature importances:\n")
  print(utils::head(x$importance(), 10L))
  invisible(x)
}

#' @export
summary.MiltExplanation <- function(object, ...) print(object)

#' @export
as_tibble.MiltExplanation <- function(x, ...) x$as_tibble()

#' @export
plot.MiltExplanation <- function(x, top_n = 20L, ...) {
  tbl <- utils::head(x$importance(), as.integer(top_n))
  tbl$feature <- factor(tbl$feature, levels = rev(tbl$feature))

  ggplot2::ggplot(tbl, ggplot2::aes(x = .data$importance,
                                     y = .data$feature)) +
    ggplot2::geom_col(fill = "#4472C4", width = 0.7) +
    ggplot2::labs(
      title    = paste0("Feature Importance [", x$method(), "]"),
      subtitle = paste0("Top ", nrow(tbl), " features"),
      x        = "Importance",
      y        = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face = "bold"),
      axis.text.y = ggplot2::element_text(size = 9)
    )
}

# ── Internal extractors (one per backend) ────────────────────────────────────

#' Extract importance from an xgboost model
#' @noRd
.explain_xgboost <- function(model_obj, X, ...) {
  check_installed_backend("xgboost", "milt_explain (xgboost)")
  imp_mat <- xgboost::xgb.importance(model = model_obj)
  imp_tbl <- tibble::tibble(
    feature    = as.character(imp_mat$Feature),
    importance = as.numeric(imp_mat$Gain)
  )
  imp_tbl <- imp_tbl[order(imp_tbl$importance, decreasing = TRUE), ]

  shap_tbl <- NULL
  shap_raw <- tryCatch(
    stats::predict(model_obj, newdata = X, predcontrib = TRUE),
    error = function(e) NULL
  )
  if (!is.null(shap_raw)) {
    # Last column is BIAS — remove it
    shap_mat <- shap_raw[, -ncol(shap_raw), drop = FALSE]
    shap_means <- colMeans(abs(shap_mat))
    shap_tbl <- tibble::tibble(
      feature       = colnames(X),
      shap_mean_abs = as.numeric(shap_means)
    )
    shap_tbl <- shap_tbl[order(shap_tbl$shap_mean_abs, decreasing = TRUE), ]
  }

  list(importance = imp_tbl, shap = shap_tbl)
}

#' Extract importance from a ranger random forest
#' @noRd
.explain_random_forest <- function(model_obj, ...) {
  if (is.null(model_obj$variable.importance)) {
    milt_abort(
      c(
        "Random forest was not trained with variable importance.",
        "i" = "Re-fit with {.code importance = 'impurity'} or {.code 'permutation'}."
      ),
      class = "milt_error_not_supported"
    )
  }
  vi <- model_obj$variable.importance
  imp_tbl <- tibble::tibble(
    feature    = names(vi),
    importance = as.numeric(vi)
  )
  imp_tbl <- imp_tbl[order(imp_tbl$importance, decreasing = TRUE), ]
  list(importance = imp_tbl, shap = NULL)
}

#' Extract importance from a glmnet elastic-net model
#' @noRd
.explain_elastic_net <- function(model_obj, lambda, ...) {
  check_installed_backend("glmnet", "milt_explain (elastic_net)")
  coefs <- as.matrix(stats::coef(model_obj, s = lambda))
  # Drop intercept row
  coefs <- coefs[-1L, , drop = FALSE]
  imp_tbl <- tibble::tibble(
    feature    = rownames(coefs),
    importance = abs(as.numeric(coefs[, 1L]))
  )
  imp_tbl <- imp_tbl[order(imp_tbl$importance, decreasing = TRUE), ]
  list(importance = imp_tbl, shap = NULL)
}

#' Extract importance from a lightgbm model
#' @noRd
.explain_lightgbm <- function(model_obj, ...) {
  check_installed_backend("lightgbm", "milt_explain (lightgbm)")
  imp_mat <- lightgbm::lgb.importance(model = model_obj)
  imp_tbl <- tibble::tibble(
    feature    = as.character(imp_mat$Feature),
    importance = as.numeric(imp_mat$Gain)
  )
  imp_tbl <- imp_tbl[order(imp_tbl$importance, decreasing = TRUE), ]
  list(importance = imp_tbl, shap = NULL)
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Explain a fitted ML time series model
#'
#' Extracts feature importance (and optionally SHAP values for XGBoost) from
#' a fitted ML-backed `MiltModel`. Supported backends: `"xgboost"`,
#' `"random_forest"`, `"elastic_net"`, and `"lightgbm"`.
#'
#' @param model A fitted `MiltModel` (must have been fit with [milt_fit()]).
#' @param series Optional `MiltSeries` object. When provided, the series is
#'   used to compute the design matrix for SHAP value calculation (XGBoost
#'   only).  If omitted the training data stored in the model is used.
#' @param ... Additional arguments (currently unused).
#' @return A `MiltExplanation` object.
#' @seealso [milt_model()], [milt_fit()]
#' @family explain
#' @examples
#' \donttest{
#' s   <- milt_series(AirPassengers)
#' m   <- milt_model("xgboost") |> milt_fit(s)
#' exp <- milt_explain(m)
#' plot(exp)
#' }
#' @export
milt_explain <- function(model, series = NULL, ...) {
  if (!inherits(model, "MiltModel")) {
    milt_abort(
      "{.arg model} must be a fitted {.cls MiltModel} from {.fn milt_fit}.",
      class = "milt_error_not_milt_model"
    )
  }
  if (!model$is_fitted()) {
    milt_abort(
      "{.arg model} must be a fitted model. Call {.fn milt_fit} first.",
      class = "milt_error_not_fitted"
    )
  }

  be <- model$.__enclos_env__$private$.backend_model
  if (is.null(be)) {
    milt_abort(
      "No backend model object found. Ensure the model was fit with {.fn milt_fit}.",
      class = "milt_error_not_fitted"
    )
  }

  backend_name <- model$.__enclos_env__$private$.name
  training_s   <- model$.__enclos_env__$private$.training_series
  target_s     <- if (!is.null(series)) series else training_s

  result <- switch(backend_name,
    "xgboost" = {
      check_installed_backend("xgboost", "milt_explain")
      # Reconstruct design matrix from the stored model's feature names
      X <- if (!is.null(be$feature_names)) {
        tryCatch({
          xgboost::xgb.DMatrix(
            data = stats::model.matrix(~ . - 1,
                                data = as.data.frame(
                                  be$feature_names  # just the names; fallback below
                                ))
          )
        }, error = function(e) NULL)
      } else NULL

      # Fall back to a simple numeric matrix from the series values
      if (is.null(X) && !is.null(target_s)) {
        vals <- as.numeric(target_s$values())
        X_raw <- matrix(vals, ncol = 1L,
                        dimnames = list(NULL, "value"))
        # Add lags matching what the backend would have used
        n_lags <- be$params$n_lags %||% 12L
        for (k in seq_len(n_lags)) {
          lag_col <- c(rep(NA_real_, k), vals[seq_len(length(vals) - k)])
          X_raw <- cbind(X_raw, matrix(lag_col, ncol = 1L,
                                       dimnames = list(NULL, paste0("lag_", k))))
        }
        complete_rows <- stats::complete.cases(X_raw)
        X_raw <- X_raw[complete_rows, , drop = FALSE]
        X <- xgboost::xgb.DMatrix(data = X_raw)
      }

      .explain_xgboost(be, X)
    },

    "random_forest" = .explain_random_forest(be),

    "elastic_net" = {
      lambda_best <- be$lambda.min %||% be$lambda[[1L]]
      .explain_elastic_net(be, lambda = lambda_best)
    },

    "lightgbm" = .explain_lightgbm(be),

    milt_abort(
      c(
        "Backend {.val {backend_name}} does not support {.fn milt_explain}.",
        "i" = "Supported backends: {.val xgboost}, {.val random_forest},",
        "i" = "                    {.val elastic_net}, {.val lightgbm}."
      ),
      class = "milt_error_not_supported"
    )
  )

  .new_milt_explanation(
    model      = model,
    importance = result$importance,
    shap       = result$shap,
    method     = backend_name
  )
}
