# Add a lag step to a pipeline

Appends a lag-feature step to the pipeline. When the pipeline is fitted,
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md)
is called on the training series and the `lags` parameter is stored. The
same lags are applied at forecast-time.

## Usage

``` r
milt_pipe_step_lag(pipeline, lags = 1:12)
```

## Arguments

- pipeline:

  A `MiltPipeline` created by
  [`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md).

- lags:

  Integer vector of lag values. Default `1:12`.

## Value

The updated `MiltPipeline`, invisibly.

## See also

[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_rolling.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
pipe <- milt_pipeline() |> milt_pipe_step_lag(lags = 1:6)
```
