# Pipeline engine — milt_pipeline() + milt_step_*() DSL
#
# A MiltPipeline is an ordered list of transformation steps that can be
# applied reproducibly to new MiltSeries objects. Steps store the
# parameters learned during fit so they can be re-applied at predict-time
# without data leakage.
#
# Usage:
#   pipe <- milt_pipeline() |>
#     milt_pipe_step_lag(lags = 1:12) |>
#     milt_pipe_step_scale() |>
#     milt_pipe_model("auto_arima")
#
#   pipe <- milt_pipeline_fit(pipe, train_series)
#   fct  <- milt_pipeline_forecast(pipe, horizon = 12)

# ── MiltPipelineR6 ─────────────────────────────────────────────────────────────

MiltPipelineR6 <- R6::R6Class(
  classname = "MiltPipeline",
  cloneable = TRUE,

  private = list(
    .steps  = NULL,   # list of step specs (list with $type, $params, $fitted)
    .model  = NULL,   # MiltModel appended via milt_pipe_model()
    .fitted = FALSE
  ),

  public = list(

    initialize = function() {
      private$.steps  <- list()
      private$.fitted <- FALSE
    },

    n_steps   = function() length(private$.steps),
    is_fitted = function() private$.fitted,
    get_model = function() private$.model,
    get_steps = function() private$.steps,

    add_step = function(step_spec) {
      private$.steps <- c(private$.steps, list(step_spec))
      invisible(self)
    },

    set_model = function(model) {
      if (!inherits(model, "MiltModel") && !is.character(model)) {
        milt_abort(
          "{.arg model} must be a {.cls MiltModel} or a model name string.",
          class = "milt_error_invalid_arg"
        )
      }
      private$.model <- model
      invisible(self)
    },

    # Apply all feature-engineering steps to a series (fit + transform).
    fit_transform = function(series) {
      assert_milt_series(series)
      s <- series
      fitted_steps <- vector("list", length(private$.steps))
      for (i in seq_along(private$.steps)) {
        step <- private$.steps[[i]]
        res  <- .pipeline_fit_step(step, s)
        s    <- res$series
        fitted_steps[[i]] <- res$step
      }
      private$.steps  <- fitted_steps
      private$.fitted <- TRUE
      s
    },

    # Apply only the transform (no re-fitting of step parameters).
    transform = function(series) {
      assert_milt_series(series)
      if (!private$.fitted) {
        milt_abort(
          "Pipeline has not been fitted yet. Call {.fn milt_pipeline_fit} first.",
          class = "milt_error_not_fitted"
        )
      }
      s <- series
      for (step in private$.steps) {
        s <- .pipeline_transform_step(step, s)
      }
      s
    }
  )
)

# ── S3 methods ─────────────────────────────────────────────────────────────────

#' Print a MiltPipeline
#'
#' @param x A `MiltPipeline` object.
#' @param ... Ignored.
#' @export
print.MiltPipeline <- function(x, ...) {
  p      <- x$.__enclos_env__$private
  status <- if (x$is_fitted()) cli::col_green("fitted") else cli::col_red("unfitted")

  cat(glue::glue("# A MiltPipeline [{status}]\n"))
  cat(glue::glue("# Steps : {x$n_steps()}\n"))

  if (x$n_steps() > 0L) {
    for (i in seq_along(p$.steps)) {
      step <- p$.steps[[i]]
      cat(glue::glue("  {i}. {step$type}\n"))
    }
  } else {
    cat("  (no steps)\n")
  }

  if (!is.null(p$.model)) {
    model_name <- if (is.character(p$.model)) p$.model else class(p$.model)[[1L]]
    cat(glue::glue("# Model : {model_name}\n"))
  }

  invisible(x)
}

# ── Public constructors / verbs ────────────────────────────────────────────────

#' Create a new milt pipeline
#'
#' Returns an empty `MiltPipeline` object. Chain steps onto it with
#' `milt_pipe_step_*()` functions and attach a model with [milt_pipe_model()].
#' Fit the whole pipeline with [milt_pipeline_fit()].
#'
#' @return An empty `MiltPipeline` object.
#' @seealso [milt_pipeline_fit()], [milt_pipeline_forecast()],
#'   [milt_pipe_step_lag()], [milt_pipe_step_scale()],
#'   [milt_pipe_step_rolling()], [milt_pipe_model()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline()
#' pipe
#' @export
milt_pipeline <- function() {
  MiltPipelineR6$new()
}

