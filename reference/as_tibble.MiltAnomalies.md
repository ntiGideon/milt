# Convert MiltAnomalies to tibble

Convert MiltAnomalies to tibble

## Usage

``` r
# S3 method for class 'MiltAnomalies'
as_tibble(x, ...)
```

## Arguments

- x:

  A `MiltAnomalies` object.

- ...:

  Ignored.

## Value

A
[`tibble::tibble()`](https://tibble.tidyverse.org/reference/tibble.html)
with columns `time`, `value`, `.is_anomaly`, `.anomaly_score`, and
compatibility aliases `is_anomaly`, `anomaly_score`.
