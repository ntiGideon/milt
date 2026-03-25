# milt (development version)

## Initial release — 0.1.0

### New features

**Core data layer**

* `milt_series()` creates a `MiltSeries` object from a vector, `ts`, `data.frame`,
  or `tibble`. Supports univariate and multivariate series, optional grouping
  (multi-series), and covariate columns.
* `milt_window()`, `milt_split()`, `milt_concat()`, `milt_resample()`,
  `milt_fill_gaps()` for series manipulation.

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

**Classical backends** (`forecast` package):
`"auto_arima"`, `"ets"`, `"tbats"`, `"theta"`, `"croston"`, `"nnetar"`,
`"hw_additive"`, `"hw_multiplicative"`.

**Statistical backends**: `"stlm"`, `"tslm"`, `"var"`.

**Machine-learning backends** (lazy-loaded): `"xgboost"`, `"lightgbm"`,
`"random_forest"`, `"elastic_net"`, `"svm"`, `"knn"` (pure R, no extra
dependency).

**Deep-learning backends** (requires `torch` or `reticulate` + Darts):
`"nbeats"`, `"nhits"`, `"tcn"`, `"deepar"`, `"tft"`, `"patch_tst"`.

**fable / tidyverts backends**: `"fable_arima"`, `"fable_ets"`, `"fable_var"`.

**Prophet backend**: `"prophet"` (requires `prophet` package).

**Feature engineering**

* `milt_step_lag()`, `milt_step_roll()`, `milt_step_fourier()`,
  `milt_step_calendar()` — ML-ready feature constructors.
* `milt_step_scale()` / `milt_step_unscale()` — invertible normalization
  (z-score, min-max, robust).

**Anomaly detection**

* `milt_detector()` + `milt_detect()` universal detector API.
* Built-in detectors: `"iqr"`, `"gesd"`, `"grubbs"`, `"stl"`,
  `"isolation_forest"`, `"lof"`, `"ensemble"`, `"autoencoder"`.
* `milt_changepoints()` wraps `changepoint` and `strucchange` backends.

**Multi-series & hierarchy**

* `milt_cluster()` — time series clustering (euclidean, k-Shape, feature-based,
  DTW k-means).
* `milt_classifier()` / `milt_classify_fit()` / `milt_classify_predict()` —
  feature-based and ROCKET classifiers.
* `milt_reconcile()` — hierarchical forecast reconciliation (OLS, WLS-struct,
  MinT-shrink).

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

* `ModelRegistry` — central registry; new backends register with
  `ModelRegistry$register()`.
* `milt_info()`, `milt_warn()`, `milt_abort()` — `cli`-powered messaging
  utilities.
* `milt_setup_darts()` — helper to configure the Python / Darts environment for
  deep-learning backends.
