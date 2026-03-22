# TCN backend (requires torch package)
#
# Temporal Convolutional Network (Bai et al. 2018).
# Stacked residual blocks of dilated causal 1-D convolutions.  Each block
# doubles the dilation factor, giving a receptive field that grows
# exponentially with depth.  The last time-step of the final feature map
# is projected to the forecast horizon.

# ── Torch module definitions ───────────────────────────────────────────────────

.build_tcn_modules <- function() {
  if (!is.null(.milt_env$tcn_net)) return(invisible(NULL))

  # One temporal residual block: two dilated causal convolutions + skip.
  # Causality is enforced by using symmetric padding equal to the left-side
  # requirement and trimming the right-side extra outputs.
  .milt_env$tcn_block <- torch::nn_module(
    "MiltTCNBlock",
    initialize = function(in_ch, out_ch, kernel_size, dilation, dropout_rate) {
      pad           <- (kernel_size - 1L) * dilation
      self$conv1    <- torch::nn_conv1d(in_ch,  out_ch, kernel_size,
                                         padding = pad, dilation = dilation)
      self$conv2    <- torch::nn_conv1d(out_ch, out_ch, kernel_size,
                                         padding = pad, dilation = dilation)
      self$dropout  <- torch::nn_dropout(p = dropout_rate)
      self$downsamp <- if (in_ch != out_ch) {
        torch::nn_conv1d(in_ch, out_ch, 1L)
      } else {
        NULL
      }
      self$pad <- pad
    },
    forward = function(x) {
      # x: (batch, in_ch, length)
      L <- x$size(3)

      # Conv1 — trim right-side padding to restore causal length
      out1 <- self$conv1(x)
      out1 <- out1$narrow(3L, 1L, L)
      out1 <- torch::nnf_relu(self$dropout(out1))

      # Conv2
      out2 <- self$conv2(out1)
      out2 <- out2$narrow(3L, 1L, L)

      res <- if (!is.null(self$downsamp)) self$downsamp(x) else x
      torch::nnf_relu(out2 + res)
    }
  )

  .milt_env$tcn_net <- torch::nn_module(
    "MiltTCNNet",
    initialize = function(input_size, output_size,
                          n_filters, kernel_size, n_layers, dropout_rate) {
      blocks <- vector("list", n_layers)
      in_ch  <- 1L
      for (i in seq_len(n_layers)) {
        blocks[[i]] <- .milt_env$tcn_block(
          in_ch        = in_ch,
          out_ch       = n_filters,
          kernel_size  = kernel_size,
          dilation     = 2L ^ (i - 1L),
          dropout_rate = dropout_rate
        )
        in_ch <- n_filters
      }
      self$blocks   <- torch::nn_module_list(blocks)
      self$n_layers <- n_layers
      self$out_lin  <- torch::nn_linear(n_filters, output_size)
    },
    forward = function(x) {
      # x: (batch, input_size) — flattened window
      # Reshape to (batch, 1, input_size) for 1-D convolution
      h <- x$unsqueeze(2L)
      for (i in seq_len(self$n_layers)) {
        h <- self$blocks[[i]](h)
      }
      # h: (batch, n_filters, input_size) — take last time step
      last <- h$select(3L, h$size(3))   # (batch, n_filters)
      self$out_lin(last)                 # (batch, output_size)
    }
  )
}

# ── MiltTCN R6 backend ────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltTCN <- R6::R6Class(
  classname = "MiltTCN",
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
    #' @param n_filters Integer. Number of channels per conv layer. Default `32L`.
    #' @param kernel_size Integer. Conv kernel size. Default `3L`.
    #' @param n_layers Integer. Number of temporal residual blocks. Default `4L`.
    #' @param dropout Numeric. Dropout rate. Default `0.2`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience. Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Validation fraction. Default `0.1`.
    #' @param ... Unused; for forward compatibility.
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          n_filters   = 32L,
                          kernel_size = 3L,
                          n_layers    = 4L,
                          dropout     = 0.2,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "tcn",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        n_filters           = as.integer(n_filters),
        kernel_size         = as.integer(kernel_size),
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
      check_installed_backend("torch", "tcn")
      .build_tcn_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("tcn requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p   <- private$.params
      icl <- p$input_chunk_length
      ocl <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c(
            "Series too short for TCN with these chunk lengths.",
            "i" = "Need at least {icl + ocl + 1} observations; series has {length(vals)}.",
            "i" = "Decrease {.arg input_chunk_length} or {.arg output_chunk_length}."
          ),
          class = "milt_error_insufficient_data"
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

      net <- .milt_env$tcn_net(
        input_size   = icl,
        output_size  = ocl,
        n_filters    = p$n_filters,
        kernel_size  = p$kernel_size,
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
        model_name      = "tcn",
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

.onLoad_tcn <- function() {
  register_milt_model("tcn", MiltTCN)
}
