# Initialise a milt model

Looks up the requested model in the registry and returns an unfitted
model object ready to be passed to
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md).

## Usage

``` r
milt_model(name, ...)
```

## Arguments

- name:

  Character scalar. The model identifier (e.g. `"auto_arima"`,
  `"naive"`, `"xgboost"`). Use
  [`list_milt_models()`](https://ntigideon.github.io/milt/reference/list_milt_models.md)
  to see all options.

- ...:

  Hyperparameters forwarded to the model's constructor.

## Value

An unfitted `MiltModel` object.

## See also

[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md),
[`list_milt_models()`](https://ntigideon.github.io/milt/reference/list_milt_models.md)

Other model:
[`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntigideon.github.io/milt/reference/milt_compare.md),
[`milt_conformal()`](https://ntigideon.github.io/milt/reference/milt_conformal.md),
[`milt_cv()`](https://ntigideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntigideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md),
[`milt_global_model()`](https://ntigideon.github.io/milt/reference/milt_global_model.md),
[`milt_grid_search()`](https://ntigideon.github.io/milt/reference/milt_grid_search.md),
[`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md),
[`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntigideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
m <- milt_model("naive")
# }
```
