skip_if_not_installed("forecast")

air <- milt_series(AirPassengers)   # seasonal monthly series

# ── Registration ──────────────────────────────────────────────────────────────

test_that("stl: model is registered", {
  expect_true(is_registered_model("stl"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("stl: fit returns fitted MiltModel", {
  m <- milt_model("stl") |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("stl: errors on non-seasonal series (frequency = 1)", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2000-01-01"), by = "year", length.out = 20),
    value = cumsum(rnorm(20))
  )
  s_annual <- milt_series(tbl, time_col = "date", value_cols = "value",
                           frequency = "annual")
  expect_error(milt_fit(milt_model("stl"), s_annual),
               class = "milt_error_invalid_frequency")
})

test_that("stl: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("stl"), s),
               class = "milt_error_not_univariate")
})

test_that("stl: errors on invalid method", {
  expect_error(milt_model("stl", method = "random_forest"),
               class = "milt_error_invalid_arg")
})

test_that("stl: errors when not fitted", {
  expect_error(milt_forecast(milt_model("stl"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("stl: forecast returns MiltForecast (ets method)", {
  fct <- milt_model("stl", method = "ets") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("stl: forecast returns MiltForecast (arima method)", {
  fct <- milt_model("stl", method = "arima") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("stl: horizon matches", {
  fct <- milt_model("stl") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("stl: point forecast has no NAs", {
  fct <- milt_model("stl") |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("stl: lower_80 <= mean <= upper_80", {
  fct <- milt_model("stl") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

test_that("stl: 95% interval is at least as wide as 80%", {
  fct <- milt_model("stl") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

# ── Residuals / Predict (stl warns — stlf does not expose them) ──────────────

test_that("stl: milt_predict warns and returns NA vector", {
  m <- milt_model("stl") |> milt_fit(air)
  expect_warning(prd <- milt_predict(m))
  expect_length(prd, 144L)
})

test_that("stl: milt_residuals warns and returns NA vector", {
  m <- milt_model("stl") |> milt_fit(air)
  expect_warning(r <- milt_residuals(m))
  expect_length(r, 144L)
})

# ── End-to-end pipe ───────────────────────────────────────────────────────────

test_that("stl: full pipe produces correct model name", {
  fct <- milt_model("stl") |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "stl")
})

test_that("stl: as_tibble output integrates with milt_accuracy", {
  spl    <- milt_split(air)
  fct    <- milt_model("stl") |> milt_fit(spl$train) |>
    milt_forecast(spl$test$n_timesteps())
  actual <- spl$test$values()
  acc    <- milt_accuracy(actual, fct$as_tibble()$.mean)
  expect_s3_class(acc, "tbl_df")
  expect_true("RMSE" %in% acc$metric)
})
