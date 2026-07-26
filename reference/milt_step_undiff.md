# Invert a differencing step on a time series

Convenience wrapper around `MiltDiffStep$inverse_transform()`.
Reconstructs the original series from its differenced version — it does
not invert a *forecast* made in the differenced domain (that requires
the training series' trailing values, not its leading ones, as the
reconstruction seed).

## Usage

``` r
milt_step_undiff(step, series)
```

## Arguments

- step:

  A `MiltDiffStep` object returned by
  [`milt_step_diff()`](https://ntigideon.github.io/milt/reference/milt_step_diff.md).

- series:

  The differenced `MiltSeries` to invert.

## Value

The original-scale `MiltSeries`.

## See also

[`milt_step_diff()`](https://ntigideon.github.io/milt/reference/milt_step_diff.md)

Other features:
[`milt_step_boxcox()`](https://ntigideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_calendar()`](https://ntigideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_diff()`](https://ntigideon.github.io/milt/reference/milt_step_diff.md),
[`milt_step_fourier()`](https://ntigideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntigideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_map()`](https://ntigideon.github.io/milt/reference/milt_step_map.md),
[`milt_step_rolling()`](https://ntigideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntigideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unboxcox()`](https://ntigideon.github.io/milt/reference/milt_step_unboxcox.md),
[`milt_step_unscale()`](https://ntigideon.github.io/milt/reference/milt_step_unscale.md)
