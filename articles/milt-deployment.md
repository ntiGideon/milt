# Deploying milt Models

``` r
library(milt)
```

## Overview

Once a model is trained it can be: 1. **Saved to disk** with
[`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md)
and restored with
[`milt_load()`](https://ntiGideon.github.io/milt/reference/milt_load.md).
2. **Served as a REST API** with
[`milt_serve()`](https://ntiGideon.github.io/milt/reference/milt_serve.md)
(Plumber). 3. **Explored in a dashboard** with
[`milt_dashboard()`](https://ntiGideon.github.io/milt/reference/milt_dashboard.md)
(Shiny). 4. **Included in a report** with
[`milt_report()`](https://ntiGideon.github.io/milt/reference/milt_report.md)
(R Markdown / Quarto).

------------------------------------------------------------------------

## 1. Save and load

``` r
air <- milt_series(AirPassengers)
m   <- milt_model("ets") |> milt_fit(air)

# Save
path <- milt_save(m, "my_ets_model")   # writes my_ets_model.milt
cat("Saved to:", path, "\n")

# Load later
m2 <- milt_load("my_ets_model.milt")
fct <- milt_forecast(m2, 12)
plot(fct)
```

Any milt object can be saved: `MiltSeries`, `MiltForecast`,
`MiltAnomalies`, detectors, etc.

------------------------------------------------------------------------

## 2. REST API with Plumber

[`milt_serve()`](https://ntiGideon.github.io/milt/reference/milt_serve.md)
wraps the model in a Plumber API that exposes:

| Endpoint       | Method | Description                                         |
|----------------|--------|-----------------------------------------------------|
| `/health`      | GET    | Version + model name                                |
| `/series_info` | GET    | Training series metadata                            |
| `/forecast`    | POST   | Accepts `{"horizon": <int>}`, returns JSON forecast |

``` r
# Launch (blocking — runs until interrupted)
milt_serve(m, host = "127.0.0.1", port = 8000)

# Non-blocking: get the router object without starting
router <- milt_serve(m, launch = FALSE)
```

Test with curl:

``` bash
curl -s http://127.0.0.1:8000/health
curl -s -X POST http://127.0.0.1:8000/forecast \
     -H "Content-Type: application/json" \
     -d '{"horizon": 12}'
```

------------------------------------------------------------------------

## 3. Shiny monitoring dashboard

[`milt_dashboard()`](https://ntiGideon.github.io/milt/reference/milt_dashboard.md)
launches an interactive four-tab app:

- **Series** — interactive line chart of training data.
- **Forecast** — adjustable horizon slider with PI fan chart.
- **Diagnostics** — residuals, ACF plot, and histogram.
- **Anomalies** — IQR anomaly overlay with adjustable multiplier.

``` r
milt_dashboard(m)
```

------------------------------------------------------------------------

## 4. Automated reports

[`milt_report()`](https://ntiGideon.github.io/milt/reference/milt_report.md)
renders a self-contained HTML or PDF analysis report:

``` r
# HTML (default)
path <- milt_report(
  series  = air,
  models  = list(ets = m),
  horizon = 24
)
cat("Report at:", path, "\n")

# PDF
milt_report(air, output_format = "pdf", output_file = "air_report.pdf")
```

The report includes: - Series overview and plot - Diagnostic tests (ADF,
KPSS, seasonality) - EDA statistics - Forecast plots for each supplied
model - Anomaly detection overview

------------------------------------------------------------------------

## 5. Model versioning

Save checkpoints at each refit:

``` r
# After initial training
milt_save(m, "model_v1")

# After refit on new data
new_data <- milt_series(AirPassengers)
m_v2     <- milt_refit(m, new_data)
milt_save(m_v2, "model_v2")

# Load the best version
best <- milt_load("model_v1.milt")
```
