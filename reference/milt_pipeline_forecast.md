# Generate forecasts from a fitted milt pipeline

Applies the (already-fitted) preprocessing steps to a new series (or the
training series) and then calls
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)
on the attached model.

## Usage

``` r
milt_pipeline_forecast(pipeline, horizon, new_data = NULL, ...)
```

## Arguments

- pipeline:

  A fitted `MiltPipeline`.

- horizon:

  Positive integer. Number of steps ahead to forecast.

- new_data:

  Optional `MiltSeries` to use instead of the training data. When `NULL`
  the model forecasts from the end of the training series.

- ...:

  Additional arguments forwarded to
  [`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md).

## Value

A `MiltForecast` object.

## See also

[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
# \donttest{
s    <- milt_series(AirPassengers)
pipe <- milt_pipeline() |>
  milt_pipe_model("naive") |>
  milt_pipeline_fit(s)
#> Fitting pipeline (0 step(s))…
#> Fitting <MiltNaive> model…
#> Done in 0s.
#> Pipeline fitted.
fct  <- milt_pipeline_forecast(pipe, horizon = 12)
# }
```
