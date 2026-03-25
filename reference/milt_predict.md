# In-sample predictions from a fitted milt model

Returns fitted values for the training series, or applies the fitted
model to a new `MiltSeries` for one-step-ahead predictions.

## Usage

``` r
milt_predict(model, series = NULL, ...)

milt_predict(model, series = NULL, ...)
```

## Arguments

- model:

  A fitted `MiltModel` created by
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)
  and trained with
  [`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md).

- series:

  Optional `MiltSeries`. When `NULL` (default), returns the in-sample
  fitted values for the original training data. When supplied, the model
  is applied to this series instead.

- ...:

  Additional arguments forwarded to the backend's
  [`predict()`](https://rdrr.io/r/stats/predict.html) method.

## Value

A numeric vector of fitted/predicted values.

A numeric vector of fitted/predicted values with the same length as the
target series.

## See also

[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
m <- milt_model("naive") |> milt_fit(s)
#> Fitting <MiltNaive> model…
#> Done in 0s.
fitted_vals <- milt_predict(m)
length(fitted_vals) == length(s)  # TRUE
#> [1] TRUE
# }
```