#' Add a lag step to a pipeline
#'
#' Appends a lag-feature step to the pipeline. When the pipeline is fitted,
#' `milt_step_lag()` is called on the training series and the `lags` parameter
#' is stored. The same lags are applied at forecast-time.
#'
#' @param pipeline A `MiltPipeline` created by [milt_pipeline()].
#' @param lags Integer vector of lag values. Default `1:12`.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_step_lag()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline() |> milt_pipe_step_lag(lags = 1:6)
#' @export
milt_pipe_step_lag <- function(pipeline, lags = 1:12) {
  .assert_milt_pipeline(pipeline)
  pipeline$add_step(list(
    type   = "lag",
    params = list(lags = as.integer(lags)),
    fitted = NULL
  ))
  invisible(pipeline)
}

#' Add a rolling-statistics step to a pipeline
#'
#' @param pipeline A `MiltPipeline`.
#' @param windows Integer vector of window widths. Default `c(7L, 14L, 30L)`.
#' @param fns Character vector of summary functions to apply.
#'   Supported: `"mean"`, `"sd"`, `"min"`, `"max"`, `"median"`. Default
#'   `c("mean", "sd")`.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_step_rolling()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline() |> milt_pipe_step_rolling(windows = c(7L, 14L))
#' @export
milt_pipe_step_rolling <- function(pipeline,
                                   windows = c(7L, 14L, 30L),
                                   fns     = c("mean", "sd")) {
  .assert_milt_pipeline(pipeline)
  pipeline$add_step(list(
    type   = "rolling",
    params = list(windows = as.integer(windows), fns = fns),
    fitted = NULL
  ))
  invisible(pipeline)
}

#' Add a Fourier-terms step to a pipeline
#'
#' @param pipeline A `MiltPipeline`.
#' @param period Numeric. Seasonal period. Default `12`.
#' @param K Integer. Number of Fourier harmonics. Default `4L`.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_step_fourier()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline() |> milt_pipe_step_fourier(period = 12, K = 4L)
#' @export
milt_pipe_step_fourier <- function(pipeline, period = 12, K = 4L) {
  .assert_milt_pipeline(pipeline)
  pipeline$add_step(list(
    type   = "fourier",
    params = list(period = period, K = as.integer(K)),
    fitted = NULL
  ))
  invisible(pipeline)
}

#' Add a calendar-features step to a pipeline
#'
#' @param pipeline A `MiltPipeline`.
#' @param features Character vector of calendar features to add.
#'   Supported: `"dow"` (day of week), `"month"`, `"quarter"`, `"year"`,
#'   `"week"`. Default: all of the above.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_step_calendar()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline() |> milt_pipe_step_calendar()
#' @export
milt_pipe_step_calendar <- function(pipeline,
                                    features = c("dow", "month", "quarter",
                                                 "year", "week")) {
  .assert_milt_pipeline(pipeline)
  pipeline$add_step(list(
    type   = "calendar",
    params = list(features = features),
    fitted = NULL
  ))
  invisible(pipeline)
}

#' Add a scaling step to a pipeline
#'
#' Scales the series values. During [milt_pipeline_fit()] the mean and
#' standard deviation are computed from the training data and stored so that
#' the same transformation can be applied at predict-time.
#'
#' @param pipeline A `MiltPipeline`.
#' @param method Character scalar. `"zscore"` (default) or `"minmax"`.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_step_scale()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' pipe <- milt_pipeline() |> milt_pipe_step_scale()
#' @export
milt_pipe_step_scale <- function(pipeline, method = "zscore") {
  .assert_milt_pipeline(pipeline)
  if (!method %in% c("zscore", "minmax")) {
    milt_abort(
      "{.arg method} must be {.val zscore} or {.val minmax}.",
      class = "milt_error_invalid_arg"
    )
  }
  pipeline$add_step(list(
    type   = "scale",
    params = list(method = method),
    fitted = NULL
  ))
  invisible(pipeline)
}

