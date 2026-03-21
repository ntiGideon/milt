# Tests for DL utility functions (dl-utils.R)
# torch-dependent tests are skipped when torch is not installed.

# ── .create_ts_windows (no torch dependency) ──────────────────────────────────

test_that("create_ts_windows: returns list with X and y", {
  wins <- .create_ts_windows(1:20, input_length = 5L, output_length = 3L)
  expect_type(wins, "list")
  expect_true(all(c("X", "y") %in% names(wins)))
})

test_that("create_ts_windows: X has correct dimensions", {
  wins <- .create_ts_windows(1:20, input_length = 5L, output_length = 3L)
  # n_windows = 20 - 5 - 3 + 1 = 13
  expect_equal(nrow(wins$X), 13L)
  expect_equal(ncol(wins$X), 5L)
})

test_that("create_ts_windows: y has correct dimensions", {
  wins <- .create_ts_windows(1:20, input_length = 5L, output_length = 3L)
  expect_equal(nrow(wins$y), 13L)
  expect_equal(ncol(wins$y), 3L)
})

test_that("create_ts_windows: first X row equals values[1:input_length]", {
  vals <- as.numeric(1:20)
  wins <- .create_ts_windows(vals, input_length = 4L, output_length = 2L)
  expect_equal(wins$X[1L, ], vals[1:4])
})

test_that("create_ts_windows: first y row equals values[(input+1):(input+output)]", {
  vals <- as.numeric(1:20)
  wins <- .create_ts_windows(vals, input_length = 4L, output_length = 2L)
  expect_equal(wins$y[1L, ], vals[5:6])
})

test_that("create_ts_windows: errors when series too short", {
  expect_error(.create_ts_windows(1:5, 4L, 3L),
               class = "milt_error_insufficient_data")
})

# ── .ts_normalise / .ts_denormalise ───────────────────────────────────────────

test_that("ts_normalise: returns list with norm, mean, sd", {
  n <- .ts_normalise(c(1, 2, 3, 4, 5))
  expect_named(n, c("norm", "mean", "sd"))
})

test_that("ts_normalise: normalised series has mean ≈ 0", {
  n <- .ts_normalise(rnorm(100, mean = 50, sd = 10))
  expect_equal(mean(n$norm), 0, tolerance = 1e-10)
})

test_that("ts_normalise: normalised series has sd ≈ 1", {
  n <- .ts_normalise(rnorm(100, mean = 50, sd = 10))
  expect_equal(stats::sd(n$norm), 1, tolerance = 1e-10)
})

test_that("ts_denormalise: round-trip recovers original values", {
  x   <- c(10, 20, 30, 40, 50)
  n   <- .ts_normalise(x)
  rec <- .ts_denormalise(n$norm, n$mean, n$sd)
  expect_equal(rec, x, tolerance = 1e-10)
})

test_that("ts_normalise: handles constant series without error", {
  n <- .ts_normalise(rep(5, 10))
  expect_equal(n$mean, 5)
  expect_equal(n$sd, 1)   # sd defaulted to 1
  expect_true(all(n$norm == 0))
})

# ── milt_torch_device (torch-dependent) ───────────────────────────────────────

test_that("milt_torch_device: returns a torch_device when torch is installed", {
  skip_if_not_installed("torch")
  dev <- milt_torch_device()
  expect_true(inherits(dev, "torch_device"))
})

# ── .fit_torch_model smoke test ───────────────────────────────────────────────

test_that("fit_torch_model: trains without error on small dataset", {
  skip_if_not_installed("torch")

  # Tiny linear model y = W*x
  net <- torch::nn_module(
    "TinyNet",
    initialize = function() {
      self$lin <- torch::nn_linear(5L, 1L, bias = FALSE)
    },
    forward = function(x) self$lin(x)
  )()

  X <- matrix(rnorm(50 * 5), nrow = 50, ncol = 5)
  y <- matrix(rowSums(X) + rnorm(50, sd = 0.1), ncol = 1L)

  device <- milt_torch_device()
  result <- .fit_torch_model(
    model    = net,
    X_train  = X,
    y_train  = y,
    n_epochs = 20L,
    patience = 5L,
    device   = device
  )
  expect_true(inherits(result, "nn_module"))
})
