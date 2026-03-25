# Create an ensemble milt model

Combines multiple models into a single `MiltModel` that aggregates their
forecasts. The ensemble is fitted with
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)
and forecasted with
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)
just like any other model.

## Usage

``` r
milt_ensemble(models, method = c("mean", "median", "weighted"), weights = NULL)
```

## Arguments

- models:

  A **named** list of unfitted `MiltModel` objects created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).
  Each model is independently fitted on the same training series inside
  [`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md).

- method:

  Aggregation method for combining member point forecasts:

  - `"mean"` (default) — simple average.

  - `"median"` — element-wise median (more robust to outliers).

  - `"weighted"` — weighted average; supply weights via `weights`.

- weights:

  Numeric vector of the same length as `models`, used when
  `method = "weighted"`. Values need not sum to 1 (they are normalised
  internally). `NULL` uses equal weights.

## Value

An unfitted `MiltModel` of class `"MiltEnsemble"`.

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
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
ens <- milt_ensemble(
  models = list(naive = milt_model("naive"), drift = milt_model("drift")),
  method = "mean"
) |>
  milt_fit(s) |>
  milt_forecast(12)
#> Fitting <MiltEnsemble> model…
#> Fitting ensemble member "naive"…
#> Fitting ensemble member "drift"…
#> Done in 0.02s.
print(ens)
#> # A MiltForecast <ensemble_mean>: horizon = 12# Forecast from: 1960-12-01# Intervals    : 80, 95%#
#> # A tibble: 6 × 7
#>   time       .model        .mean .lower_80 .upper_80 .lower_95 .upper_95
#>   <date>     <chr>         <dbl>     <dbl>     <dbl>     <dbl>     <dbl>
#> 1 1961-01-01 ensemble_mean  433.      431.      435.      430.      436.
#> 2 1961-02-01 ensemble_mean  434.      430.      438.      428.      440.
#> 3 1961-03-01 ensemble_mean  435.      429.      441.      426.      445.
#> 4 1961-04-01 ensemble_mean  436.      428.      445.      424.      449.
#> 5 1961-05-01 ensemble_mean  438.      427.      448.      422.      453.
#> 6 1961-06-01 ensemble_mean  439.      427.      451.      420.      457.
#> # … with 6 more rows
# }
```
