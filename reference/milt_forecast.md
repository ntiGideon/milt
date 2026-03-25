# Generate forecasts from a fitted milt model

Generate forecasts from a fitted milt model

## Usage

``` r
milt_forecast(
  model,
  horizon,
  level = c(80, 95),
  num_samples = NULL,
  future_covariates = NULL,
  ...
)
```

## Arguments

- model:

  A fitted `MiltModel`.

- horizon:

  Positive integer. Number of steps ahead to forecast.

- level:

  Numeric vector of confidence levels for prediction intervals. Default
  `c(80, 95)`.

- num_samples:

  Integer or `NULL`. Number of sample paths to draw for probabilistic
  forecasts. `NULL` returns point forecasts only.

- future_covariates:

  A `MiltSeries` of future-known covariates, or `NULL`.

- ...:

  Additional arguments forwarded to the backend's `forecast()` method.

## Value

A `MiltForecast` object.

## See also

[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
s   <- milt_series(AirPassengers)
fct <- milt_model("naive") |> milt_fit(s) |> milt_forecast(horizon = 12)
#> Fitting <MiltNaive> model…
#> Done in 0s.
# }
```
