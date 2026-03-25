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
