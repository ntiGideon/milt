# Continuous Ranked Probability Score (CRPS)

Computes the empirical CRPS from a matrix of forecast samples using the
energy-score formulation: `CRPS = E|X - y| - 0.5 * E|X - X'|`

## Usage

``` r
milt_crps(actual, forecast_dist)
```

## Arguments

- actual:

  Numeric vector of observed values (length `n`).

- forecast_dist:

  Numeric matrix of forecast samples with `n` rows and `S` columns (one
  column per sample path).

## Value

Mean CRPS across all time steps (lower is better).

## See also

Other metrics:
[`milt_accuracy()`](https://ntigideon.github.io/milt/reference/milt_accuracy.md),
[`milt_coefficient_of_variation()`](https://ntigideon.github.io/milt/reference/milt_coefficient_of_variation.md),
[`milt_coverage()`](https://ntigideon.github.io/milt/reference/milt_coverage.md),
[`milt_mae()`](https://ntigideon.github.io/milt/reference/milt_mae.md),
[`milt_mape()`](https://ntigideon.github.io/milt/reference/milt_mape.md),
[`milt_marre()`](https://ntigideon.github.io/milt/reference/milt_marre.md),
[`milt_mase()`](https://ntigideon.github.io/milt/reference/milt_mase.md),
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
