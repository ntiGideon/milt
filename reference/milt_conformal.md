# Wrap a milt model with conformal prediction intervals

Calibrates model-agnostic prediction intervals using split-conformal
prediction. The model is refit on a series of walk-forward calibration
folds (same fold structure as
[`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md));
the resulting per-horizon-step absolute forecast errors give empirical
quantiles that are applied as a `point ± margin` interval around the
final forecast — regardless of whether the underlying model natively
produces prediction intervals.

## Usage

``` r
milt_conformal(
  model,
  series,
  horizon,
  level = c(80, 95),
  initial_window = NULL,
  stride = 1L,
  method = c("expanding", "sliding"),
  window = NULL
)
```

## Arguments

- model:

  An unfitted `MiltModel` (created with
  [`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md)).
  It is cloned and refit from scratch on each calibration fold, then
  refit once more on the full `series` for the final forecast; the
  original object passed in is not modified.

- series:

  A `MiltSeries` used both for calibration folds and as the training
  data for the final forecast.

- horizon:

  Positive integer. Forecast horizon.

- level:

  Numeric vector of confidence levels, e.g. `c(80, 95)`.

- initial_window:

  Positive integer. Size of the first calibration training window.
  Defaults to `max(floor(n * 0.5), horizon + 1L)`.

- stride:

  Positive integer. Steps between calibration folds. Default `1L`.

- method:

  Character scalar: `"expanding"` or `"sliding"` calibration window,
  same semantics as
  [`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md).

- window:

  Positive integer. Only used when `method = "sliding"`.

## Value

A `MiltForecast` object whose prediction intervals are
conformal-calibrated rather than model-native. The point forecast is
unchanged from the underlying model.

## See also

[`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md)

Other model:
[`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntigideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntigideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntigideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md),
[`milt_global_model()`](https://ntigideon.github.io/milt/reference/milt_global_model.md),
[`milt_grid_search()`](https://ntigideon.github.io/milt/reference/milt_grid_search.md),
[`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md),
[`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntigideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
s   <- milt_series(AirPassengers)
fct <- milt_conformal(milt_model("naive"), s, horizon = 12)
#> Calibrating conformal intervals (61 folds): naive, h=12
plot(fct)

# }
```
