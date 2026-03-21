# PatchTST backend (requires torch package)
#
# PatchTST (Nie et al. 2023): Transformer on non-overlapping patches.
# The input window is divided into fixed-length patches; each patch is linearly
# embedded into a token.  A learnable positional encoding is added and a
# standard Transformer encoder is applied.  All patch representations are
# flattened and projected to the forecast horizon.

# ── Torch module definitions ───────────────────────────────────────────────────

.build_patch_tst_modules <- function() {
  if (!is.null(.milt_env$patch_tst_net)) return(invisible(NULL))

  .milt_env$patch_tst_net <- torch::nn_module(
    "MiltPatchTSTNet",
    initialize = function(input_size, output_size,
                          patch_len, d_model, n_heads, n_layers, dropout_rate) {
      patch_len   <- as.integer(patch_len)
      n_patches   <- as.integer(ceiling(input_size / patch_len))
      pad_size    <- as.integer(n_patches * patch_len - input_size)

      self$patch_len  <- patch_len
      self$n_patches  <- n_patches
      self$pad_size   <- pad_size
      self$d_model    <- as.integer(d_model)

      # Linear patch embedding
      self$patch_embed <- torch::nn_linear(patch_len, d_model)

      # Learnable positional encoding (0-indexed: positions 0..n_patches-1)
      self$pos_embed   <- torch::nn_embedding(n_patches, d_model)

      # Transformer encoder
      enc_layer <- torch::nn_transformer_encoder_layer(
        d_model         = d_model,
        nhead           = n_heads,
        dim_feedforward = d_model * 4L,
        dropout         = dropout_rate,
        batch_first     = TRUE
      )
      self$transformer <- torch::nn_transformer_encoder(
        enc_layer,
        num_layers = n_layers
      )

      self$dropout <- torch::nn_dropout(p = dropout_rate)

      # Prediction head: flatten all patch representations
      self$fc <- torch::nn_linear(d_model * n_patches, output_size)
    },
    forward = function(x) {
      # x: (batch, input_size) — normalised input window
      B <- x$shape[1]

      # Pad right to a multiple of patch_len
      if (self$pad_size > 0L) {
        x <- torch::nnf_pad(x, c(0L, self$pad_size))
      }

      # Reshape to patches: (batch, n_patches, patch_len)
      x_patches <- x$view(c(B, self$n_patches, self$patch_len))

      # Patch embedding: (batch, n_patches, d_model)
      tok_emb <- self$patch_embed(x_patches)

      # Positional encoding (0-indexed)
      pos <- torch::torch_arange(
        start = 0L,
        end   = self$n_patches,
        device = x$device,
        dtype  = torch::torch_long()
      )
      pos_emb <- self$pos_embed(pos)$unsqueeze(1L)  # (1, n_patches, d_model)

      h <- self$dropout(tok_emb + pos_emb)

      # Transformer encoder: (batch, n_patches, d_model)
      h <- self$transformer(h)

      # Flatten: (batch, n_patches * d_model)
      h <- h$contiguous()$view(c(B, self$n_patches * self$d_model))

      self$fc(h)   # (batch, output_size)
    }
  )
}

# ── MiltPatchTST R6 backend ───────────────────────────────────────────────────

