test_that("milt_info emits an informational message", {
  expect_message(milt_info("hello world"), "hello world")
})

test_that("milt_warn emits a warning", {
  expect_warning(milt_warn("something fishy"), "something fishy")
})

test_that("milt_abort throws an error with milt_error class", {
  expect_error(
    milt_abort("something broke"),
    class = "milt_error"
  )
})

test_that("milt_abort attaches the supplied subclass", {
  expect_error(
    milt_abort("bad input", class = "milt_error_invalid_series"),
    class = "milt_error_invalid_series"
  )
})

test_that("milt_abort subclass also inherits milt_error", {
  err <- tryCatch(
    milt_abort("x", class = "milt_error_custom"),
    error = function(e) e
  )
  expect_true(inherits(err, "milt_error"))
  expect_true(inherits(err, "milt_error_custom"))
})
