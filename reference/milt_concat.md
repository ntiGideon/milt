# Concatenate MiltSeries objects along the time axis

Binds two or more `MiltSeries` objects that share the same columns and
frequency into a single series. Rows are sorted by time after binding.

## Usage

``` r
milt_concat(...)
```

## Arguments

- ...:

  Two or more `MiltSeries` objects.

## Value

A `MiltSeries` spanning the union of all time points.

## See also

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntiGideon.github.io/milt/reference/milt_add_datetime_component.md),
[`milt_add_holidays()`](https://ntiGideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_check_seasonality()`](https://ntiGideon.github.io/milt/reference/milt_check_seasonality.md),
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
s      <- milt_series(AirPassengers)
splits <- milt_split(s)
s_back <- milt_concat(splits$train, splits$test)
```
