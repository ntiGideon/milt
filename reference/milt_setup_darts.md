# Set up the Python Darts environment

Verifies that Python and the `darts` package are available via
`reticulate`. Optionally installs `darts` with `pip` when it is missing.
Call this once per session before using any `darts_*` model.

## Usage

``` r
milt_setup_darts(install = FALSE)
```

## Arguments

- install:

  Logical. When `TRUE`, attempts `reticulate::py_install("darts")` if
  the package is not found. Default `FALSE`.

## Value

Invisible `NULL`.

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`list_milt_models()`](https://ntiGideon.github.io/milt/reference/list_milt_models.md)

Other dl:
[`milt_torch_device()`](https://ntiGideon.github.io/milt/reference/milt_torch_device.md)

## Examples

``` r
# \donttest{
milt_setup_darts()                      # check only
#> Downloading uv...
#> Done!
#> Error in milt_setup_darts(): The Python darts package is not installed.
#> ℹ Run `milt_setup_darts(install = TRUE)` to install it automatically.
#> ℹ Or manually from a terminal: `pip install darts`
milt_setup_darts(install = TRUE)        # check + install if missing
#> Installing Python darts — this may take a few minutes …
#> Warning: An ephemeral virtual environment managed by 'reticulate' is currently in use.
#> To add more packages to your current session, call `py_require()` instead
#> of `py_install()`. Running:
#>   `py_require(c("darts"))`
#> darts installed successfully.
# }
```
