# Tests for milt_changepoints() and MiltChangepoints class

air <- milt_series(AirPassengers)

# ── milt_changepoints: input validation ───────────────────────────────────────

test_that("changepoint: errors without changepoint package", {
  skip_if_not_installed("changepoint")  # if present this block is skipped
  expect_error(milt_changepoints(air))
})

test_that("changepoint: errors on non-MiltSeries input", {
  skip_if_not_installed("changepoint")
  expect_error(milt_changepoints(AirPassengers),
               class = "milt_error_not_milt_series")
})

test_that("changepoint: errors on multivariate series", {
  skip_if_not_installed("changepoint")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a    = rnorm(24),
    b    = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_changepoints(s),
               class = "milt_error_not_univariate")
})

# ── milt_changepoints: basic round-trip ───────────────────────────────────────

test_that("changepoint: returns MiltChangepoints", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air, method = "pelt", stat = "mean")
  expect_s3_class(cp, "MiltChangepoints")
})

test_that("changepoint: method() matches requested method", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air, method = "binseg", stat = "mean")
  expect_equal(cp$method(), "binseg")
})

test_that("changepoint: series() returns original MiltSeries", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air)
  expect_s3_class(cp$series(), "MiltSeries")
  expect_equal(cp$series()$n_timesteps(), 144L)
})

test_that("changepoint: indices are integers in (0, n)", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air)
  idx <- cp$indices()
  n   <- air$n_timesteps()
  expect_type(idx, "integer")
  expect_true(all(idx >= 1L & idx < n))
})

test_that("changepoint: n_changepoints() matches length of indices()", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air)
  expect_equal(cp$n_changepoints(), length(cp$indices()))
})

# ── MiltChangepoints: as_tibble ───────────────────────────────────────────────

test_that("changepoint: as_tibble() returns tibble with index and time", {
  skip_if_not_installed("changepoint")
  cp  <- milt_changepoints(air)
  tbl <- cp$as_tibble()
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("index", "time") %in% names(tbl)))
})

test_that("changepoint: as_tibble() has one row per changepoint", {
  skip_if_not_installed("changepoint")
  cp  <- milt_changepoints(air)
  tbl <- cp$as_tibble()
  expect_equal(nrow(tbl), cp$n_changepoints())
})

test_that("changepoint: S3 as_tibble dispatch works", {
  skip_if_not_installed("changepoint")
  cp  <- milt_changepoints(air)
  tbl <- tibble::as_tibble(cp)
  expect_s3_class(tbl, "tbl_df")
})

# ── MiltChangepoints: print / summary ─────────────────────────────────────────

test_that("changepoint: print() runs and mentions method", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air, method = "pelt")
  expect_output(print(cp), "pelt")
})

test_that("changepoint: print() returns x invisibly", {
  skip_if_not_installed("changepoint")
  cp  <- milt_changepoints(air)
  ret <- withVisible(print(cp))
  expect_false(ret$visible)
})

test_that("changepoint: summary() is identical to print()", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air)
  out_p <- capture.output(print(cp))
  out_s <- capture.output(summary(cp))
  expect_equal(out_p, out_s)
})

# ── MiltChangepoints: plot ────────────────────────────────────────────────────

test_that("changepoint: plot() returns a ggplot object", {
  skip_if_not_installed("changepoint")
  cp <- milt_changepoints(air)
  p  <- plot(cp)
  expect_s3_class(p, "gg")
})

test_that("changepoint: plot() with 0 changepoints still returns ggplot", {
  skip_if_not_installed("changepoint")
  # amoc on very stable series may find 0
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    value = rep(10, 24)
  )
  s  <- milt_series(tbl, time_col = "date", value_cols = "value")
  cp <- milt_changepoints(s, method = "amoc")
  p  <- plot(cp)
  expect_s3_class(p, "gg")
})

# ── stat variants ─────────────────────────────────────────────────────────────

test_that("changepoint: stat='variance' runs without error", {
  skip_if_not_installed("changepoint")
  expect_no_error(milt_changepoints(air, stat = "variance"))
})

test_that("changepoint: stat='meanvar' runs without error", {
  skip_if_not_installed("changepoint")
  expect_no_error(milt_changepoints(air, stat = "meanvar"))
})
