# Compute a per-timestep anomaly score from residuals

Turns a vector of forecast residuals (actual minus fitted/predicted)
into a continuous anomaly score, where a larger value means "more
anomalous".

## Usage

``` r
milt_anomaly_score(residuals, method = c("norm", "difference", "nll_gaussian"))
```

## Arguments

- residuals:

  Numeric vector of residuals (e.g. from
  [`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)).

- method:

  Character. One of:

  - `"norm"` (default): absolute residual, `abs(residuals)`.

  - `"difference"`: the signed residual itself (useful for
    [`milt_check_seasonality()`](https://ntigideon.github.io/milt/reference/milt_check_seasonality.md)-style
    directional analysis).

  - `"nll_gaussian"`: negative log-likelihood of each residual under a
    Gaussian fit to the whole residual distribution — penalises
    residuals that are unlikely even relative to the model's own typical
    error.

## Value

A numeric vector the same length as `residuals` (with `NA` preserved
where `residuals` is `NA`).

## See also

[`milt_anomaly_model()`](https://ntigideon.github.io/milt/reference/milt_anomaly_model.md)

Other anomaly:
[`milt_anomaly_model()`](https://ntigideon.github.io/milt/reference/milt_anomaly_model.md),
[`milt_causal_impact()`](https://ntigideon.github.io/milt/reference/milt_causal_impact.md),
[`milt_changepoints()`](https://ntigideon.github.io/milt/reference/milt_changepoints.md),
[`milt_detect()`](https://ntigideon.github.io/milt/reference/milt_detect.md),
[`milt_detect_anomalies()`](https://ntigideon.github.io/milt/reference/milt_detect_anomalies.md),
[`milt_detector()`](https://ntigideon.github.io/milt/reference/milt_detector.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
m   <- milt_model("naive") |> milt_fit(s)
#> Fitting <MiltNaive> model…
#> Done in 0s.
milt_anomaly_score(milt_residuals(m), method = "norm")
#>   [1]  NA   6  14   3   8  14  13   0  12  17  15  14   3  11  15   6  10  24
#>  [19]  21   0  12  25  19  26   5   5  28  15   9   6  21   0  15  22  16  20
#>  [37]   5   9  13  12   2  35  12  12  33  18  19  22   2   0  40   1   6  14
#>  [55]  21   8  35  26  31  21   3  16  47   8   7  30  38   9  34  30  26  26
#>  [73]  13   9  34   2   1  45  49  17  35  38  37  41   6   7  40   4   5  56
#>  [91]  39   8  50  49  35  35   9  14  55   8   7  67  43   2  63  57  42  31
#> [109]   4  22  44  14  15  72  56  14 101  45  49  27  23  18  64  10  24  52
#> [127]  76  11  96  56  45  43  12  26  28  42  11  63  87  16  98  47  71  42
```
