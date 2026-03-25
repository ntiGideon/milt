# Fit a milt model to a MiltSeries

Calls the model's internal `fit()` method and records the elapsed time.
Returns the fitted model invisibly for pipe compatibility.

## Usage

``` r
milt_fit(model, series, ...)
```

## Arguments

- model:

  An unfitted `MiltModel` created by
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).

- series:

  A `MiltSeries` object.

- ...:

  Additional arguments forwarded to the backend's `fit()` method.

## Value

The fitted `MiltModel`, invisibly.

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
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
m <- milt_model("naive") |> milt_fit(s)
#> Fitting <MiltNaive> model…
#> Done in 0s.
# }
```
