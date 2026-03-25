# Add covariates to a MiltSeries

Attaches external covariate data to a `MiltSeries`. Three types are
supported:

## Usage

``` r
milt_add_covariates(
  series,
  covariates,
  type,
  time_col = NULL,
  group_col = NULL
)
```

## Arguments

- series:

  A `MiltSeries` object.

- covariates:

  A data frame or tibble containing the covariate columns. For `"past"`
  and `"future"` types it must include a time column matching
  `time_col`. For `"static"` it must include a column matching
  `group_col`.

- type:

  One of `"past"`, `"future"`, or `"static"`.

- time_col:

  Name of the time column in `covariates`. Defaults to the same time
  column name as the series.

- group_col:

  Name of the group column in `covariates` (static only). Defaults to
  the group column of the series.

## Value

The same `MiltSeries` with covariates stored internally. The underlying
data tibble is **not** modified; covariates are kept separate and
accessed by models via the private fields.

## Details

- **past**: time-varying covariates observed in the past (same time
  range as the series). Used for in-sample feature enrichment.

- **future**: time-varying covariates available beyond the series end
  (e.g., calendar, weather forecasts). Used by models to produce
  covariate-informed forecasts.

- **static**: scalar attributes per group that do not vary over time
  (e.g., store size, region). Only meaningful for multi-series.

## See also

[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md)

Other series:
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
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)

## Examples

``` r
s <- milt_series(AirPassengers)
dates <- s$as_tibble()$time
cov_df <- data.frame(time = dates, month_num = as.integer(format(dates, "%m")))
s2 <- milt_add_covariates(s, cov_df, type = "past", time_col = "time")
#> Added past covariates to <MiltSeries> (1 covariate column).
```
