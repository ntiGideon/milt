# Tests for milt_filter()

air <- milt_series(AirPassengers)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("milt_filter errors on non-MiltSeries input", {
  expect_error(milt_filter(AirPassengers, "moving_average"),
               class = "milt_error_not_milt_series")
})

test_that("milt_filter errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a    = rnorm(24),
    b    = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_filter(s, "moving_average"),
               class = "milt_error_not_univariate")
})

test_that("milt_filter errors on invalid method", {
  expect_error(milt_filter(air, "not_a_method"))
})

# ── Return shape ──────────────────────────────────────────────────────────────

test_that("milt_filter returns a MiltSeries with the same time index", {
  sm <- milt_filter(air, "moving_average")
  expect_s3_class(sm, "MiltSeries")
  expect_equal(sm$n_timesteps(), air$n_timesteps())
  expect_equal(sm$times(), air$times())
})

test_that("milt_filter preserves the value column name", {
  sm  <- milt_filter(air, "moving_average")
  tbl_orig <- air$as_tibble()
  tbl_sm   <- sm$as_tibble()
  expect_equal(names(tbl_sm), names(tbl_orig))
})

# ── Moving Average ────────────────────────────────────────────────────────────

test_that("moving_average: centered window matches manual rolling mean", {
  sm <- milt_filter(air, "moving_average", window = 5L, centered = TRUE)
  v  <- air$values()
  manual <- stats::filter(v, rep(1 / 5, 5), sides = 2L)
  expect_equal(sm$values(), as.numeric(manual))
})

test_that("moving_average: trailing (non-centered) window has NAs only at the start", {
  sm <- milt_filter(air, "moving_average", window = 4L, centered = FALSE)
  v  <- sm$values()
  expect_true(all(is.na(v[1:3])))
  expect_false(any(is.na(v[-(1:3)])))
})

test_that("moving_average: window of 1 returns the original series unchanged", {
  sm <- milt_filter(air, "moving_average", window = 1L)
  expect_equal(sm$values(), air$values())
})

test_that("moving_average: errors on window larger than series length", {
  expect_error(milt_filter(air, "moving_average", window = 1000L),
               class = "milt_error_invalid_arg")
})

test_that("moving_average: errors on non-positive window", {
  expect_error(milt_filter(air, "moving_average", window = 0L),
               class = "milt_error_invalid_arg")
})

# ── Kalman ────────────────────────────────────────────────────────────────────

test_that("kalman: returns smoothed series of correct length", {
  sm <- milt_filter(air, "kalman")
  expect_equal(sm$n_timesteps(), air$n_timesteps())
  expect_false(any(is.na(sm$values())))
})

test_that("kalman: accepts type = 'trend'", {
  sm <- milt_filter(air, "kalman", type = "trend")
  expect_equal(sm$n_timesteps(), air$n_timesteps())
})

test_that("kalman: errors on invalid type", {
  expect_error(milt_filter(air, "kalman", type = "not_a_type"))
})

# ── Gaussian Process ──────────────────────────────────────────────────────────

test_that("gp: returns smoothed series of correct length", {
  sm <- milt_filter(air, "gp")
  expect_equal(sm$n_timesteps(), air$n_timesteps())
  expect_false(any(is.na(sm$values())))
})

test_that("gp: reduces variance relative to a noisy series (actual smoothing)", {
  set.seed(1)
  noisy_vals <- sin(seq(0, 10, length.out = 100)) + rnorm(100, sd = 0.5)
  s  <- milt_series(noisy_vals, frequency = "monthly", start = c(2020, 1))
  sm <- milt_filter(s, "gp")
  expect_true(stats::sd(diff(sm$values())) < stats::sd(diff(noisy_vals)))
})

test_that("gp: accepts custom length_scale and noise", {
  sm <- milt_filter(air, "gp", length_scale = 2, noise = 5)
  expect_equal(sm$n_timesteps(), air$n_timesteps())
})
