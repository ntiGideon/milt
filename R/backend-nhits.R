# N-HiTS backend (requires torch package)
#
# Neural Hierarchical Interpolation for Time Series (Challu et al. 2023).
# Extends N-BEATS with multi-rate signal sampling: each stack max-pools the
# input by an exponentially increasing factor so coarser stacks capture slower
# patterns.  The residual backcast architecture is otherwise identical.

# ── Torch module definitions ───────────────────────────────────────────────────

.build_nhits_modules <- function() {
  if (!is.null(.milt_env$nhits_block)) return(invisible(NULL))

  .milt_env$nhits_block <- torch::nn_module(
    "MiltNHiTSBlock",
    initialize = function(input_size, output_size, pool_size,
                          hidden_size, n_layers) {
      self$pool_size <- as.integer(pool_size)
      if (pool_size > 1L) {
        self$pool <- torch::nn_max_pool1d(
          kernel_size = pool_size,
          stride      = pool_size,
          ceil_mode   = TRUE
        )
      }
      pooled_size <- ceiling(input_size / pool_size)
      fc    <- vector("list", n_layers)
      in_sz <- pooled_size
      for (i in seq_len(n_layers)) {
        fc[[i]] <- torch::nn_linear(in_sz, hidden_size)
        in_sz   <- hidden_size
      }
      self$fc_layers    <- torch::nn_module_list(fc)
      self$backcast_lin <- torch::nn_linear(hidden_size, input_size,  bias = FALSE)
      self$forecast_lin <- torch::nn_linear(hidden_size, output_size, bias = FALSE)
    },
    forward = function(x) {
      # x: (batch, input_size)
      if (self$pool_size > 1L) {
        # Reshape to (batch, 1, input_size) for 1-D max-pooling
        pooled <- self$pool(x$unsqueeze(2L))$squeeze(2L)
      } else {
        pooled <- x
      }
      h <- pooled
      for (i in seq_along(self$fc_layers)) {
        h <- torch::nnf_relu(self$fc_layers[[i]](h))
      }
      list(
        backcast = self$backcast_lin(h),
        forecast = self$forecast_lin(h)
      )
    }
  )

  .milt_env$nhits_net <- torch::nn_module(
    "MiltNHiTSNet",
    initialize = function(input_size, output_size,
                          n_stacks, n_blocks, hidden_size, n_layers) {
      # Exponentially increasing pool sizes: finest stack pools by 1,
      # coarsest stack pools by 2^(n_stacks-1).
      pool_sizes <- as.integer(pmax(1L, 2L ^ (rev(seq_len(n_stacks)) - 1L)))
      blks <- vector("list", n_stacks * n_blocks)
      k    <- 1L
      for (s in seq_len(n_stacks)) {
        for (b in seq_len(n_blocks)) {
          blks[[k]] <- .milt_env$nhits_block(
            input_size  = input_size,
            output_size = output_size,
            pool_size   = pool_sizes[[s]],
            hidden_size = hidden_size,
            n_layers    = n_layers
          )
          k <- k + 1L
        }
      }
      self$blocks      <- torch::nn_module_list(blks)
      self$n_blocks    <- n_stacks * n_blocks
      self$output_size <- output_size
    },
    forward = function(x) {
      residual  <- x
      forecasts <- torch::torch_zeros(
        c(x$shape[1], self$output_size),
        device = x$device,
        dtype  = x$dtype
      )
      for (i in seq_len(self$n_blocks)) {
        out       <- self$blocks[[i]](residual)
        residual  <- residual - out$backcast
        forecasts <- forecasts + out$forecast
      }
      forecasts
    }
  )
}

# ── MiltNHiTS R6 backend ──────────────────────────────────────────────────────

MiltNHiTS <- R6::R6Class(
  classname = "MiltNHiTS",
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

    #' @param input_chunk_length Integer. Lookback window fed to the network.
    #'   Default `24L`.
    #' @param output_chunk_length Integer. Steps predicted per forward pass.
    #'   Default `12L`.
    #' @param n_stacks Integer. Number of hierarchical stacks (scales).
    #'   Default `3L`.
    #' @param n_blocks Integer. Blocks per stack. Default `1L`.
    #' @param hidden_size Integer. FC layer width. Default `64L`.
    #' @param n_layers Integer. Depth of FC layers per block. Default `4L`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Validation fraction. Default `0.1`.
    #' @param ... Unused; for forward compatibility.
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          n_stacks    = 3L,
                          n_blocks    = 1L,
                          hidden_size = 64L,
                          n_layers    = 4L,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "nhits",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        n_stacks            = as.integer(n_stacks),
        n_blocks            = as.integer(n_blocks),
        hidden_size         = as.integer(hidden_size),
        n_layers            = as.integer(n_layers),
        n_epochs            = as.integer(n_epochs),
        lr                  = as.numeric(lr),
        patience            = as.integer(patience),
        val_split           = as.numeric(val_split),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("torch", "nhits")
      .build_nhits_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("nhits requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p   <- private$.params
      icl <- p$input_chunk_length
      ocl <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c(
            "Series too short for N-HiTS with these chunk lengths.",
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

      net <- .milt_env$nhits_net(
        input_size  = icl,
        output_size = ocl,
        n_stacks    = p$n_stacks,
        n_blocks    = p$n_blocks,
        hidden_size = p$hidden_size,
        n_layers    = p$n_layers
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

      # In-sample residuals (last forecast step per window)
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
        model_name      = "nhits",
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

.onLoad_nhits <- function() {
  register_milt_model("nhits", MiltNHiTS)
}
