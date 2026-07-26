# Mean Relative Absolute Error

Measures performance relative to a benchmark forecast.

## Usage

``` r
milt_mrae(actual, predicted, benchmark)
```

## Arguments

- actual:

  Numeric vector of observed values.

- predicted:

  Numeric vector of predicted values.

- benchmark:

  Numeric vector of benchmark forecast values (same length as `actual`).

## Value

A single numeric value. Values \< 1 mean the model outperforms the
benchmark.

## See also

Other metrics:
[`milt_accuracy()`](https://ntigideon.github.io/milt/reference/milt_accuracy.md),
[`milt_coefficient_of_variation()`](https://ntigideon.github.io/milt/reference/milt_coefficient_of_variation.md),
[`milt_coverage()`](https://ntigideon.github.io/milt/reference/milt_coverage.md),
[`milt_crps()`](https://ntigideon.github.io/milt/reference/milt_crps.md),
[`milt_mae()`](https://ntigideon.github.io/milt/reference/milt_mae.md),
[`milt_mape()`](https://ntigideon.github.io/milt/reference/milt_mape.md),
[`milt_marre()`](https://ntigideon.github.io/milt/reference/milt_marre.md),
[`milt_mase()`](https://ntigideon.github.io/milt/reference/milt_mase.md),
[`milt_mse()`](https://ntigideon.github.io/milt/reference/milt_mse.md),
[`milt_ope()`](https://ntigideon.github.io/milt/reference/milt_ope.md),
[`milt_pinball()`](https://ntigideon.github.io/milt/reference/milt_pinball.md),
[`milt_r_squared()`](https://ntigideon.github.io/milt/reference/milt_r_squared.md),
[`milt_rmse()`](https://ntigideon.github.io/milt/reference/milt_rmse.md),
[`milt_rmsle()`](https://ntigideon.github.io/milt/reference/milt_rmsle.md),
[`milt_rmsse()`](https://ntigideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntigideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntigideon.github.io/milt/reference/milt_winkler.md),
[`milt_wmape()`](https://ntigideon.github.io/milt/reference/milt_wmape.md)
