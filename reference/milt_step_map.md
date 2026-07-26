# Apply an arbitrary elementwise function to a time series

Applies `fn` to every value in each value column. `fn` may take either
one argument (the values only, e.g. `log1p`) or two arguments (the
timestamps and the values, e.g.
`function(time, value) value / lubridate::year(time)`) — the number of
arguments `fn` declares is detected automatically, mirroring darts'
dual-mode `TimeSeries.map()`. Supply `inverse_fn` to get back an
invertible `MiltMapStep`.

## Usage

``` r
milt_step_map(series, fn, inverse_fn = NULL)
```

## Arguments

- series:

  A `MiltSeries` object.

- fn:

  A function of one argument (`value`) or two arguments (`time`,
  `value`).

- inverse_fn:

  Optional function satisfying `inverse_fn(fn(x)) == x` (or the
  two-argument equivalent), e.g. `expm1` to invert `log1p`. When `NULL`
  (default), `$step` is `NULL`.

## Value

A named list:

- `$series` — the mapped `MiltSeries`.

- `$step` — a `MiltMapStep` for inverting the transform, or `NULL` when
  `inverse_fn` was not supplied.

## See also

[`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md)

Other features:
[`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unboxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_unboxcox.md),
[`milt_step_undiff()`](https://ntiGideon.github.io/milt/reference/milt_step_undiff.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
out <- milt_step_map(s, fn = log1p, inverse_fn = expm1)
s_mapped   <- out$series
s_original <- out$step$inverse_transform(s_mapped)

# time-aware mapping: zero out the first year of observations
out2 <- milt_step_map(s, fn = function(time, value) {
  ifelse(lubridate::year(time) == lubridate::year(min(time)), 0, value)
})
```
