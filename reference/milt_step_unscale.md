# Invert a scaling step on a time series

Convenience wrapper around `MiltScaleStep$inverse_transform()`.

## Usage

``` r
milt_step_unscale(step, series)
```

## Arguments

- step:

  A `MiltScaleStep` object returned by
  [`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md).

- series:

  A `MiltSeries` to unscale.

## Value

The unscaled `MiltSeries`.

## See also

[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md)

Other features:
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md)
