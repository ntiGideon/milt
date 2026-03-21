air <- milt_series(AirPassengers)

# ── milt_step_scale ────────────────────────────────────────────────────────────

test_that("scale: returns list with series and step", {
  out <- milt_step_scale(air)
  expect_named(out, c("series", "step"))
  expect_s3_class(out$series, "MiltSeries")
  expect_s3_class(out$step, "MiltScaleStep")
})

test_that("scale: zscore produces mean~0 sd~1", {
  out  <- milt_step_scale(air, method = "zscore")
  vals <- out$series$values()
  expect_equal(mean(vals), 0, tolerance = 1e-8)
  expect_equal(stats::sd(vals), 1, tolerance = 1e-8)
})

test_that("scale: minmax produces values in [0, 1]", {
  out  <- milt_step_scale(air, method = "minmax")
  vals <- out$series$values()
  expect_true(min(vals) >= -1e-8)
  expect_true(max(vals) <= 1 + 1e-8)
})

test_that("scale: robust centres at median", {
  out  <- milt_step_scale(air, method = "robust")
  vals <- out$series$values()
  # median of z-transformed series should be near 0
  expect_equal(stats::median(vals), 0, tolerance = 0.1)
})

test_that("scale: print() runs without error", {
  out <- milt_step_scale(air)
  expect_output(print(out$step), "MiltScaleStep")
})

# ── inverse_transform ──────────────────────────────────────────────────────────

test_that("scale: inverse_transform restores original values", {
  out      <- milt_step_scale(air, method = "zscore")
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()),
               tolerance = 1e-8)
})

test_that("scale: minmax inverse_transform restores original values", {
  out      <- milt_step_scale(air, method = "minmax")
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()),
               tolerance = 1e-8)
})

# ── milt_step_unscale ─────────────────────────────────────────────────────────

test_that("step_unscale: works like inverse_transform", {
  out      <- milt_step_scale(air)
  restored <- milt_step_unscale(out$step, out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()),
               tolerance = 1e-8)
})

test_that("step_unscale: errors on non-MiltScaleStep", {
  expect_error(milt_step_unscale("not_a_step", air),
               class = "milt_error_invalid_arg")
})

# ── inverse_transform_vector ──────────────────────────────────────────────────

test_that("scale: inverse_transform_vector restores original values", {
  out <- milt_step_scale(air, method = "zscore")
  z   <- as.numeric(out$series$values())
  restored <- out$step$inverse_transform_vector(z)
  expect_equal(restored, as.numeric(air$values()), tolerance = 1e-8)
})
