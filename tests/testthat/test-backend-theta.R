skip_if_not_installed("forecast")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("theta: model is registered", {
  expect_true(is_registered_model("theta"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("theta: fit returns fitted MiltModel", {
  m <- milt_model("theta") |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("theta: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("theta"), s),
               class = "milt_error_not_univariate")
})

test_that("theta: errors when not fitted", {
  expect_error(milt_forecast(milt_model("theta"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("theta: forecast returns MiltForecast", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("theta: horizon matches", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("theta: point forecast is numeric with no NAs", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("theta: lower_80 <= mean <= upper_80", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

test_that("theta: 95% interval wider than 80%", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

# ── Residuals / Predict (theta warns) ────────────────────────────────────────

test_that("theta: milt_predict warns and returns NA vector", {
  m <- milt_model("theta") |> milt_fit(air)
  expect_warning(prd <- milt_predict(m))
  expect_length(prd, 144L)
  expect_true(all(is.na(prd)))
})

test_that("theta: milt_residuals warns and returns NA vector", {
  m <- milt_model("theta") |> milt_fit(air)
  expect_warning(r <- milt_residuals(m))
  expect_length(r, 144L)
  expect_true(all(is.na(r)))
})

# ── End-to-end pipe ───────────────────────────────────────────────────────────

test_that("theta: full pipe produces correct model name", {
  fct <- milt_model("theta") |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "theta")
})
