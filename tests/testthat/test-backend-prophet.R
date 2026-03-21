make_dated_series <- function(n = 36L) {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = n),
    value = sin(seq(0, 3 * pi, length.out = n)) * 10 + 50 + rnorm(n)
  )
  milt_series(tbl, time_col = "date", value_cols = "value")
}

test_that("prophet: model is registered", {
  skip_if_not_installed("prophet")
  expect_true(is_registered_model("prophet"))
})

test_that("prophet: returns MiltForecast", {
  skip_if_not_installed("prophet")
  s   <- make_dated_series()
  fct <- suppressMessages(
    milt_model("prophet") |> milt_fit(s) |> milt_forecast(6)
  )
  expect_s3_class(fct, "MiltForecast")
})

test_that("prophet: horizon matches", {
  skip_if_not_installed("prophet")
  s   <- make_dated_series()
  fct <- suppressMessages(
    milt_model("prophet") |> milt_fit(s) |> milt_forecast(12)
  )
  expect_equal(fct$horizon(), 12L)
})

test_that("prophet: intervals exist", {
  skip_if_not_installed("prophet")
  s   <- make_dated_series()
  fct <- suppressMessages(
    milt_model("prophet") |> milt_fit(s) |> milt_forecast(6)
  )
  tbl <- fct$as_tibble()
  expect_true(all(c(".lower_80", ".upper_80") %in% names(tbl)))
})

test_that("prophet: errors on multivariate series", {
  skip_if_not_installed("prophet")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(suppressMessages(milt_fit(milt_model("prophet"), s)),
               class = "milt_error_not_univariate")
})
