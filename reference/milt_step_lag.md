# Add lag features to a MiltSeries

Appends one column per lag value to the series tibble. Rows where any
lag column is `NA` (the first `max(lags)` rows) are dropped. The
original value column is retained unchanged.

## Usage

``` r
milt_step_lag(series, lags = 1:12)
```

## Arguments

- series:

  A univariate `MiltSeries`.

- lags:

  Integer vector of lag values. Default `1:12`.

## Value

An augmented `MiltSeries` with additional columns `.lag_1`, `.lag_2`, …
(one per element of `lags`) and `max(lags)` fewer rows. The attribute
`"milt_step_lag"` stores the step specification.

## Details

The returned `MiltSeries` carries a `"milt_step_lag"` attribute that
records which lags were used and the last `max(lags)` training values
needed to generate lag features for future observations.

## See also

[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md)

Other features:
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s      <- milt_series(AirPassengers)
s_lag  <- milt_step_lag(s, lags = 1:3)
head(s_lag$as_tibble())
#> # A tibble: 6 × 5
#>   time       value .lag_1 .lag_2 .lag_3
#>   <date>     <dbl>  <dbl>  <dbl>  <dbl>
#> 1 1949-04-01   129    132    118    112
#> 2 1949-05-01   121    129    132    118
#> 3 1949-06-01   135    121    129    132
#> 4 1949-07-01   148    135    121    129
#> 5 1949-08-01   148    148    135    121
#> 6 1949-09-01   136    148    148    135
```
