# Forecast Accuracy Metrics Guide

milt provides a comprehensive set of accuracy and probabilistic scoring
metrics. This guide explains each metric: its formula, interpretation,
when to use it, and what its weaknesses are.

------------------------------------------------------------------------

## Quick Reference

| Function                                                                           | Name          | Scale-free? | Requires training? | Notes                            |
|------------------------------------------------------------------------------------|---------------|-------------|--------------------|----------------------------------|
| [`milt_mae()`](https://ntiGideon.github.io/milt/reference/milt_mae.md)             | MAE           | No          | No                 | Robust to outliers               |
| [`milt_mse()`](https://ntiGideon.github.io/milt/reference/milt_mse.md)             | MSE           | No          | No                 | Sensitive to large errors        |
| [`milt_rmse()`](https://ntiGideon.github.io/milt/reference/milt_rmse.md)           | RMSE          | No          | No                 | Same units as data               |
| [`milt_mape()`](https://ntiGideon.github.io/milt/reference/milt_mape.md)           | MAPE          | Yes         | No                 | Undefined when actual = 0        |
| [`milt_smape()`](https://ntiGideon.github.io/milt/reference/milt_smape.md)         | sMAPE         | Yes         | No                 | Bounded in \[0, 2\]              |
| [`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md)           | MASE          | Yes         | Yes                | Best for cross-series comparison |
| [`milt_rmsse()`](https://ntiGideon.github.io/milt/reference/milt_rmsse.md)         | RMSSE         | Yes         | Yes                | RMSE analogue of MASE            |
| [`milt_mrae()`](https://ntiGideon.github.io/milt/reference/milt_mrae.md)           | MRAE          | Yes         | No                 | Relative to a benchmark          |
| [`milt_r_squared()`](https://ntiGideon.github.io/milt/reference/milt_r_squared.md) | R²            | Yes         | No                 | Can be negative                  |
| [`milt_crps()`](https://ntiGideon.github.io/milt/reference/milt_crps.md)           | CRPS          | No          | No                 | Distributional forecast          |
| [`milt_pinball()`](https://ntiGideon.github.io/milt/reference/milt_pinball.md)     | Pinball loss  | No          | No                 | Quantile forecast                |
| [`milt_winkler()`](https://ntiGideon.github.io/milt/reference/milt_winkler.md)     | Winkler score | No          | No                 | Prediction interval              |
| [`milt_coverage()`](https://ntiGideon.github.io/milt/reference/milt_coverage.md)   | Coverage      | Yes         | No                 | Interval calibration             |

------------------------------------------------------------------------

## 1. Point Forecast Metrics

All point metrics share the signature `(actual, predicted)` where both
arguments are numeric vectors of the same length.

### Mean Absolute Error — `milt_mae()`

$$\text{MAE} = \frac{1}{n}\sum\limits_{t = 1}^{n}\left| y_{t} - {\widehat{y}}_{t} \right|$$

**Returns:** a single non-negative number in the same units as `actual`.

**Interpretation:** the average absolute deviation between observed and
predicted values. A MAE of 50 means forecasts are off by 50 units on
average.

**When to use:** when you want an easily interpretable, outlier-robust
error measure on a single series where scale comparisons are meaningful.

**Weakness:** not comparable across series with different scales or
units.

``` r
library(milt)

actual    <- c(100, 110, 95, 130, 120)
predicted <- c(105, 108, 98, 125, 118)

milt_mae(actual, predicted)
#> [1] 4.6
```

------------------------------------------------------------------------

### Mean Squared Error — `milt_mse()`

$$\text{MSE} = \frac{1}{n}\sum\limits_{t = 1}^{n}\left( y_{t} - {\widehat{y}}_{t} \right)^{2}$$

**Returns:** a single non-negative number in squared units.

**Interpretation:** MSE penalises large errors more heavily than MAE. A
model that occasionally produces huge errors will have a much higher MSE
than one with consistently small errors.

**When to use:** when large errors are disproportionately costly
(e.g. energy trading, manufacturing).

**Weakness:** squared units make it hard to interpret directly; not
scale-free.

``` r
milt_mse(actual, predicted)
#> [1] 28.4
```

------------------------------------------------------------------------

### Root Mean Squared Error — `milt_rmse()`

$$\text{RMSE} = \sqrt{\text{MSE}}$$

**Returns:** a single non-negative number in the same units as `actual`.

**Interpretation:** RMSE restores the original scale while retaining
MSE’s property of penalising large errors heavily. It is the most widely
reported metric in academic forecasting competitions.

**When to use:** when you want scale-preserved error that still
penalises large mistakes.

``` r
milt_rmse(actual, predicted)
#> [1] 5.329
```

------------------------------------------------------------------------

### Mean Absolute Percentage Error — `milt_mape()`

$$\text{MAPE} = \frac{1}{n}\sum\limits_{t = 1}^{n}\left| \frac{y_{t} - {\widehat{y}}_{t}}{y_{t}} \right|$$

**Returns:** a single numeric value (expressed as a fraction, not a
percentage — multiply by 100 for display). A value of `0.05` means 5 %.

**Interpretation:** a percentage error, making it comparable across
series with different scales. Widely used in industry.

**When to use:** when actuals are always strictly positive and you want
a scale-free, easily explainable metric.

**Weaknesses:** - Undefined (returns `Inf`) when any `actual` value is
zero. - Asymmetric: the same absolute error produces a larger percentage
when the actual is small vs. large. - Biased towards forecasts that are
too low.

``` r
milt_mape(actual, predicted)
#> [1] 0.04085
# i.e. ≈ 4.1 %

# When actuals contain zero, use milt_smape() instead:
actuals_with_zero <- c(0, 10, 20, 30)
milt_smape(actuals_with_zero, c(1, 9, 22, 28))
```

------------------------------------------------------------------------

### Symmetric MAPE — `milt_smape()`

$$\text{sMAPE} = \frac{2}{n}\sum\limits_{t = 1}^{n}\frac{\left| y_{t} - {\widehat{y}}_{t} \right|}{\left| y_{t} \right| + \left| {\widehat{y}}_{t} \right|}$$

**Returns:** a single numeric value in `[0, 2]` (i.e. `[0 %, 200 %]`).

**Interpretation:** symmetric around over- and under-prediction and
avoids division by zero when both actual and predicted are non-zero. A
value of `0.10` means approximately 10 % symmetric error.

**When to use:** when series contain zeros or near-zeros, or when you
want a symmetric, bounded error measure.

**Weakness:** can still be undefined when both actual and predicted are
zero simultaneously (milt sets those terms to 0 and emits a warning).

``` r
milt_smape(actual, predicted)
#> [1] 0.04078
```

------------------------------------------------------------------------

### Mean Absolute Scaled Error — `milt_mase()`

$$\text{MASE} = \frac{\text{MAE}}{\frac{1}{n - m}\sum\limits_{t = m + 1}^{n}\left| y_{t} - y_{t - m} \right|}$$

where *m* is the seasonal period.

``` r
milt_mase(actual, predicted, training, season = 1L)
```

| Argument    | Type             | Default | Description                                                                                   |
|-------------|------------------|---------|-----------------------------------------------------------------------------------------------|
| `actual`    | numeric vector   | —       | Observed values in the test set.                                                              |
| `predicted` | numeric vector   | —       | Forecast values.                                                                              |
| `training`  | numeric vector   | —       | In-sample (training) values used to compute the scaling denominator.                          |
| `season`    | positive integer | `1L`    | Seasonal period. Use `1` for non-seasonal. Use `12` for monthly data with annual seasonality. |

**Returns:** a single non-negative number.

**Interpretation:** - MASE \< 1: model outperforms the naïve seasonal
benchmark. - MASE = 1: model matches naïve forecasting exactly. - MASE
\> 1: model is worse than naïve.

**When to use:** the **recommended** metric for comparing forecast
accuracy across series with different scales and seasonal patterns
(e.g. M4 competition).

**Why it works:** the denominator is the mean absolute error of a
seasonal naïve forecast on the training data, providing a scale-free,
unbiased baseline.

``` r
train_data <- as.numeric(AirPassengers)[1:120]
test_data  <- as.numeric(AirPassengers)[121:144]
fc_naive   <- rep(tail(train_data, 12), 2)  # seasonal naïve

milt_mase(test_data, fc_naive, training = train_data, season = 12L)
#> [1] 1.0   # exactly naïve, as expected
```

------------------------------------------------------------------------

### Root Mean Squared Scaled Error — `milt_rmsse()`

$$\text{RMSSE} = \sqrt{\frac{\text{MSE}}{\frac{1}{n - m}\sum\limits_{t = m + 1}^{n}\left( y_{t} - y_{t - m} \right)^{2}}}$$

Same signature as
[`milt_mase()`](https://ntiGideon.github.io/milt/reference/milt_mase.md).

**Interpretation:** the RMSE analogue of MASE. Values \< 1 indicate
better-than-naive performance. RMSSE penalises large errors more than
MASE. Used as the primary metric in the M5 forecasting competition.

``` r
milt_rmsse(test_data, fc_naive, training = train_data, season = 12L)
```

------------------------------------------------------------------------

### Mean Relative Absolute Error — `milt_mrae()`

$$\text{MRAE} = \frac{1}{n}\sum\limits_{t = 1}^{n}\frac{\left| y_{t} - {\widehat{y}}_{t} \right|}{\left| y_{t} - {\widehat{b}}_{t} \right|}$$

``` r
milt_mrae(actual, predicted, benchmark)
```

| Argument    | Type    | Description                                  |
|-------------|---------|----------------------------------------------|
| `actual`    | numeric | Observed values.                             |
| `predicted` | numeric | Your model’s forecasts.                      |
| `benchmark` | numeric | A benchmark model’s forecasts (same length). |

**Interpretation:** values \< 1 mean your model outperforms the
benchmark.

``` r
benchmark <- rep(mean(actual), length(actual))
milt_mrae(actual, predicted, benchmark)
```

------------------------------------------------------------------------

### Coefficient of Determination — `milt_r_squared()`

$$R^{2} = 1 - \frac{\sum\left( y_{t} - {\widehat{y}}_{t} \right)^{2}}{\sum\left( y_{t} - \bar{y} \right)^{2}}$$

**Returns:** a numeric value, typically in $( - \infty,1\rbrack$.

**Interpretation:** - R² = 1: perfect fit. - R² = 0: model is no better
than predicting the mean. - R² \< 0: model is worse than predicting the
mean.

**When to use:** supplementary measure of explained variance; less
informative than MASE or RMSSE for time series.

``` r
milt_r_squared(actual, predicted)
```

------------------------------------------------------------------------

## 2. Aggregate Accuracy — `milt_accuracy()`

[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md)
computes multiple metrics at once for a fitted model or backtest result:

``` r
milt_accuracy(object, metrics = c("MAE", "RMSE", "MAPE", "MASE", "RMSSE"))
```

| Argument  | Type                                          | Default                                 | Description                                                                                                        |
|-----------|-----------------------------------------------|-----------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| `object`  | MiltForecast, MiltBacktest, or MiltComparison | —                                       | The result object to evaluate.                                                                                     |
| `metrics` | character vector                              | `c("MAE","RMSE","MAPE","MASE","RMSSE")` | Which metrics to compute. Supported: `"MAE"`, `"MSE"`, `"RMSE"`, `"MAPE"`, `"SMAPE"`, `"MASE"`, `"RMSSE"`, `"R2"`. |

**Returns:** a tibble with one row per model (or series) and one column
per metric.

``` r
ap  <- milt_series(AirPassengers)
sp  <- milt_split(ap, prop = 0.8)

fc  <- milt_model("auto_arima") |>
  milt_fit(sp$train) |>
  milt_forecast(h = milt_tail(sp$test, n = nrow(sp$test$data()))$n_timesteps())

milt_accuracy(fc, metrics = c("MAE", "RMSE", "MAPE", "MASE"))
```

------------------------------------------------------------------------

## 3. Probabilistic Forecast Metrics

These metrics evaluate distributional or interval forecasts, where the
model produces uncertainty estimates rather than a single point
forecast.

### Continuous Ranked Probability Score — `milt_crps()`

``` r
milt_crps(actual, forecast_dist)
```

| Argument        | Type                        | Description                                                                                          |
|-----------------|-----------------------------|------------------------------------------------------------------------------------------------------|
| `actual`        | numeric vector (length *n*) | Observed values.                                                                                     |
| `forecast_dist` | numeric matrix (*n* × *S*)  | *S* sample paths from the predictive distribution. Each row is a time step; each column is a sample. |

**Formula (energy score form):**

$$\text{CRPS} = {\mathbb{E}}|X - y| - \frac{1}{2}{\mathbb{E}}|X - X\prime|$$

where $X,X\prime$ are independent draws from the forecast distribution
and $y$ is the observation.

**Interpretation:** the lower the better. A CRPS of 0 is perfect
(degenerate distribution concentrated on the true value). CRPS collapses
to MAE when only a point forecast is given.

**When to use:** when comparing probabilistic models (e.g. DeepAR, TFT)
or when evaluating whether uncertainty estimates are well-calibrated.

``` r
# Simulate 100 sample paths from a simple normal predictive distribution
set.seed(42)
n_steps  <- 12
n_samples <- 100

actual_vals   <- rnorm(n_steps, mean = 100, sd = 15)
forecast_dist <- matrix(rnorm(n_steps * n_samples, mean = 100, sd = 18),
                        nrow = n_steps, ncol = n_samples)

milt_crps(actual_vals, forecast_dist)
```

------------------------------------------------------------------------

### Pinball Loss — `milt_pinball()`

``` r
milt_pinball(actual, quantile_forecast, tau)
```

| Argument            | Type              | Description                                          |
|---------------------|-------------------|------------------------------------------------------|
| `actual`            | numeric vector    | Observed values.                                     |
| `quantile_forecast` | numeric vector    | Forecast at quantile level `tau`.                    |
| `tau`               | numeric in (0, 1) | Quantile level (e.g. `0.9` for the 90th percentile). |

**Formula:**

$$L_{\tau}\left( y,\widehat{q} \right) = \begin{cases}
{\tau\left( y - \widehat{q} \right)} & {{\text{if}\mspace{6mu}}y \geq \widehat{q}} \\
{(1 - \tau)\left( \widehat{q} - y \right)} & {{\text{if}\mspace{6mu}}y < \widehat{q}}
\end{cases}$$

**Interpretation:** minimising the average pinball loss at level $\tau$
yields the optimal $\tau$-quantile forecast. Lower is better.

**When to use:** evaluating quantile forecasts, e.g. to assess a model’s
10th or 90th percentile estimates independently.

``` r
# Evaluate the 90th-percentile forecast
actual_vals      <- c(95, 103, 110, 98, 115, 122, 108)
q90_forecast     <- c(100, 110, 112, 105, 118, 120, 115)

milt_pinball(actual_vals, q90_forecast, tau = 0.9)
```

------------------------------------------------------------------------

### Winkler Score — `milt_winkler()`

``` r
milt_winkler(actual, lower, upper, alpha)
```

| Argument | Type              | Description                                                                                                      |
|----------|-------------------|------------------------------------------------------------------------------------------------------------------|
| `actual` | numeric vector    | Observed values.                                                                                                 |
| `lower`  | numeric vector    | Lower bound of the prediction interval.                                                                          |
| `upper`  | numeric vector    | Upper bound of the prediction interval.                                                                          |
| `alpha`  | numeric in (0, 1) | Significance level — the interval targets `(1 - alpha) * 100 %` coverage. E.g. `alpha = 0.2` for 80 % intervals. |

**Formula:**

$$W_{\alpha} = \begin{cases}
{(U - L) + \frac{2}{\alpha}(L - y)} & {{\text{if}\mspace{6mu}}y < L} \\
(U - L) & {{\text{if}\mspace{6mu}}L \leq y \leq U} \\
{(U - L) + \frac{2}{\alpha}(y - U)} & {{\text{if}\mspace{6mu}}y > U}
\end{cases}$$

**Interpretation:** the score equals the interval width when the
observation falls inside; a penalty proportional to the miss distance is
added when it falls outside. Narrower intervals are rewarded, but
missing the observation incurs a large penalty. Lower is better.

**When to use:** evaluating the quality of a model’s prediction
intervals jointly (sharpness and calibration simultaneously).

``` r
actual_vals <- c(95, 103, 110, 98, 115, 122, 108)
lower_80    <- c(82,  90, 95,  86, 100, 105,  93)
upper_80    <- c(115, 120, 128, 112, 132, 138, 122)

milt_winkler(actual_vals, lower_80, upper_80, alpha = 0.2)
```

------------------------------------------------------------------------

### Interval Coverage — `milt_coverage()`

``` r
milt_coverage(actual, lower, upper)
```

| Argument | Type           | Description                          |
|----------|----------------|--------------------------------------|
| `actual` | numeric vector | Observed values.                     |
| `lower`  | numeric vector | Lower bound of prediction intervals. |
| `upper`  | numeric vector | Upper bound of prediction intervals. |

**Formula:**

$$\text{Coverage} = \frac{1}{n}\sum\limits_{t = 1}^{n}\mathbf{1}\left\lbrack L_{t} \leq y_{t} \leq U_{t} \right\rbrack$$

**Interpretation:** the fraction of observations that fall within the
stated prediction interval. A well-calibrated 80 % interval should have
coverage ≈ 0.80. Coverage \> nominal = over-conservative intervals;
coverage \< nominal = under-conservative (too narrow).

**When to use:** a quick calibration check for any probabilistic model
producing prediction intervals.

``` r
milt_coverage(actual_vals, lower_80, upper_80)
#> [1] 1.0  # all 7 observations within the 80 % interval
```

------------------------------------------------------------------------

## 4. Choosing the Right Metric

| Scenario                               | Recommended metric       |
|----------------------------------------|--------------------------|
| Single series, interpretable units     | MAE or RMSE              |
| Scale-free comparison, positive series | MAPE                     |
| Series with zeros or near-zeros        | sMAPE                    |
| Comparing across multiple series       | MASE or RMSSE            |
| Outperforming a specific benchmark     | MRAE                     |
| Probabilistic / distribution forecast  | CRPS                     |
| Quantile forecast evaluation           | Pinball loss             |
| Prediction interval quality            | Winkler score + coverage |
| Quick competition baseline             | RMSSE (M5 standard)      |

------------------------------------------------------------------------

## 5. Using Metrics in Backtesting

[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md)
and [`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md)
return `MiltBacktest` objects. Pass them to
[`milt_accuracy()`](https://ntiGideon.github.io/milt/reference/milt_accuracy.md)
to aggregate metrics across all folds:

``` r
bt <- milt_backtest(
  milt_model("auto_arima"),
  milt_series(AirPassengers),
  horizon  = 12,
  metrics  = c("MAE", "RMSE", "MASE")
)

# Per-fold metrics
tibble::as_tibble(bt)

# Aggregated (mean across folds)
milt_accuracy(bt)
```

------------------------------------------------------------------------

## See Also

- [`vignette("milt-forecasting")`](https://ntiGideon.github.io/milt/articles/milt-forecasting.md)
  — fitting models and obtaining forecasts
- [`vignette("milt-model-reference")`](https://ntiGideon.github.io/milt/articles/milt-model-reference.md)
  — full model parameter reference
- [`vignette("milt-eda-diagnostics")`](https://ntiGideon.github.io/milt/articles/milt-eda-diagnostics.md)
  — pre-modelling diagnostics
