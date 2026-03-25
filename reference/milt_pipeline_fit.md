# Fit a milt pipeline to a training series

Applies all feature-engineering steps (fitting step parameters from the
training data) and then calls
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)
on the attached model.

## Usage

``` r
milt_pipeline_fit(pipeline, series, ...)
```

## Arguments

- pipeline:

  A `MiltPipeline` with at least one step or a model attached.

- series:

  A `MiltSeries` training set.

- ...:

  Additional arguments forwarded to
  [`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md).

## Value

The fitted `MiltPipeline`, invisibly.

## See also

[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
# \donttest{
s    <- milt_series(AirPassengers)
pipe <- milt_pipeline() |>
  milt_pipe_step_lag(lags = 1:3) |>
  milt_pipe_model("naive") |>
  milt_pipeline_fit(s)
#> Fitting pipeline (1 step(s))…
#> Fitting <MiltNaive> model…
#> Done in 0s.
#> Pipeline fitted.
# }
```
