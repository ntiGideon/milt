skip_if_not_installed("torch")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("tcn: model is registered", {
  expect_true(is_registered_model("tcn"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

.tcn_small <- function() {
  milt_model("tcn",
             input_chunk_length  = 12L,
             output_chunk_length = 6L,
             n_filters   = 8L,
             kernel_size = 3L,
             n_layers    = 2L,
             dropout     = 0.0,
             n_epochs    = 5L,
             patience    = 3L)
}

test_that("tcn: fit returns fitted MiltModel", {
  m <- .tcn_small() |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("tcn: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_fit(milt_model("tcn"), s),
    class = "milt_error_not_univariate"
  )
})

test_that("tcn: errors on insufficient data", {
  tiny <- milt_series(1:10)
  expect_error(
    milt_model("tcn",
               input_chunk_length = 8L,
               output_chunk_length = 8L) |>
      milt_fit(tiny),
    class = "milt_error_insufficient_data"
  )
})

test_that("tcn: errors when not fitted", {
  expect_error(milt_forecast(milt_model("tcn"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("tcn: forecast returns MiltForecast", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("tcn: horizon matches requested value", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("tcn: point forecast has no NAs", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("tcn: point forecast is numeric", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  expect_type(fct$as_tibble()$.mean, "double")
})

test_that("tcn: lower_80 <= mean + 1e-8", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("tcn: 95% interval at least as wide as 80%", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("tcn: recursive horizon longer than output_chunk_length", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(18)
  expect_equal(fct$horizon(), 18L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("tcn: residuals have correct length", {
  m <- .tcn_small() |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("tcn: predict returns correct length", {
  m <- .tcn_small() |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("tcn: params are stored correctly", {
  m <- milt_model("tcn", n_filters = 16L, kernel_size = 5L)
  p <- m$get_params()
  expect_equal(p$n_filters,   16L)
  expect_equal(p$kernel_size, 5L)
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("tcn: full pipe produces correct model name", {
  fct <- .tcn_small() |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "tcn")
})