#' Attach a model to a pipeline
#'
#' The model is the final stage of the pipeline. It will be fitted on the
#' transformed training series when [milt_pipeline_fit()] is called.
#'
#' @param pipeline A `MiltPipeline`.
#' @param model Either a `MiltModel` object (from [milt_model()]) or a
#'   character model name (e.g. `"auto_arima"`).
#' @param ... Hyperparameters forwarded to [milt_model()] when `model` is a
#'   character string.
#' @return The updated `MiltPipeline`, invisibly.
#' @seealso [milt_pipeline_fit()], [milt_pipeline()]
#' @family pipeline
#' @examples
#' \donttest{
#' pipe <- milt_pipeline() |>
#'   milt_pipe_step_lag(lags = 1:6) |>
#'   milt_pipe_model("naive")
#' }
#' @export
milt_pipe_model <- function(pipeline, model, ...) {
  .assert_milt_pipeline(pipeline)
  if (is.character(model)) {
    model <- milt_model(model, ...)
  }
  pipeline$set_model(model)
  invisible(pipeline)
}

#' Fit a milt pipeline to a training series
#'
#' Applies all feature-engineering steps (fitting step parameters from the
#' training data) and then calls [milt_fit()] on the attached model.
#'
#' @param pipeline A `MiltPipeline` with at least one step or a model attached.
#' @param series A `MiltSeries` training set.
#' @param ... Additional arguments forwarded to [milt_fit()].
#' @return The fitted `MiltPipeline`, invisibly.
#' @seealso [milt_pipeline()], [milt_pipeline_forecast()]
#' @family pipeline
#' @examples
#' \donttest{
#' s    <- milt_series(AirPassengers)
#' pipe <- milt_pipeline() |>
#'   milt_pipe_step_lag(lags = 1:3) |>
#'   milt_pipe_model("naive") |>
#'   milt_pipeline_fit(s)
#' }
#' @export
milt_pipeline_fit <- function(pipeline, series, ...) {
  .assert_milt_pipeline(pipeline)
  assert_milt_series(series)

  if (is.null(pipeline$get_model())) {
    milt_abort(
      c(
        "No model is attached to this pipeline.",
        "i" = "Add one with {.fn milt_pipe_model}."
      ),
      class = "milt_error_no_model"
    )
  }

  milt_info("Fitting pipeline ({pipeline$n_steps()} step(s))\u2026")

  # 1. Fit-transform all preprocessing steps
  transformed <- pipeline$fit_transform(series)

  # 2. Fit the model on the transformed series
  milt_fit(pipeline$get_model(), transformed, ...)

  milt_info("Pipeline fitted.")
  invisible(pipeline)
}

#' Generate forecasts from a fitted milt pipeline
#'
#' Applies the (already-fitted) preprocessing steps to a new series (or the
#' training series) and then calls [milt_forecast()] on the attached model.
#'
#' @param pipeline A fitted `MiltPipeline`.
#' @param horizon Positive integer. Number of steps ahead to forecast.
#' @param new_data Optional `MiltSeries` to use instead of the training data.
#'   When `NULL` the model forecasts from the end of the training series.
#' @param ... Additional arguments forwarded to [milt_forecast()].
#' @return A `MiltForecast` object.
#' @seealso [milt_pipeline_fit()], [milt_forecast()]
#' @family pipeline
#' @examples
#' \donttest{
#' s    <- milt_series(AirPassengers)
#' pipe <- milt_pipeline() |>
#'   milt_pipe_model("naive") |>
#'   milt_pipeline_fit(s)
#' fct  <- milt_pipeline_forecast(pipe, horizon = 12)
#' }
#' @export
milt_pipeline_forecast <- function(pipeline, horizon, new_data = NULL, ...) {
  .assert_milt_pipeline(pipeline)
  if (!pipeline$is_fitted()) {
    milt_abort(
      c(
        "Pipeline has not been fitted yet.",
        "i" = "Call {.fn milt_pipeline_fit} first."
      ),
      class = "milt_error_not_fitted"
    )
  }
  assert_positive_integer(horizon, "horizon")

  if (!is.null(new_data)) {
    assert_milt_series(new_data, "new_data")
    new_data <- pipeline$transform(new_data)
    milt_forecast(pipeline$get_model(), horizon = as.integer(horizon),
                  new_data = new_data, ...)
  } else {
    milt_forecast(pipeline$get_model(), horizon = as.integer(horizon), ...)
  }
}

