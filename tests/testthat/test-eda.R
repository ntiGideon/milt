# Tests for milt_eda() / MiltEDA

air <- milt_series(AirPassengers)

test_that("eda: returns MiltEDA", {
  e <- milt_eda(air)
  expect_s3_class(e, "MiltEDA")
})

test_that("eda: series() returns original MiltSeries", {
  e <- milt_eda(air)
  expect_s3_class(e$series(), "MiltSeries")
  expect_equal(e$series()$n_timesteps(), 144L)
})

test_that("eda: stats() is a tibble with stat and value columns", {
  e   <- milt_eda(air)
  tbl <- e$stats()
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("stat", "value") %in% names(tbl)))
})

test_that("eda: stats() includes mean and sd rows", {
  e   <- milt_eda(air)
  tbl <- e$stats()
  expect_true("mean" %in% tbl$stat)
  expect_true("sd"   %in% tbl$stat)
})

test_that("eda: stationarity() returns a list with adf_pvalue", {
  e  <- milt_eda(air)
  st <- e$stationarity()
  expect_true(is.list(st))
  expect_true("adf_pvalue" %in% names(st))
})

test_that("eda: seasonality() detects AirPassengers as seasonal", {
  e    <- milt_eda(air)
  seas <- e$seasonality()
  expect_equal(seas$period, 12L)
  expect_true(seas$has_seasonality)
  expect_gt(seas$strength, 0.3)
})

test_that("eda: print() runs without error", {
  expect_output(milt_eda(air), "MiltEDA")
})

test_that("eda: as_tibble() returns stats tibble", {
  e   <- milt_eda(air)
  tbl <- tibble::as_tibble(e)
  expect_s3_class(tbl, "tbl_df")
})

test_that("eda: plot() returns a list of ggplot objects", {
  e  <- milt_eda(air)
  ps <- plot(e)
  expect_type(ps, "list")
  expect_true(all(vapply(ps, inherits, logical(1L), "gg")))
})

test_that("eda: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_eda(s), class = "milt_error_not_univariate")
})

test_that("eda: errors on non-MiltSeries input", {
  expect_error(milt_eda(AirPassengers), class = "milt_error_not_milt_series")
})
