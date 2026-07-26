# Convert a MiltForecast to a data.table

Convert a MiltForecast to a data.table

## Usage

``` r
# S3 method for class 'MiltForecast'
as.data.table(x, ...)
```

## Arguments

- x:

  A `MiltForecast` object.

- ...:

  Ignored.

## Value

A
[`data.table::data.table()`](https://rdrr.io/pkg/data.table/man/data.table.html)
with the same columns as
[`as_tibble.MiltForecast()`](https://ntiGideon.github.io/milt/reference/as_tibble.MiltForecast.md).
