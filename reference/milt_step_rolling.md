# Add rolling-window summary features to a MiltSeries

For each combination of `windows` and `fns`, appends one column named
`.rolling_<fn>_<window>` to the series tibble. The first
`max(windows) - 1` rows (where the window is incomplete) are dropped.

## Usage

``` r
milt_step_rolling(series, windows = c(7L, 14L, 30L), fns = c("mean", "sd"))
```

## Arguments

- series:

  A univariate `MiltSeries`.

- windows:

  Integer vector of window sizes (in number of observations). Default
  `c(7L, 14L, 30L)`.

- fns:

  Character vector of summary functions to apply within each window.
  Supported: `"mean"`, `"sd"`, `"median"`, `"min"`, `"max"`, `"sum"`.
  Default `c("mean", "sd")`.

## Value

An augmented `MiltSeries` with additional rolling-feature columns and
`max(windows) - 1` fewer rows. Attribute `"milt_step_rolling"` stores
the step specification.

## See also

[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md)

Other features:
[`milt_step_calendar()`](https://ntiGideon.github.io/milt/reference/milt_step_calendar.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s     <- milt_series(AirPassengers)
s_rol <- milt_step_rolling(s, windows = c(3L, 6L), fns = "mean")
head(s_rol$as_tibble())
#> # A tibble: 6 × 4
#>   time       value .rolling_mean_3 .rolling_mean_6
#>   <date>     <dbl>           <dbl>           <dbl>
#> 1 1949-06-01   135            128.            124.
#> 2 1949-07-01   148            135.            130.
#> 3 1949-08-01   148            144.            136.
#> 4 1949-09-01   136            144             136.
#> 5 1949-10-01   119            134.            134.
#> 6 1949-11-01   104            120.            132.
```
