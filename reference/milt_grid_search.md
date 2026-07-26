# Grid search over a model's hyperparameters via backtesting

Backtests every combination of `param_grid` (via
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md))
and ranks them by a chosen metric. Works with any registered backend,
not just the Theta method — e.g. sweep `theta` over `season_mode`, or
`xgboost` over `nrounds`/`max_depth`.

## Usage

``` r
milt_grid_search(model_name, param_grid, series, horizon, metric = "MAE", ...)
```

## Arguments

- model_name:

  Character. Registered backend name (see
  [`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md)).

- param_grid:

  Named list of parameter value vectors. Every combination (the full
  Cartesian product) is tried.

- series:

  A `MiltSeries` used for backtesting.

- horizon:

  Positive integer forecast horizon, forwarded to
  [`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md).

- metric:

  Character scalar. Metric to rank by (must be one of `"MAE"`, `"RMSE"`,
  `"MSE"`, `"MAPE"`, `"SMAPE"`). Default `"MAE"`.

- ...:

  Additional arguments forwarded to
  [`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
  (e.g. `initial_window`, `stride`, `method`).

## Value

A tibble with one row per combination, its mean backtest `metric` value,
and rows ordered best-first (`NA` for combinations that errored).

## See also

[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_conformal()`](https://ntiGideon.github.io/milt/reference/milt_conformal.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_global_model()`](https://ntiGideon.github.io/milt/reference/milt_global_model.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
milt_grid_search(
  "theta",
  param_grid = list(theta = c(1, 2, 3)),
  series = s, horizon = 12,
  initial_window = 120L, stride = 12L
)
#> Grid search over 3 combinations of "theta"
#> Running expanding backtest (2 folds): theta, h=12
#> Running expanding backtest (2 folds): theta, h=12
#> Running expanding backtest (2 folds): theta, h=12
#> # A tibble: 3 × 2
#>   theta   MAE
#>   <dbl> <dbl>
#> 1     1  36.5
#> 2     2  36.5
#> 3     3  36.5
# }
```
