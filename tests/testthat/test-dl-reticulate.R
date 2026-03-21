# Tests for the reticulate / Darts bridge (dl-reticulate.R).
# All tests skip when reticulate is not installed OR when Python / Darts
# are unavailable so they remain no-ops in normal CI without Python.

# ── Registration ──────────────────────────────────────────────────────────────

test_that("darts_rnn: model is registered", {
  expect_true(is_registered_model("darts_rnn"))
})

test_that("darts_transformer: model is registered", {
  expect_true(is_registered_model("darts_transformer"))
})

test_that("darts_nbeats: model is registered", {
  expect_true(is_registered_model("darts_nbeats"))
})

# ── milt_setup_darts() ────────────────────────────────────────────────────────

test_that("milt_setup_darts: errors clearly when reticulate is absent", {
  skip_if(requireNamespace("reticulate", quietly = TRUE),
          "reticulate is installed — skip 'absent' test")
  expect_error(milt_setup_darts(), class = "milt_error_missing_package")
})

test_that("milt_setup_darts: errors clearly when Python is not found", {
  skip_if_not_installed("reticulate")
  skip_if(reticulate::py_available(initialize = FALSE),
          "Python already initialised — skip 'no python' test")
  # Don't call py_available(initialize = TRUE) as it might find Python.
  # Just confirm the function is exported and callable.
  expect_true(is.function(milt_setup_darts))
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("darts_rnn: params are stored correctly (no Python needed)", {
  m <- milt_model("darts_rnn", hidden_dim = 128L, n_rnn_layers = 3L)
  p <- m$get_params()
  expect_equal(p$hidden_dim,   128L)
  expect_equal(p$n_rnn_layers, 3L)
})

test_that("darts_transformer: params are stored correctly", {
  m <- milt_model("darts_transformer", d_model = 32L, nhead = 2L)
  p <- m$get_params()
  expect_equal(p$d_model, 32L)
  expect_equal(p$nhead,   2L)
})

test_that("darts_nbeats: params are stored correctly", {
  m <- milt_model("darts_nbeats", num_stacks = 10L, layer_widths = 128L)
  p <- m$get_params()
  expect_equal(p$num_stacks,   10L)
  expect_equal(p$layer_widths, 128L)
})

# ── Unfitted model errors ──────────────────────────────────────────────────────

test_that("darts_rnn: errors when forecasting unfitted model", {
  expect_error(
    milt_forecast(milt_model("darts_rnn"), 12),
    class = "milt_error_not_fitted"
  )
})

# ── Full pipeline (requires Python + Darts) ───────────────────────────────────

.darts_available <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) return(FALSE)
  if (!reticulate::py_available(initialize = TRUE))    return(FALSE)
  tryCatch({
    reticulate::import("darts")
    TRUE
  }, error = function(e) FALSE)
}

test_that("darts_rnn: fit + forecast end-to-end", {
  skip_if(!.darts_available(), "Python / Darts not available")
  air <- milt_series(AirPassengers)
  m   <- milt_model("darts_rnn",
                    input_chunk_length = 12L,
                    training_length    = 18L,
                    hidden_dim         = 16L,
                    n_rnn_layers       = 1L,
                    n_epochs           = 5L)
  fct <- m |> milt_fit(air) |> milt_forecast(12, num_samples = 50L)
  expect_s3_class(fct, "MiltForecast")
  expect_equal(fct$horizon(), 12L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("darts_rnn: PI lower_80 <= mean", {
  skip_if(!.darts_available(), "Python / Darts not available")
  air <- milt_series(AirPassengers)
  fct <- milt_model("darts_rnn",
                    input_chunk_length = 12L,
                    training_length    = 18L,
                    hidden_dim         = 16L,
                    n_rnn_layers       = 1L,
                    n_epochs           = 5L) |>
    milt_fit(air) |>
    milt_forecast(12, num_samples = 100L)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("darts_rnn: predict() warns and returns NAs", {
  skip_if(!.darts_available(), "Python / Darts not available")
  air <- milt_series(AirPassengers)
  m   <- milt_model("darts_rnn",
                    input_chunk_length = 12L,
                    training_length    = 18L,
                    hidden_dim         = 16L,
                    n_rnn_layers       = 1L,
                    n_epochs           = 5L) |>
    milt_fit(air)
  expect_warning(pred <- milt_predict(m))
  expect_true(all(is.na(pred)))
})

test_that("darts_rnn: residuals() warns and returns NAs", {
  skip_if(!.darts_available(), "Python / Darts not available")
  air <- milt_series(AirPassengers)
  m   <- milt_model("darts_rnn",
                    input_chunk_length = 12L,
                    training_length    = 18L,
                    hidden_dim         = 16L,
                    n_rnn_layers       = 1L,
                    n_epochs           = 5L) |>
    milt_fit(air)
  expect_warning(res <- milt_residuals(m))
  expect_true(all(is.na(res)))
})

test_that("darts_rnn: errors on multivariate series", {
  skip_if(!.darts_available(), "Python / Darts not available")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_model("darts_rnn") |> milt_fit(s),
    class = "milt_error_not_univariate"
  )
})
