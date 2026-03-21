# ── Shared fixture ────────────────────────────────────────────────────────────

air <- milt_series(AirPassengers)   # 144 monthly obs, 1949-1960

# ── VERIFY END-TO-END (Step 33) ───────────────────────────────────────────────

test_that("END-TO-END: milt_series(AirPassengers) |> naive |> milt_forecast(12)", {
  fct <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
  expect_equal(fct$horizon(), 12L)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95))
})

# ── Naive ─────────────────────────────────────────────────────────────────────

test_that("naive: model is registered", {
  expect_true(is_registered_model("naive"))
})

test_that("naive: milt_model('naive') returns unfitted MiltModel", {
  m <- milt_model("naive")
  expect_s3_class(m, "MiltModel")
  expect_false(m$is_fitted())
})

test_that("naive: fit sets is_fitted to TRUE", {
  m <- milt_model("naive") |> milt_fit(air)
  expect_true(m$is_fitted())
})

test_that("naive: forecast returns MiltForecast", {
  fct <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("naive: forecast horizon matches requested value", {
  fct <- milt_model("naive") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("naive: point forecast is constant (last value repeated)", {
  m   <- milt_model("naive") |> milt_fit(air)
  fct <- milt_forecast(m, 6)
  last_val <- air$values()[[144]]
  expect_true(all(abs(fct$as_tibble()$.mean - last_val) < 1e-10))
})

test_that("naive: intervals widen with horizon", {
  fct <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  diffs <- diff(tbl$.upper_80 - tbl$.lower_80)
  expect_true(all(diffs >= 0))   # width is monotonically non-decreasing
})

test_that("naive: lower_95 <= lower_80 <= mean <= upper_80 <= upper_95", {
  fct <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80))
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95))
})

test_that("naive: residuals have correct length with NA at position 1", {
  m <- milt_model("naive") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_length(r, 144L)
  expect_true(is.na(r[[1L]]))
  expect_false(any(is.na(r[-1L])))
})

test_that("naive: predict returns lag-1 fitted values", {
  m   <- milt_model("naive") |> milt_fit(air)
  prd <- milt_predict(m)
  v   <- air$values()
  expect_length(prd, 144L)
  expect_true(is.na(prd[[1L]]))
  expect_equal(prd[[2L]], v[[1L]])
  expect_equal(prd[[144L]], v[[143L]])
})

test_that("naive: num_samples produces sample paths", {
  fct <- milt_model("naive") |> milt_fit(air) |>
    milt_forecast(12, num_samples = 100)
  expect_true(fct$has_samples())
})

test_that("naive: errors on non-MiltSeries input to milt_fit", {
  expect_error(milt_fit(milt_model("naive"), AirPassengers),
               class = "milt_error_not_milt_series")
})

# ── Seasonal Naive ────────────────────────────────────────────────────────────

test_that("snaive: model is registered", {
  expect_true(is_registered_model("snaive"))
})

test_that("snaive: forecast returns MiltForecast", {
  fct <- milt_model("snaive") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("snaive: horizon matches", {
  fct <- milt_model("snaive") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("snaive: point forecast equals last seasonal period", {
  m   <- milt_model("snaive") |> milt_fit(air)
  fct <- milt_forecast(m, 12)
  # Last 12 values of AirPassengers (1960) should be the 1-step seasonal naive
  last_12 <- tail(air$values(), 12)
  expect_equal(fct$as_tibble()$.mean, last_12, tolerance = 1e-10)
})

test_that("snaive: intervals are valid", {
  fct <- milt_model("snaive") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
})

test_that("snaive: residuals length equals training obs", {
  m <- milt_model("snaive") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_length(r, 144L)
})

test_that("snaive: first period residuals are NA", {
  m <- milt_model("snaive") |> milt_fit(air)
  r <- milt_residuals(m)
  expect_true(all(is.na(r[1:12])))
})

test_that("snaive: errors for non-seasonal series", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "year", length.out = 10),
    value = 1:10
  )
  s_annual <- milt_series(tbl, time_col = "date", value_cols = "value",
                           frequency = "annual")
  expect_error(
    milt_fit(milt_model("snaive"), s_annual),
    class = "milt_error_invalid_frequency"
  )
})

# ── Drift ─────────────────────────────────────────────────────────────────────

test_that("drift: model is registered", {
  expect_true(is_registered_model("drift"))
})

test_that("drift: forecast returns MiltForecast", {
  fct <- milt_model("drift") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("drift: point forecast is linearly increasing for upward trend", {
  fct  <- milt_model("drift") |> milt_fit(air) |> milt_forecast(12)
  vals <- fct$as_tibble()$.mean
  diffs <- diff(vals)
  expect_true(all(diffs > 0))       # AirPassengers has positive slope
  # All differences should be equal (constant slope extrapolation)
  expect_true(all(abs(diff(diffs)) < 1e-8))
})

test_that("drift: slope is (last - first) / (n - 1)", {
  v     <- air$values()
  n     <- length(v)
  slope <- (v[[n]] - v[[1L]]) / (n - 1L)
  m     <- milt_model("drift") |> milt_fit(air)
  expect_equal(m$.__enclos_env__$private$.backend_model$slope, slope,
               tolerance = 1e-10)
})

test_that("drift: intervals are valid and widen with horizon", {
  fct <- milt_model("drift") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
  widths <- tbl$.upper_80 - tbl$.lower_80
  expect_true(all(diff(widths) >= 0))
})

test_that("drift: residuals have correct length", {
  m <- milt_model("drift") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("drift: predict + residuals sum to values", {
  m     <- milt_model("drift") |> milt_fit(air)
  v     <- air$values()
  prd   <- milt_predict(m)
  resid <- milt_residuals(m)
  expect_equal(prd + resid, v, tolerance = 1e-8)
})

test_that("drift: errors on series with < 3 observations", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 2),
    value = c(1, 2)
  )
  s2 <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_error(milt_fit(milt_model("drift"), s2),
               class = "milt_error_insufficient_data")
})
