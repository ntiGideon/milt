air <- milt_series(AirPassengers)

test_that("tbats: model is registered", {
  skip_if_not_installed("forecast")
  expect_true(is_registered_model("tbats"))
})

test_that("tbats: returns MiltForecast", {
  skip_if_not_installed("forecast")
  fct <- milt_model("tbats") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("tbats: horizon matches", {
  skip_if_not_installed("forecast")
  fct <- milt_model("tbats") |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("tbats: intervals are valid", {
  skip_if_not_installed("forecast")
  fct <- milt_model("tbats") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean    <= tbl$.upper_80))
})

test_that("tbats: residuals have correct length", {
  skip_if_not_installed("forecast")
  m <- milt_model("tbats") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("tbats: errors on multivariate series", {
  skip_if_not_installed("forecast")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("tbats"), s),
               class = "milt_error_not_univariate")
})
