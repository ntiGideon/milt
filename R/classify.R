# Time series classification
#
# milt_classifier() creates an unfitted classifier.
# milt_classify_fit() trains it on labelled MiltSeries.
# milt_classify_predict() predicts class labels for new series.
#
# Supported methods:
#   "feature_based" — extract statistical features → train a random forest
#   "rocket"        — random convolutional kernel transform (simplified version)

# ── Result class ──────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltClassifierR6 <- R6::R6Class(
  classname = "MiltClassifier",
  cloneable = TRUE,

  private = list(
    .method  = NULL,
    .params  = NULL,
    .fitted  = FALSE,
    .model   = NULL,   # trained classifier object
    .classes = NULL    # character vector of class names
  ),

  public = list(

    initialize = function(method, params) {
      private$.method <- as.character(method)
      private$.params <- params
    },

    method    = function() private$.method,
    is_fitted = function() private$.fitted,
    classes   = function() private$.classes,

    fit = function(series_list, labels) {
      X <- .classifier_features(series_list, private$.method, private$.params)
      y <- as.factor(labels)
      private$.classes <- levels(y)

      if (private$.method %in% c("feature_based", "rocket")) {
        check_installed_backend("ranger", "milt_classify_fit")
        private$.model <- ranger::ranger(
          y          = y,
          x          = as.data.frame(X),
          num.trees  = private$.params$n_trees %||% 100L,
          probability = TRUE
        )
      }
      private$.fitted <- TRUE
      invisible(self)
    },

    predict = function(series_list) {
      if (!private$.fitted) {
        milt_abort("Classifier has not been fitted. Call {.fn milt_classify_fit} first.",
                   class = "milt_error_not_fitted")
      }
      X    <- .classifier_features(series_list, private$.method, private$.params)
      pred <- predict(private$.model, data = as.data.frame(X))

      if (private$.method %in% c("feature_based", "rocket")) {
        probs  <- pred$predictions
        labels <- private$.classes[apply(probs, 1L, which.max)]
        list(labels = labels, probabilities = probs)
      } else {
        list(labels = pred, probabilities = NULL)
      }
    }
  )
)

