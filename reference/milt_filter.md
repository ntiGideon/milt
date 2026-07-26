# Apply a filtering model to smooth a MiltSeries

Filtering estimates the underlying signal from noisy observations at the
*same* timestamps as the input series — it does not forecast forward in
time. Use
[`milt_forecast()`](https://ntigideon.github.io/milt/reference/milt_forecast.md)
to predict future values instead.

## Usage

``` r
milt_filter(series, method = c("moving_average", "kalman", "gp"), ...)
```

## Arguments

- series:

  A univariate `MiltSeries` object.

- method:

  Character. One of `"moving_average"` (rolling-mean smoothing),
  `"kalman"` (state-space smoothing via
  [`stats::StructTS()`](https://rdrr.io/r/stats/StructTS.html)), or
  `"gp"` (Gaussian Process smoothing with an RBF kernel).

- ...:

  Additional arguments forwarded to the chosen filter:

  - `moving_average`: `window` (default `3L`), `centered` (default
    `TRUE`)

  - `kalman`: `type`, one of `"level"`, `"trend"`, `"BSM"` (default
    `"level"`)

  - `gp`: `length_scale` (default `n / 20`), `noise` (default
    `0.1 * sd(values)`)

## Value

A `MiltSeries` with the same time index and value column(s), containing
the filtered (smoothed) values.

## See also

[`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md)

Other series:
[`milt_add_covariates()`](https://ntigideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_add_datetime_component()`](https://ntigideon.github.io/milt/reference/milt_add_datetime_component.md),
[`milt_add_holidays()`](https://ntigideon.github.io/milt/reference/milt_add_holidays.md),
[`milt_check_seasonality()`](https://ntigideon.github.io/milt/reference/milt_check_seasonality.md),
[`milt_concat()`](https://ntigideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntigideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntigideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_get_covariates()`](https://ntigideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntigideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntigideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntigideon.github.io/milt/reference/milt_plot_decomp.md),
[`milt_read_parquet()`](https://ntigideon.github.io/milt/reference/milt_read_parquet.md),
[`milt_resample()`](https://ntigideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntigideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntigideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntigideon.github.io/milt/reference/milt_split_at.md),
[`milt_stack()`](https://ntigideon.github.io/milt/reference/milt_stack.md),
[`milt_tail()`](https://ntigideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntigideon.github.io/milt/reference/milt_window.md),
[`milt_write_parquet()`](https://ntigideon.github.io/milt/reference/milt_write_parquet.md),
[`plot.MiltSeries()`](https://ntigideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s   <- milt_series(AirPassengers)
sm1 <- milt_filter(s, "moving_average", window = 5L)
sm2 <- milt_filter(s, "kalman")
sm3 <- milt_filter(s, "gp")
```
