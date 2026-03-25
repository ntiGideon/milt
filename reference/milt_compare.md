# Compare multiple milt models via walk-forward backtesting

Runs
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
on each model and collects results into a ranked comparison table.

## Usage

``` r
milt_compare(
  models,
  series,
  horizon,
  initial_window = NULL,
  stride = 1L,
  method = c("expanding", "sliding"),
  metrics = c("MAE", "RMSE", "MAPE"),
  rank_metric = metrics[[1L]]
)
```

## Arguments

- models:

  A **named** list of unfitted `MiltModel` objects created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).
  Names become the model labels in the comparison table.

- series:

  A `MiltSeries` object.

- horizon:

  Positive integer. Forecast horizon for each fold.

- initial_window:

  Positive integer or `NULL`. Passed to
  [`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md).

- stride:

  Positive integer. Steps between consecutive folds. Default `1L`.

- method:

  `"expanding"` or `"sliding"`. Default `"expanding"`.

- metrics:

  Character vector of metric names. Default `c("MAE", "RMSE", "MAPE")`.

- rank_metric:

  Character scalar. Metric used to rank models in the summary. Must be
  one of `metrics`. Default `metrics[[1L]]`.

## Value

A `MiltComparison` object.

## See also

[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
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
s <- milt_series(AirPassengers)
cmp <- milt_compare(
  models = list(naive = milt_model("naive"), drift = milt_model("drift")),
  series = s, horizon = 12,
  initial_window = 120L, stride = 12L
)
#> Comparing 2 models: naive, drift
#> Running backtest for "naive"...
#> Running expanding backtest (2 folds): naive, h=12
#> Running backtest for "drift"...
#> Running expanding backtest (2 folds): drift, h=12
print(cmp)
#> 
#> ── MiltComparison - 2 models ──
#> 
#> • Rank metric : MAE
#> • Models : naive, drift
#> 
#> 
#> ── Ranked by MAE (mean across folds) 
#> # A tibble: 2 × 5
#>   model   MAE  RMSE  MAPE  rank
#>   <chr> <dbl> <dbl> <dbl> <int>
#> 1 drift  72.7  97.6 0.145     1
#> 2 naive  83.7 108.  0.169     2
# }
```
