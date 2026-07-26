# Read a MiltSeries from a Parquet file

Read a MiltSeries from a Parquet file

## Usage

``` r
milt_read_parquet(
  path,
  time_col = NULL,
  value_cols = NULL,
  group_col = NULL,
  frequency = NULL,
  ...
)
```

## Arguments

- path:

  Character. Path to a Parquet file.

- time_col:

  Name of the time column. Auto-detected when `NULL`.

- value_cols:

  Character vector of value column names. Auto-detected when `NULL`.

- group_col:

  Name of the grouping column for multi-series data. `NULL` for single
  series.

- frequency:

  Frequency label (`"monthly"`, `"quarterly"`, etc.) or a numeric value.
  Auto-detected from the time index when `NULL`.

- ...:

  Additional arguments forwarded to
  [`arrow::read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.html).

## Value

A `MiltSeries` object.

## See also

[`milt_write_parquet()`](https://ntiGideon.github.io/milt/reference/milt_write_parquet.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntiGideon.github.io/milt/reference/milt_add_datetime_component.md),
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
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntiGideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntiGideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)
