# Automated report generation
#
# milt_report() renders an R Markdown / Quarto analysis report for a series
# and optional set of fitted models.  Output formats: "html" (default), "pdf".

#' Generate an analysis report
#'
#' Renders a self-contained HTML or PDF report covering series diagnostics,
#' model forecasts, and anomaly detection.  Requires `rmarkdown` (and
#' `tinytex` for PDF output).
#'
#' @param series A [MiltSeries] object.
#' @param models Optional named list of fitted [MiltModel] objects.  Each
#'   model will be forecasted and plotted in the report.
#' @param horizon Integer. Forecast horizon shown in the report. Default `12L`.
#' @param output_format Character. `"html"` (default) or `"pdf"`.
#' @param output_file Character. Output file path.  Default is a temp file.
#' @param open Logical. Open the rendered file after generation? Default `TRUE`.
#' @param ... Additional arguments forwarded to [rmarkdown::render()].
#' @return The path to the rendered report (invisibly).
#' @seealso [milt_eda()], [milt_diagnose()]
#' @family report
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' # milt_report(s)
#' }
#' @export
milt_report <- function(series,
                         models        = NULL,
                         horizon       = 12L,
                         output_format = "html",
                         output_file   = NULL,
                         open          = TRUE,
                         ...) {
  check_installed_backend("rmarkdown", "milt_report")
  assert_milt_series(series)

  output_format <- match.arg(output_format, c("html", "pdf"))

  if (is.null(output_file)) {
    ext         <- if (output_format == "html") ".html" else ".pdf"
    output_file <- tempfile(fileext = ext)
  }

  # ── Write the Rmd template to a temp file ─────────────────────────────────
  rmd_file <- tempfile(fileext = ".Rmd")

  rmd_content <- .build_report_rmd(series, models, horizon, output_format)
  writeLines(rmd_content, rmd_file)

  # ── Render ─────────────────────────────────────────────────────────────────
  # Pass objects into the knit environment
  knit_env <- new.env(parent = globalenv())
  knit_env$.milt_report_series  <- series
  knit_env$.milt_report_models  <- models
  knit_env$.milt_report_horizon <- as.integer(horizon)

  out_fmt <- if (output_format == "html") {
    rmarkdown::html_document(self_contained = TRUE, toc = TRUE)
  } else {
    rmarkdown::pdf_document(toc = TRUE)
  }

  rendered <- tryCatch(
    rmarkdown::render(
      input         = rmd_file,
      output_format = out_fmt,
      output_file   = output_file,
      envir         = knit_env,
      quiet         = TRUE,
      ...
    ),
    error = function(e) {
      milt_abort(
        c("Report rendering failed.", "x" = conditionMessage(e)),
        class = "milt_error_report"
      )
    }
  )

  milt_info("Report written to {.file {rendered}}.")

  if (open && interactive()) {
    utils::browseURL(rendered)
  }

  invisible(rendered)
}

# ── Internal: build the Rmd template string ───────────────────────────────────

.build_report_rmd <- function(series, models, horizon, output_format) {
  has_models <- !is.null(models) && length(models) > 0L

  header <- glue::glue('---
title: "milt Analysis Report"
date: "`r Sys.Date()`"
output:
  {if (output_format == "html") "html_document" else "pdf_document"}:
    toc: true
---

```{{r setup, include=FALSE}}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE,
                      fig.width = 8, fig.height = 4)
library(milt)
series  <- .milt_report_series
models  <- .milt_report_models
horizon <- .milt_report_horizon
```

## Series Overview

```{{r series-overview}}
print(series)
```

```{{r series-plot}}
plot(series)
```

## Diagnostics

```{{r diagnostics}}
tryCatch({{
  d <- milt_diagnose(series)
  print(d)
  plot(d)
}}, error = function(e) cat("Diagnostics unavailable:", conditionMessage(e)))
```

## EDA

```{{r eda}}
tryCatch({{
  e <- milt_eda(series)
}}, error = function(e) cat("EDA unavailable:", conditionMessage(e)))
```')

  model_section <- if (has_models) {
    '## Forecasts

```{r forecasts, results="asis"}
for (nm in names(models)) {
  cat("\\n### Model:", nm, "\\n")
  tryCatch({
    fct <- milt_forecast(models[[nm]], horizon)
    print(plot(fct))
    tbl <- fct$as_tibble()
    print(knitr::kable(utils::head(tbl, 6),
                       caption = paste("First 6 forecast steps:", nm)))
  }, error = function(e) cat("Error:", conditionMessage(e), "\\n"))
}
```'
  } else {
    ""
  }

  anomaly_section <- '## Anomaly Detection

```{r anomalies}
tryCatch({
  d <- milt_detector("iqr")
  a <- milt_detect(d, series)
  print(a)
  plot(a)
}, error = function(e) cat("Anomaly detection unavailable:", conditionMessage(e)))
```'

  paste(c(header, model_section, anomaly_section), collapse = "\n\n")
}
