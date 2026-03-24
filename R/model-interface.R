# MiltModelBase R6 class + public-facing model verbs

# ── Base model class ──────────────────────────────────────────────────────────

#' @title MiltModelBase — base class for all milt model backends
#' @description
#' Every model backend inherits from this class and overrides `fit()`,
#' `forecast()`, `predict()`, and `residuals()`. Users interact exclusively
#' through the public verbs [milt_model()], [milt_fit()], [milt_forecast()],
#' [milt_predict()], and [milt_residuals()].
#'
#' @export
MiltModelBase <- R6::R6Class(
  classname = "MiltModel",
  cloneable = TRUE,

  private = list(
    .name            = NULL,   # character: model identifier
    .params          = NULL,   # list: hyperparameters passed at init
    .fitted          = FALSE,  # logical
    .training_series = NULL,   # MiltSeries used in fit()
    .backend_model   = NULL,   # the raw backend object (e.g., Arima, xgb.Booster)
    .fit_time        = NULL    # difftime: how long fit() took
  ),

  public = list(

    #' @description Initialise a model with hyperparameters.
    #' @param name Character scalar: model identifier string.
    #' @param ... Hyperparameters stored in `private$.params`.
    initialize = function(name = NULL, ...) {
      private$.name   <- name %||% class(self)[[1L]]
      private$.params <- list(...)
      private$.fitted <- FALSE
    },

    # ── Methods backends MUST override ──────────────────────────────────────

    #' @description Fit the model to a `MiltSeries`. **Must be overridden.**
    #' @param series A `MiltSeries` object.
    fit = function(series) {
      milt_abort(
        "Backend {.cls {class(self)[[1L]]}} must implement {.fn fit}.",
        class = "milt_error_not_implemented"
      )
    },

    #' @description Generate a `MiltForecast`. **Must be overridden.**
    #' @param horizon Integer number of steps ahead.
    #' @param ... Additional arguments.
    forecast = function(horizon, ...) {
      milt_abort(
        "Backend {.cls {class(self)[[1L]]}} must implement {.fn forecast}.",
        class = "milt_error_not_implemented"
      )
    },

    #' @description In-sample predictions. **Must be overridden.**
    #' @param series Optional `MiltSeries`. When `NULL`, returns training
    #'   fitted values.
    predict = function(series = NULL) {
      milt_abort(
        "Backend {.cls {class(self)[[1L]]}} must implement {.fn predict}.",
        class = "milt_error_not_implemented"
      )
    },

    #' @description Training residuals. **Must be overridden.**
    residuals = function() {
      milt_abort(
        "Backend {.cls {class(self)[[1L]]}} must implement {.fn residuals}.",
        class = "milt_error_not_implemented"
      )
    },

    # ── Common accessors (no override needed) ────────────────────────────────

    #' @description `TRUE` after [milt_fit()] has been called successfully.
    is_fitted = function() private$.fitted,

    #' @description Return the hyperparameter list supplied at construction.
    get_params = function() private$.params,

    #' @description Print a summary to the console.
    summary = function() {
      cat(format(self), "\n")
      invisible(self)
    }
  )
)

# ── S3 methods for MiltModel ──────────────────────────────────────────────────

#' Print a MiltModel
#'
#' @param x A `MiltModel` object.
#' @param ... Ignored.
#' @export
print.MiltModel <- function(x, ...) {
  p      <- x$.__enclos_env__$private
  status <- if (x$is_fitted()) cli::col_green("fitted") else cli::col_red("unfitted")

  cat(glue::glue("# A MiltModel <{p$.name}> [{status}]\n"))

  if (length(p$.params) > 0L) {
    param_str <- paste(
      names(p$.params), "=",
      vapply(p$.params, function(v) paste(as.character(v), collapse = ", "),
             character(1L)),
      collapse = "; "
    )
    cat(glue::glue("# Params      : {param_str}\n"))
  }

  if (x$is_fitted() && !is.null(p$.training_series)) {
    s <- p$.training_series
    cat(glue::glue(
      "# Trained on  : {s$n_timesteps()} obs [{s$freq()}]",
      " {s$start_time()} \u2014 {s$end_time()}\n"
    ))
  }

  if (!is.null(p$.fit_time)) {
    cat(glue::glue("# Fit time    : {round(as.numeric(p$.fit_time, units = 'secs'), 2)}s\n"))
  }

  invisible(x)
}

#' @export
format.MiltModel <- function(x, ...) {
  p <- x$.__enclos_env__$private
  glue::glue("<MiltModel: {p$.name} [{if (x$is_fitted()) 'fitted' else 'unfitted'}]>")
}

# ── Public verbs ──────────────────────────────────────────────────────────────

#' Initialise a milt model
#'
#' Looks up the requested model in the registry and returns an unfitted model
#' object ready to be passed to [milt_fit()].
#'
#' @param name Character scalar. The model identifier (e.g. `"auto_arima"`,
#'   `"naive"`, `"xgboost"`). Use [list_milt_models()] to see all options.
#' @param ... Hyperparameters forwarded to the model's constructor.
#' @return An unfitted `MiltModel` object.
#' @seealso [milt_fit()], [milt_forecast()], [list_milt_models()]
#' @family model
#' @examples
#' \donttest{
#' m <- milt_model("naive")
#' }
#' @export
milt_model <- function(name, ...) {
  if (!is_scalar_character(name)) {
    milt_abort(
      "{.arg name} must be a single string. Did you mean {.code milt_model('auto_arima')}?",
      class = "milt_error_invalid_arg"
    )
  }
  cls <- get_milt_model_class(name)
  cls$new(...)
}

