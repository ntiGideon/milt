# Residuals from a fitted milt model

Returns the vector of training residuals (actual minus fitted) from a
fitted model. Useful for residual diagnostics and assumption checking.

## Usage

``` r
milt_residuals(model, ...)

milt_residuals(model, ...)
```

## Arguments

- model:

  A fitted `MiltModel`.

- ...:

  Additional arguments forwarded to the backend's
  [`residuals()`](https://rdrr.io/r/stats/residuals.html) method.

## Value

A numeric vector of residuals (actual minus fitted).

A numeric vector of residuals with the same length as the training
series.

## See also

[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md)

## Examples

``` r
# \donttest{
s   <- milt_series(AirPassengers)
m   <- milt_model("naive") |> milt_fit(s)
#> Fitting <MiltNaive> model…
#> Done in 0s.
res <- milt_residuals(m)
mean(res, na.rm = TRUE)  # close to 0 for well-specified models
#> [1] 2.237762
# }
```
