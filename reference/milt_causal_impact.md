# Estimate the causal impact of an intervention

Fits a Bayesian structural time-series model on the pre-intervention
period of `series` and extrapolates it as the counterfactual for the
post-intervention period. The difference between actual and
counterfactual estimates the causal effect.

## Usage

``` r
milt_causal_impact(series, event_time, covariates = NULL, n_seasons = 0L, ...)
```

## Arguments

- series:

  A `MiltSeries` object (univariate).

- event_time:

  The time at which the intervention occurred. Must be a value present
  in `series$times()`. The pre-period is everything strictly before
  `event_time`; the post-period is `event_time` onwards.

- covariates:

  Optional `MiltSeries` object (or numeric matrix with the same number
  of rows as `series`) providing control covariates. Passed to
  `CausalImpact` as additional columns in the data matrix.

- n_seasons:

  Integer. Number of seasons for the seasonal component. `0L` (default)
  disables seasonality.

- ...:

  Additional arguments forwarded to
  [`CausalImpact::CausalImpact()`](https://rdrr.io/pkg/CausalImpact/man/CausalImpact.html).

## Value

A `MiltCausalImpact` object.

## Details

Requires the `CausalImpact` package (\>= 1.2.7).

## See also

[`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md)

Other anomaly:
[`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md),
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md),
[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
ci <- milt_causal_impact(s, event_time = as.Date("1956-01-01"))
plot(ci)
#> Warning: A <numeric> value was passed to a Date scale.
#> ℹ The value was converted to a <Date> object.

# }
```