.new_milt_classifier <- function(method, params) {
  obj <- MiltClassifierR6$new(method, params)
  class(obj) <- c("MiltClassifier", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltClassifier <- function(x, ...) {
  cat(glue::glue(
    "# MiltClassifier [{x$method()}]\n",
    "# Fitted: {x$is_fitted()}\n"
  ))
  if (x$is_fitted()) {
    cat(glue::glue("# Classes: {paste(x$classes(), collapse = ', ')}\n"))
  }
  invisible(x)
}

# ── Feature extraction ────────────────────────────────────────────────────────

.classifier_features <- function(series_list, method, params) {
  extract_one <- function(s) {
    v    <- as.numeric(s$values())
    n    <- length(v)
    acf1 <- tryCatch(
      stats::acf(v, lag.max = 1L, plot = FALSE)$acf[2L, 1L, 1L],
      error = function(e) 0
    )
    fft_power <- if (n >= 4L) {
      ft <- Mod(stats::fft(v))^2
      stats::var(ft[seq_len(floor(n / 2L))], na.rm = TRUE)
    } else 0
    base_feats <- c(
      mean_v     = mean(v, na.rm = TRUE),
      sd_v       = stats::sd(v, na.rm = TRUE),
      skew       = mean((v - mean(v, na.rm=TRUE))^3, na.rm=TRUE) /
                     max(stats::sd(v, na.rm=TRUE)^3, 1e-10),
      kurtosis   = mean((v - mean(v, na.rm=TRUE))^4, na.rm=TRUE) /
                     max(stats::sd(v, na.rm=TRUE)^4, 1e-10),
      min_v      = min(v, na.rm = TRUE),
      max_v      = max(v, na.rm = TRUE),
      range_v    = diff(range(v, na.rm = TRUE)),
      acf1       = acf1,
      fft_power  = fft_power
    )
    if (method == "rocket") {
      # Simplified ROCKET: 10 random convolutional kernels
      n_k <- params$n_kernels %||% 10L
      set.seed(42L)
      kernel_feats <- vapply(seq_len(n_k), function(ki) {
        k_len   <- sample(c(7L, 9L, 11L), 1L)
        weights <- stats::rnorm(k_len)
        padding <- floor(k_len / 2L)
        v_pad   <- c(rep(0, padding), v, rep(0, padding))
        conv_out <- stats::filter(v_pad, weights, sides = 2L,
                                   method = "convolution")
        conv_out <- as.numeric(conv_out[!is.na(conv_out)])
        c(max(conv_out), mean(conv_out > 0))
      }, numeric(2L))
      c(base_feats, as.numeric(kernel_feats))
    } else {
      base_feats
    }
  }

  mat <- do.call(rbind, lapply(series_list, extract_one))
  mat
}

# ── Public verbs ──────────────────────────────────────────────────────────────

#' Create a time series classifier
#'
#' Returns an unfitted `MiltClassifier`.  Train it with [milt_classify_fit()].
#'
#' @param method Character. Classification method:
#'   * `"feature_based"` (default) — statistical features + random forest.
#'   * `"rocket"` — random convolutional kernel transform + random forest.
#' @param n_trees Integer. Number of trees (random forest). Default `100L`.
#' @param n_kernels Integer. Number of ROCKET kernels (only for `"rocket"`).
#'   Default `10L`.
#' @param ... Additional arguments (unused).
#' @return A `MiltClassifier` object.
#' @seealso [milt_classify_fit()], [milt_classify_predict()]
#' @family classify
#' @examples
#' clf <- milt_classifier("feature_based")
#' @export
milt_classifier <- function(method    = "feature_based",
                             n_trees   = 100L,
                             n_kernels = 10L,
                             ...) {
  method <- match.arg(method, c("feature_based", "rocket"))
  params <- list(n_trees = as.integer(n_trees),
                 n_kernels = as.integer(n_kernels))
  .new_milt_classifier(method, params)
}

#' Fit a time series classifier
#'
#' Trains the classifier on a labelled set of time series.
#'
#' @param classifier A `MiltClassifier` from [milt_classifier()].
#' @param series_list A list of `MiltSeries` objects (training set).
#' @param labels Character or factor vector of class labels, one per series.
#' @return The fitted `MiltClassifier` (invisibly, mutated in place).
#' @seealso [milt_classifier()], [milt_classify_predict()]
#' @family classify
#' @export
milt_classify_fit <- function(classifier, series_list, labels) {
  if (!inherits(classifier, "MiltClassifier")) {
    milt_abort("{.arg classifier} must be a {.cls MiltClassifier}.",
               class = "milt_error_invalid_arg")
  }
  if (length(series_list) != length(labels)) {
    milt_abort("{.arg series_list} and {.arg labels} must have the same length.",
               class = "milt_error_invalid_arg")
  }
  classifier$fit(series_list, labels)
  invisible(classifier)
}

#' Predict class labels for new time series
#'
#' Applies a fitted `MiltClassifier` to a list of new series.
#'
#' @param classifier A fitted `MiltClassifier`.
#' @param series_list A list of `MiltSeries` objects (test set).
#' @return A named list:
#'   * `$labels` — character vector of predicted class labels.
#'   * `$probabilities` — matrix of class probabilities (or `NULL`).
#' @seealso [milt_classifier()], [milt_classify_fit()]
#' @family classify
#' @export
milt_classify_predict <- function(classifier, series_list) {
  if (!inherits(classifier, "MiltClassifier")) {
    milt_abort("{.arg classifier} must be a {.cls MiltClassifier}.",
               class = "milt_error_invalid_arg")
  }
  classifier$predict(series_list)
}
