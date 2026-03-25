# Add a Fourier-terms step to a pipeline

Add a Fourier-terms step to a pipeline

## Usage

``` r
milt_pipe_step_fourier(pipeline, period = 12, K = 4L)
```

## Arguments

- pipeline:

  A `MiltPipeline`.

- period:

  Numeric. Seasonal period. Default `12`.

- K:

  Integer. Number of Fourier harmonics. Default `4L`.

## Value

The updated `MiltPipeline`, invisibly.

## See also

[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
pipe <- milt_pipeline() |> milt_pipe_step_fourier(period = 12, K = 4L)
```
