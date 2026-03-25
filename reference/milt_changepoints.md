# Detect changepoints in a time series

Wraps the `changepoint` package to identify structural breaks in the
mean, variance, or both.

## Usage

``` r
milt_changepoints(
  series,
  method = "pelt",
  stat = "mean",
  penalty = "BIC",
  n_cpts = NA,
  ...
)
```

## Arguments

- series:

  A `MiltSeries` object (univariate).

- method:

  Character. Search method: `"pelt"` (default), `"binseg"`, or `"amoc"`
  (at-most-one-changepoint).

- stat:

  Character. Test statistic: `"mean"` (default), `"variance"`, or
  `"meanvar"`.

- penalty:

  Character. Penalty type passed to the `changepoint` package. Default
  `"BIC"`.

- n_cpts:

  Integer or `NA`. Maximum number of changepoints for `"binseg"`.
  Ignored for other methods. Default `NA`.

- ...:

  Additional arguments forwarded to the `changepoint` function.

## Value

A `MiltChangepoints` object.

## See also

[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md),
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)

Other anomaly:
[`milt_causal_impact()`](https://ntiGideon.github.io/milt/reference/milt_causal_impact.md),
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md),
[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

## Examples

``` r
# \donttest{
s  <- milt_series(AirPassengers)
cp <- milt_changepoints(s, method = "pelt", stat = "mean")
plot(cp)

# }
```
