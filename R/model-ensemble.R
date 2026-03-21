# Ensemble model: MiltEnsemble R6 + milt_ensemble()

MiltEnsemble <- R6::R6Class(
  classname = "MiltEnsemble",
  inherit   = MiltModelBase,

  private = list(
    .member_specs  = NULL,   # list of unfitted MiltModel clones (specs)
    .member_fitted = NULL,   # list of fitted MiltModel objects (after fit())
    .method        = NULL,   # "mean" | "median" | "weighted"
    .weights       = NULL    # numeric vector, NULL for equal weighting
  ),

  public = list(

    #' @param member_specs Named list of unfitted `MiltModel` objects.
    #' @param method Aggregation method.
    #' @param weights Numeric vector (one per model) or `NULL`.
    initialize = function(member_specs, method, weights) {
      name <- paste0("ensemble_", method)
      super$initialize(name = name, method = method)
      private$.member_specs <- member_specs
      private$.method       <- method
      private$.weights      <- weights
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      specs  <- private$.member_specs
      fitted <- vector("list", length(specs))
      names(fitted) <- names(specs)

      for (nm in names(specs)) {
        milt_info("  Fitting ensemble member {.val {nm}}\u2026")
        m <- specs[[nm]]$clone()
        m$fit(series, ...)
        m$.__enclos_env__$private$.training_series <- series
        fitted[[nm]] <- m
      }

      private$.member_fitted <- fitted
      private$.fitted        <- TRUE
      private$.backend_model <- fitted   # store reference for print
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      horizon  <- as.integer(horizon)
      method   <- private$.method
      fitted   <- private$.member_fitted
      weights  <- private$.weights

      # Collect point forecasts from each member
      pt_list <- lapply(fitted, function(m) {
        m$forecast(horizon, level = level, ...)$as_tibble()$.mean
      })
      pt_mat <- do.call(cbind, pt_list)  # horizon × n_members

      # Aggregate
      if (method == "mean") {
        pt_agg <- rowMeans(pt_mat, na.rm = TRUE)
      } else if (method == "median") {
        pt_agg <- apply(pt_mat, 1L, stats::median, na.rm = TRUE)
      } else if (method == "weighted") {
        w      <- if (is.null(weights)) rep(1 / ncol(pt_mat), ncol(pt_mat)) else weights
        w      <- w / sum(w)   # normalise
        pt_agg <- as.numeric(pt_mat %*% w)
      } else {
        pt_agg <- rowMeans(pt_mat, na.rm = TRUE)
      }

      training_series <- private$.training_series %||%
        private$.member_fitted[[1L]]$.__enclos_env__$private$.training_series
      times  <- .future_times(training_series, horizon)
      pt_tbl <- tibble::tibble(time = times, value = pt_agg)

      # Prediction intervals: use quantiles across member point forecasts
      lower <- stats::setNames(
        lapply(level, function(l) {
          z  <- stats::qnorm(1 - (1 - l / 100) / 2)
          sd_across <- apply(pt_mat, 1L, stats::sd, na.rm = TRUE)
          tibble::tibble(time = times, value = pt_agg - z * sd_across)
        }),
        as.character(level)
      )
      upper <- stats::setNames(
        lapply(level, function(l) {
          z  <- stats::qnorm(1 - (1 - l / 100) / 2)
          sd_across <- apply(pt_mat, 1L, stats::sd, na.rm = TRUE)
          tibble::tibble(time = times, value = pt_agg + z * sd_across)
        }),
        as.character(level)
      )

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = lower,
        upper           = upper,
        model_name      = private$.name,
        horizon         = horizon,
        training_end    = training_series$end_time(),
        training_series = training_series
      )
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      fitted <- private$.member_fitted
      preds_list <- lapply(fitted, function(m) {
        suppressWarnings(m$predict(series, ...))
      })
      preds_mat <- do.call(cbind, preds_list)
      rowMeans(preds_mat, na.rm = TRUE)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      fitted <- private$.member_fitted
      resid_list <- lapply(fitted, function(m) {
        suppressWarnings(m$residuals(...))
      })
      resid_mat <- do.call(cbind, resid_list)
      rowMeans(resid_mat, na.rm = TRUE)
    },

    #' @description Named list of the fitted member models.
    member_models = function() private$.member_fitted,

    #' @description Aggregation method.
    method = function() private$.method
  )
)

# ── milt_ensemble() ───────────────────────────────────────────────────────────

#' Create an ensemble milt model
#'
#' Combines multiple models into a single `MiltModel` that aggregates their
#' forecasts.  The ensemble is fitted with [milt_fit()] and forecasted with
#' [milt_forecast()] just like any other model.
#'
#' @param models A **named** list of unfitted `MiltModel` objects created with
#'   [milt_model()].  Each model is independently fitted on the same training
#'   series inside [milt_fit()].
#' @param method Aggregation method for combining member point forecasts:
#'   * `"mean"` (default) — simple average.
#'   * `"median"` — element-wise median (more robust to outliers).
#'   * `"weighted"` — weighted average; supply weights via `weights`.
#' @param weights Numeric vector of the same length as `models`, used when
#'   `method = "weighted"`.  Values need not sum to 1 (they are normalised
#'   internally). `NULL` uses equal weights.
#' @return An unfitted `MiltModel` of class `"MiltEnsemble"`.
#'
#' @seealso [milt_model()], [milt_fit()], [milt_forecast()], [milt_compare()]
#' @family model
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' ens <- milt_ensemble(
#'   models = list(naive = milt_model("naive"), drift = milt_model("drift")),
#'   method = "mean"
#' ) |>
#'   milt_fit(s) |>
#'   milt_forecast(12)
#' print(ens)
#' }
#' @export
milt_ensemble <- function(models, method = c("mean", "median", "weighted"),
                           weights = NULL) {
  method <- match.arg(method)

  if (!is.list(models) || length(models) == 0L) {
    milt_abort("{.arg models} must be a non-empty named list of MiltModel objects.",
               class = "milt_error_invalid_arg")
  }
  if (is.null(names(models)) || any(nchar(names(models)) == 0L)) {
    milt_abort("{.arg models} must be a **named** list.",
               class = "milt_error_invalid_arg")
  }
  for (nm in names(models)) {
    .assert_milt_model(models[[nm]], arg = glue::glue("models${nm}"))
  }
  if (method == "weighted" && !is.null(weights)) {
    if (length(weights) != length(models)) {
      milt_abort(
        c(
          "{.arg weights} must have the same length as {.arg models}.",
          "i" = "Got {length(weights)} weights for {length(models)} models."
        ),
        class = "milt_error_invalid_arg"
      )
    }
    if (any(weights < 0, na.rm = TRUE)) {
      milt_abort("{.arg weights} must all be non-negative.",
                 class = "milt_error_invalid_arg")
    }
  }

  MiltEnsemble$new(
    member_specs = models,
    method       = method,
    weights      = weights
  )
}
