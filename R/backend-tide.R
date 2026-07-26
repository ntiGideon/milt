# TiDE backend (requires torch package)
#
# Das et al. 2023 ("Long-term Forecasting with TiDE"). Simplified variant: an
# MLP encoder-decoder built from residual blocks (Linear -> ReLU -> Linear ->
# Dropout, with a skip connection), no attention — a cheap, strong
# alternative to Transformer-based long-horizon models. As with milt's other
# "simplified" DL backends (e.g. patch_tst, tft), this omits TiDE's dynamic/
# static-covariate projection stages and keeps to the core residual encoder-
# decoder structure.

.build_tide_modules <- function() {
  if (!is.null(.milt_env$tide_net)) return(invisible(NULL))

  .milt_env$tide_block <- torch::nn_module(
    "MiltTiDEBlock",
    initialize = function(input_size, hidden_size, output_size, dropout = 0.1) {
      self$fc1     <- torch::nn_linear(input_size, hidden_size)
      self$fc2     <- torch::nn_linear(hidden_size, output_size)
      self$dropout <- torch::nn_dropout(dropout)
      self$skip    <- if (input_size != output_size) {
        torch::nn_linear(input_size, output_size, bias = FALSE)
      } else {
        NULL
      }
    },
    forward = function(x) {
      h    <- torch::nnf_relu(self$fc1(x))
      h    <- self$dropout(self$fc2(h))
      skip <- if (!is.null(self$skip)) self$skip(x) else x
      h + skip
    }
  )

  .milt_env$tide_net <- torch::nn_module(
    "MiltTiDENet",
    initialize = function(input_size, output_size, hidden_size = 64L,
                          n_encoder_layers = 2L, n_decoder_layers = 2L,
                          dropout = 0.1) {
      enc <- vector("list", n_encoder_layers)
      in_sz <- input_size
      for (i in seq_len(n_encoder_layers)) {
        enc[[i]] <- .milt_env$tide_block(in_sz, hidden_size, hidden_size, dropout)
        in_sz    <- hidden_size
      }
      self$encoder <- torch::nn_module_list(enc)

      dec <- vector("list", n_decoder_layers)
      in_sz <- hidden_size
      for (i in seq_len(n_decoder_layers)) {
        out_sz  <- if (i == n_decoder_layers) output_size else hidden_size
        dec[[i]] <- .milt_env$tide_block(in_sz, hidden_size, out_sz, dropout)
        in_sz   <- out_sz
      }
      self$decoder <- torch::nn_module_list(dec)
    },
    forward = function(x) {
      h <- x
      for (i in seq_along(self$encoder)) h <- self$encoder[[i]](h)
      for (i in seq_along(self$decoder)) h <- self$decoder[[i]](h)
      h
    }
  )
}

#' @keywords internal
#' @noRd
MiltTiDE <- R6::R6Class(
  classname = "MiltTiDE",
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
    #' @param output_chunk_length Integer. Steps produced per forward pass.
    #'   Default `12L`.
    #' @param hidden_size Integer. Width of the residual blocks. Default `64L`.
    #' @param n_encoder_layers,n_decoder_layers Integer. Number of residual
    #'   blocks in the encoder/decoder. Default `2L` each.
    #' @param dropout Numeric in `[0, 1)`. Dropout rate. Default `0.1`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Fraction of windows held out for
    #'   validation. Default `0.1`.
    #' @param ... Additional arguments (unused; for forward compatibility).
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          hidden_size       = 64L,
                          n_encoder_layers  = 2L,
                          n_decoder_layers  = 2L,
                          dropout           = 0.1,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "tide",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        hidden_size         = as.integer(hidden_size),
        n_encoder_layers    = as.integer(n_encoder_layers),
        n_decoder_layers    = as.integer(n_decoder_layers),
        dropout             = as.numeric(dropout),
        n_epochs            = as.integer(n_epochs),
        lr                  = as.numeric(lr),
        patience            = as.integer(patience),
        val_split           = as.numeric(val_split),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("torch", "tide")
      .build_tide_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("tide requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      icl  <- p$input_chunk_length
      ocl  <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c("Series too short for TiDE with these chunk lengths.",
            "i" = "Need at least {icl + ocl + 1} observations; series has {length(vals)}."),
          class = "milt_error_insufficient_data"
        )
      }

      norm   <- .ts_normalise(vals)
      vals_n <- norm$norm
      wins   <- .create_ts_windows(vals_n, icl, ocl)
      n_win  <- nrow(wins$X)
      n_val  <- max(1L, floor(n_win * p$val_split))
      n_train <- n_win - n_val

      X_train <- wins$X[seq_len(n_train), , drop = FALSE]
      y_train <- wins$y[seq_len(n_train), , drop = FALSE]
      X_val   <- wins$X[(n_train + 1L):n_win, , drop = FALSE]
      y_val   <- wins$y[(n_train + 1L):n_win, , drop = FALSE]

      device <- .milt_torch_device()
      net    <- .milt_env$tide_net(
        input_size = icl, output_size = ocl, hidden_size = p$hidden_size,
        n_encoder_layers = p$n_encoder_layers, n_decoder_layers = p$n_decoder_layers,
        dropout = p$dropout
      )

      .fit_torch_model(
        model = net, X_train = X_train, y_train = y_train,
        X_val = X_val, y_val = y_val,
        n_epochs = p$n_epochs, lr = p$lr, patience = p$patience, device = device
      )

      net$eval()
      y_hat_n <- as.numeric(
        torch::with_no_grad({
          X_t <- torch::torch_tensor(X_train, dtype = torch::torch_float())$to(device = device)
          net(X_t)$cpu()$detach()
        })[, ocl]
      )
      resid_final <- .ts_denormalise(y_train[, ocl], norm$mean, norm$sd) -
        .ts_denormalise(y_hat_n, norm$mean, norm$sd)

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
      horizon <- as.integer(horizon)
      icl     <- private$.icl
      ocl     <- private$.ocl
      net     <- private$.torch_model
      device  <- .milt_torch_device()
      history <- as.numeric(private$.last_input)

      generated <- numeric(0L)
      while (length(generated) < horizon) {
        x_in  <- matrix(utils::tail(c(history, generated), icl), nrow = 1L)
        x_t   <- torch::torch_tensor(x_in, dtype = torch::torch_float())$to(device = device)
        y_hat <- as.numeric(torch::with_no_grad({ net(x_t) })$cpu()$detach())
        n_need <- horizon - length(generated)
        generated <- c(generated, y_hat[seq_len(min(ocl, n_need))])
      }
      generated <- generated[seq_len(horizon)]
      pt_vals   <- .ts_denormalise(generated, private$.x_mean, private$.x_sd)

      training_series <- private$.training_series
      times  <- .future_times(training_series, horizon)
      pt_tbl <- tibble::tibble(time = times, value = pt_vals)
      pi     <- .ml_pi_from_residuals(private$.residuals_, pt_vals, times, level)

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = pi$lower,
        upper           = pi$upper,
        model_name      = "tide",
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
      X_t    <- torch::torch_tensor(wins$X, dtype = torch::torch_float())$to(device = device)
      y_hat  <- as.numeric(torch::with_no_grad({ net(X_t) })$cpu()$detach()[, ocl])
      y_hat  <- .ts_denormalise(y_hat, private$.x_mean, private$.x_sd)
      c(rep(NA_real_, n - length(y_hat)), y_hat)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      n_train <- length(private$.training_series$values())
      c(rep(NA_real_, n_train - length(private$.residuals_)), private$.residuals_)
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_tide <- function() {
  register_milt_model("tide", MiltTiDE)
}
