# Tests for all four feature engineering step functions

air <- milt_series(AirPassengers)   # 144 monthly obs

# ══════════════════════════════════════════════════════════════════════════════
# milt_step_lag
# ══════════════════════════════════════════════════════════════════════════════

test_that("step_lag: returns a MiltSeries", {
  s <- milt_step_lag(air, lags = 1:3)
  expect_s3_class(s, "MiltSeries")
})

test_that("step_lag: drops max(lags) rows", {
  s <- milt_step_lag(air, lags = 1:6)
  expect_equal(s$n_timesteps(), 144L - 6L)
})

test_that("step_lag: adds correct number of lag columns", {
  s    <- milt_step_lag(air, lags = c(1L, 3L, 12L))
  nms  <- names(s$as_tibble())
  expect_true(all(c(".lag_1", ".lag_3", ".lag_12") %in% nms))
})

test_that("step_lag: lag_1 equals value shifted by 1", {
  s   <- milt_step_lag(air, lags = 1L)
  tbl <- s$as_tibble()
  v   <- air$values()
  # First row of lagged series: lag_1 = original v[1]
  expect_equal(tbl$.lag_1[[1L]], v[[1L]], tolerance = 1e-10)
})

test_that("step_lag: no NA values remain in lag columns", {
  s   <- milt_step_lag(air, lags = 1:12)
  tbl <- s$as_tibble()
  lag_cols <- grep("^\\.lag_", names(tbl), value = TRUE)
  expect_false(any(is.na(tbl[lag_cols])))
})

test_that("step_lag: stores spec attribute with lags and last_values", {
  s    <- milt_step_lag(air, lags = 1:3)
  spec <- attr(s, "milt_step_lag")
  expect_equal(spec$lags, 1:3)
  expect_length(spec$last_values, 3L)
})

test_that("step_lag: errors on non-MiltSeries input", {
  expect_error(milt_step_lag(AirPassengers, lags = 1:3),
               class = "milt_error_not_milt_series")
})

test_that("step_lag: errors on invalid lags", {
  expect_error(milt_step_lag(air, lags = 0L),
               class = "milt_error_invalid_arg")
})

test_that("step_lag: errors when series too short for lags", {
  tiny <- milt_series(1:5, frequency = 1L)
  expect_error(milt_step_lag(tiny, lags = 1:10),
               class = "milt_error_insufficient_data")
})

# ══════════════════════════════════════════════════════════════════════════════
# milt_step_rolling
# ══════════════════════════════════════════════════════════════════════════════

test_that("step_rolling: returns a MiltSeries", {
  s <- milt_step_rolling(air, windows = 3L, fns = "mean")
  expect_s3_class(s, "MiltSeries")
})

test_that("step_rolling: drops max(windows)-1 rows", {
  s <- milt_step_rolling(air, windows = c(3L, 6L), fns = "mean")
  expect_equal(s$n_timesteps(), 144L - (6L - 1L))
})

test_that("step_rolling: adds correct column names", {
  s   <- milt_step_rolling(air, windows = c(3L, 6L), fns = c("mean", "sd"))
  nms <- names(s$as_tibble())
  expect_true(all(c(".rolling_mean_3", ".rolling_sd_3",
                    ".rolling_mean_6", ".rolling_sd_6") %in% nms))
})

test_that("step_rolling: no NA in rolling columns after drop", {
  s    <- milt_step_rolling(air, windows = 12L, fns = "mean")
  tbl  <- s$as_tibble()
  col  <- ".rolling_mean_12"
  expect_false(any(is.na(tbl[[col]])))
})

test_that("step_rolling: rolling mean of constant series equals constant", {
  vals    <- rep(5, 30)
  s_const <- milt_series(vals, frequency = 1L)
  s_rol   <- milt_step_rolling(s_const, windows = 5L, fns = "mean")
  expect_true(all(abs(s_rol$as_tibble()$.rolling_mean_5 - 5) < 1e-10))
})

test_that("step_rolling: stores spec attribute", {
  s    <- milt_step_rolling(air, windows = 3L, fns = "mean")
  spec <- attr(s, "milt_step_rolling")
  expect_equal(spec$windows, 3L)
  expect_equal(spec$fns, "mean")
})

