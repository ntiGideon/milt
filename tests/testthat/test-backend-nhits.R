skip_if_not_installed("torch")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("nhits: model is registered", {
  expect_true(is_registered_model("nhits"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

.nhits_small <- function() {
  milt_model("nhits",
             input_chunk_length  = 12L,
             output_chunk_length = 6L,
             n_stacks    = 2L,
             n_blocks    = 1L,
             hidden_size = 16L,
             n_layers    = 2L,
             n_epochs    = 5L,
             patience    = 3L)
}

test_that("nhits: fit returns fitted MiltModel", {
  m <- .nhits_small() |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("nhits: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_fit(milt_model("nhits"), s),
    class = "milt_error_not_univariate"
  )
})

test_that("nhits: errors on insufficient data", {
  tiny <- milt_series(1:10)
  expect_error(
    milt_model("nhits",
               input_chunk_length = 8L,
               output_chunk_length = 8L) |>
      milt_fit(tiny),
    class = "milt_error_insufficient_data"
  )
})

test_that("nhits: errors when not fitted", {
  expect_error(milt_forecast(milt_model("nhits"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("nhits: forecast returns MiltForecast", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("nhits: horizon matches requested value", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("nhits: point forecast has no NAs", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("nhits: point forecast is numeric", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  expect_type(fct$as_tibble()$.mean, "double")
})

test_that("nhits: lower_80 <= mean + 1e-8", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("nhits: 95% interval at least as wide as 80%", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("nhits: recursive horizon longer than output_chunk_length", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(18)
  expect_equal(fct$horizon(), 18L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("nhits: residuals have correct length", {
  m <- .nhits_small() |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("nhits: predict returns correct length", {
  m <- .nhits_small() |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("nhits: params are stored correctly", {
  m <- milt_model("nhits", hidden_size = 32L, n_stacks = 2L)
  p <- m$get_params()
  expect_equal(p$hidden_size, 32L)
  expect_equal(p$n_stacks,    2L)
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("nhits: full pipe produces correct model name", {
  fct <- .nhits_small() |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "nhits")
})
