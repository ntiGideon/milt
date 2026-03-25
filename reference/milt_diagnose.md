# Diagnose a MiltSeries

Runs a suite of statistical checks and returns a `MiltDiagnosis` report
with stationarity, seasonality, trend, gap, and outlier information,
plus actionable recommendations.

## Usage

``` r
milt_diagnose(
  series,
  alpha = 0.05,
  seasonality_threshold = 0.3,
  iqr_multiplier = 1.5
)
```

## Arguments

- series:

  A `MiltSeries` object. For multi-component series, diagnostics are
  computed on the first component.

- alpha:

  Significance level for the trend test. Default `0.05`.

- seasonality_threshold:

  ACF strength above which seasonality is reported. Default `0.3`.

- iqr_multiplier:

  IQR multiplier for outlier detection. Default `1.5`.

## Value

A `MiltDiagnosis` object.

## See also

[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_get_covariates()`](https://ntiGideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntiGideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s <- milt_series(AirPassengers)
diag <- milt_diagnose(s)
print(diag)
#> # MiltDiagnosis
#> # Series    : 144 obs @ monthly# Range     : 1949-01-01 — 1960-12-01
#> Stationarity : stationary (CV ratio = 0.028)Seasonality  : seasonal (strength = 0.462, period = 12)Trend        : trend present (slope = 2.6572, p = 0)Gaps         : noneOutliers     : none
#> Recommendations:
#> • Significant linear trend detected. Models without detrending may underfit.• Seasonality detected (strength = 0.46, period = 12). Use a seasonal model (ETS, SARIMA, STL).
```
