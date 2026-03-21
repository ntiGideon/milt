# Shared torch infrastructure for deep learning backends

# ── Device detection ──────────────────────────────────────────────────────────

#' Detect the best available torch device
#'
#' Returns a `torch_device` for CUDA (if available) or CPU.  Called
#' automatically by all DL backends; users rarely need this directly.
#'
#' @return A `torch::torch_device` object.
#' @family dl
#' @export
milt_torch_device <- function() {
  check_installed_backend("torch", "deep learning")
  if (torch::cuda_is_available()) {
    torch::torch_device("cuda")
  } else {
    torch::torch_device("cpu")
  }
}

# Internal alias (no export)
.milt_torch_device <- milt_torch_device

# ── Windowing ─────────────────────────────────────────────────────────────────

# Create overlapping (input_window, output_window) pairs from a numeric vector.
# Returns list(X = matrix [n_windows x input_length],
#              y = matrix [n_windows x output_length])
.create_ts_windows <- function(values, input_length, output_length) {
  n         <- length(values)
  n_windows <- n - input_length - output_length + 1L
  if (n_windows <= 0L) {
    milt_abort(
      c(
        "Series is too short to create training windows.",
        "i" = paste0("Need at least {input_length + output_length} observations;",
                     " series has {n}.")
      ),
      class = "milt_error_insufficient_data"
    )
  }
  X <- matrix(NA_real_, nrow = n_windows, ncol = input_length)
  y <- matrix(NA_real_, nrow = n_windows, ncol = output_length)
  for (i in seq_len(n_windows)) {
    X[i, ] <- values[i:(i + input_length  - 1L)]
    y[i, ] <- values[(i + input_length):(i + input_length + output_length - 1L)]
  }
  list(X = X, y = y)
}

# ── Training loop ─────────────────────────────────────────────────────────────

# Fit a torch nn_module with early stopping and optional validation.
# model       — torch::nn_module (modified in-place; reference semantics)
# X_train, y_train — R numeric matrices
# X_val, y_val     — R numeric matrices or NULL (no validation split)
# Returns the trained model (same reference, for convenience).
.fit_torch_model <- function(model,
                              X_train,
                              y_train,
                              X_val    = NULL,
                              y_val    = NULL,
                              n_epochs = 100L,
                              lr       = 1e-3,
                              patience = 10L,
                              device   = .milt_torch_device()) {

  to_tensor <- function(m) {
    torch::torch_tensor(m, dtype = torch::torch_float())$to(device = device)
  }

  X_tr <- to_tensor(X_train)
  y_tr <- to_tensor(y_train)
  has_val <- !is.null(X_val) && nrow(X_val) > 0L
  if (has_val) {
    X_vl <- to_tensor(X_val)
    y_vl <- to_tensor(y_val)
  }

  model$to(device = device)
  optimizer  <- torch::optim_adam(model$parameters, lr = lr)
  best_loss  <- Inf
  no_improve <- 0L
  best_state <- NULL

  prog <- cli::cli_progress_bar(
    name  = "Training",
    total = n_epochs,
    clear = FALSE
  )

  for (epoch in seq_len(n_epochs)) {
    # ── Train step ─────────────────────────────────────────────────────────
    model$train()
    optimizer$zero_grad()
    pred_tr <- model(X_tr)
    loss_tr <- torch::nnf_mse_loss(pred_tr, y_tr)
    loss_tr$backward()
    optimizer$step()

    # ── Validation / early stopping ────────────────────────────────────────
    monitor_loss <- if (has_val) {
      model$eval()
      torch::with_no_grad({
        pred_vl <- model(X_vl)
        torch::nnf_mse_loss(pred_vl, y_vl)$item()
      })
    } else {
      loss_tr$item()
    }

    if (monitor_loss < best_loss - 1e-7) {
      best_loss  <- monitor_loss
      no_improve <- 0L
      # Snapshot best weights
      best_state <- lapply(model$state_dict(), function(t) t$clone())
    } else {
      no_improve <- no_improve + 1L
    }

    cli::cli_progress_update(id = prog)

    if (no_improve >= patience) {
      cli::cli_progress_done(id = prog)
      milt_info("Early stopping at epoch {epoch} (best val loss: {round(best_loss, 5)}).")
      break
    }
  }
  cli::cli_progress_done(id = prog)

  # Restore best weights
  if (!is.null(best_state)) {
    model$load_state_dict(best_state)
  }
  model$eval()
  model
}

# ── Normalisation helpers ──────────────────────────────────────────────────────

# Z-score normalise a numeric vector; returns list(norm, mean, sd).
.ts_normalise <- function(x) {
  mu  <- mean(x, na.rm = TRUE)
  sig <- stats::sd(x, na.rm = TRUE)
  if (is.na(sig) || sig < 1e-8) sig <- 1
  list(norm = (x - mu) / sig, mean = mu, sd = sig)
}

# Invert normalisation.
.ts_denormalise <- function(x_norm, mu, sig) {
  x_norm * sig + mu
}
