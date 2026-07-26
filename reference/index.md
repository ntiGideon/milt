# Package index

## Series

Create and manipulate MiltSeries objects

- [`milt_series()`](https://ntigideon.github.io/milt/reference/milt_series.md)
  : Create a MiltSeries object
- [`milt_head()`](https://ntigideon.github.io/milt/reference/milt_head.md)
  : Return the first n observations of a MiltSeries
- [`milt_tail()`](https://ntigideon.github.io/milt/reference/milt_tail.md)
  : Return the last n observations of a MiltSeries
- [`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md)
  : Subset a MiltSeries to a time window
- [`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md)
  : Split a MiltSeries into train and test sets
- [`milt_split_at()`](https://ntigideon.github.io/milt/reference/milt_split_at.md)
  : Split a MiltSeries at a specific time point
- [`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md)
  : Concatenate MiltSeries objects along the time axis
- [`milt_resample()`](https://ntigideon.github.io/milt/reference/milt_resample.md)
  : Change the temporal resolution of a MiltSeries
- [`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md)
  : Fill gaps in a MiltSeries
- [`milt_to_tibble()`](https://ntigideon.github.io/milt/reference/milt_to_tibble.md)
  : Convert a MiltSeries to a tibble
- [`milt_to_ts()`](https://ntigideon.github.io/milt/reference/milt_to_ts.md)
  : Convert a MiltSeries to a base R ts object
- [`milt_to_tsibble()`](https://ntigideon.github.io/milt/reference/milt_to_tsibble.md)
  : Convert a MiltSeries to a tsibble
- [`milt_read_parquet()`](https://ntigideon.github.io/milt/reference/milt_read_parquet.md)
  : Read a MiltSeries from a Parquet file
- [`milt_write_parquet()`](https://ntigideon.github.io/milt/reference/milt_write_parquet.md)
  : Write a MiltSeries to a Parquet file
- [`milt_stack()`](https://ntigideon.github.io/milt/reference/milt_stack.md)
  : Stack MiltSeries into one multivariate series
- [`milt_add_datetime_component()`](https://ntigideon.github.io/milt/reference/milt_add_datetime_component.md)
  : Add a datetime attribute as a new series component
- [`milt_add_holidays()`](https://ntigideon.github.io/milt/reference/milt_add_holidays.md)
  : Add a binary holidays component
- [`milt_check_seasonality()`](https://ntigideon.github.io/milt/reference/milt_check_seasonality.md)
  : Check whether a series has a significant seasonal period
- [`` `[`( ``*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/sub-.MiltSeries.md)
  : Subset a MiltSeries by row index
- [`Ops(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/Ops.MiltSeries.md)
  : Arithmetic operators for MiltSeries

## Models

Train and forecast with time series models

- [`list_milt_models()`](https://ntigideon.github.io/milt/reference/list_milt_models.md)
  : List all registered milt models
- [`milt_model()`](https://ntigideon.github.io/milt/reference/milt_model.md)
  : Initialise a milt model
- [`milt_fit()`](https://ntigideon.github.io/milt/reference/milt_fit.md)
  : Fit a milt model to a MiltSeries
- [`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md)
  : Generate forecasts from a fitted milt model
- [`milt_predict()`](https://ntigideon.github.io/milt/reference/milt_predict.md)
  : In-sample predictions from a fitted milt model
- [`milt_residuals()`](https://ntigideon.github.io/milt/reference/milt_residuals.md)
  : Residuals from a fitted milt model
- [`milt_refit()`](https://ntigideon.github.io/milt/reference/milt_refit.md)
  : Refit a milt model on new data without re-tuning
- [`milt_backtest()`](https://ntigideon.github.io/milt/reference/milt_backtest.md)
  : Walk-forward backtesting of a milt model
- [`milt_cv()`](https://ntigideon.github.io/milt/reference/milt_cv.md) :
  Time series cross-validation
- [`milt_compare()`](https://ntigideon.github.io/milt/reference/milt_compare.md)
  : Compare multiple milt models via walk-forward backtesting
- [`milt_ensemble()`](https://ntigideon.github.io/milt/reference/milt_ensemble.md)
  : Create an ensemble milt model
- [`milt_local_model()`](https://ntigideon.github.io/milt/reference/milt_local_model.md)
  : Create a local (per-group) model for multi-series forecasting
- [`milt_global_model()`](https://ntigideon.github.io/milt/reference/milt_global_model.md)
  : Fit one shared model across every group of a multi-series MiltSeries
- [`milt_grid_search()`](https://ntigideon.github.io/milt/reference/milt_grid_search.md)
  : Grid search over a model's hyperparameters via backtesting
- [`milt_conformal()`](https://ntigideon.github.io/milt/reference/milt_conformal.md)
  : Wrap a milt model with conformal prediction intervals
- [`milt_filter()`](https://ntigideon.github.io/milt/reference/milt_filter.md)
  : Apply a filtering model to smooth a MiltSeries

## Feature Engineering

Build lag, rolling, calendar, and pipeline features

- [`milt_pipeline()`](https://ntigideon.github.io/milt/reference/milt_pipeline.md)
  : Create a new milt pipeline
- [`milt_pipeline_fit()`](https://ntigideon.github.io/milt/reference/milt_pipeline_fit.md)
  : Fit a milt pipeline to a training series
- [`milt_pipeline_forecast()`](https://ntigideon.github.io/milt/reference/milt_pipeline_forecast.md)
  : Generate forecasts from a fitted milt pipeline
- [`milt_pipeline_transform()`](https://ntigideon.github.io/milt/reference/milt_pipeline_transform.md)
  : Transform new data through a fitted pipeline (without the model
  step)
- [`milt_pipe_step_lag()`](https://ntigideon.github.io/milt/reference/milt_pipe_step_lag.md)
  : Add a lag step to a pipeline
- [`milt_pipe_step_rolling()`](https://ntigideon.github.io/milt/reference/milt_pipe_step_rolling.md)
  : Add a rolling-statistics step to a pipeline
- [`milt_pipe_step_fourier()`](https://ntigideon.github.io/milt/reference/milt_pipe_step_fourier.md)
  : Add a Fourier-terms step to a pipeline
- [`milt_pipe_step_calendar()`](https://ntigideon.github.io/milt/reference/milt_pipe_step_calendar.md)
  : Add a calendar-features step to a pipeline
- [`milt_pipe_step_scale()`](https://ntigideon.github.io/milt/reference/milt_pipe_step_scale.md)
  : Add a scaling step to a pipeline
- [`milt_pipe_model()`](https://ntigideon.github.io/milt/reference/milt_pipe_model.md)
  : Attach a model to a pipeline
- [`milt_step_lag()`](https://ntigideon.github.io/milt/reference/milt_step_lag.md)
  : Add lag features to a MiltSeries
- [`milt_step_rolling()`](https://ntigideon.github.io/milt/reference/milt_step_rolling.md)
  : Add rolling-window summary features to a MiltSeries
- [`milt_step_fourier()`](https://ntigideon.github.io/milt/reference/milt_step_fourier.md)
  : Add Fourier-term features to a MiltSeries
- [`milt_step_calendar()`](https://ntigideon.github.io/milt/reference/milt_step_calendar.md)
  : Add calendar features to a MiltSeries
- [`milt_step_scale()`](https://ntigideon.github.io/milt/reference/milt_step_scale.md)
  : Scale a time series
- [`milt_step_unscale()`](https://ntigideon.github.io/milt/reference/milt_step_unscale.md)
  : Invert a scaling step on a time series
- [`milt_step_boxcox()`](https://ntigideon.github.io/milt/reference/milt_step_boxcox.md)
  : Box-Cox power-transform a time series
- [`milt_step_unboxcox()`](https://ntigideon.github.io/milt/reference/milt_step_unboxcox.md)
  : Invert a Box-Cox transform on a time series
- [`milt_step_diff()`](https://ntigideon.github.io/milt/reference/milt_step_diff.md)
  : Difference a time series
- [`milt_step_undiff()`](https://ntigideon.github.io/milt/reference/milt_step_undiff.md)
  : Invert a differencing step on a time series
- [`milt_step_map()`](https://ntigideon.github.io/milt/reference/milt_step_map.md)
  : Apply an arbitrary elementwise function to a time series

## Anomaly Detection

Detect outliers and anomalies in time series

- [`milt_detector()`](https://ntigideon.github.io/milt/reference/milt_detector.md)
  : Create an anomaly detector
- [`milt_detect()`](https://ntigideon.github.io/milt/reference/milt_detect.md)
  : Detect anomalies in a time series
- [`milt_changepoints()`](https://ntigideon.github.io/milt/reference/milt_changepoints.md)
  : Detect changepoints in a time series
- [`milt_anomaly_model()`](https://ntigideon.github.io/milt/reference/milt_anomaly_model.md)
  : Wrap a model with residual-based anomaly detection
- [`milt_anomaly_score()`](https://ntigideon.github.io/milt/reference/milt_anomaly_score.md)
  : Compute a per-timestep anomaly score from residuals
- [`milt_detect_anomalies()`](https://ntigideon.github.io/milt/reference/milt_detect_anomalies.md)
  : Detect anomalies from a fitted MiltAnomalyModel

## Multi-Series And Hierarchies

Clustering, classification, and reconciliation

- [`milt_cluster()`](https://ntigideon.github.io/milt/reference/milt_cluster.md)
  : Cluster multiple time series
- [`milt_classifier()`](https://ntigideon.github.io/milt/reference/milt_classifier.md)
  : Create a time series classifier
- [`milt_classify_fit()`](https://ntigideon.github.io/milt/reference/milt_classify_fit.md)
  : Fit a time series classifier
- [`milt_classify_predict()`](https://ntigideon.github.io/milt/reference/milt_classify_predict.md)
  : Predict class labels for new time series
- [`milt_reconcile()`](https://ntigideon.github.io/milt/reference/milt_reconcile.md)
  : Reconcile hierarchical time series forecasts

## Analysis

EDA, diagnostics, explainability, and causal analysis

- [`milt_eda()`](https://ntigideon.github.io/milt/reference/milt_eda.md)
  : Automated exploratory data analysis for a time series
- [`milt_diagnose()`](https://ntigideon.github.io/milt/reference/milt_diagnose.md)
  : Diagnose a MiltSeries
- [`milt_plot_acf()`](https://ntigideon.github.io/milt/reference/milt_plot_acf.md)
  : Plot the ACF and PACF of a MiltSeries
- [`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md)
  : Plot a simple STL-style decomposition of a MiltSeries
- [`milt_explain()`](https://ntigideon.github.io/milt/reference/milt_explain.md)
  : Explain a fitted ML time series model
- [`milt_causal_impact()`](https://ntigideon.github.io/milt/reference/milt_causal_impact.md)
  : Estimate the causal impact of an intervention

## Deployment

Save, serve, and share trained models

- [`milt_save()`](https://ntigideon.github.io/milt/reference/milt_save.md)
  : Save a milt object to disk
- [`milt_load()`](https://ntigideon.github.io/milt/reference/milt_load.md)
  : Load a milt object from disk
- [`milt_serve()`](https://ntigideon.github.io/milt/reference/milt_serve.md)
  : Deploy a milt model as a REST API
- [`milt_dashboard()`](https://ntigideon.github.io/milt/reference/milt_dashboard.md)
  : Launch a Shiny monitoring dashboard
- [`milt_report()`](https://ntigideon.github.io/milt/reference/milt_report.md)
  : Generate an analysis report

## Deep Learning

Neural network backends and setup helpers

- [`milt_install_backends()`](https://ntigideon.github.io/milt/reference/milt_install_backends.md)
  : Install optional backend packages for milt
- [`milt_setup_darts()`](https://ntigideon.github.io/milt/reference/milt_setup_darts.md)
  : Set up the Python Darts environment
- [`milt_torch_device()`](https://ntigideon.github.io/milt/reference/milt_torch_device.md)
  : Detect the best available torch device

## Metrics

Forecast accuracy and probabilistic scoring metrics

- [`milt_accuracy()`](https://ntigideon.github.io/milt/reference/milt_accuracy.md)
  : Compute multiple forecast accuracy metrics at once
- [`milt_mae()`](https://ntigideon.github.io/milt/reference/milt_mae.md)
  : Mean Absolute Error
- [`milt_mse()`](https://ntigideon.github.io/milt/reference/milt_mse.md)
  : Mean Squared Error
- [`milt_rmse()`](https://ntigideon.github.io/milt/reference/milt_rmse.md)
  : Root Mean Squared Error
- [`milt_mape()`](https://ntigideon.github.io/milt/reference/milt_mape.md)
  : Mean Absolute Percentage Error
- [`milt_smape()`](https://ntigideon.github.io/milt/reference/milt_smape.md)
  : Symmetric Mean Absolute Percentage Error
- [`milt_mase()`](https://ntigideon.github.io/milt/reference/milt_mase.md)
  : Mean Absolute Scaled Error
- [`milt_rmsse()`](https://ntigideon.github.io/milt/reference/milt_rmsse.md)
  : Root Mean Squared Scaled Error
- [`milt_mrae()`](https://ntigideon.github.io/milt/reference/milt_mrae.md)
  : Mean Relative Absolute Error
- [`milt_r_squared()`](https://ntigideon.github.io/milt/reference/milt_r_squared.md)
  : Coefficient of Determination (R^2)
- [`milt_wmape()`](https://ntigideon.github.io/milt/reference/milt_wmape.md)
  : Weighted Mean Absolute Percentage Error
- [`milt_ope()`](https://ntigideon.github.io/milt/reference/milt_ope.md)
  : Overall Percentage Error
- [`milt_coefficient_of_variation()`](https://ntigideon.github.io/milt/reference/milt_coefficient_of_variation.md)
  : Coefficient of Variation of the RMSE
- [`milt_marre()`](https://ntigideon.github.io/milt/reference/milt_marre.md)
  : Mean Absolute Ranged Relative Error
- [`milt_rmsle()`](https://ntigideon.github.io/milt/reference/milt_rmsle.md)
  : Root Mean Squared Log Error
- [`milt_coverage()`](https://ntigideon.github.io/milt/reference/milt_coverage.md)
  : Prediction Interval Coverage
- [`milt_crps()`](https://ntigideon.github.io/milt/reference/milt_crps.md)
  : Continuous Ranked Probability Score (CRPS)
- [`milt_pinball()`](https://ntigideon.github.io/milt/reference/milt_pinball.md)
  : Pinball Loss (Quantile Score)
- [`milt_winkler()`](https://ntigideon.github.io/milt/reference/milt_winkler.md)
  : Winkler Score

## Data

Built-in example datasets

- [`milt_air`](https://ntigideon.github.io/milt/reference/milt_air.md) :
  AirPassengers as a milt-ready tibble
- [`milt_retail`](https://ntigideon.github.io/milt/reference/milt_retail.md)
  : Synthetic multi-series monthly retail sales
- [`milt_energy`](https://ntigideon.github.io/milt/reference/milt_energy.md)
  : Synthetic hourly energy consumption with covariates

## Registry And Utilities

Model registry helpers and other exported utilities

- [`get_milt_model_class()`](https://ntigideon.github.io/milt/reference/get_milt_model_class.md)
  : Retrieve a registered model's R6 class generator
- [`is_registered_model()`](https://ntigideon.github.io/milt/reference/is_registered_model.md)
  : Check whether a model name is registered
- [`register_milt_model()`](https://ntigideon.github.io/milt/reference/register_milt_model.md)
  : Register a model backend with the milt model registry
- [`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md)
  : Add covariates to a MiltSeries
- [`milt_get_covariates()`](https://ntigideon.github.io/milt/reference/milt_get_covariates.md)
  : Retrieve covariates attached to a MiltSeries
- [`hello()`](https://ntigideon.github.io/milt/reference/hello.md) :
  Hello, World!

## Classes

Result objects and class constructors

- [`MiltBacktestR6`](https://ntigideon.github.io/milt/reference/MiltBacktestR6.md)
  : MiltBacktest — walk-forward evaluation results
- [`MiltComparisonR6`](https://ntigideon.github.io/milt/reference/MiltComparisonR6.md)
  : MiltComparison - results of milt_compare()
- [`MiltForecastR6`](https://ntigideon.github.io/milt/reference/MiltForecastR6.md)
  : MiltForecast — results of milt_forecast()
- [`MiltModelBase`](https://ntigideon.github.io/milt/reference/MiltModelBase.md)
  : MiltModelBase — base class for all milt model backends
- [`MiltSeriesR6`](https://ntigideon.github.io/milt/reference/MiltSeriesR6.md)
  : MiltSeries — core time series object

## Methods

Documented S3 methods for printed, plotted, and summary outputs

- [`as_tibble(`*`<MiltAnomalies>`*`)`](https://ntigideon.github.io/milt/reference/as_tibble.MiltAnomalies.md)
  : Convert MiltAnomalies to tibble
- [`as_tibble(`*`<MiltBacktest>`*`)`](https://ntigideon.github.io/milt/reference/as_tibble.MiltBacktest.md)
  : Coerce a MiltBacktest to a tibble
- [`as_tibble(`*`<MiltComparison>`*`)`](https://ntigideon.github.io/milt/reference/as_tibble.MiltComparison.md)
  : Coerce a MiltComparison to a tibble
- [`as_tibble(`*`<MiltForecast>`*`)`](https://ntigideon.github.io/milt/reference/as_tibble.MiltForecast.md)
  : Convert a MiltForecast to a tibble
- [`as.data.table(`*`<MiltAnomalies>`*`)`](https://ntigideon.github.io/milt/reference/as.data.table.MiltAnomalies.md)
  : Convert MiltAnomalies to a data.table
- [`as.data.table(`*`<MiltForecast>`*`)`](https://ntigideon.github.io/milt/reference/as.data.table.MiltForecast.md)
  : Convert a MiltForecast to a data.table
- [`as.data.table(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/as.data.table.MiltSeries.md)
  : Convert a MiltSeries to a data.table
- [`plot(`*`<MiltAnomalies>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltAnomalies.md)
  : Plot a MiltAnomalies object
- [`plot(`*`<MiltBacktest>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltBacktest.md)
  : Plot a MiltBacktest
- [`plot(`*`<MiltClusters>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltClusters.md)
  : Plot a MiltClusters object
- [`plot(`*`<MiltComparison>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltComparison.md)
  : Plot a MiltComparison
- [`plot(`*`<MiltDiagnosis>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltDiagnosis.md)
  : Plot a MiltDiagnosis
- [`plot(`*`<MiltEDA>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltEDA.md)
  : Plot a MiltEDA object
- [`plot(`*`<MiltForecast>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltForecast.md)
  : Plot a MiltForecast
- [`plot(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)
  [`autoplot(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)
  : Plot a MiltSeries
- [`print(`*`<MiltAnomalies>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltAnomalies.md)
  : Print a MiltAnomalies object
- [`print(`*`<MiltBacktest>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltBacktest.md)
  : Print a MiltBacktest
- [`print(`*`<MiltComparison>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltComparison.md)
  : Print a MiltComparison
- [`print(`*`<MiltForecast>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltForecast.md)
  : Print a MiltForecast
- [`print(`*`<MiltModel>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltModel.md)
  : Print a MiltModel
- [`print(`*`<MiltPipeline>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltPipeline.md)
  : Print a MiltPipeline
- [`print(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/print.MiltSeries.md)
  : Print a MiltSeries
- [`summary(`*`<MiltAnomalies>`*`)`](https://ntigideon.github.io/milt/reference/summary.MiltAnomalies.md)
  : Summarise a MiltAnomalies object
- [`summary(`*`<MiltBacktest>`*`)`](https://ntigideon.github.io/milt/reference/summary.MiltBacktest.md)
  : Summary of a MiltBacktest
- [`summary(`*`<MiltComparison>`*`)`](https://ntigideon.github.io/milt/reference/summary.MiltComparison.md)
  : Summary of a MiltComparison
- [`summary(`*`<MiltForecast>`*`)`](https://ntigideon.github.io/milt/reference/summary.MiltForecast.md)
  : Summarise a MiltForecast
- [`summary(`*`<MiltSeries>`*`)`](https://ntigideon.github.io/milt/reference/summary.MiltSeries.md)
  : Summarise a MiltSeries
