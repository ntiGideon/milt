# TFT backend (requires torch package)
#
# Simplified Temporal Fusion Transformer (Lim et al. 2021).
# An LSTM encoder contextualises the input window.  The last hidden state
# then cross-attends to all encoder outputs via scaled dot-product attention,
# followed by a position-wise feed-forward block and a linear decoder.
# (Full TFT features such as variable-selection networks and gating units are
# not included; use a dedicated TFT library for production interpretability.)

# ── Torch module definitions ───────────────────────────────────────────────────

.build_tft_modules <- function() {
  if (!is.null(.milt_env$tft_net)) return(invisible(NULL))

  .milt_env$tft_net <- torch::nn_module(
    "MiltTFTNet",
    initialize = function(input_size, output_size,
                          hidden_size, n_heads, n_layers, dropout_rate) {
      self$hidden_size <- as.integer(hidden_size)
      self$n_layers    <- as.integer(n_layers)

      # LSTM encoder: each timestep is a scalar (univariate series)
      self$lstm <- torch::nn_lstm(
        input_size  = 1L,
        hidden_size = hidden_size,
        num_layers  = n_layers,
        batch_first = TRUE,
        dropout     = if (n_layers > 1L) dropout_rate else 0
      )

      # Cross-attention projections (manual multi-head skipped for simplicity;
      # uses a single-head dot-product attention on the full hidden_size)
      self$wq <- torch::nn_linear(hidden_size, hidden_size, bias = FALSE)
      self$wk <- torch::nn_linear(hidden_size, hidden_size, bias = FALSE)
      self$wv <- torch::nn_linear(hidden_size, hidden_size, bias = FALSE)
      self$wo <- torch::nn_linear(hidden_size, hidden_size, bias = FALSE)

      self$dropout <- torch::nn_dropout(p = dropout_rate)

      # Post-attention layer norm + feed-forward
      self$ln1 <- torch::nn_layer_norm(hidden_size)
      self$ff1 <- torch::nn_linear(hidden_size, hidden_size * 4L)
      self$ff2 <- torch::nn_linear(hidden_size * 4L, hidden_size)
      self$ln2 <- torch::nn_layer_norm(hidden_size)

      # Output projection
      self$fc  <- torch::nn_linear(hidden_size, output_size)
    },
    forward = function(x) {
      # x: (batch, input_size) — flattened normalised input window
      # Encode with LSTM
      x_seq    <- x$unsqueeze(3L)       # (batch, seq_len=input_size, 1)
      lstm_out <- self$lstm(x_seq)
      enc      <- lstm_out[[1]]          # (batch, seq_len, hidden_size)

      # Last hidden state as query
      last_h <- enc$select(2L, enc$size(2))$unsqueeze(2L)  # (batch, 1, hidden_size)

      Q <- self$wq(last_h)   # (batch, 1, hidden_size)
      K <- self$wk(enc)      # (batch, seq_len, hidden_size)
      V <- self$wv(enc)      # (batch, seq_len, hidden_size)

      scale    <- sqrt(as.numeric(self$hidden_size))
      scores   <- torch::torch_bmm(Q, K$transpose(2L, 3L)) / scale  # (batch, 1, seq_len)
      weights  <- torch::nnf_softmax(scores, dim = 3L)
      attn_out <- torch::torch_bmm(weights, V)$squeeze(2L)           # (batch, hidden_size)
      attn_out <- self$wo(attn_out)

      # Add & norm (residual from last encoder hidden state)
      query_sq <- last_h$squeeze(2L)  # (batch, hidden_size)
      h        <- self$ln1(query_sq + self$dropout(attn_out))

      # Feed-forward block
      ff <- self$ff2(torch::nnf_relu(self$ff1(h)))
      h  <- self$ln2(h + self$dropout(ff))

      self$fc(h)   # (batch, output_size)
    }
  )
}

# ── MiltTFT R6 backend ────────────────────────────────────────────────────────

MiltTFT <- R6::R6Class(
  classname = "MiltTFT",
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

    #' @param input_chunk_length Integer. Lookback window fed to the LSTM
    #'   encoder. Default `24L`.
    #' @param output_chunk_length Integer. Steps predicted per forward pass.
    #'   Default `12L`.
    #' @param hidden_size Integer. LSTM hidden state and attention dimension.
    #'   Default `64L`.
    #' @param n_heads Integer. Number of attention heads (currently
    #'   single-head; reserved for future multi-head support). Default `4L`.
    #' @param n_layers Integer. LSTM encoder depth. Default `2L`.
    #' @param dropout Numeric. Dropout rate applied to attention and
    #'   feed-forward sub-layers. Default `0.1`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Validation fraction. Default `0.1`.
    #' @param ... Unused; for forward compatibility.
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          hidden_size = 64L,
                          n_heads     = 4L,
                          n_layers    = 2L,
                          dropout     = 0.1,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "tft",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        hidden_size         = as.integer(hidden_size),
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
      check_installed_backend("torch", "tft")
      .build_tft_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("tft requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p   <- private$.params
      icl <- p$input_chunk_length
      ocl <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c(
            "Series too short for TFT with these chunk lengths.",
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

      net <- .milt_env$tft_net(
        input_size   = icl,
        output_size  = ocl,
        hidden_size  = p$hidden_size,
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
        model_name      = "tft",
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

.onLoad_tft <- function() {
  register_milt_model("tft", MiltTFT)
}
