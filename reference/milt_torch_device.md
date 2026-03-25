# Detect the best available torch device

Returns a `torch_device` for CUDA (if available) or CPU. Called
automatically by all DL backends; users rarely need this directly.

## Usage

``` r
milt_torch_device()
```

## Value

A
[`torch::torch_device`](https://torch.mlverse.org/docs/reference/torch_device.html)
object.

## See also

Other dl:
[`milt_setup_darts()`](https://ntiGideon.github.io/milt/reference/milt_setup_darts.md)
