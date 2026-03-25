# AirPassengers as a milt-ready tibble

Monthly totals of international airline passengers (thousands), January
1949 to December 1960. This is the classic Box & Jenkins dataset
repackaged as a plain tibble so it can be passed directly to
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md).

## Usage

``` r
milt_air
```

## Format

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with 144 rows and 2 columns:

- date:

  `Date`. First day of each month.

- value:

  `numeric`. Total passengers (thousands).

## Source

Base R dataset
[`AirPassengers`](https://rdrr.io/r/datasets/AirPassengers.html). Box,
G. E. P., Jenkins, G. M., and Reinsel, G. C. (1976) *Time Series
Analysis, Forecasting and Control*, 3rd ed. Holden-Day. Series G.

## See also

[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[milt_retail](https://ntiGideon.github.io/milt/reference/milt_retail.md),
[milt_energy](https://ntiGideon.github.io/milt/reference/milt_energy.md)

Other datasets:
[`milt_energy`](https://ntiGideon.github.io/milt/reference/milt_energy.md),
[`milt_retail`](https://ntiGideon.github.io/milt/reference/milt_retail.md)

## Examples

``` r
# \donttest{
data(milt_air)
s <- milt_series(milt_air, time_col = "date", value_cols = "value",
                 frequency = "monthly")
s
#> # A MiltSeries: 144 x 1 [monthly]
#> # Time range : 1949 Jan — 1960 Dec
#> # Components : value
#> # Gaps       : none
#> # A tibble: 6 × 2
#>   date       value
#>   <date>     <dbl>
#> 1 1949-01-01   112
#> 2 1949-02-01   118
#> 3 1949-03-01   132
#> 4 1949-04-01   129
#> 5 1949-05-01   121
#> 6 1949-06-01   135
#> # … with 138 more rows
# }
```