test_that("step_rolling: errors on invalid fn name", {
  expect_error(milt_step_rolling(air, windows = 3L, fns = "variance"),
               regexp = "should be one of")
})

# ══════════════════════════════════════════════════════════════════════════════
# milt_step_fourier
# ══════════════════════════════════════════════════════════════════════════════

test_that("step_fourier: returns a MiltSeries", {
  s <- milt_step_fourier(air, period = 12, K = 2L)
  expect_s3_class(s, "MiltSeries")
})

test_that("step_fourier: does not drop rows", {
  s <- milt_step_fourier(air, period = 12, K = 2L)
  expect_equal(s$n_timesteps(), 144L)
})

test_that("step_fourier: adds 2*K columns", {
  s   <- milt_step_fourier(air, period = 12, K = 3L)
  tbl <- s$as_tibble()
  expected_cols <- c(".fourier_sin_1", ".fourier_cos_1",
                     ".fourier_sin_2", ".fourier_cos_2",
                     ".fourier_sin_3", ".fourier_cos_3")
  expect_true(all(expected_cols %in% names(tbl)))
})

test_that("step_fourier: sin and cos values are in [-1, 1]", {
  s   <- milt_step_fourier(air, period = 12, K = 2L)
  tbl <- s$as_tibble()
  sin_cols <- grep("sin", names(tbl), value = TRUE)
  cos_cols <- grep("cos", names(tbl), value = TRUE)
  expect_true(all(abs(tbl[sin_cols]) <= 1 + 1e-10))
  expect_true(all(abs(tbl[cos_cols]) <= 1 + 1e-10))
})

test_that("step_fourier: no NA values", {
  s   <- milt_step_fourier(air, period = 12, K = 4L)
  tbl <- s$as_tibble()
  ft_cols <- grep("^\\.fourier_", names(tbl), value = TRUE)
  expect_false(any(is.na(tbl[ft_cols])))
})

test_that("step_fourier: errors when K > floor(period/2)", {
  expect_error(milt_step_fourier(air, period = 12, K = 7L),
               class = "milt_error_invalid_arg")
})

test_that("step_fourier: stores spec attribute", {
  s    <- milt_step_fourier(air, period = 12, K = 2L)
  spec <- attr(s, "milt_step_fourier")
  expect_equal(spec$period, 12)
  expect_equal(spec$K, 2L)
})

# ══════════════════════════════════════════════════════════════════════════════
# milt_step_calendar
# ══════════════════════════════════════════════════════════════════════════════

test_that("step_calendar: returns a MiltSeries", {
  s <- milt_step_calendar(air)
  expect_s3_class(s, "MiltSeries")
})

test_that("step_calendar: does not drop rows", {
  s <- milt_step_calendar(air)
  expect_equal(s$n_timesteps(), 144L)
})

test_that("step_calendar: adds .year column", {
  s <- milt_step_calendar(air)
  expect_true(".year" %in% names(s$as_tibble()))
})

test_that("step_calendar: adds .month column", {
  s <- milt_step_calendar(air)
  expect_true(".month" %in% names(s$as_tibble()))
})

test_that("step_calendar: .month values are in 1:12", {
  s    <- milt_step_calendar(air)
  mnth <- s$as_tibble()$.month
  expect_true(all(mnth >= 1L & mnth <= 12L))
})

test_that("step_calendar: .is_weekend is 0 or 1", {
  s   <- milt_step_calendar(air)
  iwe <- s$as_tibble()$.is_weekend
  expect_true(all(iwe %in% c(0L, 1L)))
})

test_that("step_calendar: hourly data gets .hour column", {
  tbl <- tibble::tibble(
    dt    = seq(as.POSIXct("2023-01-01", tz = "UTC"),
                by = "hour", length.out = 48L),
    value = rnorm(48L)
  )
  s_hr <- milt_series(tbl, time_col = "dt", value_cols = "value",
                      frequency = "hourly")
  s_cal <- milt_step_calendar(s_hr)
  expect_true(".hour" %in% names(s_cal$as_tibble()))
})

test_that("step_calendar: stores spec attribute", {
  s    <- milt_step_calendar(air)
  spec <- attr(s, "milt_step_calendar")
  expect_false(is.null(spec))
})
