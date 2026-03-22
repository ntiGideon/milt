# milt — Modern Integrated Library for Timeseries

<!-- badges: start -->
[![R-CMD-check](https://github.com/ntiGideon/milt/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ntiGideon/milt/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

**milt** is a unified R framework for time series forecasting, anomaly
detection, classification, and clustering.  Think Python's
[Darts](https://unit8co.github.io/darts/) or
[sktime](https://www.sktime.net/) — but natively in R with a
tidyverse-friendly API.

Every model, from a naïve baseline to an XGBoost regressor, follows the
same three-step pipe:

```r
milt_model("auto_arima") |> milt_fit(series) |> milt_forecast(h = 12)
```

## Installation

```r
# Development version from GitHub:
# install.packages("pak")
pak::pak("ntiGideon/milt")
```

Documentation site: <https://gideon-ntiboateng.github.io/milt>

## Quick start

```r
library(milt)

# 1. Create a MiltSeries from any R time series object
air <- milt_series(AirPassengers)

# 2. Inspect the series
print(air)
milt_diagnose(air)

# 3. Fit a model and forecast
fct <- milt_model("auto_arima") |>
  milt_fit(air) |>
  milt_forecast(horizon = 24)

print(fct)
plot(fct)

# 4. Evaluate accuracy
spl    <- milt_split(air, ratio = 0.8)
fct_cv <- milt_model("ets") |>
  milt_fit(spl$train) |>
  milt_forecast(spl$test$n_timesteps())

milt_accuracy(spl$test$values(), fct_cv$as_tibble()$.mean)

# 5. Walk-forward backtesting
bt <- milt_backtest(milt_model("naive"), air, horizon = 12)
print(bt)
plot(bt)
```

## Core API

| Function | Description |
|---|---|
| `milt_series()` | Create a `MiltSeries` from a ts, tibble, data.frame, xts, … |
| `milt_split()` | Train/test split |
| `milt_window()` | Subset by time range |
| `milt_fill_gaps()` | Impute missing observations |
| `milt_diagnose()` | Stationarity, seasonality, trend, outlier report |
| `milt_model()` | Initialise a model by name |
| `milt_fit()` | Fit a model to a `MiltSeries` |
| `milt_forecast()` | Generate point + interval forecasts |
| `milt_predict()` | In-sample fitted values |
| `milt_residuals()` | Training residuals |
| `milt_backtest()` | Walk-forward cross-validation |
| `milt_accuracy()` | Compute MAE, RMSE, MAPE, SMAPE, MASE, … |

## Available models (Phase 1)

| Key | Description |
|---|---|
| `"naive"` | Last-value repeat |
| `"snaive"` | Seasonal naïve |
| `"drift"` | Linear drift extrapolation |
| `"ets"` | Exponential smoothing (`forecast::ets`) |
| `"auto_arima"` | Automatic ARIMA (`forecast::auto.arima`) |
| `"theta"` | Theta method (`forecast::thetaf`) |
| `"stl"` | STL decomposition + ETS/ARIMA (`forecast::stlf`) |

Use `list_milt_models()` to see all currently registered models.

## Package datasets

```r
data(milt_air)      # AirPassengers as a tibble (144 monthly obs)
data(milt_retail)   # Synthetic multi-series retail sales (5 categories)
data(milt_energy)   # Synthetic hourly energy + temperature covariates
```

## Architecture

```
Layer 1  User-facing API      milt_series(), milt_model(), milt_forecast(), …
Layer 2  Core engine          MiltSeriesR6, ModelRegistry, MiltForecast, …
Layer 3  Model backends       R/backend-*.R  (one file per model family)
Layer 4  Data layer           tsibble, arrow, data.table integration
```

Adding a new model requires only creating one `backend-<name>.R` file that
inherits from `MiltModelBase` and registers itself — no changes to core code.

## Contributing

Bug reports and pull requests are welcome at
<https://github.com/ntiGideon/milt/issues>.

## License

MIT © Gideon Nti Boateng
