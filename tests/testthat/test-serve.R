test_that("milt_serve() returns a plumber router when launch = FALSE", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("jsonlite")

  model <- milt_model("naive") |> milt_fit(milt_series(AirPassengers))
  api <- milt_serve(model, launch = FALSE)

  expect_s3_class(api, "plumber")
})

test_that("milt_serve() rejects unfitted models", {
  skip_if_not_installed("plumber")
  skip_if_not_installed("jsonlite")

  model <- milt_model("naive")

  expect_error(
    milt_serve(model, launch = FALSE),
    class = "milt_error_not_fitted"
  )
})