MiltPatchTST <- R6::R6Class(
  classname = "MiltPatchTST",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  private = list(
    .torch_model = NULL,
    .x_mean      = NULL,
    .x_sd        = NULL,
    .last_input  = NULL,
    .residuals_  = NULL,
    .icl         = NULL,
    .ocl         = NULL
  ),

  public = list(

    #' @param input_chunk_length Integer. Lookback window length. Default `24L`.
    #' @param output_chunk_length Integer. Steps predicted per pass. Default `12L`.
    #' @param patch_len Integer. Length of each non-overlapping patch. Default `8L`.
    #' @param d_model Integer. Patch embedding / Transformer model dimension.
    #'   Default `64L`.
    #' @param n_heads Integer. Number of attention heads. Default `4L`.
    #' @param n_layers Integer. Transformer encoder depth. Default `2L`.
    #' @param dropout Numeric. Dropout rate. Default `0.1`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Validation fraction. Default `0.1`.
    #' @param ... Unused; for forward compatibility.
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          patch_len = 8L,
                          d_model   = 64L,
                          n_heads   = 4L,
                          n_layers  = 2L,
                          dropout   = 0.1,
                          n_epochs  = 100L,
                          lr        = 1e-3,
                          patience  = 10L,
                          val_split = 0.1,
                          ...) {
      super$initialize(
        name                = "patch_tst",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        patch_len           = as.integer(patch_len),
        d_model             = as.integer(d_model),
        n_heads             = as.integer(n_heads),
        n_layers            = as.integer(n_layers),
        dropout             = as.numeric(dropout),
        n_epochs            = as.integer(n_epochs),
        lr                  = as.numeric(lr),
        patience            = as.integer(patience),
        val_split           = as.numeric(val_split),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("torch", "patch_tst")
      .build_patch_tst_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("patch_tst requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p   <- private$.params
      icl <- p$input_chunk_length
      ocl <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c(
            "Series too short for PatchTST with these chunk lengths.",
            "i" = "Need at least {icl + ocl + 1} observations; series has {length(vals)}.",
            "i" = "Decrease {.arg input_chunk_length} or {.arg output_chunk_length}."
          ),
          class = "milt_error_insufficient_data"
        )
      }

      # Validate patch_len divides sensibly into input_chunk_length
      if (p$patch_len > icl) {
        milt_abort(
          c(
            "{.arg patch_len} ({p$patch_len}) is larger than {.arg input_chunk_length} ({icl}).",
            "i" = "Use a smaller {.arg patch_len}."
          ),
          class = "milt_error_invalid_params"
        )
      }

      norm   <- .ts_normalise(vals)
      vals_n <- norm$norm

      wins    <- .create_ts_windows(vals_n, icl, ocl)
      n_win   <- nrow(wins$X)
      n_val   <- max(1L, floor(n_win * p$val_split))
      n_train <- n_win - n_val

      X_train <- wins$X[seq_len(n_train), , drop = FALSE]
      y_train <- wins$y[seq_len(n_train), , drop = FALSE]
      X_val   <- wins$X[(n_train + 1L):n_win, , drop = FALSE]
      y_val   <- wins$y[(n_train + 1L):n_win, , drop = FALSE]

      device <- .milt_torch_device()

      net <- .milt_env$patch_tst_net(
        input_size   = icl,
        output_size  = ocl,
        patch_len    = p$patch_len,
        d_model      = p$d_model,
        n_heads      = p$n_heads,
        n_layers     = p$n_layers,
        dropout_rate = p$dropout
      )

      .fit_torch_model(
        model    = net,
        X_train  = X_train,
        y_train  = y_train,
        X_val    = X_val,
        y_val    = y_val,
        n_epochs = p$n_epochs,
        lr       = p$lr,
        patience = p$patience,
        device   = device
      )

      # In-sample residuals
      net$eval()
      y_hat_denorm <- .ts_denormalise(
        as.numeric(
          torch::with_no_grad({
            X_t <- torch::torch_tensor(X_train,
                                        dtype = torch::torch_float())$to(device)
            net(X_t)$cpu()$detach()
          })[, ocl]
        ),
        norm$mean, norm$sd
      )
      y_true_denorm <- vals[(icl + ocl):length(vals)]
      resid_final   <- y_true_denorm - y_hat_denorm

      private$.torch_model <- net
      private$.x_mean      <- norm$mean
      private$.x_sd        <- norm$sd
      private$.last_input  <- utils::tail(vals_n, icl)
      private$.residuals_  <- resid_final
      private$.icl         <- icl
      private$.ocl         <- ocl
      private$.fitted      <- TRUE
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      .assert_is_fitted(self)
      horizon  <- as.integer(horizon)
      icl      <- private$.icl
      ocl      <- private$.ocl
      net      <- private$.torch_model
      device   <- .milt_torch_device()
      history  <- as.numeric(private$.last_input)

      generated <- numeric(0L)
      while (length(generated) < horizon) {
        x_in  <- matrix(utils::tail(c(history, generated), icl), nrow = 1L)
        x_t   <- torch::torch_tensor(x_in, dtype = torch::torch_float())$to(device)
        y_hat <- as.numeric(
          torch::with_no_grad({ net(x_t) })$cpu()$detach()
        )
        n_need    <- horizon - length(generated)
        generated <- c(generated, y_hat[seq_len(min(ocl, n_need))])
      }
      generated <- generated[seq_len(horizon)]
      pt_vals   <- .ts_denormalise(generated, private$.x_mean, private$.x_sd)

      training_series <- private$.training_series
      times   <- .future_times(training_series, horizon)
      pt_tbl  <- tibble::tibble(time = times, value = pt_vals)
      pi      <- .ml_pi_from_residuals(
        private$.residuals_, pt_vals, times, level
      )

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "patch_tst",
        horizon         = horizon,
        training_end    = training_series$end_time(),
        training_series = training_series
      )
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      icl  <- private$.icl
      ocl  <- private$.ocl
      vals <- if (is.null(series)) {
        private$.training_series$values()
      } else {
        assert_milt_series(series)
        series$values()
      }
      n      <- length(vals)
      wins   <- .create_ts_windows(.ts_normalise(vals)$norm, icl, ocl)
      device <- .milt_torch_device()
      net    <- private$.torch_model
      X_t    <- torch::torch_tensor(wins$X,
                                     dtype = torch::torch_float())$to(device)
      y_hat  <- as.numeric(
        torch::with_no_grad({ net(X_t) })$cpu()$detach()[, ocl]
      )
      y_hat  <- .ts_denormalise(y_hat, private$.x_mean, private$.x_sd)
      c(rep(NA_real_, n - length(y_hat)), y_hat)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      n_train <- length(private$.training_series$values())
      c(rep(NA_real_, n_train - length(private$.residuals_)),
        private$.residuals_)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_patch_tst <- function() {
  register_milt_model("patch_tst", MiltPatchTST)
}
