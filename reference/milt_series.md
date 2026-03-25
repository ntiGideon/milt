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

  - A `data.frame` or `tibble`

  - A numeric vector (requires `frequency` and `start`)

- time_col:

  Name of the time column when `x` is a data frame or tibble.
  Auto-detected when `NULL`.

- value_cols:

  Character vector of value column names. Auto-detected when `NULL` (all
  non-time, non-group columns).

- group_col:

  Name of the grouping column for multi-series data frames. `NULL` for
  single series.

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

[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_get_covariates()`](https://ntiGideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntiGideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

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
```
