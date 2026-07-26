# Plot the ACF and PACF of a MiltSeries

Displays autocorrelation and partial autocorrelation side-by-side using
base R graphics.

## Usage

``` r
milt_plot_acf(series, lag.max = 36L, ...)
```

## Arguments

- series:

  A univariate `MiltSeries` object.

- lag.max:

  Maximum lag to compute. Default 36.

- ...:

  Additional arguments passed to
  [`stats::acf()`](https://rdrr.io/r/stats/acf.html).

## Value

Invisibly returns a list with `acf` and `pacf` objects.

## See also

[`milt_diagnose()`](https://ntigideon.github.io/milt/reference/milt_diagnose.md)

Other series:
[`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntigideon.github.io/milt/reference/milt_add_datetime_component.md),
[`milt_add_holidays()`](https://ntigideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_check_seasonality()`](https://ntigideon.github.io/milt/reference/milt_check_seasonality.md),
[`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntigideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_filter()`](https://ntigideon.github.io/milt/reference/milt_filter.md),
[`milt_get_covariates()`](https://ntigideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntigideon.github.io/milt/reference/milt_head.md),
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
