# Coefficient of Variation of the RMSE

Expresses
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md)
as a fraction of the mean of `actual`, making error magnitude comparable
across series with different scales.

## Usage

``` r
milt_coefficient_of_variation(actual, predicted)
```

## Arguments

- actual:

  Numeric vector of observed values.

- predicted:

  Numeric vector of predicted values.

## Value

A single numeric value (fraction, e.g. `0.05` = 5 %).

## See also

Other metrics:
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md),
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
[`milt_rmsle()`](https://ntiGideon.github.io/milt/reference/milt_rmsle.md),
[`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md),
[`milt_wmape()`](https://ntiGideon.github.io/milt/reference/milt_wmape.md)
