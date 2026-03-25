# Reconcile hierarchical time series forecasts

Adjusts a set of base forecasts so that they are coherent with a
user-supplied summing matrix `S`. Three methods are available:

## Usage

``` r
milt_reconcile(forecasts, S, method = "ols", residuals = NULL)
```

## Arguments

- forecasts:

  A named list of `MiltForecast` objects, one per node (both aggregate
  and bottom-level). All must share the same horizon.

- S:

  Integer/numeric matrix. Summing matrix with `nrow(S)` equal to the
  total number of series (length of `forecasts`) and `ncol(S)` equal to
  the number of bottom-level series.

- method:

  Character. Reconciliation method: `"ols"` (default), `"wls_struct"`,
  or `"mint_shrink"`.

- residuals:

  Optional named list of numeric vectors (in-sample residuals per
  series). Required for `"mint_shrink"`.

## Value

A `MiltReconciliation` object.

## Details

- `"ols"` — ordinary-least-squares reconciliation (equal weights).

- `"wls_struct"` — WLS with structural scaling (diagonal of
  `S %*% t(S)`).

- `"mint_shrink"` — MinT with shrinkage covariance estimate (requires
  the in-sample residuals supplied via `residuals`).

## See also

[`milt_forecast()`](https://ntiGideon.github.io/milt/reference/milt_forecast.md)

## Examples

``` r
# \donttest{
# Two-level hierarchy: Total = A + B
S <- matrix(c(1, 1, 1, 0, 0, 1), nrow = 3, ncol = 2,
            dimnames = list(c("Total", "A", "B"), c("A", "B")))
# (forecast each series first, then reconcile)
# }
```
