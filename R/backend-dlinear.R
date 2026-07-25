# DLinear backend (requires torch package)
#
# Zeng et al. 2022. Decomposes the input window into a trend component
# (moving-average) and a seasonal/residual component (input minus trend),
# maps each through its own linear layer, and sums the two projections.

.build_dlinear_modules <- function() {
  if (!is.null(.milt_env$dlinear_net)) return(invisible(NULL))

  .milt_env$dlinear_net <- torch::nn_module(
    "MiltDLinearNet",
    initialize = function(input_size, output_size, kernel_size = 25L) {
      self$kernel_size      <- min(as.integer(kernel_size), input_size)
      self$linear_trend     <- torch::nn_linear(input_size, output_size)
      self$linear_seasonal  <- torch::nn_linear(input_size, output_size)
    },
    forward = function(x) {
      k          <- self$kernel_size
      pad_left   <- (k - 1L) %/% 2L
      pad_right  <- k - 1L - pad_left
      x_ch       <- x$unsqueeze(2)   # (batch, 1, length) for 1D pooling
      x_padded   <- torch::nnf_pad(x_ch, c(pad_left, pad_right), mode = "replicate")
      trend      <- torch::nnf_avg_pool1d(x_padded, kernel_size = k, stride = 1L)$squeeze(2)
      seasonal   <- x - trend
      self$linear_trend(trend) + self$linear_seasonal(seasonal)
    }
  )
}

#' @keywords internal
#' @noRd
MiltDLinear <- R6::R6Class(
  classname = "MiltDLinear",
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
    #' @param kernel_size Integer. Moving-average window used for the
    #'   trend/seasonal decomposition. Default `25L`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Fraction of windows held out for
    #'   validation. Default `0.1`.
    #' @param ... Additional arguments (unused; for forward compatibility).
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          kernel_size = 25L,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "dlinear",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        kernel_size         = as.integer(kernel_size),
        n_epochs            = as.integer(n_epochs),
        lr                  = as.numeric(lr),
        patience            = as.integer(patience),
        val_split           = as.numeric(val_split),
        ...
      )
    },

    fit = function(series, ...) {
      check_installed_backend("torch", "dlinear")
      .build_dlinear_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("dlinear requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      icl  <- p$input_chunk_length
      ocl  <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c("Series too short for DLinear with these chunk lengths.",
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
      net    <- .milt_env$dlinear_net(
        input_size = icl, output_size = ocl, kernel_size = p$kernel_size
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
        model_name      = "dlinear",
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

.onLoad_dlinear <- function() {
  register_milt_model("dlinear", MiltDLinear)
}
