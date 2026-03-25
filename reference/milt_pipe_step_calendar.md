# Add a calendar-features step to a pipeline

Add a calendar-features step to a pipeline

## Usage

``` r
milt_pipe_step_calendar(
  pipeline,
  features = c("day_of_week", "month", "quarter", "year", "week")
)
```

## Arguments

- pipeline:

  A `MiltPipeline`.

- features:

  Character vector of calendar features to add. Supported: `"dow"` (day
  of week), `"month"`, `"quarter"`, `"year"`, `"week"`. Default: all of
  the above.

## Value

The updated `MiltPipeline`, invisibly.

## See also

[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_pipeline()`](https://ntiGideon.github.io/milt/reference/milt_pipeline.md)

Other pipeline:
[`milt_pipe_model()`](https://ntiGideon.github.io/milt/reference/milt_pipe_model.md),
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
pipe <- milt_pipeline() |> milt_pipe_step_calendar()
```
