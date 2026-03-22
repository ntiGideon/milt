# Tests for milt_predict() and milt_residuals()

air <- milt_series(AirPassengers)

# ── milt_predict() ────────────────────────────────────────────────────────────

test_that("predict: returns numeric vector", {
  m <- milt_model("naive") |> milt_fit(air)
  p <- milt_predict(m)
  expect_type(p, "double")
})

test_that("predict: length equals training series length", {
  m <- milt_model("naive") |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

test_that("predict: fitted + residuals reconstruct observed values", {
  m     <- milt_model("drift") |> milt_fit(air)
  v     <- air$values()
  prd   <- milt_predict(m)
  resid <- milt_residuals(m)
  expect_equal(prd + resid, v, tolerance = 1e-8)
})

test_that("predict: errors on unfitted model", {
  expect_error(milt_predict(milt_model("naive")),
               class = "milt_error_not_fitted")
})

test_that("predict: errors when model is not a MiltModel", {
  expect_error(milt_predict("not_a_model"),
               class = "milt_error_not_milt_model")
})

test_that("predict: optional series argument is validated", {
  m <- milt_model("naive") |> milt_fit(air)
  expect_error(milt_predict(m, series = "not_a_series"),
               class = "milt_error_not_milt_series")
})

test_that("predict: works with arima model", {
  skip_if_not_installed("forecast")
  m <- milt_model("auto_arima") |> milt_fit(air)
  p <- milt_predict(m)
  expect_length(p, 144L)
  expect_type(p, "double")
})

test_that("predict: works with ets model", {
  skip_if_not_installed("forecast")
  m <- milt_model("ets") |> milt_fit(air)
  p <- milt_predict(m)
  expect_length(p, 144L)
})

# ── milt_residuals() ──────────────────────────────────────────────────────────

test_that("residuals: returns numeric vector", {
  m <- milt_model("naive") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_type(r, "double")
})

test_that("residuals: length equals training series length", {
  m <- milt_model("naive") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("residuals: errors on unfitted model", {
  expect_error(milt_residuals(milt_model("naive")),
               class = "milt_error_not_fitted")
})

test_that("residuals: errors when model is not a MiltModel", {
  expect_error(milt_residuals(42L),
               class = "milt_error_not_milt_model")
})

test_that("residuals: non-NA residuals have mean near zero for drift on trend data", {
  m     <- milt_model("drift") |> milt_fit(air)
  r     <- milt_residuals(m)
  r_nna <- r[!is.na(r)]
  expect_true(abs(mean(r_nna)) < sd(r_nna))
})

test_that("residuals: snaive first-season residuals are NA", {
  m <- milt_model("snaive") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_true(all(is.na(r[1:12])))
})

test_that("residuals: works with arima model", {
  skip_if_not_installed("forecast")
  m <- milt_model("auto_arima") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_length(r, 144L)
  expect_true(sum(is.na(r)) < 144L)
})
