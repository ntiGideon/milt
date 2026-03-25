# Explain a fitted ML time series model

Extracts feature importance (and optionally SHAP values for XGBoost)
from a fitted ML-backed `MiltModel`. Supported backends: `"xgboost"`,
`"random_forest"`, `"elastic_net"`, and `"lightgbm"`.

## Usage

``` r
milt_explain(model, series = NULL, ...)
```

## Arguments

- model:

  A fitted `MiltModel` (must have been fit with
  [`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)).

- series:

  Optional `MiltSeries` object. When provided, the series is used to
  compute the design matrix for SHAP value calculation (XGBoost only).
  If omitted the training data stored in the model is used.

- ...:

  Additional arguments (currently unused).

## Value

A `MiltExplanation` object.

## See also

[`milt_model()`](https://ntiGideon.github.io/milt/reference/milt_model.md),
[`milt_fit()`](https://ntiGideon.github.io/milt/reference/milt_fit.md)

## Examples

``` r
# \donttest{
s   <- milt_series(AirPassengers)
m   <- milt_model("xgboost") |> milt_fit(s)
#> Fitting <MiltXGBoost> model…
#> Done in 0.76s.
exp <- milt_explain(m)
plot(exp)

# }
```
