make_intermittent <- function(n = 60L) {
  vals <- c(0, 0, 5, 0, 0, 0, 3, 0, 0, 8, rep(0, n - 10L))
  tbl  <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = n),
    value = vals
  )
  milt_series(tbl, time_col = "date", value_cols = "value")
}

test_that("croston: model is registered", {
  skip_if_not_installed("forecast")
  expect_true(is_registered_model("croston"))
})

test_that("croston: returns MiltForecast for intermittent series", {
  skip_if_not_installed("forecast")
  s   <- make_intermittent()
  fct <- milt_model("croston") |> milt_fit(s) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("croston: horizon matches", {
  skip_if_not_installed("forecast")
  s   <- make_intermittent()
  fct <- milt_model("croston") |> milt_fit(s) |> milt_forecast(6)
  expect_equal(fct$horizon(), 6L)
})

test_that("croston: point forecast is non-negative for demand series", {
  skip_if_not_installed("forecast")
  s   <- make_intermittent()
  fct <- milt_model("croston") |> milt_fit(s) |> milt_forecast(12)
  expect_true(all(fct$as_tibble()$.mean >= 0))
})

test_that("croston: alpha parameter is stored", {
  skip_if_not_installed("forecast")
  m <- milt_model("croston", alpha = 0.2)
  expect_equal(m$get_params()$alpha, 0.2)
})
