# Wrap a model with residual-based anomaly detection

Fits `model` on a series, scores its in-sample residuals with
[`milt_anomaly_score()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_score.md),
and fits a threshold from that score distribution — "flag the points
where my own model's prediction was most wrong." Mirrors darts'
`ForecastingAnomalyModel`.

## Usage

``` r
milt_anomaly_model(
  model,
  scorer = c("norm", "difference", "nll_gaussian"),
  detector = c("quantile", "threshold"),
  quantile = 0.95,
  low = NULL,
  high = NULL,
  ...
)
```

## Arguments

- model:

  An unfitted `MiltModel` (created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)).
  Cloned internally; the object passed in is not modified.

- scorer:

  Character. Passed to
  [`milt_anomaly_score()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_score.md):
  `"norm"` (default), `"difference"`, or `"nll_gaussian"`.

- detector:

  Character. `"quantile"` (default): threshold at the `quantile`
  quantile of in-sample scores. `"threshold"`: use explicit `low`/`high`
  bounds.

- quantile:

  Numeric in `(0, 1)`. Used when `detector = "quantile"`. Default
  `0.95`.

- low, high:

  Numeric bounds used when `detector = "threshold"`.

- ...:

  Additional arguments forwarded to `model$fit()`.

## Value

An unfitted `MiltModel`. Fit it with
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
then call
[`milt_detect_anomalies()`](https://ntiGideon.github.io/milt/reference/milt_detect_anomalies.md)
to get a `MiltAnomalies` result.

## See also

[`milt_detect_anomalies()`](https://ntiGideon.github.io/milt/reference/milt_detect_anomalies.md),
[`milt_anomaly_score()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_score.md),
[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

Other anomaly:
[`milt_anomaly_score()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_score.md),
[`milt_causal_impact()`](https://ntiGideon.github.io/milt/reference/milt_causal_impact.md),
[`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md),
[`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md),
[`milt_detect_anomalies()`](https://ntiGideon.github.io/milt/reference/milt_detect_anomalies.md),
[`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md)

## Examples

``` r
# \donttest{
s  <- milt_series(AirPassengers)
am <- milt_anomaly_model(milt_model("naive"), scorer = "norm") |> milt_fit(s)
#> Fitting <MiltAnomalyModel> model…
#> Done in 0s.
anoms <- milt_detect_anomalies(am)
plot(anoms)

# }
```
