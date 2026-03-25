# Plot a MiltSeries

Produces a ggplot2 line chart of the series values over time.
Automatically facets for multi-series data and uses coloured lines for
multivariate series.

## Usage

``` r
# S3 method for class 'MiltSeries'
plot(x, title = NULL, color = "#2166AC", ...)

# S3 method for class 'MiltSeries'
autoplot(object, ...)
```

## Arguments

- x:

  A `MiltSeries` object.

- title:

  Optional plot title. Defaults to `"MiltSeries [<freq>]"`.

- color:

  Single hex colour string used for univariate series.

- ...:

  Ignored.

- object:

  A `MiltSeries` object.

## Value

A `ggplot` object, invisibly.

## See also

`autoplot.MiltSeries()`,
[`milt_plot_acf()`](https://ntiGideon.github.io/milt/reference/milt_plot_acf.md),
[`milt_plot_decomp()`](https://ntiGideon.github.io/milt/reference/milt_plot_decomp.md)

Other series:
[`milt_add_covariates()`](https://ntiGideon.github.io/milt/reference/milt_add_covariates.md),
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
[`milt_window()`](https://ntiGideon.github.io/milt/reference/milt_window.md)
