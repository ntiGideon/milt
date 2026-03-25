# SVM regression backend (requires e1071 package)
#
# Fits an epsilon-SVR on auto-generated lag features from the training series.
# Uses the same .ml_build_lag_features / .ml_recursive_forecast helpers
# defined in backend-xgboost.R.

#' @keywords internal
#' @noRd
MiltSVM <- R6::R6Class(
  classname = "MiltSVM",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  public = list(

    #' @param lags Integer vector. Lag indices to use as features. Default `1:12`.
    #' @param kernel Character. SVM kernel: `"radial"` (default), `"linear"`,
    #'   `"polynomial"`, or `"sigmoid"`.
    #' @param cost Numeric. Cost parameter C. Default `1`.
    #' @param epsilon Numeric. Epsilon in the insensitive loss function.
    #'   Default `0.1`.
    #' @param gamma Numeric or `NULL`. Kernel coefficient. `NULL` auto-sets
    #'   to `1 / n_features`.
    initialize = function(lags    = 1:12,
                          kernel  = "radial",
                          cost    = 1,
                          epsilon = 0.1,
                          gamma   = NULL) {
      super$initialize(
        name    = "svm",
        lags    = as.integer(lags),
        kernel  = as.character(kernel),
        cost    = as.numeric(cost),
        epsilon = as.numeric(epsilon),
        gamma   = gamma
      )
    },

    fit = function(series) {
      check_installed_backend("e1071", "svm")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("SVM requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      vals <- series$values()
      feat <- .ml_build_lag_features(vals, p$lags)

      svm_args <- list(
        x       = feat$X,
        y       = feat$y,
        type    = "eps-regression",
        kernel  = p$kernel,
        cost    = p$cost,
        epsilon = p$epsilon
      )
      if (!is.null(p$gamma)) svm_args$gamma <- p$gamma

      private$.backend_model <- tryCatch(
        do.call(e1071::svm, svm_args),
        error = function(e) {
          milt_abort(c("SVM fitting failed.", "x" = conditionMessage(e)),
                     class = "milt_error_fit_failed")
        }
      )
      private$.feat    <- feat
      private$.train_vals <- as.numeric(vals)
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      p   <- private$.params
      mdl <- private$.backend_model

      predict_fn <- function(x_row) {
        as.numeric(predict(mdl, x_row))
      }

      fct <- .ml_recursive_forecast(
        predict_fn      = predict_fn,
        last_values     = private$.train_vals,
        lags            = p$lags,
        horizon         = as.integer(horizon),
        training_series = private$.training_series,
        model_name      = "svm",
        level           = level
      )

      # Improve PIs using in-sample residuals
      resid  <- self$residuals()
      times  <- .future_times(private$.training_series, horizon)
      pt_v   <- fct$as_tibble()$.mean
      pi     <- .ml_pi_from_residuals(resid, pt_v, times, level)

      MiltForecastR6$new(
        point_forecast  = tibble::tibble(time = times, value = pt_v),
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "svm",
        horizon         = as.integer(horizon),
        training_end    = private$.training_series$end_time(),
        training_series = private$.training_series
      )
    },

    predict = function(series = NULL) {
      fitted <- as.numeric(predict(private$.backend_model, private$.feat$X))
      # Pad with NA for the initial max_lag observations
      c(rep(NA_real_, private$.feat$max_lag), fitted)
    },

    residuals = function() {
      p   <- private$.params
      n   <- length(private$.train_vals)
      fit <- self$predict()
      private$.train_vals - fit
    }
  ),

  private = list(
    .feat        = NULL,
    .train_vals  = NULL
  )
)

.onLoad_svm <- function() {
  register_milt_model(
    name        = "svm",
    class       = MiltSVM,
    description = "Support Vector Machine regression with lag features (e1071 package)",
    supports    = list(
      multivariate  = FALSE,
      probabilistic = TRUE,
      covariates    = FALSE,
      multi_series  = FALSE
    )
  )
}
