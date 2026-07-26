# Compute multiple forecast accuracy metrics at once

Returns a tidy tibble of metric names and values. When
`metrics = "auto"`, selects point metrics only (probabilistic metrics
require additional arguments supplied via `...`).

## Usage

``` r
milt_accuracy(
  actual,
  predicted,
  training = NULL,
  season = 1L,
  metrics = "auto"
)
```

## Arguments

- actual:

  Numeric vector of observed values. Also accepts a `MiltSeries` object,
  in which case values are extracted automatically.

- predicted:

  Numeric vector of point forecast values.

- training:

  Numeric vector of training values (required for MASE and RMSSE).
  Optional for all other metrics.

- season:

  Seasonal period for MASE/RMSSE. Default `1`.

- metrics:

  Character vector of metric names to compute, or one of:

  - `"auto"` - all metrics computable from `actual` and `predicted`

  - `"all"` - same as `"auto"` (alias)

  - `"point"` - point metrics only (excludes MASE/RMSSE if training
    missing)

## Value

A tibble with columns `metric` (character) and `value` (numeric).

## See also

[`milt_mae()`](https://ntigideon.github.io/milt/reference/milt_mae.md),
[`milt_rmse()`](https://ntigideon.github.io/milt/reference/milt_rmse.md),
[`milt_mase()`](https://ntigideon.github.io/milt/reference/milt_mase.md)

Other metrics:
[`milt_coefficient_of_variation()`](https://ntigideon.github.io/milt/reference/milt_coefficient_of_variation.md),
[`milt_coverage()`](https://ntigideon.github.io/milt/reference/milt_coverage.md),
[`milt_crps()`](https://ntigideon.github.io/milt/reference/milt_crps.md),
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

## Examples

``` r
actual    <- c(100, 120, 130, 125, 140)
predicted <- c(105, 115, 135, 120, 145)
milt_accuracy(actual, predicted)
#> # A tibble: 9 × 2
#>   metric    value
#>   <chr>     <dbl>
#> 1 MAE     5      
#> 2 MSE    25      
#> 3 RMSE    5      
#> 4 MAPE    0.0412 
#> 5 R2      0.858  
#> 6 WMAPE   0.0407 
#> 7 OPE     0.00813
#> 8 CV      0.0407 
#> 9 MARRE   0.125  
```
