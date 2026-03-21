# DeepAR backend (requires torch package)
#
# DeepAR (Salinas et al. 2020): LSTM-based probabilistic forecasting.
# The LSTM encodes the input window; two linear heads produce the mean (mu)
# and log-standard-deviation (log_sigma) of a Gaussian for each forecast step.
# Training minimises the Gaussian negative log-likelihood.
# Prediction intervals are derived analytically from the predicted sigma.

# ── Torch module definitions ───────────────────────────────────────────────────

.build_deepar_modules <- function() {
  if (!is.null(.milt_env$deepar_net)) return(invisible(NULL))

  .milt_env$deepar_net <- torch::nn_module(
    "MiltDeepARNet",
    initialize = function(input_size, output_size, hidden_size, n_layers) {
      self$n_layers <- as.integer(n_layers)
      self$lstm     <- torch::nn_lstm(
        input_size  = 1L,
        hidden_size = hidden_size,
        num_layers  = n_layers,
        batch_first = TRUE,
        dropout     = if (n_layers > 1L) 0.1 else 0
      )
      self$mu_lin    <- torch::nn_linear(hidden_size, output_size)
      self$sigma_lin <- torch::nn_linear(hidden_size, output_size)
    },
    forward = function(x) {
      # x: (batch, input_size) — normalised input window
      # Reshape to (batch, seq_len=input_size, features=1) for LSTM
      x_seq    <- x$unsqueeze(3L)
      lstm_out <- self$lstm(x_seq)
      # h_n: (num_layers, batch, hidden_size) — take last layer
      h_n    <- lstm_out[[2]][[1]]
      last_h <- h_n$select(1L, self$n_layers)   # (batch, hidden_size)

      mu        <- self$mu_lin(last_h)     # (batch, output_size)
      log_sigma <- self$sigma_lin(last_h)  # (batch, output_size)
      list(mu = mu, log_sigma = log_sigma)
    }
  )
}

# ── MiltDeepAR R6 backend ─────────────────────────────────────────────────────

