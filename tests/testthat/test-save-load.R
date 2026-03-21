# Tests for milt_save() / milt_load()

air <- milt_series(AirPassengers)

# ── milt_save() ───────────────────────────────────────────────────────────────

test_that("save: writes file with .milt extension", {
  tmp <- tempfile()
  path <- milt_save(air, tmp)
  expect_true(file.exists(path))
  expect_true(grepl("\\.milt$", path))
  unlink(path)
})

test_that("save: does not double-add extension when .milt present", {
  tmp  <- tempfile(fileext = ".milt")
  path <- milt_save(air, tmp)
  expect_false(grepl("\\.milt\\.milt$", path))
  unlink(path)
})

test_that("save: returns path invisibly", {
  tmp <- tempfile()
  ret <- withVisible(milt_save(air, tmp))
  expect_false(ret$visible)
  unlink(ret$value)
})

test_that("save: non-character path errors", {
  expect_error(milt_save(air, 123), class = "milt_error_invalid_arg")
})

# ── milt_load() ───────────────────────────────────────────────────────────────

test_that("load: round-trips a MiltSeries", {
  tmp  <- tempfile(fileext = ".milt")
  milt_save(air, tmp)
  air2 <- milt_load(tmp)
  expect_s3_class(air2, "MiltSeries")
  expect_equal(air2$n_timesteps(), air$n_timesteps())
  expect_equal(as.numeric(air2$values()), as.numeric(air$values()))
  unlink(tmp)
})

test_that("load: round-trips a fitted MiltModel", {
  skip_if_not_installed("forecast")
  m   <- milt_model("arima") |> milt_fit(air)
  tmp <- tempfile(fileext = ".milt")
  milt_save(m, tmp)
  m2  <- milt_load(tmp)
  expect_s3_class(m2, "MiltModel")
  expect_true(m2$is_fitted())
  unlink(tmp)
})

test_that("load: non-existent file errors", {
  expect_error(milt_load("/nonexistent/path/file.milt"),
               class = "milt_error_io")
})

test_that("load: invalid file errors", {
  tmp <- tempfile(fileext = ".milt")
  saveRDS(list(not_a_milt = TRUE), tmp)
  expect_error(milt_load(tmp), class = "milt_error_io")
  unlink(tmp)
})
