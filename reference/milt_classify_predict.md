# Predict class labels for new time series

Applies a fitted `MiltClassifier` to a list of new series.

## Usage

``` r
milt_classify_predict(classifier, series_list)
```

## Arguments

- classifier:

  A fitted `MiltClassifier`.

- series_list:

  A list of `MiltSeries` objects (test set).

## Value

A named list:

- `$labels` — character vector of predicted class labels.

- `$probabilities` — matrix of class probabilities (or `NULL`).

## See also

[`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md)

Other classify:
[`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_fit()`](https://ntiGideon.github.io/milt/reference/milt_classify_fit.md)

## Examples

``` r
# \donttest{
if (requireNamespace("ranger", quietly = TRUE)) {
  s1  <- milt_series(AirPassengers)
  s2  <- milt_series(AirPassengers * 1.2)
  clf <- milt_classifier("feature_based")
  milt_classify_fit(clf, list(s1, s2), labels = c("low", "high"))
  milt_classify_predict(clf, list(s1))
}
#> $labels
#> [1] "low"
#> 
#> $probabilities
#>      high  low
#> [1,] 0.47 0.53
#> 
# }
```
