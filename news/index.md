# Changelog

## milt (development version)

### Initial release — 0.1.0

#### New features

**Core data layer**

- [`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md)
  creates a `MiltSeries` object from a vector, `ts`, `data.frame`,
  `tibble`, or `data.table`. Supports univariate and multivariate
  series, optional grouping (multi-series, auto-detected from a
  `data.table`’s key), and covariate columns.
- [`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
  [`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
  [`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
  [`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
  [`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md)
  for series manipulation.
- `as.data.table()` methods for `MiltSeries`, `MiltForecast`, and
  `MiltAnomalies`.
- [`milt_write_parquet()`](https://ntiGideon.github.io/milt/reference/milt_write_parquet.md)
  /
  [`milt_read_parquet()`](https://ntiGideon.github.io/milt/reference/milt_read_parquet.md)
  — Parquet I/O for `MiltSeries` data via the `arrow` package.
- Arithmetic operators (`+`, `-`, `*`, `/`, `^`) between two
  `MiltSeries` sharing an identical time index, or between a
  `MiltSeries` and a scalar.
- [`milt_stack()`](https://ntiGideon.github.io/milt/reference/milt_stack.md)
  — combines series sharing a time index into one multivariate series
  (side by side, by component — unlike
  [`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
  which joins end-to-end by time).
- [`milt_add_datetime_component()`](https://ntiGideon.github.io/milt/reference/milt_add_datetime_component.md)
  — appends a calendar attribute (month, quarter, day of week, …) as a
  new component, raw or sin/cos-cyclic.
- [`milt_add_holidays()`](https://ntiGideon.github.io/milt/reference/milt_add_holidays.md)
  — appends a binary holiday-indicator component (built-in `"US"`
  federal calendar, or a custom `dates` vector).
- [`milt_check_seasonality()`](https://ntiGideon.github.io/milt/reference/milt_check_seasonality.md)
  — detects the strongest statistically significant seasonal period via
  the ACF and Bartlett’s formula.

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
  `MiltSeries`; static, past, and future covariates (added via
  [`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md))
  are sliced per group and passed through to each group’s fit.
- [`milt_conformal()`](https://ntiGideon.github.io/milt/reference/milt_conformal.md)
  — model-agnostic, split-conformal prediction intervals: calibrates a
  `point ± margin` interval from walk-forward calibration-fold errors,
  usable with any model regardless of native probabilistic support.
- [`milt_grid_search()`](https://ntiGideon.github.io/milt/reference/milt_grid_search.md)
  — hyperparameter search via backtesting; tries every combination of a
  parameter grid and ranks by a chosen metric, for any registered model.
- [`milt_filter()`](https://ntiGideon.github.io/milt/reference/milt_filter.md)
  — smooths an already-observed `MiltSeries` in place (as opposed to
  forecasting forward): `"moving_average"`, `"kalman"` (state-space
  smoothing via
  [`stats::StructTS()`](https://rdrr.io/r/stats/StructTS.html)), and
  `"gp"` (Gaussian Process smoothing with an RBF kernel). All three are
  base-R only.

**Baseline backends** (pure R, no dependency): `"naive"`, `"snaive"`,
`"drift"`, `"mean"`, `"moving_average"`.

**Classical backends** (`forecast` package): `"auto_arima"`, `"ets"`,
`"theta"`, `"stl"`, `"tbats"`, `"croston"`.

**Prophet backend**: `"prophet"` (requires `prophet` package).

**Machine-learning backends** (lazy-loaded): `"xgboost"`, `"lightgbm"`,
`"random_forest"`, `"elastic_net"`, `"svm"`, `"knn"` (pure R, no extra
dependency).

**Deep-learning backends** (requires `torch`): `"nbeats"`, `"nhits"`,
`"tcn"`, `"deepar"`, `"tft"`, `"patch_tst"`, `"nlinear"`, `"dlinear"`,
`"tide"`, `"tsmixer"`.

**Darts bridge backends** (requires `reticulate` + Python Darts, via
[`milt_setup_darts()`](https://ntiGideon.github.io/milt/reference/milt_setup_darts.md)):
`"darts_rnn"`, `"darts_transformer"`, `"darts_nbeats"`.

**Feature engineering**

- [`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
  [`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
  [`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
  [`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md)
  — ML-ready feature constructors.
- [`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md)
  /
  [`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)
  — invertible normalization (z-score, min-max, robust).
- [`milt_step_boxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_boxcox.md)
  /
  [`milt_step_unboxcox()`](https://ntiGideon.github.io/milt/reference/milt_step_unboxcox.md)
  — invertible Box-Cox power transform (auto-estimated or fixed lambda).
- [`milt_step_diff()`](https://ntiGideon.github.io/milt/reference/milt_step_diff.md)
  /
  [`milt_step_undiff()`](https://ntiGideon.github.io/milt/reference/milt_step_undiff.md)
  — invertible sequential lagged differencing (e.g. `lags = c(1, 12)`
  for trend + yearly seasonality).
- [`milt_step_map()`](https://ntiGideon.github.io/milt/reference/milt_step_map.md)
  — generic elementwise transform, over values only or (when `fn` takes
  two arguments) both timestamps and values, with an optional invertible
  pair (e.g. `log1p`/`expm1`).

**Anomaly detection**

- [`milt_detector()`](https://ntiGideon.github.io/milt/reference/milt_detector.md) +
  [`milt_detect()`](https://ntiGideon.github.io/milt/reference/milt_detect.md)
  universal detector API.
- Built-in detectors: `"iqr"`, `"gesd"`, `"grubbs"`, `"stl"`,
  `"iforest"`, `"lof"`, `"ensemble"`, `"autoencoder"`.
- [`milt_changepoints()`](https://ntiGideon.github.io/milt/reference/milt_changepoints.md)
  wraps the `changepoint` package (PELT, BinSeg, AMOC, SegNeigh).
- [`milt_anomaly_model()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_model.md) +
  [`milt_detect_anomalies()`](https://ntiGideon.github.io/milt/reference/milt_detect_anomalies.md)
  — wraps *any* fitted `MiltModel` as an anomaly detector by scoring its
  residuals
  ([`milt_anomaly_score()`](https://ntiGideon.github.io/milt/reference/milt_anomaly_score.md):
  `"norm"`, `"difference"`, `"nll_gaussian"`) and thresholding them
  (`"quantile"` or explicit `"threshold"` bounds) — the same
  forecasting-residual pattern as Darts’ `ForecastingAnomalyModel`.
  Returns a standard `MiltAnomalies` object, so all existing
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html)/[`print()`](https://rdrr.io/r/base/print.html)/[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
  methods work unchanged.

**Multi-series & hierarchy**

- [`milt_global_model()`](https://ntiGideon.github.io/milt/reference/milt_global_model.md)
  — trains a *single* shared model (`"knn"` or `"xgboost"`) across every
  group of a grouped `MiltSeries`, one-hot encoding group identity and
  appending static covariates as constant-per-group columns — unlike
  [`milt_local_model()`](https://ntiGideon.github.io/milt/reference/milt_local_model.md),
  which fits one independent model per group. Supports `forecast()` for
  one group and `forecast_all()` for every group at once.
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

**Metrics**

- Point-forecast accuracy:
  [`milt_mae()`](https://ntiGideon.github.io/milt/reference/milt_mae.md),
  [`milt_mse()`](https://ntiGideon.github.io/milt/reference/milt_mse.md),
  [`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md),
  [`milt_mape()`](https://ntiGideon.github.io/milt/reference/milt_mape.md),
  [`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md),
  [`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md),
  [`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md),
  [`milt_mrae()`](https://ntiGideon.github.io/milt/reference/milt_mrae.md),
  [`milt_r_squared()`](https://ntiGideon.github.io/milt/reference/milt_r_squared.md),
  [`milt_wmape()`](https://ntiGideon.github.io/milt/reference/milt_wmape.md),
  [`milt_ope()`](https://ntiGideon.github.io/milt/reference/milt_ope.md),
  [`milt_coefficient_of_variation()`](https://ntiGideon.github.io/milt/reference/milt_coefficient_of_variation.md),
  [`milt_marre()`](https://ntiGideon.github.io/milt/reference/milt_marre.md),
  [`milt_rmsle()`](https://ntiGideon.github.io/milt/reference/milt_rmsle.md).
- Probabilistic/interval accuracy:
  [`milt_crps()`](https://ntiGideon.github.io/milt/reference/milt_crps.md),
  [`milt_coverage()`](https://ntiGideon.github.io/milt/reference/milt_coverage.md),
  [`milt_pinball()`](https://ntiGideon.github.io/milt/reference/milt_pinball.md),
  [`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md).
- [`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md)
  computes a tibble of multiple metrics at once.

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

- A central model registry; new backends register with
  [`register_milt_model()`](https://ntiGideon.github.io/milt/reference/register_milt_model.md)
  and can be listed with
  [`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md).
- Internal `cli`-powered messaging helpers (`milt_info()`,
  `milt_warn()`, `milt_abort()`) give consistent, actionable
  error/warning formatting throughout the package.
- [`milt_setup_darts()`](https://ntiGideon.github.io/milt/reference/milt_setup_darts.md)
  — helper to configure the Python / Darts environment for deep-learning
  backends.
