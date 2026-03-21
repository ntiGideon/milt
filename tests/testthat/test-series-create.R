# Tests for milt_series() constructor (R/series-create.R)
# Verifies: creation from ts, mts, data.frame, tibble, numeric vector, tsibble

# ── From ts ───────────────────────────────────────────────────────────────────

test_that("milt_series(ts) creates a MiltSeries", {
  s <- milt_series(AirPassengers)
  expect_s3_class(s, "MiltSeries")
})

test_that("milt_series(AirPassengers) has correct dimensions", {
  s <- milt_series(AirPassengers)
  expect_equal(s$n_timesteps(),  144L)
  expect_equal(s$n_components(),   1L)
  expect_true(s$is_univariate())
})

test_that("milt_series(AirPassengers) detects monthly frequency", {
  s <- milt_series(AirPassengers)
  expect_equal(s$freq(), "monthly")
})

test_that("milt_series(AirPassengers) start/end times are correct", {
  s <- milt_series(AirPassengers)
  expect_equal(s$start_time(), as.Date("1949-01-01"))
  expect_equal(s$end_time(),   as.Date("1960-12-01"))
})

test_that("milt_series(AirPassengers) has no gaps", {
  s <- milt_series(AirPassengers)
  expect_false(s$has_gaps())
})

test_that("milt_series(ts) values match original ts values", {
  s <- milt_series(AirPassengers)
  expect_equal(s$values(), as.numeric(AirPassengers))
})

# ── From mts (multivariate ts) ────────────────────────────────────────────────

test_that("milt_series(mts) creates multivariate MiltSeries", {
  skip_if_not_installed("stats")
  m <- ts(matrix(1:48, ncol = 2, dimnames = list(NULL, c("a", "b"))),
          frequency = 12, start = c(2000, 1))
  s <- milt_series(m)
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$n_components(), 2L)
  expect_true(s$is_multivariate())
})

# ── From data.frame ───────────────────────────────────────────────────────────

test_that("milt_series(data.frame) creates a MiltSeries", {
  df <- data.frame(
    date  = seq(as.Date("2021-01-01"), by = "month", length.out = 12),
    sales = cumsum(rnorm(12, 100))
  )
  s <- milt_series(df, time_col = "date", value_cols = "sales")
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$n_timesteps(), 12L)
})

test_that("milt_series(data.frame) auto-detects time column", {
  df <- data.frame(
    date  = seq(as.Date("2021-01-01"), by = "month", length.out = 6),
    value = 1:6
  )
  # No time_col supplied — should auto-detect "date"
  expect_message(
    s <- milt_series(df),
    "date"
  )
  expect_s3_class(s, "MiltSeries")
})

test_that("milt_series(data.frame) errors when time_col is wrong", {
  df <- data.frame(date = Sys.Date(), v = 1)
  expect_error(
    milt_series(df, time_col = "no_such_col", value_cols = "v"),
    class = "milt_error_no_time_col"
  )
})

test_that("milt_series(data.frame) handles multi-series with group_col", {
  df <- data.frame(
    date  = rep(seq(as.Date("2021-01-01"), by = "month", length.out = 6), 3),
    value = runif(18),
    store = rep(c("A", "B", "C"), each = 6)
  )
  s <- milt_series(df, time_col = "date", value_cols = "value",
                   group_col = "store")
  expect_true(s$is_multi_series())
  expect_equal(s$n_series(), 3L)
})

test_that("milt_series(data.frame) handles multivariate value_cols", {
  df <- data.frame(
    date = seq(as.Date("2021-01-01"), by = "month", length.out = 12),
    a    = 1:12,
    b    = 13:24
  )
  s <- milt_series(df, time_col = "date", value_cols = c("a", "b"))
  expect_equal(s$n_components(), 2L)
})

# ── From tibble ───────────────────────────────────────────────────────────────

test_that("milt_series(tibble) creates a MiltSeries", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2022-01-01"), by = "week", length.out = 52),
    value = rnorm(52)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$n_timesteps(), 52L)
  expect_equal(s$freq(), "weekly")
})

# ── From numeric vector ───────────────────────────────────────────────────────

test_that("milt_series(numeric) creates a MiltSeries", {
  s <- milt_series(as.numeric(AirPassengers), frequency = 12,
                   start = c(1949, 1))
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$n_timesteps(), 144L)
})

test_that("milt_series(numeric) values match original", {
  v <- as.numeric(AirPassengers)
  s <- milt_series(v, frequency = 12, start = c(1949, 1))
  expect_equal(s$values(), v)
})

test_that("milt_series(numeric) errors without frequency", {
  expect_error(
    milt_series(1:24),
    class = "milt_error_missing_frequency"
  )
})

test_that("milt_series(numeric) accepts character frequency", {
  s <- milt_series(1:12, frequency = "monthly", start = c(2020, 1))
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$freq(), "monthly")
})

# ── From tsibble ──────────────────────────────────────────────────────────────

test_that("milt_series(tsibble) creates a MiltSeries", {
  skip_if_not_installed("tsibble")
  tbl <- tibble::tibble(
    month = tsibble::yearmonth(seq(as.Date("2020-01-01"), by = "month",
                                   length.out = 12)),
    value = 1:12
  )
  tsbl <- tsibble::as_tsibble(tbl, index = month)
  s <- milt_series(tsbl)
  expect_s3_class(s, "MiltSeries")
  expect_equal(s$n_timesteps(), 12L)
})

# ── Round-trip conversions ────────────────────────────────────────────────────

test_that("milt_series → as_tibble → milt_series round-trips", {
  s1  <- milt_series(AirPassengers)
  tbl <- s1$as_tibble()
  s2  <- milt_series(tbl, time_col = "time", value_cols = "value",
                     frequency = "monthly")
  expect_equal(s1$values(), s2$values())
  expect_equal(s1$n_timesteps(), s2$n_timesteps())
})

test_that("milt_series(ts) → as_ts() round-trips values", {
  s      <- milt_series(AirPassengers)
  ts_out <- s$as_ts()
  expect_equal(as.numeric(ts_out), as.numeric(AirPassengers))
})

# ── value_col alias ───────────────────────────────────────────────────────────

test_that("value_col alias works the same as value_cols", {
  df <- data.frame(
    date = seq(as.Date("2021-01-01"), by = "month", length.out = 6),
    rev  = 1:6
  )
  s1 <- milt_series(df, time_col = "date", value_cols = "rev")
  s2 <- milt_series(df, time_col = "date", value_col  = "rev")
  expect_equal(s1$values(), s2$values())
})
