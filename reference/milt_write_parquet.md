# Write a MiltSeries to a Parquet file

Write a MiltSeries to a Parquet file

## Usage

``` r
milt_write_parquet(series, path, ...)
```

## Arguments

- series:

  A `MiltSeries` object.

- path:

  Character. Destination file path.

- ...:

  Additional arguments forwarded to
  [`arrow::write_parquet()`](https://arrow.apache.org/docs/r/reference/write_parquet.html).

## Value

`path` (invisibly).

## See also

[`milt_read_parquet()`](https://ntiGideon.github.io/milt/reference/milt_read_parquet.md)

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
[`milt_read_parquet()`](https://ntiGideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntiGideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
# \donttest{
if (requireNamespace("arrow", quietly = TRUE)) {
  s   <- milt_series(AirPassengers)
  tmp <- tempfile(fileext = ".parquet")
  milt_write_parquet(s, tmp)
  s2  <- milt_read_parquet(tmp, time_col = "time", value_cols = "value",
                            frequency = "monthly")
}
#> Wrote /tmp/RtmpfPZx0H/file1cf91dd6d6f4.parquet.
# }
```
