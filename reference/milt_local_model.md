# Create a local (per-group) model for multi-series forecasting

Wraps any milt model so that, when fitted on a multi-series
`MiltSeries`, one independent instance is trained per series group. The
result is a `MiltModel` that participates in the standard pipe:

## Usage

``` r
milt_local_model(model)
```

## Arguments

- model:

  An unfitted `MiltModel` created with
  [`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md).

## Value

An unfitted `MiltLocalModel`.

## Details

    milt_local_model(milt_model("ets")) |> milt_fit(multi_series) |>
      milt_forecast(12)

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)

Other model:
[`milt_backtest()`](https://ntiGideon.github.io/milt/reference/milt_backtest.md),
[`milt_compare()`](https://ntiGideon.github.io/milt/reference/milt_compare.md),
[`milt_cv()`](https://ntiGideon.github.io/milt/reference/milt_cv.md),
[`milt_ensemble()`](https://ntiGideon.github.io/milt/reference/milt_ensemble.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md),
[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_predict()`](https://ntiGideon.github.io/milt/reference/milt_predict.md),
[`milt_refit()`](https://ntiGideon.github.io/milt/reference/milt_refit.md),
[`milt_residuals()`](https://ntiGideon.github.io/milt/reference/milt_residuals.md)

## Examples

``` r
# \donttest{
# Single-series: behaves like the underlying model
s   <- milt_series(AirPassengers)
fct <- milt_local_model(milt_model("naive")) |>
  milt_fit(s) |>
  milt_forecast(12)
#> Fitting <MiltLocalModel> model…
#> Done in 0s.
print(fct)
#> # A MiltForecast <naive>: horizon = 12# Forecast from: 1960-12-01# Intervals    : 80, 95%#
#> # A tibble: 6 × 7
#>   time       .model .mean .lower_80 .upper_80 .lower_95 .upper_95
#>   <date>     <chr>  <dbl>     <dbl>     <dbl>     <dbl>     <dbl>
#> 1 1961-01-01 naive    432      389.      475.      366.      498.
#> 2 1961-02-01 naive    432      371.      493.      339.      525.
#> 3 1961-03-01 naive    432      357.      507.      318.      546.
#> 4 1961-04-01 naive    432      346.      518.      300.      564.
#> 5 1961-05-01 naive    432      335.      529.      284.      580.
#> 6 1961-06-01 naive    432      326.      538.      270.      594.
#> # … with 6 more rows
# }
```
