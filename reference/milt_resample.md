# Change the temporal resolution of a MiltSeries

Aggregates the series to a lower frequency by applying `agg_fn` within
each period bucket.

## Usage

``` r
milt_resample(series, period, agg_fn = mean)
```

## Arguments

- series:

  A `MiltSeries` object.

- period:

  Target period as a string: `"daily"`, `"weekly"`, `"monthly"`,
  `"quarterly"`, or `"annual"`.

- agg_fn:

  Aggregation function. Default `mean`. Must accept a numeric vector and
  return a scalar (e.g., `sum`, `median`, `max`).

## Value

A `MiltSeries` at the new frequency.

## See also

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_get_covariates()`](https://ntiGideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntiGideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
# Already monthly — upsample not supported, but annual works
milt_resample(s, "annual", sum)
#> # A MiltSeries: 12 x 1 [annual]
#> # Time range : 1949 — 1960
#> # Components : value
#> # Gaps       : none
#> # A tibble: 6 × 2
#>   time       value
#>   <date>     <dbl>
#> 1 1949-01-01  1520
#> 2 1950-01-01  1676
#> 3 1951-01-01  2042
#> 4 1952-01-01  2364
#> 5 1953-01-01  2700
#> 6 1954-01-01  2867
#> # … with 6 more rows
# }
```