#' Transform new data through a fitted pipeline (without the model step)
#'
#' Useful for applying the same preprocessing to a test set before evaluation.
#'
#' @param pipeline A fitted `MiltPipeline`.
#' @param series A `MiltSeries` to transform.
#' @return A transformed `MiltSeries`.
#' @seealso [milt_pipeline_fit()]
#' @family pipeline
#' @examples
#' \donttest{
#' s    <- milt_series(AirPassengers)
#' spl  <- milt_split(s, 0.8)
#' pipe <- milt_pipeline() |>
#'   milt_pipe_step_lag(lags = 1:3) |>
#'   milt_pipe_model("naive") |>
#'   milt_pipeline_fit(spl$train)
#' test_transformed <- milt_pipeline_transform(pipe, spl$test)
#' }
#' @export
milt_pipeline_transform <- function(pipeline, series) {
  .assert_milt_pipeline(pipeline)
  assert_milt_series(series)
  pipeline$transform(series)
}

# ── Step dispatch helpers ──────────────────────────────────────────────────────

# Fit a single step to `series` and return list(series = ..., step = ...) where
# step is the updated spec with fitted parameters stored.
.pipeline_fit_step <- function(step, series) {
  type <- step$type
  p    <- step$params

  if (type == "lag") {
    s_out <- milt_step_lag(series, lags = p$lags)
    step$fitted <- list(lags = p$lags,
                        last_values = attr(s_out, "milt_step_lag")$last_values)

  } else if (type == "rolling") {
    s_out <- milt_step_rolling(series, windows = p$windows, fns = p$fns)
    step$fitted <- list(windows = p$windows, fns = p$fns)

  } else if (type == "fourier") {
    s_out <- milt_step_fourier(series, period = p$period, K = p$K)
    step$fitted <- list(period = p$period, K = p$K)

  } else if (type == "calendar") {
    s_out <- milt_step_calendar(series, features = p$features)
    step$fitted <- list(features = p$features)

  } else if (type == "scale") {
    res   <- milt_step_scale(series, method = p$method)
    s_out <- res$series
    step$fitted <- res$step   # MiltScaleStep object

  } else {
    milt_abort(
      "Unknown pipeline step type: {.val {type}}.",
      class = "milt_error_unknown_step"
    )
  }

  list(series = s_out, step = step)
}

# Apply a step using only the fitted parameters (no re-learning).
.pipeline_transform_step <- function(step, series) {
  type <- step$type
  p    <- step$params
  f    <- step$fitted

  if (type == "lag") {
    milt_step_lag(series, lags = p$lags)

  } else if (type == "rolling") {
    milt_step_rolling(series, windows = p$windows, fns = p$fns)

  } else if (type == "fourier") {
    milt_step_fourier(series, period = p$period, K = p$K)

  } else if (type == "calendar") {
    milt_step_calendar(series, features = p$features)

  } else if (type == "scale") {
    if (is.null(f)) {
      milt_abort(
        "Scale step has not been fitted. Call {.fn milt_pipeline_fit} first.",
        class = "milt_error_not_fitted"
      )
    }
    # Re-apply using the stored MiltScaleStep (trained on training data)
    f$transform(series)

  } else {
    milt_abort(
      "Unknown pipeline step type: {.val {type}}.",
      class = "milt_error_unknown_step"
    )
  }
}

# ── Internal guard ─────────────────────────────────────────────────────────────

.assert_milt_pipeline <- function(x, arg = "pipeline") {
  if (!inherits(x, "MiltPipeline")) {
    milt_abort(
      c(
        "{.arg {arg}} must be a {.cls MiltPipeline} object.",
        "i" = "Create one with {.fn milt_pipeline}."
      ),
      class = "milt_error_not_milt_pipeline"
    )
  }
  invisible(x)
}
