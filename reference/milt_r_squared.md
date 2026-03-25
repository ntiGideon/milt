# Coefficient of Determination (R^2)

Coefficient of Determination (R^2)

## Usage

``` r
milt_r_squared(actual, predicted)
```

## Arguments

- actual:

  Numeric vector of observed values.

- predicted:

  Numeric vector of predicted values.

## Value

A numeric value, typically in `(-Inf, 1]`. A value of 1 is perfect; 0
means the model is no better than predicting the mean; negative values
indicate the model is worse than the mean.

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
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
[`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md)
