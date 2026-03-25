# Load a milt object from disk

Reads an `.milt` file previously written by
[`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md)
and returns the stored object. Issues a warning if the saved `milt`
version differs from the installed version.

## Usage

``` r
milt_load(path)
```

## Arguments

- path:

  Character. Path to an `.milt` file.

## Value

The deserialised milt object.

## See also

[`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md)

Other save:
[`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md)

## Examples

``` r
# \donttest{
tmp <- tempfile(fileext = ".milt")
milt_save(milt_series(AirPassengers), tmp)
#> Saved to /tmp/Rtmp0oPiQm/file1f29799d0247.milt.
s <- milt_load(tmp)
# }
```
