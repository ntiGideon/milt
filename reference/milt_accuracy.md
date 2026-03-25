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

[`milt_mae()`](https://ntiGideon.github.io/milt/reference/milt_mae.md),
[`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
[`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md)

Other metrics:
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
[`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
[`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
[`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md)

## Examples

``` r
actual    <- c(100, 120, 130, 125, 140)
predicted <- c(105, 115, 135, 120, 145)
milt_accuracy(actual, predicted)
#> # A tibble: 5 × 2
#>   metric   value
#>   <chr>    <dbl>
#> 1 MAE     5     
#> 2 MSE    25     
#> 3 RMSE    5     
#> 4 MAPE    0.0412
#> 5 R2      0.858 
```
