test_that("check_installed_backend passes when package is available", {
  # base R is always available
  expect_invisible(check_installed_backend("base", "test feature"))
})

test_that("check_installed_backend errors when package is missing", {
  # Use a nonsense package name that will never be installed
  expect_error(
    check_installed_backend("thisisnotapackage12345", "fictional feature")
  )
})

# check_series_has_no_gaps and check_series_has_enough_data require
# MiltSeries objects, so these tests live in test-MiltSeries.R and
# test-series-create.R once that class is available.

test_that("check_covariates_aligned errors on non-data-frame covariates", {
  # We need a MiltSeries to call this; stub a minimal one by creating
  # a plain list with the MiltSeries class so we can reach the covariate check
  fake <- structure(list(), class = "MiltSeries")
  expect_error(
    check_covariates_aligned(fake, covariates = 42, time_col = "date"),
    class = "milt_error_invalid_covariates"
  )
})

test_that("check_covariates_aligned errors when time_col is absent", {
  fake <- structure(list(), class = "MiltSeries")
  cov  <- data.frame(date = Sys.Date(), x = 1)
  expect_error(
    check_covariates_aligned(fake, covariates = cov, time_col = "wrong_col"),
    class = "milt_error_invalid_covariates"
  )
})
