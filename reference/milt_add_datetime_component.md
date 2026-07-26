# Add a datetime attribute as a new series component

Extracts a calendar attribute (month, quarter, day of week, ...) from
the time index and appends it as a new value column, turning a
univariate series multivariate. Mirrors darts'
`datetime_attribute_timeseries()` followed by stacking onto the original
series.

## Usage

``` r
milt_add_datetime_component(series, attribute, cyclic = FALSE, name = NULL)
```

## Arguments

- series:

  A `MiltSeries` object.

- attribute:

  Character. One of `"year"`, `"month"`, `"quarter"`, `"week"`, `"day"`,
  `"dayofweek"`, `"dayofyear"`, `"hour"`.

- cyclic:

  Logical. When `TRUE`, encodes the attribute as a sin/cos pair (two new
  components, `<attribute>_sin` / `<attribute>_cos`) instead of a single
  raw integer column. Default `FALSE`.

- name:

  Optional character. Name for the new column (raw mode only). Defaults
  to `attribute`.

## Value

A multivariate `MiltSeries` with the new component(s) appended.

## See also

[`milt_add_holidays()`](https://ntiGideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_holidays()`](https://ntiGideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_check_seasonality()`](https://ntiGideon.github.io/milt/reference/milt_check_seasonality.md),
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
s   <- milt_series(AirPassengers)
s2  <- milt_add_datetime_component(s, "month")
s3  <- milt_add_datetime_component(s, "month", cyclic = TRUE)
```
