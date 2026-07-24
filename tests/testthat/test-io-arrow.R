# Tests for milt_write_parquet() / milt_read_parquet()

air <- milt_series(AirPassengers)

test_that("write_parquet: errors without arrow package", {
  local_mocked_bindings(
    check_installed_backend = function(...) {
      milt_abort("mocked missing package", class = "milt_error_missing_package")
    }
  )
  expect_error(milt_write_parquet(air, tempfile()), class = "milt_error_missing_package")
})

test_that("write_parquet: errors on non-MiltSeries input", {
  skip_if_not_installed("arrow")
  expect_error(milt_write_parquet(AirPassengers, tempfile()),
               class = "milt_error_not_milt_series")
})

test_that("write_parquet: writes a file and returns the path invisibly", {
  skip_if_not_installed("arrow")
  tmp <- tempfile(fileext = ".parquet")
  ret <- withVisible(milt_write_parquet(air, tmp))
  expect_false(ret$visible)
  expect_equal(ret$value, tmp)
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("read_parquet: round-trips a MiltSeries", {
  skip_if_not_installed("arrow")
  tmp <- tempfile(fileext = ".parquet")
  milt_write_parquet(air, tmp)
  air2 <- milt_read_parquet(tmp, time_col = "time", value_cols = "value",
                             frequency = "monthly")
  expect_s3_class(air2, "MiltSeries")
  expect_equal(air2$n_timesteps(), air$n_timesteps())
  expect_equal(as.numeric(air2$values()), as.numeric(air$values()))
  unlink(tmp)
})

test_that("read_parquet: non-existent file errors", {
  skip_if_not_installed("arrow")
  expect_error(milt_read_parquet("/nonexistent/path/file.parquet"),
               class = "milt_error_io")
})
