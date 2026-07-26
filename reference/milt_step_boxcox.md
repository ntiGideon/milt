# Box-Cox power-transform a time series

Stabilises variance by applying `(y^lambda - 1) / lambda` (or `log(y)`
when `lambda == 0`) to each value column. Requires strictly positive
values.

## Usage

``` r
milt_step_boxcox(series, lambda = NULL)
```

## Arguments

- series:

  A `MiltSeries` object.

- lambda:

  Numeric power parameter. `NULL` (default) estimates it via
  profile-likelihood optimisation over `[-2, 2]`.

## Value

A named list:

- `$series` — the transformed `MiltSeries`.

- `$step` — a `MiltBoxCoxStep` object for inverting the transform.

## See also

[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md)

Other features:
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_map()`](https://ntiGideon.github.io/milt/reference/milt_step_map.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unboxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_unboxcox.md),
[`milt_step_undiff()`](https://ntiGideon.github.io/milt/reference/milt_step_undiff.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
out <- milt_step_boxcox(s)
s_transformed <- out$series
s_original    <- out$step$inverse_transform(s_transformed)
```
