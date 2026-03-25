# Install optional backend packages for milt

milt keeps heavy dependencies (Prophet, XGBoost, torch, …) in `Suggests`
so that installing milt itself is always fast and reliable. Call
`milt_install_backends()` to install whichever backend groups you need.

### Backend groups

|                   |                                                 |
|-------------------|-------------------------------------------------|
| Group             | Packages installed                              |
| `"forecasting"`   | forecast, prophet                               |
| `"ml"`            | xgboost, lightgbm, glmnet, ranger, e1071        |
| `"deep_learning"` | torch                                           |
| `"extras"`        | isotree, dbscan, dtw, CausalImpact, changepoint |
| `"reporting"`     | rmarkdown, shiny, plumber, jsonlite             |
| `"all"`           | everything above                                |

You can also pass individual package names directly (e.g.
`milt_install_backends("prophet")`).

### torch / GPU note

After installing the `"deep_learning"` group (or `"torch"` directly),
run
[`torch::install_torch()`](https://torch.mlverse.org/docs/reference/install_torch.html)
once to download the Lantern runtime.

## Usage

``` r
milt_install_backends(backends = "all", upgrade = FALSE, quiet = FALSE)
```

## Arguments

- backends:

  Character vector of group name(s) or package name(s) to install. Use
  `"all"` (default) to install every optional backend.

- upgrade:

  Logical. If `TRUE`, upgrade packages that are already installed to
  their latest CRAN version. Default `FALSE`.

- quiet:

  Logical. Suppress per-package install output. Default `FALSE`.

## Value

Invisibly returns a named logical vector indicating which packages were
newly installed (`TRUE`) vs already present (`FALSE`).

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md),
[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Install everything
milt_install_backends()

# Just the classical forecasting backends
milt_install_backends("forecasting")

# Just prophet
milt_install_backends("prophet")

# ML + deep learning together
milt_install_backends(c("ml", "deep_learning"))
} # }
```
