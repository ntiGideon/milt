# Refit a milt model on new data without re-tuning

Uses the model's existing hyperparameters but trains on a new series.
Useful for rolling updates in production.

## Usage

``` r
milt_refit(model, series, ...)
```

## Arguments

- model:

  A previously fitted `MiltModel`.

- series:

  A `MiltSeries` containing the new training data.

- ...:

  Additional arguments forwarded to `fit()`.

## Value

The refitted `MiltModel`, invisibly.

## See also

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
[`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md),
[`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)
