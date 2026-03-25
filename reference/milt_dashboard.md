# Launch a Shiny monitoring dashboard

Opens an interactive dashboard for exploring a fitted model and its
training series. Requires the `shiny` package.

## Usage

``` r
milt_dashboard(model, series = NULL, port = NULL, launch_browser = TRUE)
```

## Arguments

- model:

  A fitted `MiltModel`.

- series:

  Optional `MiltSeries` to display; defaults to the training series
  stored in `model`.

- port:

  Integer. Shiny port. Default `NULL` (Shiny auto-selects).

- launch_browser:

  Logical. Open in browser? Default `TRUE`.

## Value

The Shiny app object (returned invisibly; the app blocks until the user
closes it).

## Details

The dashboard provides four tabs:

- **Series** - interactive line chart of the training data.

- **Forecast** - adjustable horizon slider with PI fan chart.

- **Diagnostics** - residuals, ACF, and histogram.

- **Anomalies** - IQR-based anomaly overlay.

## See also

[`milt_serve()`](https://ntiGideon.github.io/milt/reference/milt_serve.md)

Other deploy:
[`milt_serve()`](https://ntiGideon.github.io/milt/reference/milt_serve.md)

## Examples

``` r
# \donttest{
m <- milt_model("naive") |> milt_fit(milt_series(AirPassengers))
#> Fitting <MiltNaive> model…
#> Done in 0s.
# milt_dashboard(m)
# }
```
