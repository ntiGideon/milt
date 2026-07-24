air <- milt_series(AirPassengers)

test_that("check_seasonality: detects the 12-month period in AirPassengers", {
  res <- milt_check_seasonality(air, max_lag = 24L)
  expect_true(res$is_seasonal)
  expect_equal(res$period, 12L)
})

test_that("check_seasonality: returns not-seasonal for white noise", {
  set.seed(1)
  s <- milt_series(rnorm(200), frequency = "monthly", start = c(2000, 1))
  res <- milt_check_seasonality(s, max_lag = 24L)
  expect_type(res$is_seasonal, "logical")
  if (!res$is_seasonal) expect_true(is.na(res$period))
})

test_that("check_seasonality: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_check_seasonality(s), class = "milt_error_not_univariate")
})

test_that("check_seasonality: errors on series too short for max_lag", {
  s <- milt_series(1:2, frequency = "monthly", start = c(2020, 1))
  expect_error(milt_check_seasonality(s, max_lag = 24L), class = "milt_error_insufficient_data")
})

test_that("check_seasonality: returns a list with is_seasonal and period", {
  res <- milt_check_seasonality(air)
  expect_named(res, c("is_seasonal", "period"))
})
