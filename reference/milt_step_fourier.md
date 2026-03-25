# Add Fourier-term features to a MiltSeries

Appends `2 * K` columns of sine and cosine terms at harmonics
`k = 1, 2, ..., K` of the given seasonal `period`. No rows are dropped
(all terms are defined for every time step).

## Usage

``` r
milt_step_fourier(series, period = NULL, K = 4L)
```

## Arguments

- series:

  A `MiltSeries`.

- period:

  Positive number. The seasonal period in units of the series frequency
  (e.g. `12` for annual seasonality in monthly data, `7` for weekly
  seasonality in daily data). Defaults to the series frequency when
  `NULL`.

- K:

  Positive integer. Number of Fourier pairs (harmonics) to include.
  Higher `K` captures more complex seasonal shapes. Must satisfy
  `K <= floor(period / 2)`. Default `4L`.

## Value

An augmented `MiltSeries` with columns `.fourier_sin_1`,
`.fourier_cos_1`, ..., `.fourier_sin_K`, `.fourier_cos_K` appended.
Attribute `"milt_step_fourier"` stores the step specification.

## Details

Fourier features are a compact, continuous representation of seasonality
and are particularly useful for ML and DL models that cannot natively
model seasonal patterns.

## See also

[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md)

Other features:
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s     <- milt_series(AirPassengers)
s_fft <- milt_step_fourier(s, period = 12, K = 2)
head(s_fft$as_tibble())
#> # A tibble: 6 × 6
#>   time       value .fourier_sin_1 .fourier_cos_1 .fourier_sin_2 .fourier_cos_2
#>   <date>     <dbl>          <dbl>          <dbl>          <dbl>          <dbl>
#> 1 1949-01-01   112       5   e- 1       8.66e- 1       8.66e- 1          0.5  
#> 2 1949-02-01   118       8.66e- 1       5   e- 1       8.66e- 1         -0.5  
#> 3 1949-03-01   132       1   e+ 0       6.12e-17       1.22e-16         -1    
#> 4 1949-04-01   129       8.66e- 1      -5   e- 1      -8.66e- 1         -0.500
#> 5 1949-05-01   121       5   e- 1      -8.66e- 1      -8.66e- 1          0.5  
#> 6 1949-06-01   135       1.22e-16      -1   e+ 0      -2.45e-16          1    
```
