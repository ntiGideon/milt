# Walk-forward backtesting of a milt model

Performs time series cross-validation using either an **expanding** or a
**sliding** window strategy, computing forecast accuracy metrics for
each fold.

## Usage

``` r
milt_backtest(
  model,
  series,
  horizon,
  initial_window = NULL,
  stride = 1L,
  method = c("expanding", "sliding"),
  window = NULL,
  metrics = c("MAE", "RMSE", "MAPE")
)
```

## Arguments

- model:

  An unfitted `MiltModel` (created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)).
  The model is cloned and re-fitted from scratch on each fold's training
  window; the original object is not modified.

- series:

  A `MiltSeries` object containing the full time series.

- horizon:

  Positive integer. Forecast horizon for each fold.

- initial_window:

  Positive integer. Size of the first training window. Defaults to
  `max(floor(n * 0.5), horizon + 1L)`.

- stride:

  Positive integer. Number of steps to advance the training cutoff
  between consecutive folds. Default `1L`.

- method:

  Character scalar: `"expanding"` (training window grows each fold) or
  `"sliding"` (training window is of fixed size, specified by `window`).
  Default `"expanding"`.

- window:

  Positive integer. Only used when `method = "sliding"`. Size of the
  sliding training window. Defaults to `initial_window`.

- metrics:

  Character vector of metric names to compute. Supported: `"MAE"`,
  `"RMSE"`, `"MSE"`, `"MAPE"`, `"SMAPE"`. Default
  `c("MAE", "RMSE", "MAPE")`.

## Value

A `MiltBacktest` object.

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md)

Other model:
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
s  <- milt_series(AirPassengers)
bt <- milt_backtest(milt_model("naive"), s, horizon = 12)
#> Running expanding backtest (61 folds): naive, h=12
print(bt)
#> 
#> ── MiltBacktest <naive> ──
#> 
#> • Method : expanding
#> • Horizon : 12
#> • Folds : 61
#> 
#> 
#> ── Summary (across folds) 
#> # A tibble: 3 × 5
#>   metric   mean      sd     min     max
#>   <chr>   <dbl>   <dbl>   <dbl>   <dbl>
#> 1 MAE    63.8   22.1    31.2    114    
#> 2 RMSE   78.6   23.8    39.2    135.   
#> 3 MAPE    0.163  0.0547  0.0897   0.303
tibble::as_tibble(bt)
#> # A tibble: 61 × 6
#>    .fold .train_n .test_n  .MAE .RMSE .MAPE
#>    <int>    <int>   <int> <dbl> <dbl> <dbl>
#>  1     1       72      12  55    68.2 0.178
#>  2     2       73      12  47.8  59.5 0.154
#>  3     3       74      12  58.2  67.8 0.189
#>  4     4       75      12  33.3  44.8 0.105
#>  5     5       76      12  35.3  45.4 0.111
#>  6     6       77      12  38.5  46.8 0.121
#>  7     7       78      12  31.2  39.2 0.106
#>  8     8       79      12  61.8  69.5 0.216
#>  9     9       80      12  55.3  60.3 0.186
#> 10    10       81      12  43.4  53.9 0.133
#> # ℹ 51 more rows
# }
```