MiltDeepAR <- R6::R6Class(
  classname = "MiltDeepAR",
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

    #' @param input_chunk_length Integer. Lookback window fed to the LSTM.
    #'   Default `24L`.
    #' @param output_chunk_length Integer. Steps predicted per forward pass.
    #'   Default `12L`.
    #' @param hidden_size Integer. LSTM hidden state dimension. Default `64L`.
    #' @param n_layers Integer. Number of LSTM layers. Default `2L`.
    #' @param n_epochs Integer. Maximum training epochs. Default `100L`.
    #' @param lr Numeric. Adam learning rate. Default `1e-3`.
    #' @param patience Integer. Early-stopping patience (epochs). Default `10L`.
    #' @param val_split Numeric in `(0, 1)`. Validation fraction. Default `0.1`.
    #' @param ... Unused; for forward compatibility.
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          hidden_size = 64L,
                          n_layers    = 2L,
                          n_epochs    = 100L,
                          lr          = 1e-3,
                          patience    = 10L,
                          val_split   = 0.1,
                          ...) {
      super$initialize(
        name                = "deepar",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
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
      check_installed_backend("torch", "deepar")
      .build_deepar_modules()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("deepar requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p   <- private$.params
      icl <- p$input_chunk_length
      ocl <- p$output_chunk_length
      vals <- series$values()

      if (length(vals) < icl + ocl + 1L) {
        milt_abort(
          c(
            "Series too short for DeepAR with these chunk lengths.",
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

      net <- .milt_env$deepar_net(
        input_size  = icl,
        output_size = ocl,
        hidden_size = p$hidden_size,
        n_layers    = p$n_layers
      )
      net$to(device = device)

      # ── Custom NLL training loop ──────────────────────────────────────────
      to_t <- function(m) {
        torch::torch_tensor(m, dtype = torch::torch_float())$to(device = device)
      }
      X_tr <- to_t(X_train);  y_tr <- to_t(y_train)
      has_val <- nrow(X_val) > 0L
      if (has_val) { X_vl <- to_t(X_val);  y_vl <- to_t(y_val) }

      optimizer  <- torch::optim_adam(net$parameters, lr = p$lr)
      best_loss  <- Inf
      no_improve <- 0L
      best_state <- NULL

      prog <- cli::cli_progress_bar(
        name  = "Training",
        total = p$n_epochs,
        clear = FALSE
      )

      .nll_loss <- function(mu, log_sig, y_true) {
        # Gaussian NLL: log_sigma + 0.5 * ((y - mu) / sigma)^2
        sigma <- torch::torch_exp(log_sig)
        torch::torch_mean(log_sig + 0.5 * ((y_true - mu) / sigma) ^ 2)
      }

      for (epoch in seq_len(p$n_epochs)) {
        net$train()
        optimizer$zero_grad()
        out_tr  <- net(X_tr)
        loss_tr <- .nll_loss(out_tr$mu, out_tr$log_sigma, y_tr)
        loss_tr$backward()
        optimizer$step()

        monitor_loss <- if (has_val) {
          net$eval()
          torch::with_no_grad({
            out_vl <- net(X_vl)
            .nll_loss(out_vl$mu, out_vl$log_sigma, y_vl)$item()
          })
        } else {
          loss_tr$item()
        }

        if (monitor_loss < best_loss - 1e-7) {
          best_loss  <- monitor_loss
          no_improve <- 0L
          best_state <- lapply(net$state_dict(), function(t) t$clone())
        } else {
          no_improve <- no_improve + 1L
        }

        cli::cli_progress_update(id = prog)
        if (no_improve >= p$patience) {
          cli::cli_progress_done(id = prog)
          milt_info(
            "Early stopping at epoch {epoch} (best val loss: {round(best_loss, 5)})."
          )
          break
        }
      }
      cli::cli_progress_done(id = prog)
      if (!is.null(best_state)) net$load_state_dict(best_state)
      net$eval()

      # In-sample residuals (point = mu)
      y_hat_denorm <- .ts_denormalise(
        as.numeric(
          torch::with_no_grad({
            X_t <- to_t(X_train)
            net(X_t)$mu$cpu()$detach()
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

      # Recursive multi-step: collect mu and sigma for each chunk
      mu_gen    <- numeric(0L)
      sigma_gen <- numeric(0L)

      while (length(mu_gen) < horizon) {
        x_in <- matrix(utils::tail(c(history, mu_gen), icl), nrow = 1L)
        x_t  <- torch::torch_tensor(x_in, dtype = torch::torch_float())$to(device)
        out  <- torch::with_no_grad({ net(x_t) })
        mu_hat    <- as.numeric(out$mu$cpu()$detach())
        sigma_hat <- as.numeric(torch::torch_exp(out$log_sigma)$cpu()$detach())
        n_need    <- horizon - length(mu_gen)
        mu_gen    <- c(mu_gen,    mu_hat[seq_len(min(ocl, n_need))])
        sigma_gen <- c(sigma_gen, sigma_hat[seq_len(min(ocl, n_need))])
      }
      mu_gen    <- mu_gen[seq_len(horizon)]
      sigma_gen <- sigma_gen[seq_len(horizon)]
      pt_vals   <- .ts_denormalise(mu_gen,    private$.x_mean, private$.x_sd)
      sig_vals  <- sigma_gen * private$.x_sd   # de-normalise sigma

      training_series <- private$.training_series
      times   <- .future_times(training_series, horizon)
      pt_tbl  <- tibble::tibble(time = times, value = pt_vals)

      # Analytical Gaussian PIs: mu ± z * sigma
      z_80 <- stats::qnorm(0.9)   # one-sided 90% = two-sided 80%
      z_95 <- stats::qnorm(0.975)

      make_pi <- function(z) {
        list(
          lower = tibble::tibble(time = times, value = pt_vals - z * sig_vals),
          upper = tibble::tibble(time = times, value = pt_vals + z * sig_vals)
        )
      }
      pi80 <- make_pi(z_80);  pi95 <- make_pi(z_95)

      lower <- list("80" = pi80$lower, "95" = pi95$lower)
      upper <- list("80" = pi80$upper, "95" = pi95$upper)

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = lower,
        upper           = upper,
        model_name      = "deepar",
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
      mu_hat <- as.numeric(
        torch::with_no_grad({ net(X_t)$mu })$cpu()$detach()[, ocl]
      )
      mu_hat <- .ts_denormalise(mu_hat, private$.x_mean, private$.x_sd)
      c(rep(NA_real_, n - length(mu_hat)), mu_hat)
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

.onLoad_deepar <- function() {
  register_milt_model("deepar", MiltDeepAR)
}
