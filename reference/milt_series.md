# Create a MiltSeries object

The main entry point for constructing time series objects in milt.
Accepts a wide variety of input formats and returns a consistent
`MiltSeries`.

## Usage

``` r
milt_series(
  x,
  time_col = NULL,
  value_cols = NULL,
  group_col = NULL,
  frequency = NULL,
  start = c(1L, 1L),
  value_col = NULL,
  ...
)
```

## Arguments

- x:

  Input data. One of:

  - A `ts` or `mts` object

  - An `xts` object

  - A `zoo` object

  - A `tsibble`

  - A `data.frame`, `tibble`, or `data.table`

  - A numeric vector (requires `frequency` and `start`)

- time_col:

  Name of the time column when `x` is a data frame or tibble.
  Auto-detected when `NULL`.

- value_cols:

  Character vector of value column names. Auto-detected when `NULL` (all
  non-time, non-group columns).

- group_col:

  Name of the grouping column for multi-series data frames. `NULL` for
  single series. When `x` is a keyed `data.table` and `group_col` is not
  supplied, the first key column is used.

- frequency:

  Frequency label (`"monthly"`, `"quarterly"`, `"daily"`, etc.) or a
  numeric value. Auto-detected from the time index when `NULL`.

- start:

  For numeric vector input only: a length-2 integer vector
  `c(year, period)`, matching the convention of
  [`stats::ts()`](https://rdrr.io/r/stats/ts.html).

- value_col:

  Convenience alias for `value_cols` when creating a single-component
  series.

- ...:

  Additional arguments passed to underlying conversion methods.

## Value

A `MiltSeries` object.

## See also

[`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md),
[`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md),
[`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md),
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
[`milt_plot_acf()`](https://ntigideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_read_parquet()`](https://ntigideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntigideon.github.io/milt/reference/milt_resample.md),
[`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntigideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntigideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntigideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntigideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
# From a base R ts object
s <- milt_series(AirPassengers)
print(s)
#> # A MiltSeries: 144 x 1 [monthly]
#> # Time range : 1949 Jan — 1960 Dec
#> # Components : value
#> # Gaps       : none
#> # A tibble: 6 × 2
#>   time       value
#>   <date>     <dbl>
#> 1 1949-01-01   112
#> 2 1949-02-01   118
#> 3 1949-03-01   132
#> 4 1949-04-01   129
#> 5 1949-05-01   121
#> 6 1949-06-01   135
#> # … with 138 more rows

# From a data.frame
df <- data.frame(
  date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
  sales = cumsum(rnorm(24, 100, 10))
)
s2 <- milt_series(df, time_col = "date", value_cols = "sales")

# From a numeric vector
s3 <- milt_series(as.numeric(AirPassengers), frequency = 12,
                  start = c(1949, 1))

# From a data.table (grouping column auto-detected from the table's key)
dt <- data.table::data.table(
  date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
  sales = cumsum(rnorm(24, 100, 10))
)
s4 <- milt_series(dt, time_col = "date", value_cols = "sales")
```