#' Fit a milt model to a MiltSeries
#'
#' Calls the model's internal `fit()` method and records the elapsed time.
#' Returns the fitted model invisibly for pipe compatibility.
#'
#' @param model An unfitted `MiltModel` created by [milt_model()].
#' @param series A `MiltSeries` object.
#' @param ... Additional arguments forwarded to the backend's `fit()` method.
#' @return The fitted `MiltModel`, invisibly.
#' @seealso [milt_model()], [milt_forecast()]
#' @family model
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' m <- milt_model("naive") |> milt_fit(s)
#' }
#' @export
milt_fit <- function(model, series, ...) {
  .assert_milt_model(model)
  assert_milt_series(series)
  check_series_has_no_gaps(series)

  milt_info("Fitting {.cls {class(model)[[1L]]}} model\u2026")
  t0 <- proc.time()[["elapsed"]]
  model$fit(series, ...)
  elapsed <- proc.time()[["elapsed"]] - t0

  # Record fit metadata in private fields (R6 reference semantics)
  model$.__enclos_env__$private$.fitted          <- TRUE
  model$.__enclos_env__$private$.fit_time        <- as.difftime(elapsed, units = "secs")
  model$.__enclos_env__$private$.training_series <- series

  milt_info("Done in {round(elapsed, 2)}s.")
  invisible(model)
}

#' Generate forecasts from a fitted milt model
#'
#' @param model A fitted `MiltModel`.
#' @param horizon Positive integer. Number of steps ahead to forecast.
#' @param level Numeric vector of confidence levels for prediction intervals.
#'   Default `c(80, 95)`.
#' @param num_samples Integer or `NULL`. Number of sample paths to draw for
#'   probabilistic forecasts. `NULL` returns point forecasts only.
#' @param future_covariates A `MiltSeries` of future-known covariates, or
#'   `NULL`.
#' @param ... Additional arguments forwarded to the backend's `forecast()`
#'   method.
#' @return A `MiltForecast` object.
#' @seealso [milt_fit()], [milt_accuracy()]
#' @family model
#' @examples
#' \donttest{
#' s   <- milt_series(AirPassengers)
#' fct <- milt_model("naive") |> milt_fit(s) |> milt_forecast(horizon = 12)
#' }
#' @export
milt_forecast <- function(model,
                           horizon,
                           level             = c(80, 95),
                           num_samples       = NULL,
                           future_covariates = NULL,
                           ...) {
  .assert_milt_model(model)
  .assert_is_fitted(model)
  assert_positive_integer(horizon, "horizon")

  if (!is.null(future_covariates)) assert_milt_series(future_covariates, "future_covariates")

  model$forecast(
    horizon           = as.integer(horizon),
    level             = level,
    num_samples       = num_samples,
    future_covariates = future_covariates,
    ...
  )
}

#' In-sample predictions from a fitted milt model
#'
#' @param model A fitted `MiltModel`.
#' @param series Optional `MiltSeries`. When `NULL`, returns fitted values for
#'   the training series.
#' @param ... Additional arguments forwarded to the backend's `predict()`.
#' @return A numeric vector of fitted/predicted values.
#' @family model
#' @examples
#' \donttest{
#' s     <- milt_series(AirPassengers)
#' model <- milt_model("naive") |> milt_fit(s)
#' fitted_vals <- milt_predict(model)
#' head(fitted_vals)
#' }
#' @export
milt_predict <- function(model, series = NULL, ...) {
  .assert_milt_model(model)
  .assert_is_fitted(model)
  if (!is.null(series)) assert_milt_series(series, "series")
  model$predict(series, ...)
}

#' Residuals from a fitted milt model
#'
#' @param model A fitted `MiltModel`.
#' @param ... Additional arguments forwarded to the backend's `residuals()`.
#' @return A numeric vector of residuals (actual minus fitted).
#' @family model
#' @export
milt_residuals <- function(model, ...) {
  .assert_milt_model(model)
  .assert_is_fitted(model)
  model$residuals(...)
}

#' Refit a milt model on new data without re-tuning
#'
#' Uses the model's existing hyperparameters but trains on a new series.
#' Useful for rolling updates in production.
#'
#' @param model A previously fitted `MiltModel`.
#' @param series A `MiltSeries` containing the new training data.
#' @param ... Additional arguments forwarded to `fit()`.
#' @return The refitted `MiltModel`, invisibly.
#' @family model
#' @export
milt_refit <- function(model, series, ...) {
  .assert_milt_model(model)
  assert_milt_series(series)
  milt_fit(model, series, ...)
}

# ── Internal guards ───────────────────────────────────────────────────────────

.assert_milt_model <- function(x, arg = "model") {
  if (!inherits(x, "MiltModel")) {
    milt_abort(
      c(
        "{.arg {arg}} must be a {.cls MiltModel} object.",
        "i" = "Create one with {.fn milt_model}."
      ),
      class = "milt_error_not_milt_model"
    )
  }
  invisible(x)
}

.assert_is_fitted <- function(model, arg = "model") {
  if (!model$is_fitted()) {
    milt_abort(
      c(
        "{.arg {arg}} has not been fitted yet.",
        "i" = "Call {.fn milt_fit} before {.fn milt_forecast}."
      ),
      class = "milt_error_not_fitted"
    )
  }
  invisible(model)
}
