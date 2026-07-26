# Invert a Box-Cox transform on a time series

Convenience wrapper around `MiltBoxCoxStep$inverse_transform()`.

## Usage

``` r
milt_step_unboxcox(step, series)
```

## Arguments

- step:

  A `MiltBoxCoxStep` object returned by
  [`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md).

- series:

  A `MiltSeries` to invert.

## Value

The original-scale `MiltSeries`.

## See also

[`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md)

Other features:
[`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_map()`](https://ntiGideon.github.io/milt/reference/milt_step_map.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_undiff()`](https://ntiGideon.github.io/milt/reference/milt_step_undiff.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)
