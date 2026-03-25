# Attach a model to a pipeline

The model is the final stage of the pipeline. It will be fitted on the
transformed training series when
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md)
is called.

## Usage

``` r
milt_pipe_model(pipeline, model, ...)
```

## Arguments

- pipeline:

  A `MiltPipeline`.

- model:

  Either a `MiltModel` object (from
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md))
  or a character model name (e.g. `"auto_arima"`).

- ...:

  Hyperparameters forwarded to
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)
  when `model` is a character string.

## Value

The updated `MiltPipeline`, invisibly.

## See also

[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md)

Other pipeline:
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
# \donttest{
pipe <- milt_pipeline() |>
  milt_pipe_step_lag(lags = 1:6) |>
  milt_pipe_model("naive")
# }
```
