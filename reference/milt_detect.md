# Detect anomalies in a time series

Runs the detector's algorithm on `series` and returns a `MiltAnomalies`
object containing binary labels and continuous anomaly scores.

## Usage

``` r
milt_detect(detector, series, ...)
```

## Arguments

- detector:

  A `MiltDetector` created by
  [`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md).

- series:

  A `MiltSeries` object (univariate).

- ...:

  Additional arguments forwarded to the detector's `detect()` method.

## Value

A `MiltAnomalies` object.

## See also

[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

Other anomaly:
[`milt_causal_impact()`](https://ntiGideon.github.io/milt/reference/milt_causal_impact.md),
[`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md),
[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

## Examples

``` r
s <- milt_series(AirPassengers)
d <- milt_detector("iqr", k = 1.5)
a <- milt_detect(d, s)
```
