# milt - Modern Integrated Library for Timeseries

<!-- badges: start -->
[![R-CMD-check](https://github.com/ntiGideon/milt/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ntiGideon/milt/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

`milt` is a unified R framework for time series forecasting, anomaly detection,
classification, clustering, diagnostics, and deployment. It is designed to give
R users a single, consistent interface across classical statistical models,
machine learning backends, and deep-learning integrations.

The package follows one core idea: users should not need to learn a different
API for each model family. Whether you are fitting a naive baseline, an
Auto-ARIMA model, an XGBoost regressor, or an ensemble, the workflow stays
consistent.

Documentation site: <https://ntigideon.github.io/milt>

## What milt covers

`milt` is intended to cover the end-to-end time series workflow:

- series creation and conversion from `ts`, `tibble`, `data.frame`, `tsibble`, `xts`, `zoo`, and numeric vectors
- forecasting with classical, ML, and deep-learning backends
- train/test splitting, rolling-origin backtesting, and model comparison
- feature engineering with lag, rolling, Fourier, calendar, and scaling steps
- anomaly detection and changepoint analysis
- multi-series clustering, classification, and hierarchical reconciliation
- diagnostics, exploratory analysis, and model explainability
- saving, loading, dashboarding, and serving models

## Installation

```r
# install.packages("pak")
pak::pak("ntiGideon/milt")
```

milt keeps heavy backend dependencies optional so the core package installs
quickly and reliably. Use `milt_install_backends()` to install what you need:

```r
library(milt)

milt_install_backends()                        # everything
milt_install_backends("forecasting")           # forecast + prophet
milt_install_backends("ml")                    # xgboost, lightgbm, glmnet, ranger, e1071
milt_install_backends("deep_learning")         # torch  (then run torch::install_torch())
milt_install_backends("extras")                # anomaly, clustering, causal impact
milt_install_backends("reporting")             # rmarkdown, shiny, plumber
milt_install_backends("prophet")               # a single package by name
```

| Group | Packages |
|---|---|
| `"forecasting"` | forecast, prophet |
| `"ml"` | xgboost, lightgbm, glmnet, ranger, e1071 |
| `"deep_learning"` | torch |
| `"extras"` | isotree, dbscan, dtw, CausalImpact, changepoint |
| `"reporting"` | rmarkdown, shiny, plumber, jsonlite |

## Core workflow

The central workflow is:

```r
library(milt)

series <- milt_series(AirPassengers)

fct <- milt_model("auto_arima") |>
  milt_fit(series) |>
  milt_forecast(horizon = 12)

print(fct)
plot(fct)
```

The same shape is used throughout the package:

```r
milt_model("<name>") |> milt_fit(series) |> milt_forecast(horizon = 12)
```

## Main objects

The package is organized around a small set of core objects:

- `MiltSeries`: the canonical time series container
- `MiltModel`: a fitted or unfitted model object
- `MiltForecast`: forecast results with point forecasts and intervals
- `MiltBacktest`: rolling-origin validation results
- `MiltComparison`: ranked comparison across multiple models
- `MiltAnomalies`: anomaly detection output

This design keeps downstream workflows stable. The same plotting, printing, and
coercion patterns apply across most outputs.

## Quick start

```r
library(milt)

# 1. Create a series
air <- milt_series(AirPassengers)

# 2. Inspect and diagnose
print(air)
dx <- milt_diagnose(air)
print(dx)

# 3. Fit and forecast
fct <- milt_model("ets") |>
  milt_fit(air) |>
  milt_forecast(horizon = 24)

print(fct)
plot(fct)

# 4. Evaluate on a split
spl <- milt_split(air, ratio = 0.8)
fct_test <- milt_model("naive") |>
  milt_fit(spl$train) |>
  milt_forecast(spl$test$n_timesteps())

milt_accuracy(
  actual = spl$test$values(),
  predicted = fct_test$as_tibble()$.mean
)

# 5. Backtest a model
bt <- milt_backtest(
  model = milt_model("naive"),
  series = air,
  horizon = 12,
  initial_window = 108L,
  stride = 12L
)

print(bt)
plot(bt)
```

## Feature engineering and pipelines

`milt` supports both direct feature steps and composed pipelines.

Direct feature engineering:

```r
air_features <- air |>
  milt_step_lag(lags = 1:12) |>
  milt_step_rolling(windows = c(3L, 6L), fns = c("mean", "sd")) |>
  milt_step_fourier(period = 12, K = 2)
```

Pipeline workflow:

```r
pipe <- milt_pipeline() |>
  milt_pipe_step_lag(lags = 1:12) |>
  milt_pipe_step_rolling(windows = 3L, fns = "mean") |>
  milt_pipe_model("xgboost")
```

## Model families

The package includes or supports:

- baseline models such as `naive`, `snaive`, and `drift`
- classical statistical models such as `ets`, `auto_arima`, `theta`, `tbats`, and `stl`
- machine-learning backends such as `xgboost`, `lightgbm`, `ranger`, `glmnet`, `svm`, and KNN-based methods
- ensemble workflows
- deep-learning integrations through `torch` and `reticulate`-based backends

Use `list_milt_models()` to inspect the currently registered model set.

## Diagnostics, anomaly detection, and explainability

The package is not limited to forecasting. It also includes:

- `milt_diagnose()` for stationarity, trend, seasonality, gaps, and outlier summaries
- `milt_detector()` and `milt_detect()` for anomaly detection
- `milt_changepoints()` for changepoint analysis
- `milt_eda()` for exploratory analysis
- `milt_explain()` for model explainability and feature importance

## Multi-series workflows

For grouped or panel time series, `milt` supports:

- grouped `MiltSeries` construction
- clustering with `milt_cluster()`
- classification with `milt_classifier()`, `milt_classify_fit()`, and `milt_classify_predict()`
- reconciliation with `milt_reconcile()`

## Deployment and reporting

Trained objects can be operationalized through:

- `milt_save()` and `milt_load()`
- `milt_serve()` for API-style serving
- `milt_dashboard()` for interactive exploration
- `milt_report()` for report generation

## Built-in datasets

```r
data(milt_air)
data(milt_retail)
data(milt_energy)
```

- `milt_air`: monthly airline passenger counts
- `milt_retail`: synthetic grouped retail sales data
- `milt_energy`: synthetic hourly energy demand with related covariates

## Documentation map

The website is organized around both reference pages and longer-form articles.

Start with:

- Getting started
- Forecasting
- Pipelines
- Multi-series workflows
- Anomaly detection
- Deep learning
- Deployment

The reference index documents the exported functions, result objects, metrics,
datasets, and S3 methods.

## Architecture

At a high level:

```text
Layer 1  User API
         milt_series(), milt_model(), milt_fit(), milt_forecast(), ...

Layer 2  Core objects
         MiltSeries, MiltModel, MiltForecast, MiltBacktest, MiltComparison

Layer 3  Feature and workflow engine
         lag/rolling/Fourier/calendar/scale steps, pipelines, backtesting

Layer 4  Backends
         classical statistical models, ML backends, deep-learning integrations

Layer 5  Delivery
         metrics, explainability, anomaly detection, saving, serving, reporting
```

This separation is what allows the package to expose one user-facing interface
while still supporting many implementation backends.

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/ntiGideon/milt/issues>.

Please review:

- `CONTRIBUTING.md`
- `CODE_OF_CONDUCT.md`

## License

MIT License.
