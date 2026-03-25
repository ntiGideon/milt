skip_if_not_installed("lightgbm")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("lightgbm: model is registered", {
  expect_true(is_registered_model("lightgbm"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("lightgbm: fit returns fitted MiltModel", {
  m <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("lightgbm: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("lightgbm"), s),
               class = "milt_error_not_univariate")
})

test_that("lightgbm: errors when not fitted", {
  expect_error(milt_forecast(milt_model("lightgbm"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("lightgbm: forecast returns MiltForecast", {
  fct <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("lightgbm: horizon matches requested value", {
  fct <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |>
    milt_fit(air) |>
    milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("lightgbm: point forecast has no NAs", {
  fct <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("lightgbm: lower_80 <= mean <= upper_80", {
  fct <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |>
    milt_fit(air) |>
    milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("lightgbm: residuals have correct length", {
  m <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("lightgbm: first max(lags) residuals are NA", {
  lags <- 1:6
  m    <- milt_model("lightgbm", lags = lags, num_iterations = 10L) |> milt_fit(air)
  r    <- milt_residuals(m)
  expect_true(all(is.na(r[seq_len(max(lags))])))
})

test_that("lightgbm: predict returns correct length", {
  m <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("lightgbm: num_iterations param is stored", {
  m <- milt_model("lightgbm", num_iterations = 50L)
  expect_equal(m$get_params()$num_iterations, 50L)
})

test_that("lightgbm: num_leaves param is stored", {
  m <- milt_model("lightgbm", num_leaves = 15L)
  expect_equal(m$get_params()$num_leaves, 15L)
})

# ── End-to-end ────────────────────────────────────────────────────────────────

test_that("lightgbm: full pipe produces correct model name", {
  fct <- milt_model("lightgbm", lags = 1:6, num_iterations = 10L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_equal(fct$model_name(), "lightgbm")
})
