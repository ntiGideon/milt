skip_if_not_installed("glmnet")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("elastic_net: model is registered", {
  expect_true(is_registered_model("elastic_net"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("elastic_net: fit returns fitted MiltModel", {
  m <- milt_model("elastic_net", lags = 1:6) |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("elastic_net: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("elastic_net"), s),
               class = "milt_error_not_univariate")
})

test_that("elastic_net: errors when not fitted", {
  expect_error(milt_forecast(milt_model("elastic_net"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("elastic_net: forecast returns MiltForecast", {
  fct <- milt_model("elastic_net", lags = 1:6) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("elastic_net: horizon matches", {
  fct <- milt_model("elastic_net", lags = 1:6) |>
    milt_fit(air) |>
    milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("elastic_net: point forecast has no NAs", {
  fct <- milt_model("elastic_net", lags = 1:6) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("elastic_net: lower_80 <= mean <= upper_80", {
  fct <- milt_model("elastic_net", lags = 1:6) |>
    milt_fit(air) |>
    milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

# ── Alpha / Lambda params ─────────────────────────────────────────────────────

test_that("elastic_net: alpha=0 (ridge) fits without error", {
  m <- milt_model("elastic_net", lags = 1:6, alpha = 0) |> milt_fit(air)
  expect_true(m$is_fitted())
})

test_that("elastic_net: alpha=1 (lasso) fits without error", {
  m <- milt_model("elastic_net", lags = 1:6, alpha = 1) |> milt_fit(air)
  expect_true(m$is_fitted())
})

test_that("elastic_net: explicit lambda fits without error", {
  m <- milt_model("elastic_net", lags = 1:6, lambda = 0.01) |> milt_fit(air)
  expect_true(m$is_fitted())
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("elastic_net: residuals have correct length", {
  m <- milt_model("elastic_net", lags = 1:6) |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("elastic_net: predict returns correct length", {
  m <- milt_model("elastic_net", lags = 1:6) |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── End-to-end ────────────────────────────────────────────────────────────────

test_that("elastic_net: full pipe produces correct model name", {
  fct <- milt_model("elastic_net", lags = 1:6) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_equal(fct$model_name(), "elastic_net")
})
