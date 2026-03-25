# Plot a MiltForecast

Renders the point forecast with optional prediction interval ribbons. If
the forecast was produced by
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)
(which stores the training series), the historical data is shown to the
left.

## Usage

``` r
# S3 method for class 'MiltForecast'
plot(x, history = 50L, title = NULL, ...)
```

## Arguments

- x:

  A `MiltForecast` object.

- history:

  Number of historical observations to display alongside the forecast.
  `NULL` shows all available history.

- title:

  Optional plot title.

- ...:

  Ignored.

## Value

A `ggplot` object, invisibly.
