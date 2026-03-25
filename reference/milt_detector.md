# Create an anomaly detector

Returns an unfitted detector object. Pass it to
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)
along with a `MiltSeries` to run detection.

## Usage

``` r
milt_detector(name, ...)
```

## Arguments

- name:

  Character. Detector name: `"stl"`, `"iqr"`, `"gesd"`, `"grubbs"`,
  `"iforest"`, `"lof"`, `"autoencoder"`, or `"ensemble"`.

- ...:

  Hyperparameters forwarded to the detector constructor.

## Value

A `MiltDetector` object.

## See also

[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)

Other anomaly:
[`milt_causal_impact()`](https://ntiGideon.github.io/milt/reference/milt_causal_impact.md),
[`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md),
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)

## Examples

``` r
d <- milt_detector("iqr", k = 1.5)
```
