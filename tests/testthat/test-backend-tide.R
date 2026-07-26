skip_if_not_installed("torch")
skip_if_not(torch::torch_is_installed(), "torch Lantern backend not installed — run torch::install_torch()")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("tide: model is registered", {
  expect_true(is_registered_model("tide"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("tide: fit returns fitted MiltModel", {
  m <- milt_model("tide",
                  input_chunk_length  = 12L,
                  output_chunk_length = 6L,
                  hidden_size = 16L,
                  n_encoder_layers = 1L, n_decoder_layers = 1L,
                  n_epochs = 5L, patience = 3L) |>
    milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("tide: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_fit(milt_model("tide"), s),
    class = "milt_error_not_univariate"
  )
})

test_that("tide: errors on insufficient data", {
  tiny <- milt_series(1:10, frequency = 1)
  expect_error(
    milt_model("tide",
               input_chunk_length = 8L,
               output_chunk_length = 8L) |>
      milt_fit(tiny),
    class = "milt_error_insufficient_data"
  )
})

test_that("tide: errors when not fitted", {
  expect_error(milt_forecast(milt_model("tide"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

.tide_small <- function() {
  milt_model("tide",
             input_chunk_length  = 12L,
             output_chunk_length = 6L,
             hidden_size = 16L,
             n_encoder_layers = 1L,
             n_decoder_layers = 1L,
             n_epochs    = 5L,
             patience    = 3L)
}

test_that("tide: forecast returns MiltForecast", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("tide: horizon matches requested value", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("tide: point forecast has no NAs", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("tide: point forecast is numeric", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  expect_type(fct$as_tibble()$.mean, "double")
})

test_that("tide: lower_80 <= mean + 1e-8", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("tide: 95% interval at least as wide as 80%", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("tide: horizon longer than output_chunk_length works (recursive)", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(18)
  expect_equal(fct$horizon(), 18L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("tide: residuals have correct length", {
  m <- .tide_small() |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("tide: predict returns correct length", {
  m <- .tide_small() |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("tide: params are stored correctly", {
  m <- milt_model("tide", hidden_size = 32L, n_epochs = 50L)
  p <- m$get_params()
  expect_equal(p$hidden_size, 32L)
  expect_equal(p$n_epochs,    50L)
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("tide: full pipe produces correct model name", {
  fct <- .tide_small() |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "tide")
})
