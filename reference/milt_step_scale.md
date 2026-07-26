# Scale a time series

Normalises the value column(s) of a `MiltSeries` and returns both the
scaled series and a `MiltScaleStep` object that can be used to invert
the transformation.

## Usage

``` r
milt_step_scale(series, method = "zscore")
```

## Arguments

- series:

  A `MiltSeries` object.

- method:

  Character. Scaling method:

  - `"zscore"` (default): subtract mean, divide by SD.

  - `"minmax"`: scale to the interval `[0, 1]`.

  - `"robust"`: subtract median, divide by IQR.

## Value

A named list:

- `$series` — the scaled `MiltSeries`.

- `$step` — a `MiltScaleStep` object for inverting the transform.

## See also

[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md)

Other features:
[`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_map()`](https://ntiGideon.github.io/milt/reference/milt_step_map.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_unboxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_unboxcox.md),
[`milt_step_undiff()`](https://ntiGideon.github.io/milt/reference/milt_step_undiff.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
out <- milt_step_scale(s, method = "zscore")
s_scaled   <- out$series
s_original <- out$step$inverse_transform(s_scaled)
```
