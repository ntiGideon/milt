# Save a milt object to disk

Serialises `object` together with version metadata to `path`. The file
is a standard RDS file with the `.milt` extension (by convention).

## Usage

``` r
milt_save(object, path, compress = TRUE)
```

## Arguments

- object:

  Any milt object: `MiltSeries`, a fitted `MiltModel`, `MiltForecast`,
  `MiltDetector`, etc.

- path:

  Character. File path. The `.milt` extension is appended if not already
  present.

- compress:

  Logical or character. Compression type passed to
  [`saveRDS()`](https://rdrr.io/r/base/readRDS.html). Default `TRUE`
  (gzip).

## Value

`path` (invisibly).

## See also

[`milt_load()`](https://ntiGideon.github.io/milt/reference/milt_load.md)

Other save:
[`milt_load()`](https://ntiGideon.github.io/milt/reference/milt_load.md)

## Examples

``` r
# \donttest{
s <- milt_series(AirPassengers)
tmp <- tempfile(fileext = ".milt")
milt_save(s, tmp)
#> Saved to /tmp/Rtmp0oPiQm/file1f2914d53685.milt.
s2 <- milt_load(tmp)
# }
```
