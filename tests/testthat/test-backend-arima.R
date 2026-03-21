skip_if_not_installed("forecast")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("auto_arima: model is registered", {
  expect_true(is_registered_model("auto_arima"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("auto_arima: fit returns fitted MiltModel", {
  m <- milt_model("auto_arima") |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("auto_arima: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("auto_arima"), s),
               class = "milt_error_not_univariate")
})

test_that("auto_arima: errors on unfitted model forecast", {
  expect_error(milt_forecast(milt_model("auto_arima"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("auto_arima: forecast returns MiltForecast", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("auto_arima: horizon matches requested value", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("auto_arima: point forecast is numeric with no NAs", {
  fct  <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  vals <- fct$as_tibble()$.mean
  expect_type(vals, "double")
  expect_false(any(is.na(vals)))
})

test_that("auto_arima: lower_80 <= mean <= upper_80", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
})

test_that("auto_arima: 95% interval wider than 80%", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95))
})

test_that("auto_arima: has_intervals is TRUE", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  expect_true(fct$has_intervals())
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("auto_arima: residuals have correct length", {
  m <- milt_model("auto_arima") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("auto_arima: residuals are numeric", {
  m <- milt_model("auto_arima") |> milt_fit(air)
  expect_type(milt_residuals(m), "double")
})

test_that("auto_arima: predict returns fitted values", {
  m   <- milt_model("auto_arima") |> milt_fit(air)
  prd <- milt_predict(m)
  expect_length(prd, 144L)
  expect_type(prd, "double")
})

# ── Hyperparameters ───────────────────────────────────────────────────────────

test_that("auto_arima: stepwise=FALSE is stored in params", {
  m <- milt_model("auto_arima", stepwise = FALSE)
  expect_false(m$get_params()$stepwise)
})

# ── End-to-end pipe ───────────────────────────────────────────────────────────

test_that("auto_arima: full pipe works", {
  fct <- milt_model("auto_arima") |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "auto_arima")
})
