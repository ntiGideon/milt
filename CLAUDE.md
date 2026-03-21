# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**milt** (Modern Integrated Library for Timeseries) is a CRAN-ready R package providing a unified API for time series forecasting, anomaly detection, classification, and clustering in R. Think Python's Darts/sktime, but natively in R with a tidyverse-friendly API.

- Function prefix: `milt_`
- Class prefix: `Milt` (e.g., `MiltSeries`, `MiltModel`, `MiltForecast`)
- Requires R >= 4.1.0 (native pipe `|>` support)
- Uses `renv` for dependency management

## Common Commands

All commands are run from within R (or RStudio terminal):

```r
# Load all package code (primary dev workflow)
devtools::load_all()

# Regenerate NAMESPACE and man/ from roxygen2 docs
devtools::document()

# Run full R CMD check (CRAN compliance)
devtools::check()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-MiltSeries.R")

# Install package locally
devtools::install()
```

## Architecture

The package follows a strict 4-layer architecture:

```
Layer 1: User-facing API     — S3 generics + exported functions
Layer 2: Core Engine         — R6 classes (MiltSeriesR6, ModelRegistry, etc.)
Layer 3: Model Backends      — Isolated adapter files (one backend per file)
Layer 4: Data Layer          — tsibble, arrow, data.table integration
```

**Key design rule — S3 outside, R6 inside:** Users interact only via S3 generics (`print`, `plot`, `summary`). R6 classes manage internal state. Users should never call `$methods()` directly.

### Core Classes (build in this order)

1. **`MiltSeriesR6`** (`R/MiltSeries.R`) — the foundational data class; everything else depends on it. Wraps a tibble with a time column, value column(s), frequency, and optional covariates.
2. **`MiltForecast`** (`R/MiltForecast.R`) — result of `milt_forecast()`
3. **`MiltAnomalies`** (`R/MiltAnomalies.R`) — result of `milt_detect()`

### Universal Model Interface

Every model (classical, ML, deep learning) follows the same pattern:
```r
milt_model("auto_arima") |> milt_fit(series) |> milt_forecast(h = 12)
```

Model backends live in isolated files (`R/backend-*.R`). Adding a new model requires only creating one backend file and registering it — no changes to core code.

### Dependency Strategy

- **Imports** (always available): `R6`, `rlang`, `cli`, `glue`, `vctrs`, `tibble`, `dplyr`, `tidyr`, `lubridate`, `tsibble`, `ggplot2`, `data.table`
- **Suggests** (lazy-loaded on demand): `forecast`, `fable`, `prophet`, `xgboost`, `lightgbm`, `torch`, `ranger`, `glmnet`, `shiny`, `plumber`, etc.

Use `rlang::check_installed()` (via the internal `check_installed_backend()` helper) to load Suggests packages with a helpful error message if missing.

## Coding Standards

- **All user-facing messages** use the `cli` package: `milt_info()`, `milt_warn()`, `milt_abort()` (from `R/utils-cli.R`). Use inline markup: `{.var x}`, `{.fn milt_fit}`, `{.val 12}`.
- **Every exported function** must have roxygen2 docs with description, all params, `@return`, at least one `@examples` block, and `@seealso` cross-references.
- **Pipe-friendly:** every user-facing function takes data/object as its **first argument** and returns something pipeable.
- **Fail loudly:** errors must say WHAT went wrong and HOW to fix it.
- **Tests:** testthat edition 3 (`Config/testthat/edition: 3`). One test file per source file (`tests/testthat/test-<source-name>.R`).
