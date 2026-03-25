# Changelog

## milt (development version)

### Initial release — 0.1.0

#### New features

**Core data layer**

- [`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md)
  creates a `MiltSeries` object from a vector, `ts`, `data.frame`, or
  `tibble`. Supports univariate and multivariate series, optional
  grouping (multi-series), and covariate columns.
- [`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
  [`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
  [`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
  [`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
  [`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md)
  for series manipulation.

**Universal model interface**

- [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md)
  dispatches to any registered backend by name string.
- [`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)
  trains a model on a `MiltSeries`.
- [`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)
  generates point forecasts and prediction intervals.
- [`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md)
  updates a fitted model on new data.
- [`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
  performs sliding-window cross-validation.
- [`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md)
  runs multiple models and returns a ranked comparison table.
- [`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md)
  combines model forecasts with weighted averaging.
- [`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md)
  wraps any model to train independently on each group of a grouped
  `MiltSeries`.

**Classical backends** (`forecast` package): `"auto_arima"`, `"ets"`,
`"tbats"`, `"theta"`, `"croston"`, `"nnetar"`, `"hw_additive"`,
`"hw_multiplicative"`.

**Statistical backends**: `"stlm"`, `"tslm"`, `"var"`.

**Machine-learning backends** (lazy-loaded): `"xgboost"`, `"lightgbm"`,
`"random_forest"`, `"elastic_net"`, `"svm"`, `"knn"` (pure R, no extra
dependency).

**Deep-learning backends** (requires `torch` or `reticulate` + Darts):
`"nbeats"`, `"nhits"`, `"tcn"`, `"deepar"`, `"tft"`, `"patch_tst"`.

**fable / tidyverts backends**: `"fable_arima"`, `"fable_ets"`,
`"fable_var"`.

**Prophet backend**: `"prophet"` (requires `prophet` package).

**Feature engineering**

- [`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
  `milt_step_roll()`,
  [`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
  [`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md)
  — ML-ready feature constructors.
- [`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md)
  /
  [`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)
  — invertible normalization (z-score, min-max, robust).

**Anomaly detection**

- [`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md) +
  [`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)
  universal detector API.
- Built-in detectors: `"iqr"`, `"gesd"`, `"grubbs"`, `"stl"`,
  `"isolation_forest"`, `"lof"`, `"ensemble"`, `"autoencoder"`.
- [`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md)
  wraps `changepoint` and `strucchange` backends.

**Multi-series & hierarchy**

- [`milt_cluster()`](https://ntiGideon.github.io/milt/reference/milt_cluster.md)
  — time series clustering (euclidean, k-Shape, feature-based, DTW
  k-means).
- [`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md)
  /
  [`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md)
  /
  [`milt_classify_predict()`](https://ntiGideon.github.io/milt/reference/milt_classify_predict.md)
  — feature-based and ROCKET classifiers.
- [`milt_reconcile()`](https://ntiGideon.github.io/milt/reference/milt_reconcile.md)
  — hierarchical forecast reconciliation (OLS, WLS-struct, MinT-shrink).

**Analysis**

- [`milt_eda()`](https://ntiGideon.github.io/milt/reference/milt_eda.md)
  — automated exploratory analysis with ADF/KPSS stationarity tests and
  STL seasonality strength.
- [`milt_explain()`](https://ntiGideon.github.io/milt/reference/milt_explain.md)
  — model explainability via SHAP (xgboost), variable importance
  (ranger), and coefficient extraction (glmnet).
- [`milt_causal_impact()`](https://ntiGideon.github.io/milt/reference/milt_causal_impact.md)
  — causal inference wrapper around `CausalImpact`.

**Deployment**

- [`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md)
  /
  [`milt_load()`](https://ntiGideon.github.io/milt/reference/milt_load.md)
  — RDS-based model serialisation with version metadata.
- [`milt_serve()`](https://ntiGideon.github.io/milt/reference/milt_serve.md)
  — Plumber REST API with `/health`, `/series_info`, and `/forecast`
  endpoints.
- [`milt_dashboard()`](https://ntiGideon.github.io/milt/reference/milt_dashboard.md)
  — four-tab Shiny monitoring dashboard.
- [`milt_report()`](https://ntiGideon.github.io/milt/reference/milt_report.md)
  — automated R Markdown / Quarto HTML or PDF report.

**Infrastructure**

- `ModelRegistry` — central registry; new backends register with
  `ModelRegistry$register()`.
- `milt_info()`, `milt_warn()`, `milt_abort()` — `cli`-powered messaging
  utilities.
- [`milt_setup_darts()`](https://ntiGideon.github.io/milt/reference/milt_setup_darts.md)
  — helper to configure the Python / Darts environment for deep-learning
  backends.
