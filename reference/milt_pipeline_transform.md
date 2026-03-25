# Transform new data through a fitted pipeline (without the model step)

Useful for applying the same preprocessing to a test set before
evaluation.

## Usage

``` r
milt_pipeline_transform(pipeline, series)
```

## Arguments

- pipeline:

  A fitted `MiltPipeline`.

- series:

  A `MiltSeries` to transform.

## Value

A transformed `MiltSeries`.

## See also

[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md)

## Examples

``` r
# \donttest{
s    <- milt_series(AirPassengers)
spl  <- milt_split(s, 0.8)
pipe <- milt_pipeline() |>
  milt_pipe_step_lag(lags = 1:3) |>
  milt_pipe_model("naive") |>
  milt_pipeline_fit(spl$train)
#> Fitting pipeline (1 step(s))…
#> Fitting <MiltNaive> model…
#> Done in 0s.
#> Pipeline fitted.
test_transformed <- milt_pipeline_transform(pipe, spl$test)
# }
```
