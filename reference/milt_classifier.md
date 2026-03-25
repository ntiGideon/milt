# Create a time series classifier

Returns an unfitted `MiltClassifier`. Train it with
[`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md).

## Usage

``` r
milt_classifier(method = "feature_based", n_trees = 100L, n_kernels = 10L, ...)
```

## Arguments

- method:

  Character. Classification method:

  - `"feature_based"` (default) — statistical features + random forest.

  - `"rocket"` — random convolutional kernel transform + random forest.

- n_trees:

  Integer. Number of trees (random forest). Default `100L`.

- n_kernels:

  Integer. Number of ROCKET kernels (only for `"rocket"`). Default
  `10L`.

- ...:

  Additional arguments (unused).

## Value

A `MiltClassifier` object.

## See also

[`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md),
[`milt_classify_predict()`](https://ntiGideon.github.io/milt/reference/milt_classify_predict.md)

Other classify:
[`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md),
[`milt_classify_predict()`](https://ntiGideon.github.io/milt/reference/milt_classify_predict.md)

## Examples

``` r
clf <- milt_classifier("feature_based")
```
