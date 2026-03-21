skip_if_not_installed("ranger")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("random_forest: model is registered", {
  expect_true(is_registered_model("random_forest"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("random_forest: fit returns fitted MiltModel", {
  m <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("random_forest: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("random_forest"), s),
               class = "milt_error_not_univariate")
})

test_that("random_forest: errors when not fitted", {
  expect_error(milt_forecast(milt_model("random_forest"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("random_forest: forecast returns MiltForecast", {
  fct <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("random_forest: horizon matches", {
  fct <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |>
    milt_fit(air) |>
    milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("random_forest: point forecast has no NAs", {
  fct <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("random_forest: lower_80 <= mean <= upper_80", {
  fct <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |>
    milt_fit(air) |>
    milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("random_forest: residuals have correct length", {
  m <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("random_forest: predict returns correct length", {
  m <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── End-to-end ────────────────────────────────────────────────────────────────

test_that("random_forest: full pipe produces correct model name", {
  fct <- milt_model("random_forest", lags = 1:6, num.trees = 50L) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_equal(fct$model_name(), "random_forest")
})
