# Arithmetic operators for MiltSeries

Supports `+`, `-`, `*`, `/`, and `^` between two `MiltSeries` objects
(which must share an identical time index and value columns) or between
a `MiltSeries` and a numeric scalar/vector.

## Usage

``` r
# S3 method for class 'MiltSeries'
Ops(e1, e2)
```

## Arguments

- e1, e2:

  A `MiltSeries` and/or a numeric value.

## Value

A `MiltSeries` with the operation applied element-wise to every value
column.

## Examples

``` r
s  <- milt_series(AirPassengers)
s2 <- s * 1.05          # a 5% bump
s3 <- s2 - s            # the (constant, up to rounding) absolute bump
```
