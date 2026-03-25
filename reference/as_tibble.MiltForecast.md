# Convert a MiltForecast to a tibble

Convert a MiltForecast to a tibble

## Usage

``` r
# S3 method for class 'MiltForecast'
as_tibble(x, ...)
```

## Arguments

- x:

  A `MiltForecast` object.

- ...:

  Ignored.

## Value

A wide tibble with columns `time`, `.model`, `.mean`, and one pair of
`.lower_<level>` / `.upper_<level>` columns per confidence level.
