# Split a MiltSeries into train and test sets

Splits by proportion of total observations. For multi-series, the split
ratio applies per group.

## Usage

``` r
milt_split(series, ratio = 0.8)
```

## Arguments

- series:

  A `MiltSeries` object.

- ratio:

  A number strictly between 0 and 1. The fraction of observations used
  for training. Default `0.8`.

## Value

A named list with elements `train` and `test`, each a `MiltSeries`.

## See also

[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md)

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
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s      <- milt_series(AirPassengers)
splits <- milt_split(s, ratio = 0.8)
splits$train
#> # A MiltSeries: 115 x 1 [monthly]
#> # Time range : 1949 Jan — 1958 Jul
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
#> # … with 109 more rows
splits$test
#> # A MiltSeries: 29 x 1 [monthly]
#> # Time range : 1958 Aug — 1960 Dec
#> # Components : value
#> # Gaps       : none
#> # A tibble: 6 × 2
#>   time       value
#>   <date>     <dbl>
#> 1 1958-08-01   505
#> 2 1958-09-01   404
#> 3 1958-10-01   359
#> 4 1958-11-01   310
#> 5 1958-12-01   337
#> 6 1959-01-01   360
#> # … with 23 more rows
```
