# Conversion helpers — full round-trip tests live in test-series-create.R once
# MiltSeriesR6 is available. These tests cover the pure helper functions.

test_that(".ts_freq_label round-trips through .freq_label_to_numeric", {
  freqs <- c(1, 4, 12, 52, 365)
  for (f in freqs) {
    label  <- .ts_freq_label(f)
    expect_equal(.freq_label_to_numeric(label), f)
  }
})

test_that(".ts_times generates correct monthly sequence", {
  times <- .ts_times(1949, 1, 12, 12)
  expect_length(times, 12)
  expect_equal(times[1],  as.Date("1949-01-01"))
  expect_equal(times[12], as.Date("1949-12-01"))
})

test_that(".ts_times generates correct annual sequence", {
  times <- .ts_times(2000, 1, 1, 5)
  expect_length(times, 5)
  expect_equal(times[1], as.Date("2000-01-01"))
  expect_equal(times[5], as.Date("2004-01-01"))
})

test_that(".ts_times generates correct quarterly sequence", {
  times <- .ts_times(2020, 1, 4, 4)
  expect_length(times, 4)
  expect_equal(times[1], as.Date("2020-01-01"))
  expect_equal(times[2], as.Date("2020-04-01"))
})

test_that(".freq_label_to_numeric handles unknown labels by coercion", {
  expect_equal(.freq_label_to_numeric("24"), 24)
})

test_that("milt_to_ts errors on non-MiltSeries input", {
  expect_error(milt_to_ts(list()), class = "milt_error_not_milt_series")
})

test_that("milt_to_tsibble errors on non-MiltSeries input", {
  expect_error(milt_to_tsibble("oops"), class = "milt_error_not_milt_series")
})

test_that("milt_to_tibble errors on non-MiltSeries input", {
  expect_error(milt_to_tibble(42), class = "milt_error_not_milt_series")
})
