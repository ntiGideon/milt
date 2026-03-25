# Deep Learning Models with milt

``` r
library(milt)
```

## Overview

milt ships six deep learning backends built on **torch for R**. They
follow the same `milt_model() |> milt_fit() |> milt_forecast()` pattern
as every other model.

> **Note:** DL examples in this vignette are not run automatically
> during package checks (`eval = FALSE`). Install `torch` and run them
> interactively.

``` r
install.packages("torch")
torch::install_torch()   # downloads libtorch (~500 MB)
```

------------------------------------------------------------------------

## 1. N-BEATS

Neural basis expansion for interpretable time series forecasting:

``` r
air <- milt_series(AirPassengers)

fct_nbeats <- milt_model("nbeats",
                           input_chunk_length  = 24,
                           output_chunk_length = 12,
                           n_epochs            = 20) |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_nbeats)
```

------------------------------------------------------------------------

## 2. N-HiTS

Multi-rate hierarchical interpolation:

``` r
fct_nhits <- milt_model("nhits",
                          input_chunk_length  = 24,
                          output_chunk_length = 12,
                          n_stacks            = 3,
                          n_epochs            = 20) |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_nhits)
```

------------------------------------------------------------------------

## 3. Temporal Convolutional Network (TCN)

Dilated causal convolutions with residual connections:

``` r
fct_tcn <- milt_model("tcn",
                        n_filters   = 32,
                        kernel_size = 3,
                        n_layers    = 4,
                        n_epochs    = 30) |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_tcn)
```

------------------------------------------------------------------------

## 4. DeepAR (probabilistic)

LSTM encoder with Gaussian likelihood — returns true predictive
distributions:

``` r
fct_deepar <- milt_model("deepar",
                           n_epochs     = 30,
                           hidden_size  = 32) |>
  milt_fit(air) |>
  milt_forecast(12)

# Inspect prediction intervals
head(fct_deepar$as_tibble())
plot(fct_deepar)
```

------------------------------------------------------------------------

## 5. Temporal Fusion Transformer (TFT-lite)

LSTM encoder + cross-attention decoder:

``` r
fct_tft <- milt_model("tft",
                        input_chunk_length  = 24,
                        output_chunk_length = 12,
                        hidden_size         = 32,
                        n_epochs            = 20) |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_tft)
```

------------------------------------------------------------------------

## 6. PatchTST

Transformer with patch-based tokenisation:

``` r
fct_pt <- milt_model("patch_tst",
                       input_chunk_length  = 48,
                       output_chunk_length = 12,
                       patch_len           = 8,
                       n_epochs            = 20) |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_pt)
```

------------------------------------------------------------------------

## 7. GPU detection

milt automatically uses a GPU if available:

``` r
milt_torch_device()
```

------------------------------------------------------------------------

## 8. Reticulate fallback (Python Darts)

For models not yet ported to torch-for-R, milt bridges to Python Darts:

``` r
# One-time setup
milt_setup_darts(install = FALSE)   # set install = TRUE to pip-install darts

fct_darts <- milt_model("darts_nbeats") |>
  milt_fit(air) |>
  milt_forecast(12)

plot(fct_darts)
```
