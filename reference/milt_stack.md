# Stack MiltSeries into one multivariate series

Combines two or more `MiltSeries` sharing an identical time index into a
single multivariate `MiltSeries`, placing each input's value column(s)
side by side as new components. Unlike
[`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md)
(which concatenates *rows*/time steps), stacking concatenates *columns*.

## Usage

``` r
milt_stack(...)
```

## Arguments

- ...:

  Two or more `MiltSeries` objects with identical time indices.

## Value

A multivariate `MiltSeries`. Value column names are taken as-is when
unique across inputs, and suffixed with the input's position (`_2`,
`_3`, ...) otherwise.

## See also

[`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md),
[`milt_add_datetime_component()`](https://ntigideon.github.io/milt/reference/milt_add_datetime_component.md)

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
[`milt_plot_acf()`](https://ntigideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_read_parquet()`](https://ntigideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntigideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntigideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntigideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntigideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntigideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
sma <- milt_filter(s, "moving_average", window = 12L)
stacked <- milt_stack(s, sma)   # components "value", "value_2"
stacked$n_components()
#> [1] 2
```
