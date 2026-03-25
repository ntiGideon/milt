# Fit a time series classifier

Trains the classifier on a labelled set of time series.

## Usage

``` r
milt_classify_fit(classifier, series_list, labels)
```

## Arguments

- classifier:

  A `MiltClassifier` from
  [`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md).

- series_list:

  A list of `MiltSeries` objects (training set).

- labels:

  Character or factor vector of class labels, one per series.

## Value

The fitted `MiltClassifier` (invisibly, mutated in place).

## See also

[`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_predict()`](https://ntiGideon.github.io/milt/reference/milt_classify_predict.md)

Other classify:
[`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md),
[`milt_classify_predict()`](https://ntiGideon.github.io/milt/reference/milt_classify_predict.md)
