air <- milt_series(AirPassengers)

test_that("svm: model is registered", {
  skip_if_not_installed("e1071")
  expect_true(is_registered_model("svm"))
})

test_that("svm: fit + forecast returns MiltForecast", {
  skip_if_not_installed("e1071")
  fct <- milt_model("svm") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("svm: horizon matches", {
  skip_if_not_installed("e1071")
  fct <- milt_model("svm") |> milt_fit(air) |> milt_forecast(6)
  expect_equal(fct$horizon(), 6L)
})

test_that("svm: intervals are valid", {
  skip_if_not_installed("e1071")
  fct <- milt_model("svm") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean    <= tbl$.upper_80))
})

test_that("svm: residuals have correct length", {
  skip_if_not_installed("e1071")
  m <- milt_model("svm") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("svm: kernel parameter stored", {
  skip_if_not_installed("e1071")
  m <- milt_model("svm", kernel = "linear")
  expect_equal(m$get_params()$kernel, "linear")
})

test_that("svm: errors on multivariate series", {
  skip_if_not_installed("e1071")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("svm"), s),
               class = "milt_error_not_univariate")
})
