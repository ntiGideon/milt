# TSMixer backend (requires torch package)
#
# Chen et al. 2023 ("TSMixer: An All-MLP Architecture for Time Series
# Forecasting"). Simplified for milt's univariate series: full TSMixer
# alternates time-mixing (across the lookback window) and feature-mixing
# (across channels) MLPs; with a single channel the feature-mixing dimension
# is degenerate, so this backend keeps only the time-mixing residual blocks
# — a stack of Linear -> ReLU -> Dropout -> Linear layers applied across the
# time dimension, each wrapped in a residual connection — followed by a
# linear projection head to the forecast horizon.

.build_tsmixer_modules <- function() {
  if (!is.null(.milt_env$tsmixer_net)) return(invisible(NULL))

  .milt_env$tsmixer_block <- torch::nn_module(
    "MiltTSMixerBlock",
    initialize = function(input_size, hidden_size, dropout = 0.1) {
      self$fc1     <- torch::nn_linear(input_size, hidden_size)
      self$fc2     <- torch::nn_linear(hidden_size, input_size)
      self$dropout <- torch::nn_dropout(dropout)
    },
    forward = function(x) {
      h <- torch::nnf_relu(self$fc1(x))
      h <- self$dropout(self$fc2(h))
      x + h
    }
  )

  .milt_env$tsmixer_net <- torch::nn_module(
    "MiltTSMixerNet",
    initialize = function(input_size, output_size, hidden_size = 64L,
                          n_blocks = 2L, dropout = 0.1) {
      blocks <- vector("list", n_blocks)
      for (i in seq_len(n_blocks)) {
        blocks[[i]] <- .milt_env$tsmixer_block(input_size, hidden_size, dropout)
      }
      self$blocks <- torch::nn_module_list(blocks)
      self$head   <- torch::nn_linear(input_size, output_size)
    },
    forward = function(x) {
      h <- x
      for (i in seq_along(self$blocks)) h <- self$blocks[[i]](h)
      self$head(h)
    }
  )
}

#' @keywords internal
#' @noRd
MiltTSMixer <- R6::R6Class(
  classname = "MiltTSMixer",
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
    #' @param hidden_size Integer. Width of the mixing blocks' hidden layer.
    #'   Default `64L`.
    #' @param n_blocks Integer. Number of residual time-mixing blocks.
    #'   Default `2L`.
    #' @param dropout Numeric in `[0, 1)`. Dropout rate. Default `0.1`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Fraction of windows held out for
    #'   validation. Default `0.1`.
    #' @param ... Additional arguments (unused; for forward compatibility).
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          hidden_size = 64L,
                          n_blocks    = 2L,
                          dropout     = 0.1,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "tsmixer",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        hidden_size         = as.integer(hidden_size),
        n_blocks            = as.integer(n_blocks),
        dropout             = as.numeric(dropout),
        n_epochs            = as.integer(n_epochs),
        lr                  = as.numeric(lr),
        patience            = as.integer(patience),
        val_split           = as.numeric(val_split),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("torch", "tsmixer")
      .build_tsmixer_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("tsmixer requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      icl  <- p$input_chunk_length
      ocl  <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c("Series too short for TSMixer with these chunk lengths.",
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
      net    <- .milt_env$tsmixer_net(
        input_size = icl, output_size = ocl, hidden_size = p$hidden_size,
        n_blocks = p$n_blocks, dropout = p$dropout
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
        model_name      = "tsmixer",
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

.onLoad_tsmixer <- function() {
  register_milt_model("tsmixer", MiltTSMixer)
}
