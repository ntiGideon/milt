# Coerce a MiltComparison to a tibble

Returns the ranked model summary tibble.

## Usage

``` r
# S3 method for class 'MiltComparison'
as_tibble(x, ...)
```

## Arguments

- x:

  A `MiltComparison` object.

- ...:

  Ignored.

## Value

A `tibble` with columns `model`, one column per metric mean, `rank`.
