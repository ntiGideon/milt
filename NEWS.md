# milt (development version)

## Initial release — 0.1.0

### New features

**Core data layer**

* `milt_series()` creates a `MiltSeries` object from a vector, `ts`, `data.frame`,
  `tibble`, or `data.table`. Supports univariate and multivariate series,
  optional grouping (multi-series, auto-detected from a `data.table`'s key),
  and covariate columns.
* `milt_window()`, `milt_split()`, `milt_concat()`, `milt_resample()`,
  `milt_fill_gaps()` for series manipulation.
* `as.data.table()` methods for `MiltSeries`, `MiltForecast`, and
  `MiltAnomalies`.
* `milt_write_parquet()` / `milt_read_parquet()` — Parquet I/O for `MiltSeries`
  data via the `arrow` package.
* Arithmetic operators (`+`, `-`, `*`, `/`, `^`) between two `MiltSeries`
  sharing an identical time index, or between a `MiltSeries` and a scalar.
* `milt_stack()` — combines series sharing a time index into one
  multivariate series (side by side, by component — unlike `milt_concat()`,
  which joins end-to-end by time).
* `milt_add_datetime_component()` — appends a calendar attribute (month,
  quarter, day of week, ...) as a new component, raw or sin/cos-cyclic.
* `milt_add_holidays()` — appends a binary holiday-indicator component
  (built-in `"US"` federal calendar, or a custom `dates` vector).
* `milt_check_seasonality()` — detects the strongest statistically
  significant seasonal period via the ACF and Bartlett's formula.

**Universal model interface**

* `milt_model()` dispatches to any registered backend by name string.
* `milt_fit()` trains a model on a `MiltSeries`.
* `milt_forecast()` generates point forecasts and prediction intervals.
* `milt_refit()` updates a fitted model on new data.
* `milt_backtest()` performs sliding-window cross-validation.
* `milt_compare()` runs multiple models and returns a ranked comparison table.
* `milt_ensemble()` combines model forecasts with weighted averaging.
* `milt_local_model()` wraps any model to train independently on each group of a
  grouped `MiltSeries`.
* `milt_conformal()` — model-agnostic, split-conformal prediction intervals:
  calibrates a `point ± margin` interval from walk-forward calibration-fold
  errors, usable with any model regardless of native probabilistic support.
* `milt_grid_search()` — hyperparameter search via backtesting; tries every
  combination of a parameter grid and ranks by a chosen metric, for any
  registered model.
* `milt_filter()` — smooths an already-observed `MiltSeries` in place (as
  opposed to forecasting forward): `"moving_average"`, `"kalman"`
  (state-space smoothing via `stats::StructTS()`), and `"gp"` (Gaussian
  Process smoothing with an RBF kernel). All three are base-R only.

**Baseline backends** (pure R, no dependency): `"naive"`, `"snaive"`,
`"drift"`, `"mean"`, `"moving_average"`.

**Classical backends** (`forecast` package): `"auto_arima"`, `"ets"`,
`"theta"`, `"stl"`, `"tbats"`, `"croston"`.

**Prophet backend**: `"prophet"` (requires `prophet` package).

**Machine-learning backends** (lazy-loaded): `"xgboost"`, `"lightgbm"`,
`"random_forest"`, `"elastic_net"`, `"svm"`, `"knn"` (pure R, no extra
dependency).

**Deep-learning backends** (requires `torch`): `"nbeats"`, `"nhits"`,
`"tcn"`, `"deepar"`, `"tft"`, `"patch_tst"`.

**Darts bridge backends** (requires `reticulate` + Python Darts, via
`milt_setup_darts()`): `"darts_rnn"`, `"darts_transformer"`,
`"darts_nbeats"`.

**Feature engineering**

* `milt_step_lag()`, `milt_step_rolling()`, `milt_step_fourier()`,
  `milt_step_calendar()` — ML-ready feature constructors.
* `milt_step_scale()` / `milt_step_unscale()` — invertible normalization
  (z-score, min-max, robust).
* `milt_step_boxcox()` / `milt_step_unboxcox()` — invertible Box-Cox power
  transform (auto-estimated or fixed lambda).
* `milt_step_diff()` / `milt_step_undiff()` — invertible sequential lagged
  differencing (e.g. `lags = c(1, 12)` for trend + yearly seasonality).
* `milt_step_map()` — generic elementwise transform, over values only or
  (when `fn` takes two arguments) both timestamps and values, with an
  optional invertible pair (e.g. `log1p`/`expm1`).

**Anomaly detection**

* `milt_detector()` + `milt_detect()` universal detector API.
* Built-in detectors: `"iqr"`, `"gesd"`, `"grubbs"`, `"stl"`,
  `"iforest"`, `"lof"`, `"ensemble"`, `"autoencoder"`.
* `milt_changepoints()` wraps the `changepoint` package (PELT, BinSeg, AMOC,
  SegNeigh).

**Multi-series & hierarchy**

* `milt_cluster()` — time series clustering (euclidean, k-Shape, feature-based,
  DTW k-means).
* `milt_classifier()` / `milt_classify_fit()` / `milt_classify_predict()` —
  feature-based and ROCKET classifiers.
* `milt_reconcile()` — hierarchical forecast reconciliation (OLS, WLS-struct,
  MinT-shrink).

**Metrics**

* Point-forecast accuracy: `milt_mae()`, `milt_mse()`, `milt_rmse()`,
  `milt_mape()`, `milt_smape()`, `milt_mase()`, `milt_rmsse()`, `milt_mrae()`,
  `milt_r_squared()`, `milt_wmape()`, `milt_ope()`,
  `milt_coefficient_of_variation()`, `milt_marre()`, `milt_rmsle()`.
* Probabilistic/interval accuracy: `milt_crps()`, `milt_coverage()`,
  `milt_pinball()`, `milt_winkler()`.
* `milt_accuracy()` computes a tibble of multiple metrics at once.

**Analysis**

* `milt_eda()` — automated exploratory analysis with ADF/KPSS stationarity tests
  and STL seasonality strength.
* `milt_explain()` — model explainability via SHAP (xgboost), variable importance
  (ranger), and coefficient extraction (glmnet).
* `milt_causal_impact()` — causal inference wrapper around `CausalImpact`.

**Deployment**

* `milt_save()` / `milt_load()` — RDS-based model serialisation with version
  metadata.
* `milt_serve()` — Plumber REST API with `/health`, `/series_info`, and
  `/forecast` endpoints.
* `milt_dashboard()` — four-tab Shiny monitoring dashboard.
* `milt_report()` — automated R Markdown / Quarto HTML or PDF report.

**Infrastructure**

* A central model registry; new backends register with
  `register_milt_model()` and can be listed with `list_milt_models()`.
* Internal `cli`-powered messaging helpers (`milt_info()`, `milt_warn()`,
  `milt_abort()`) give consistent, actionable error/warning formatting
  throughout the package.
* `milt_setup_darts()` — helper to configure the Python / Darts environment for
  deep-learning backends.
