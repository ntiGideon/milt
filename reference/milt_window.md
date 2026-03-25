# Subset a MiltSeries to a time window

Returns only observations within `[start, end]` (both inclusive). Either
bound may be `NULL` to impose no limit on that side.

## Usage

``` r
milt_window(series, start = NULL, end = NULL, group = NULL)
```

## Arguments

- series:

  A `MiltSeries` object.

- start:

  Start of the window (`Date`, `POSIXct`, or `NULL`).

- end:

  End of the window (`Date`, `POSIXct`, or `NULL`).

- group:

  Optional group value for grouped series. When supplied, only
  observations from that group are retained before applying the time
  window.

## Value

A `MiltSeries` containing only the windowed observations.

## See also

[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md)

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
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s <- milt_series(AirPassengers)
milt_window(s, start = as.Date("1953-01-01"), end = as.Date("1956-12-01"))
#> # A MiltSeries: 48 x 1 [monthly]
#> # Time range : 1953 Jan — 1956 Dec
#> # Components : value
#> # Gaps       : none
#> # A tibble: 6 × 2
#>   time       value
#>   <date>     <dbl>
#> 1 1953-01-01   196
#> 2 1953-02-01   196
#> 3 1953-03-01   236
#> 4 1953-04-01   235
#> 5 1953-05-01   229
#> 6 1953-06-01   243
#> # … with 42 more rows
```
