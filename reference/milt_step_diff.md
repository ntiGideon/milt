# Difference a time series

Applies sequential lagged differencing (e.g. `lags = c(1, 12)` removes a
trend then a yearly seasonal pattern) to stabilise the mean.
Differencing shortens the series by `sum(lags)` observations.

## Usage

``` r
milt_step_diff(series, lags = 1L)
```

## Arguments

- series:

  A `MiltSeries` object.

- lags:

  Integer vector of lag orders, applied in sequence. Default `1L` (first
  difference).

## Value

A named list:

- `$series` — the differenced `MiltSeries` (shorter than the input).

- `$step` — a `MiltDiffStep` object for inverting the transform back to
  the original series.

## See also

[`milt_step_boxcox()`](https://ntigideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_scale()`](https://ntigideon.github.io/milt/reference/milt_step_scale.md)

Other features:
[`milt_step_boxcox()`](https://ntigideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_calendar()`](https://ntigideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_fourier()`](https://ntigideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntigideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_map()`](https://ntigideon.github.io/milt/reference/milt_step_map.md),
[`milt_step_rolling()`](https://ntigideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntigideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unboxcox()`](https://ntigideon.github.io/milt/reference/milt_step_unboxcox.md),
[`milt_step_undiff()`](https://ntigideon.github.io/milt/reference/milt_step_undiff.md),
[`milt_step_unscale()`](https://ntigideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
out <- milt_step_diff(s, lags = 1L)
s_diffed   <- out$series
s_original <- out$step$inverse_transform(s_diffed)
```
