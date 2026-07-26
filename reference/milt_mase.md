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
[`milt_accuracy()`](https://ntigideon.github.io/milt/reference/milt_accuracy.md),
[`milt_coefficient_of_variation()`](https://ntigideon.github.io/milt/reference/milt_coefficient_of_variation.md),
[`milt_coverage()`](https://ntigideon.github.io/milt/reference/milt_coverage.md),
[`milt_crps()`](https://ntigideon.github.io/milt/reference/milt_crps.md),
[`milt_mae()`](https://ntigideon.github.io/milt/reference/milt_mae.md),
[`milt_mape()`](https://ntigideon.github.io/milt/reference/milt_mape.md),
[`milt_marre()`](https://ntigideon.github.io/milt/reference/milt_marre.md),
[`milt_mrae()`](https://ntigideon.github.io/milt/reference/milt_mrae.md),
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
