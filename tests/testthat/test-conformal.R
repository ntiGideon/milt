# Tests for milt_conformal()

air <- milt_series(AirPassengers)   # 144 monthly obs

# ── Input validation ──────────────────────────────────────────────────────────

test_that("conformal: errors on non-MiltModel input", {
  expect_error(milt_conformal("not_a_model", air, 12),
               class = "milt_error_not_milt_model")
})

test_that("conformal: errors on non-MiltSeries input", {
  expect_error(milt_conformal(milt_model("naive"), AirPassengers, 12),
               class = "milt_error_not_milt_series")
})

test_that("conformal: errors on invalid stride", {
  expect_error(milt_conformal(milt_model("naive"), air, 12, stride = 0L),
               class = "milt_error_invalid_arg")
})

test_that("conformal: errors when insufficient data", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 10),
    value = 1:10
  )
  s_small <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_error(
    milt_conformal(milt_model("naive"), s_small, horizon = 9, initial_window = 8),
    class = "milt_error_insufficient_data"
  )
})

# ── Return shape ──────────────────────────────────────────────────────────────

test_that("conformal: returns a MiltForecast", {
  fct <- milt_conformal(milt_model("naive"), air, horizon = 12,
                        initial_window = 120L, stride = 12L)
  expect_s3_class(fct, "MiltForecast")
  expect_equal(fct$horizon(), 12L)
})

test_that("conformal: model_name is tagged with '+conformal'", {
  fct <- milt_conformal(milt_model("naive"), air, horizon = 12,
                        initial_window = 120L, stride = 12L)
  expect_true(grepl("\\+conformal$", fct$model_name()))
})

test_that("conformal: point forecast matches a plain forecast from the same model", {
  fct_conf  <- milt_conformal(milt_model("naive"), air, horizon = 12,
                              initial_window = 120L, stride = 12L)
  fct_plain <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct_conf$as_tibble()$.mean, fct_plain$as_tibble()$.mean, tolerance = 1e-10)
})

test_that("conformal: intervals are valid (lower <= mean <= upper)", {
  fct <- milt_conformal(milt_model("naive"), air, horizon = 12,
                        initial_window = 120L, stride = 12L)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95))
})

test_that("conformal: works with sliding calibration window", {
  fct <- milt_conformal(milt_model("naive"), air, horizon = 12,
                        initial_window = 60L, stride = 12L, method = "sliding")
  expect_s3_class(fct, "MiltForecast")
})

test_that("conformal: works with drift model", {
  fct <- milt_conformal(milt_model("drift"), air, horizon = 6,
                        initial_window = 100L, stride = 6L)
  expect_s3_class(fct, "MiltForecast")
})

test_that("conformal: does not modify the original model object", {
  m <- milt_model("naive")
  milt_conformal(m, air, horizon = 12, initial_window = 120L, stride = 12L)
  expect_false(m$is_fitted())
})
