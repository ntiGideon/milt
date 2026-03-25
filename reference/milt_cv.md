# Time series cross-validation

A convenience wrapper around
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
that automatically computes a stride so that exactly `folds` evaluation
folds are produced. The training window expands fold by fold (expanding
window) — no future data is ever used in training.

## Usage

``` r
milt_cv(
  model,
  series,
  folds = 5L,
  horizon = 1L,
  initial_window = NULL,
  metrics = c("MAE", "RMSE", "MAPE")
)
```

## Arguments

- model:

  An unfitted `MiltModel` created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).

- series:

  A `MiltSeries` object.

- folds:

  Positive integer. Number of evaluation folds. Default `5L`.

- horizon:

  Positive integer. Forecast horizon per fold. Default `1L`.

- initial_window:

  Positive integer or `NULL`. Size of the first training window.
  Defaults to `floor(n * (folds / (folds + 1)))`.

- metrics:

  Character vector of metric names. Supported: `"MAE"`, `"RMSE"`,
  `"MSE"`, `"MAPE"`, `"SMAPE"`. Default `c("MAE", "RMSE", "MAPE")`.

## Value

A `MiltBacktest` object (same as
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)).

## Details

The stride is computed so that fold cut-points are approximately evenly
spaced across the remaining data:  
`stride = max(1, floor((n - horizon - initial_window) / (folds - 1)))`

When `folds = 1`, the stride is irrelevant and a single evaluation
window is used (from `initial_window` to `n - horizon`).

## See also

[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
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
cv <- milt_cv(milt_model("naive"), s, folds = 5L, horizon = 12L)
#> Running expanding backtest (5 folds): naive, h=12
print(cv)
#> 
#> ── MiltBacktest <naive> ──
#> 
#> • Method : expanding
#> • Horizon : 12
#> • Folds : 5
#> 
#> 
#> ── Summary (across folds) 
#> # A tibble: 3 × 5
#>   metric   mean      sd     min     max
#>   <chr>   <dbl>   <dbl>   <dbl>   <dbl>
#> 1 MAE    67.0   18.2    43.9     91.3  
#> 2 RMSE   85.9   21.5    65.0    113.   
#> 3 MAPE    0.140  0.0378  0.0897   0.195
# }
```
