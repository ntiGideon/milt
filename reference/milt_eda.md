# Automated exploratory data analysis for a time series

Computes descriptive statistics, stationarity tests, and seasonality
metrics for a `MiltSeries`. Results are printed in a structured report.

## Usage

``` r
milt_eda(series, ...)
```

## Arguments

- series:

  A `MiltSeries` object (univariate).

- ...:

  Additional arguments (unused).

## Value

A `MiltEDA` object.

## See also

[`milt_diagnose()`](https://ntiGideon.github.io/milt/reference/milt_diagnose.md)

## Examples

``` r
s <- milt_series(AirPassengers)
e <- milt_eda(s)
#> Registered S3 method overwritten by 'quantmod':
#>   method            from
#>   as.zoo.data.frame zoo 
#> Warning: p-value smaller than printed p-value
#> Warning: p-value smaller than printed p-value
#> # MiltEDA
#> # Series  : 144 obs  1949-01-01 — 1960-12-01
#> # Freq    : monthly
#> ## Descriptive Statistics
#> # A tibble: 11 × 2
#>    stat        value
#>    <chr>       <dbl>
#>  1 n         144    
#>  2 mean      280.   
#>  3 sd        120.   
#>  4 min       104    
#>  5 q25       180    
#>  6 median    266.   
#>  7 q75       360.   
#>  8 max       622    
#>  9 skewness    0.571
#> 10 kurtosis    2.57 
#> 11 n_missing   0    
#> ## Stationarity
#> #  ADF  p-value : 0.01
#> #  KPSS p-value : 0.01
#> #  Likely stationary: FALSE## Seasonality
#> #  Detected period   : 12
#> #  Seasonal strength : 0.462
#> #  Has seasonality   : TRUE
print(e)
#> # MiltEDA
#> # Series  : 144 obs  1949-01-01 — 1960-12-01
#> # Freq    : monthly
#> ## Descriptive Statistics
#> # A tibble: 11 × 2
#>    stat        value
#>    <chr>       <dbl>
#>  1 n         144    
#>  2 mean      280.   
#>  3 sd        120.   
#>  4 min       104    
#>  5 q25       180    
#>  6 median    266.   
#>  7 q75       360.   
#>  8 max       622    
#>  9 skewness    0.571
#> 10 kurtosis    2.57 
#> 11 n_missing   0    
#> ## Stationarity
#> #  ADF  p-value : 0.01
#> #  KPSS p-value : 0.01
#> #  Likely stationary: FALSE## Seasonality
#> #  Detected period   : 12
#> #  Seasonal strength : 0.462
#> #  Has seasonality   : TRUE
```
