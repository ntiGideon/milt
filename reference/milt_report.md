# Generate an analysis report

Renders a self-contained HTML or PDF report covering series diagnostics,
model forecasts, and anomaly detection. Requires `rmarkdown` (and
`tinytex` for PDF output).

## Usage

``` r
milt_report(
  series,
  models = NULL,
  horizon = 12L,
  output_format = "html",
  output_file = NULL,
  open = TRUE,
  ...
)
```

## Arguments

- series:

  A `MiltSeries` object.

- models:

  Optional named list of fitted `MiltModel` objects. Each model will be
  forecasted and plotted in the report.

- horizon:

  Integer. Forecast horizon shown in the report. Default `12L`.

- output_format:

  Character. `"html"` (default) or `"pdf"`.

- output_file:

  Character. Output file path. Default is a temp file.

- open:

  Logical. Open the rendered file after generation? Default `TRUE`.

- ...:

  Additional arguments forwarded to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

## Value

The path to the rendered report (invisibly).

## See also

[`milt_eda()`](https://ntiGideon.github.io/milt/reference/milt_eda.md),
[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
# milt_report(s)
# }
```
