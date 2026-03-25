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
#> # A tibble: 25 × 6
#>    name           description multivariate probabilistic covariates multi_series
#>    <chr>          <chr>       <lgl>        <lgl>         <lgl>      <lgl>       
#>  1 snaive         "Seasonal … FALSE        TRUE          FALSE      FALSE       
#>  2 ets            "Exponenti… FALSE        TRUE          FALSE      FALSE       
#>  3 nbeats         ""          FALSE        FALSE         FALSE      FALSE       
#>  4 auto_arima     "Automatic… FALSE        TRUE          TRUE       FALSE       
#>  5 knn            "K-Nearest… FALSE        TRUE          FALSE      FALSE       
#>  6 svm            "Support V… FALSE        TRUE          FALSE      FALSE       
#>  7 stl            "STL decom… FALSE        TRUE          FALSE      FALSE       
#>  8 elastic_net    ""          FALSE        FALSE         FALSE      FALSE       
#>  9 deepar         ""          FALSE        FALSE         FALSE      FALSE       
#> 10 darts_transfo… ""          FALSE        FALSE         FALSE      FALSE       
#> # ℹ 15 more rows
```
