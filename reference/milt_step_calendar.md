# Add calendar features to a MiltSeries

Appends date/time decomposition columns (year, month, quarter, week,
day-of-week, weekend indicator, and sub-daily components as
appropriate). No rows are dropped: calendar features are defined for
every time step.

## Usage

``` r
milt_step_calendar(series, features = NULL)
```

## Arguments

- series:

  A `MiltSeries` with `Date` or `POSIXct` time index.

- features:

  Optional character vector of calendar feature names to keep. By
  default, all supported features for the series frequency are added.

## Value

An augmented `MiltSeries` with calendar columns appended. Attribute
`"milt_step_calendar"` stores the step specification.

## Details

The set of columns added adapts automatically to the series frequency:

|                            |                                                                       |
|----------------------------|-----------------------------------------------------------------------|
| Frequency                  | Columns added                                                         |
| monthly, quarterly, annual | `.year`, `.month`, `.quarter`, `.week`, `.day_of_week`, `.is_weekend` |
| daily                      | \+ `.day_of_month`                                                    |
| hourly                     | \+ `.hour`                                                            |
| minutely                   | \+ `.minute`                                                          |

## See also

[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md)

Other features:
[`milt_step_fourier()`](https://ntiGideon.github.io/milt/reference/milt_step_fourier.md),
[`milt_step_lag()`](https://ntiGideon.github.io/milt/reference/milt_step_lag.md),
[`milt_step_rolling()`](https://ntiGideon.github.io/milt/reference/milt_step_rolling.md),
[`milt_step_scale()`](https://ntiGideon.github.io/milt/reference/milt_step_scale.md),
[`milt_step_unscale()`](https://ntiGideon.github.io/milt/reference/milt_step_unscale.md)

## Examples

``` r
s <- milt_series(AirPassengers)
s_cal <- milt_step_calendar(s)
head(s_cal$as_tibble())
#> # A tibble: 6 × 8
#>   time       value .year .month .quarter .week .day_of_week .is_weekend
#>   <date>     <dbl> <int>  <int>    <int> <int>        <int>       <int>
#> 1 1949-01-01   112  1949      1        1    53            6           1
#> 2 1949-02-01   118  1949      2        1     5            2           0
#> 3 1949-03-01   132  1949      3        1     9            2           0
#> 4 1949-04-01   129  1949      4        2    13            5           0
#> 5 1949-05-01   121  1949      5        2    17            7           1
#> 6 1949-06-01   135  1949      6        2    22            3           0
```
