# Mean Absolute Scaled Error

Scales the MAE by the in-sample naive seasonal forecast error (Hyndman &
Koehler 2006). Values \< 1 indicate better-than-naive performance.

## Usage

``` r
milt_mase(actual, predicted, training, season = 1L)
```

## Arguments

- actual:

  Numeric vector of observed values.

- predicted:

  Numeric vector of predicted values.

- training:

  Numeric vector of in-sample (training) values used to compute the
  scaling denominator.

- season:

  Seasonal period. Use `1` for non-seasonal scaling (random walk naive
  benchmark).

## Value

A single numeric value.

## See also

Other metrics:
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md),
[`milt_coverage()`](https://ntiGideon.github.io/milt/reference/milt_coverage.md),
[`milt_crps()`](https://ntiGideon.github.io/milt/reference/milt_crps.md),
[`milt_mae()`](https://ntiGideon.github.io/milt/reference/milt_mae.md),
[`milt_mape()`](https://ntiGideon.github.io/milt/reference/milt_mape.md),
[`milt_mrae()`](https://ntiGideon.github.io/milt/reference/milt_mrae.md),
[`milt_mse()`](https://ntiGideon.github.io/milt/reference/milt_mse.md),
[`milt_pinball()`](https://ntiGideon.github.io/milt/reference/milt_pinball.md),
[`milt_r_squared()`](https://ntiGideon.github.io/milt/reference/milt_r_squared.md),
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
[`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md)
