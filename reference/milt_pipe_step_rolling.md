# Add a rolling-statistics step to a pipeline

Add a rolling-statistics step to a pipeline

## Usage

``` r
milt_pipe_step_rolling(
  pipeline,
  windows = c(7L, 14L, 30L),
  fns = c("mean", "sd")
)
```

## Arguments

- pipeline:

  A `MiltPipeline`.

- windows:

  Integer vector of window widths. Default `c(7L, 14L, 30L)`.

- fns:

  Character vector of summary functions to apply. Supported: `"mean"`,
  `"sd"`, `"min"`, `"max"`, `"median"`. Default `c("mean", "sd")`.

## Value

The updated `MiltPipeline`, invisibly.

## See also

[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
[`milt_pipe_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_calendar.md),
[`milt_pipe_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_fourier.md),
[`milt_pipe_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_lag.md),
[`milt_pipe_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_pipe_step_scale.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md),
[`milt_pipeline_fit()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_fit.md),
[`milt_pipeline_forecast()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_forecast.md),
[`milt_pipeline_transform()`](https://ntiGideon.github.io/milt/reference/milt_pipeline_transform.md)

## Examples

``` r
pipe <- milt_pipeline() |> milt_pipe_step_rolling(windows = c(7L, 14L))
```
