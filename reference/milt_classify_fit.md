# Fit a time series classifier

Trains the classifier on a labelled set of time series.

## Usage

``` r
milt_classify_fit(classifier, series_list, labels)
```

## Arguments

- classifier:

  A `MiltClassifier` from
  [`milt_classifier()`](https://ntigideon.github.io/milt/reference/milt_classifier.md).

- series_list:

  A list of `MiltSeries` objects (training set).

- labels:

  Character or factor vector of class labels, one per series.

## Value

The fitted `MiltClassifier` (invisibly, mutated in place).

## See also

[`milt_classifier()`](https://ntigideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_predict()`](https://ntigideon.github.io/milt/reference/milt_classify_predict.md)

Other classify:
[`milt_classifier()`](https://ntigideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_predict()`](https://ntigideon.github.io/milt/reference/milt_classify_predict.md)

## Examples

``` r
# \donttest{
if (requireNamespace("ranger", quietly = TRUE)) {
  s1  <- milt_series(AirPassengers)
  s2  <- milt_series(AirPassengers * 1.2)
  clf <- milt_classifier("feature_based")
  milt_classify_fit(clf, list(s1, s2), labels = c("low", "high"))
}
# }
```
