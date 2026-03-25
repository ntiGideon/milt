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
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)
