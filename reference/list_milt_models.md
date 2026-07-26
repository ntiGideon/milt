# List all registered milt models

List all registered milt models

## Usage

``` r
list_milt_models()
```

## Value

A tibble with columns `name`, `description`, `multivariate`,
`probabilistic`, `covariates`, `multi_series`.

## Examples

``` r
list_milt_models()
#> # A tibble: 31 × 6
#>    name        description    multivariate probabilistic covariates multi_series
#>    <chr>       <chr>          <lgl>        <lgl>         <lgl>      <lgl>       
#>  1 snaive      "Seasonal Nai… FALSE        TRUE          FALSE      FALSE       
#>  2 knn         "K-Nearest Ne… FALSE        TRUE          FALSE      FALSE       
#>  3 ets         "Exponential … FALSE        TRUE          FALSE      FALSE       
#>  4 nbeats      ""             FALSE        FALSE         FALSE      FALSE       
#>  5 auto_arima  "Automatic AR… FALSE        TRUE          TRUE       FALSE       
#>  6 svm         "Support Vect… FALSE        TRUE          FALSE      FALSE       
#>  7 stl         "STL decompos… FALSE        TRUE          FALSE      FALSE       
#>  8 elastic_net ""             FALSE        FALSE         FALSE      FALSE       
#>  9 dlinear     ""             FALSE        FALSE         FALSE      FALSE       
#> 10 deepar      ""             FALSE        FALSE         FALSE      FALSE       
#> # ℹ 21 more rows
```
