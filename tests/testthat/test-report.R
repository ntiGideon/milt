test_that("milt_report() renders an HTML report", {
  skip_if_not_installed("rmarkdown")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc not available")

  series <- milt_series(AirPassengers)
  path <- tempfile(fileext = ".html")

  expect_no_error(
    out <- milt_report(series, output_file = path, open = FALSE)
  )
  expect_true(file.exists(out))
})

test_that("milt_report() rejects non-MiltSeries input", {
  expect_error(
    milt_report(AirPassengers, open = FALSE),
    class = "milt_error_not_milt_series"
  )
})
