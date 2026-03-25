skip_if_not_installed("torch")
skip_if_not(torch::torch_is_installed(), "torch Lantern backend not installed — run torch::install_torch()")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("nbeats: model is registered", {
  expect_true(is_registered_model("nbeats"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("nbeats: fit returns fitted MiltModel", {
  m <- milt_model("nbeats",
                  input_chunk_length  = 12L,
                  output_chunk_length = 6L,
                  n_stacks = 1L, n_blocks = 1L,
                  hidden_size = 16L, n_layers = 2L,
                  n_epochs = 5L, patience = 3L) |>
    milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("nbeats: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_fit(milt_model("nbeats"), s),
    class = "milt_error_not_univariate"
  )
})

test_that("nbeats: errors on insufficient data", {
  tiny <- milt_series(1:10, frequency = 1)
  expect_error(
    milt_model("nbeats",
               input_chunk_length = 8L,
               output_chunk_length = 8L) |>
      milt_fit(tiny),
    class = "milt_error_insufficient_data"
  )
})

test_that("nbeats: errors when not fitted", {
  expect_error(milt_forecast(milt_model("nbeats"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

.nbeats_small <- function() {
  milt_model("nbeats",
             input_chunk_length  = 12L,
             output_chunk_length = 6L,
             n_stacks    = 1L,
             n_blocks    = 1L,
             hidden_size = 16L,
             n_layers    = 2L,
             n_epochs    = 5L,
             patience    = 3L)
}

test_that("nbeats: forecast returns MiltForecast", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("nbeats: horizon matches requested value", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("nbeats: point forecast has no NAs", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("nbeats: point forecast is numeric", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  expect_type(fct$as_tibble()$.mean, "double")
})

test_that("nbeats: lower_80 <= mean + 1e-8", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("nbeats: 95% interval at least as wide as 80%", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("nbeats: horizon longer than output_chunk_length works (recursive)", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(18)
  expect_equal(fct$horizon(), 18L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("nbeats: residuals have correct length", {
  m <- .nbeats_small() |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("nbeats: predict returns correct length", {
  m <- .nbeats_small() |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("nbeats: params are stored correctly", {
  m <- milt_model("nbeats", hidden_size = 32L, n_epochs = 50L)
  p <- m$get_params()
  expect_equal(p$hidden_size, 32L)
  expect_equal(p$n_epochs,    50L)
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("nbeats: full pipe produces correct model name", {
  fct <- .nbeats_small() |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "nbeats")
})
