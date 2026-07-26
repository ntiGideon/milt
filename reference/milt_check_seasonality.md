# Check whether a series has a significant seasonal period

Searches the ACF for the strongest local maximum among the significant
lags (per Bartlett's formula for the standard error of the ACF under a
white-noise null) and reports it as the detected seasonal period.

## Usage

``` r
milt_check_seasonality(series, max_lag = 24L, alpha = 0.05)
```

## Arguments

- series:

  A univariate `MiltSeries` object.

- max_lag:

  Positive integer. Largest lag to examine. Default `24L`.

- alpha:

  Significance level for the Bartlett bound. Default `0.05`.

## Value

A list with:

- `is_seasonal` — logical.

- `period` — integer lag of the strongest significant local maximum, or
  `NA_integer_` when none is found.

## See also

[`milt_eda()`](https://ntiGideon.github.io/milt/reference/milt_eda.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntiGideon.github.io/milt/reference/milt_add_datetime_component.md),
[`milt_add_holidays()`](https://ntiGideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_filter()`](https://ntiGideon.github.io/milt/reference/milt_filter.md),
[`milt_get_covariates()`](https://ntiGideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntiGideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_read_parquet()`](https://ntiGideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntiGideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntiGideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s <- milt_series(AirPassengers)
milt_check_seasonality(s)
#> $is_seasonal
#> [1] TRUE
#> 
#> $period
#> [1] 12
#> 
```
