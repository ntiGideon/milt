# Fit one shared model across every group of a multi-series MiltSeries

The "global" counterpart to
[`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md):
instead of training one independent model per group, every group's
lag-feature rows are pooled into a single training matrix (tagged with a
one-hot group indicator, plus any static covariates attached via
[`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md)
as constant-per-group columns) and **one** shared model is fit across
all of them — genuine cross-series weight sharing, the way darts' global
forecasting models work.

## Usage

``` r
milt_global_model(
  method = c("knn", "xgboost"),
  lags = 1:12,
  k = 5L,
  weights = "uniform",
  nrounds = 100L,
  max_depth = 6L,
  eta = 0.1,
  ...
)
```

## Arguments

- method:

  Character. `"knn"` (pure R, no dependency) or `"xgboost"`.

- lags:

  Integer vector of lag indices used as features. Default `1:12`.

- k, weights:

  Hyperparameters for `method = "knn"`.

- nrounds, max_depth, eta:

  Hyperparameters for `method = "xgboost"`.

- ...:

  Additional hyperparameters.

## Value

An unfitted `MiltModel`. Fit it with
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md)
on a grouped `MiltSeries`; forecast a single group with `$forecast()` or
every group at once with `$forecast_all()`.

## See also

[`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md),
[`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md)

Other model:
[`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntigideon.github.io/milt/reference/milt_compare.md),
[`milt_conformal()`](https://ntigideon.github.io/milt/reference/milt_conformal.md),
[`milt_cv()`](https://ntigideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntigideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md),
[`milt_grid_search()`](https://ntigideon.github.io/milt/reference/milt_grid_search.md),
[`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntigideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
tbl <- data.frame(
  date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 36), 3),
  value = c(cumsum(rnorm(36, 1)), cumsum(rnorm(36, 2)), cumsum(rnorm(36, 0.5))),
  store = rep(c("A", "B", "C"), each = 36)
)
s <- milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")

gm <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(s)
#> Fitting <MiltGlobalModel> model…
#> Done in 0.01s.
forecasts <- gm$forecast_all(horizon = 6)
forecasts[["A"]]
#> # A MiltForecast <global_knn [A]>: horizon = 6# Forecast from: 2022-12-01# Intervals    : 80, 95%#
#> # A tibble: 6 × 7
#>   time       .model         .mean .lower_80 .upper_80 .lower_95 .upper_95
#>   <date>     <chr>          <dbl>     <dbl>     <dbl>     <dbl>     <dbl>
#> 1 2023-01-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
#> 2 2023-02-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
#> 3 2023-03-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
#> 4 2023-04-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
#> 5 2023-05-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
#> 6 2023-06-01 global_knn [A]  33.8      32.9      34.6      32.4      35.1
# }
```
