# Coerce a MiltBacktest to a tibble

Returns the per-fold metric tibble.

## Usage

``` r
# S3 method for class 'MiltBacktest'
as_tibble(x, ...)
```

## Arguments

- x:

  A `MiltBacktest` object.

- ...:

  Ignored.

## Value

A `tibble` with columns `.fold`, `.train_n`, `.test_n`, and one column
per requested metric.
