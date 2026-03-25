# Root Mean Squared Scaled Error

The RMSE analogue of
[`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md).

## Usage

``` r
milt_rmsse(actual, predicted, training, season = 1L)
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
[`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md),
[`milt_mrae()`](https://ntiGideon.github.io/milt/reference/milt_mrae.md),
[`milt_mse()`](https://ntiGideon.github.io/milt/reference/milt_mse.md),
[`milt_pinball()`](https://ntiGideon.github.io/milt/reference/milt_pinball.md),
[`milt_r_squared()`](https://ntiGideon.github.io/milt/reference/milt_r_squared.md),
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md)
