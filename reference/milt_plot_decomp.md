# Plot a simple STL-style decomposition of a MiltSeries

Decomposes the series into trend, seasonal, and remainder components
using [`stats::stl()`](https://rdrr.io/r/stats/stl.html) and plots each
panel.

## Usage

``` r
milt_plot_decomp(series, ...)
```

## Arguments

- series:

  A univariate `MiltSeries` object. Must have a numeric frequency \> 1.

- ...:

  Additional arguments passed to
  [`stats::stl()`](https://rdrr.io/r/stats/stl.html).

## Value

The `stl` decomposition object, invisibly.

## See also

[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
[`milt_concat()`](https://ntiGideon.github.io/milt/reference/milt_concat.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md),
[`milt_fill_gaps()`](https://ntiGideon.github.io/milt/reference/milt_fill_gaps.md),
[`milt_get_covariates()`](https://ntiGideon.github.io/milt/reference/milt_get_covariates.md),
[`milt_head()`](https://ntiGideon.github.io/milt/reference/milt_head.md),
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_resample()`](https://ntiGideon.github.io/milt/reference/milt_resample.md),
[`milt_series()`](https://ntiGideon.github.io/milt/reference/milt_series.md),
[`milt_split()`](https://ntiGideon.github.io/milt/reference/milt_split.md),
[`milt_split_at()`](https://ntiGideon.github.io/milt/reference/milt_split_at.md),
[`milt_tail()`](https://ntiGideon.github.io/milt/reference/milt_tail.md),
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md),
[`plot.MiltSeries()`](https://ntiGideon.github.io/milt/reference/plot.MiltSeries.md)
