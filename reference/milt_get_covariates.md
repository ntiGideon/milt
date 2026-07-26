# Retrieve covariates attached to a MiltSeries

Retrieve covariates attached to a MiltSeries

## Usage

``` r
milt_get_covariates(series, type = "past")
```

## Arguments

- series:

  A `MiltSeries` object.

- type:

  One of `"past"`, `"future"`, or `"static"`. Default `"past"`.

## Value

A tibble of covariates, or `NULL` if none have been attached.

## See also

Other series:
[`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntigideon.github.io/milt/reference/milt_add_datetime_component.md),
[`milt_add_holidays()`](https://ntigideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_check_seasonality()`](https://ntigideon.github.io/milt/reference/milt_check_seasonality.md),
[`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntigideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_filter()`](https://ntigideon.github.io/milt/reference/milt_filter.md),
[`milt_head()`](https://ntigideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntigideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_read_parquet()`](https://ntigideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntigideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntigideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntigideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntigideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntigideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntigideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)
