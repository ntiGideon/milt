# Deploy a milt model as a REST API

Generates a Plumber API with standardised endpoints and launches it on
the given host/port. Requires the `plumber` package.

## Usage

``` r
milt_serve(model, host = "127.0.0.1", port = 8000L, launch = TRUE)
```

## Arguments

- model:

  A fitted `MiltModel`.

- host:

  Character. Bind address. Default `"127.0.0.1"`.

- port:

  Integer. TCP port. Default `8000L`.

- launch:

  Logical. If `TRUE` (default) the server is started interactively
  (blocking). Set to `FALSE` to return the plumber router object without
  starting it.

## Value

The `plumber` router object (invisibly when `launch = TRUE`).

## Details

**Endpoints generated:**

- `GET /health` — returns package version and model name.

- `POST /forecast` — accepts JSON `{"horizon": <int>}`, returns
  forecast.

- `GET /series_info` — returns metadata about the training series.

## See also

[`milt_save()`](https://ntiGideon.github.io/milt/reference/milt_save.md),
[`milt_dashboard()`](https://ntiGideon.github.io/milt/reference/milt_dashboard.md)

Other deploy:
[`milt_dashboard()`](https://ntiGideon.github.io/milt/reference/milt_dashboard.md)

## Examples

``` r
# \donttest{
m <- milt_model("naive") |> milt_fit(milt_series(AirPassengers))
#> Fitting <MiltNaive> model…
#> Done in 0s.
# milt_serve(m, launch = FALSE)  # returns router without starting
# }
```
