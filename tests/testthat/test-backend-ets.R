skip_if_not_installed("forecast")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("ets: model is registered", {
  expect_true(is_registered_model("ets"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("ets: fit returns fitted MiltModel", {
  m <- milt_model("ets") |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("ets: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("ets"), s),
               class = "milt_error_not_univariate")
})

test_that("ets: errors when not fitted", {
  expect_error(milt_forecast(milt_model("ets"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("ets: forecast returns MiltForecast", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("ets: horizon matches", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("ets: no NAs in point forecast", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("ets: lower_80 <= mean <= upper_80", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
})

test_that("ets: 95% interval wider than 80%", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("ets: has_intervals is TRUE", {
  fct <- milt_model("ets") |> milt_fit(air) |> milt_forecast(12)
  expect_true(fct$has_intervals())
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("ets: residuals have correct length", {
  m <- milt_model("ets") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("ets: predict returns fitted values of correct length", {
  m <- milt_model("ets") |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Model string parameter ────────────────────────────────────────────────────

test_that("ets: model='AAN' is stored in params", {
  m <- milt_model("ets", model = "AAN")
  expect_equal(m$get_params()$model, "AAN")
})

test_that("ets: explicit model string is used in fitting", {
  # ANN = simple exponential smoothing (no trend, no seasonal)
  m <- milt_model("ets", model = "ANN") |> milt_fit(air)
  expect_true(m$is_fitted())
})
