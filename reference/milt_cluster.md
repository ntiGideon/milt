# Cluster multiple time series

Partitions a list of `MiltSeries` objects into `k` groups using one of
four algorithms.

## Usage

``` r
milt_cluster(series_list, k, method = "euclidean", max_iter = 100L, ...)
```

## Arguments

- series_list:

  A list of `MiltSeries` objects (each univariate).

- k:

  Integer. Number of clusters.

- method:

  Character. Clustering method:

  - `"dtw_kmeans"` — k-means with DTW distance (requires `dtw` package).

  - `"kshape"` — shape-based clustering (no extra package).

  - `"feature_based"` — extract time series features then k-means.

  - `"euclidean"` — k-means on raw aligned series (all must be equal
    length).

- max_iter:

  Integer. Maximum k-means iterations. Default `100L`.

- ...:

  Additional arguments (unused).

## Value

A `MiltClusters` object.

## See also

[`milt_classifier()`](https://ntiGideon.github.io/milt/reference/milt_classifier.md)

## Examples

``` r
# \donttest{
# Create 4 slightly different series
make_s <- function(offset) {
  milt_series(AirPassengers + offset)
}
series_list <- lapply(c(0, 10, 20, 30), make_s)
cl <- milt_cluster(series_list, k = 2, method = "euclidean")
print(cl)
#> # MiltClusters [euclidean]
#> # Series: 4   Clusters: 2# Cluster sizes:
#> 
#> 1 2 
#> 2 2 
# }
```
