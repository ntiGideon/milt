# Autoencoder anomaly detector (requires torch package)
#
# Trains a simple MLP autoencoder on sliding windows of the time series.
# Anomalies are identified as windows with reconstruction error above a
# threshold (in terms of z-score of training reconstruction errors).

#' @keywords internal
#' @noRd
MiltDetectorAutoencoder <- R6::R6Class(
  classname = "MiltDetectorAutoencoder",
  inherit   = MiltDetectorBase,
  cloneable = TRUE,

  public = list(

    #' @param window_size Integer. Number of consecutive time steps per window.
    #'   Default `10L`.
    #' @param hidden_size Integer. Size of the bottleneck (latent) layer.
    #'   Default `4L`.
    #' @param n_epochs Integer. Training epochs. Default `50L`.
    #' @param lr Numeric. Learning rate. Default `1e-3`.
    #' @param threshold Numeric. z-score of reconstruction error above which
    #'   a window is flagged. Default `3`.
    #' @param batch_size Integer. Mini-batch size. Default `32L`.
    initialize = function(window_size = 10L,
                          hidden_size = 4L,
                          n_epochs    = 50L,
                          lr          = 1e-3,
                          threshold   = 3,
                          batch_size  = 32L) {
      super$initialize(
        name        = "autoencoder",
        window_size = as.integer(window_size),
        hidden_size = as.integer(hidden_size),
        n_epochs    = as.integer(n_epochs),
        lr          = as.numeric(lr),
        threshold   = as.numeric(threshold),
        batch_size  = as.integer(batch_size)
      )
    },

    detect = function(series, ...) {
      check_installed_backend("torch", "autoencoder detector")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("Autoencoder detector requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p    <- private$.params
      vals <- as.numeric(series$values())
      n    <- length(vals)
      ws   <- p$window_size

      if (n < ws + 1L) {
        milt_abort(
          c(
            "Series too short for autoencoder with {.arg window_size} = {ws}.",
            "i" = "Series has {n} observations; need at least {ws + 1L}."
          ),
          class = "milt_error_insufficient_data"
        )
      }

      # Z-score normalise
      mu  <- mean(vals, na.rm = TRUE)
      sig <- stats::sd(vals, na.rm = TRUE)
      if (is.na(sig) || sig < 1e-10) sig <- 1
      v_norm <- (vals - mu) / sig

      # Build windows: (n - ws) x ws matrix
      n_wins <- n - ws
      X_mat  <- matrix(NA_real_, nrow = n_wins, ncol = ws)
      for (i in seq_len(n_wins)) {
        X_mat[i, ] <- v_norm[i:(i + ws - 1L)]
      }

      device <- milt_torch_device()

      # Build the autoencoder lazily
      enc_size <- ws
      lat_size <- p$hidden_size

      AE <- torch::nn_module(
        "AE",
        initialize = function(in_size, hidden) {
          self$enc <- torch::nn_sequential(
            torch::nn_linear(in_size, hidden * 2L),
            torch::nn_relu(),
            torch::nn_linear(hidden * 2L, hidden)
          )
          self$dec <- torch::nn_sequential(
            torch::nn_linear(hidden, hidden * 2L),
            torch::nn_relu(),
            torch::nn_linear(hidden * 2L, in_size)
          )
        },
        forward = function(x) {
          self$dec(self$enc(x))
        }
      )

      net <- AE(enc_size, lat_size)$to(device = device)
      opt <- torch::optim_adam(net$parameters, lr = p$lr)

      X_t <- torch::torch_tensor(X_mat, dtype = torch::torch_float())$to(device = device)

      # Training
      net$train()
      for (ep in seq_len(p$n_epochs)) {
        idx <- sample(n_wins)
        for (start in seq(1, n_wins, by = p$batch_size)) {
          end   <- min(start + p$batch_size - 1L, n_wins)
          batch <- X_t[idx[start:end], ]
          opt$zero_grad()
          recon <- net(batch)
          loss  <- torch::nnf_mse_loss(recon, batch)
          loss$backward()
          opt$step()
        }
      }

      # Compute reconstruction errors per window
      net$eval()
      with(torch::no_grad(), {
        recon_all <- net(X_t)$to(device = torch::torch_device("cpu"))
      })
      recon_np <- as.matrix(recon_all)
      errors   <- rowMeans((X_mat - recon_np) ^ 2)  # MSE per window

      # Map window errors back to individual time steps (take max)
      point_scores <- rep(0, n)
      for (i in seq_len(n_wins)) {
        for (j in seq_len(ws)) {
          idx_t <- i + j - 1L
          if (errors[i] > point_scores[idx_t]) point_scores[idx_t] <- errors[i]
        }
      }

      # Threshold on z-score of errors
      e_mu  <- mean(errors)
      e_sig <- stats::sd(errors)
      if (is.na(e_sig) || e_sig < 1e-10) e_sig <- 1
      z_scores <- (point_scores - e_mu) / e_sig
      is_anomaly <- z_scores > p$threshold

      .new_milt_anomalies(
        series        = series,
        is_anomaly    = is_anomaly,
        anomaly_score = pmax(z_scores, 0),
        method        = "autoencoder"
      )
    }
  )
)
