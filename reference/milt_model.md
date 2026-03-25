# Initialise a milt model

Looks up the requested model in the registry and returns an unfitted
model object ready to be passed to
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md).

## Usage

``` r
milt_model(name, ...)
```

## Arguments

- name:

  Character scalar. The model identifier (e.g. `"auto_arima"`,
  `"naive"`, `"xgboost"`). Use
  [`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md)
  to see all options.

- ...:

  Hyperparameters forwarded to the model's constructor.

## Value

An unfitted `MiltModel` object.

## See also

[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
m <- milt_model("naive")
# }
```
