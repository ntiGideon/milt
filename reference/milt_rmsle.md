# Root Mean Squared Log Error

Penalises relative (rather than absolute) errors by comparing values on
the log scale. Requires `actual > -1` and `predicted > -1`.

## Usage

``` r
milt_rmsle(actual, predicted)
```

## Arguments

- actual:

  Numeric vector of observed values.

- predicted:

  Numeric vector of predicted values.

## Value

A single numeric value.

## See also

Other metrics:
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md),
[`milt_coefficient_of_variation()`](https://ntiGideon.github.io/milt/reference/milt_coefficient_of_variation.md),
[`milt_coverage()`](https://ntiGideon.github.io/milt/reference/milt_coverage.md),
[`milt_crps()`](https://ntiGideon.github.io/milt/reference/milt_crps.md),
[`milt_mae()`](https://ntiGideon.github.io/milt/reference/milt_mae.md),
[`milt_mape()`](https://ntiGideon.github.io/milt/reference/milt_mape.md),
[`milt_marre()`](https://ntiGideon.github.io/milt/reference/milt_marre.md),
[`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md),
[`milt_mrae()`](https://ntiGideon.github.io/milt/reference/milt_mrae.md),
[`milt_mse()`](https://ntiGideon.github.io/milt/reference/milt_mse.md),
[`milt_ope()`](https://ntiGideon.github.io/milt/reference/milt_ope.md),
[`milt_pinball()`](https://ntiGideon.github.io/milt/reference/milt_pinball.md),
[`milt_r_squared()`](https://ntiGideon.github.io/milt/reference/milt_r_squared.md),
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
[`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md),
[`milt_wmape()`](https://ntiGideon.github.io/milt/reference/milt_wmape.md)
