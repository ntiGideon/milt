air <- milt_series(AirPassengers)

test_that("knn: model is registered", {
  expect_true(is_registered_model("knn"))
})

test_that("knn: fit + forecast returns MiltForecast", {
  fct <- milt_model("knn") |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("knn: horizon matches", {
  fct <- milt_model("knn") |> milt_fit(air) |> milt_forecast(6)
  expect_equal(fct$horizon(), 6L)
})

test_that("knn: intervals are valid", {
  fct <- milt_model("knn") |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean    <= tbl$.upper_80 + 1e-8))
})

test_that("knn: residuals have correct length", {
  m <- milt_model("knn") |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("knn: distance weighting runs without error", {
  fct <- milt_model("knn", weights = "distance") |>
    milt_fit(air) |> milt_forecast(6)
  expect_s3_class(fct, "MiltForecast")
})

test_that("knn: predict returns vector of correct length", {
  m <- milt_model("knn") |> milt_fit(air)
  p <- milt_predict(m)
  expect_length(p, 144L)
})

test_that("knn: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_fit(milt_model("knn"), s),
               class = "milt_error_not_univariate")
})
