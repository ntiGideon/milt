# Fill gaps in a MiltSeries

Identifies missing time steps, inserts rows with `NA` values for them,
then imputes using the chosen method.

## Usage

``` r
milt_fill_gaps(series, method = "linear")
```

## Arguments

- series:

  A `MiltSeries` object.

- method:

  Imputation method. One of:

  - `"linear"` — linear interpolation (default)

  - `"spline"` — cubic spline interpolation

  - `"locf"` — last observation carried forward

  - `"nocb"` — next observation carried backward

  - `"mean"` — column mean

  - `"zero"` — replace with 0

## Value

A `MiltSeries` with no gaps.

## See also

[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md),
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
# Artificially introduce a gap
tbl <- s$as_tibble()[-c(10, 11), ]
s_gap <- milt_series(tbl, time_col = "time", value_cols = "value",
                      frequency = "monthly")
s_filled <- milt_fill_gaps(s_gap, method = "linear")
```
