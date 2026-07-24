air <- milt_series(AirPassengers)

# ── milt_step_boxcox ──────────────────────────────────────────────────────────

test_that("boxcox: returns list with series and step", {
  out <- milt_step_boxcox(air)
  expect_named(out, c("series", "step"))
  expect_s3_class(out$series, "MiltSeries")
  expect_s3_class(out$step, "MiltBoxCoxStep")
})

test_that("boxcox: with lambda = 0 matches log transform", {
  out  <- milt_step_boxcox(air, lambda = 0)
  vals <- out$series$values()
  expect_equal(as.numeric(vals), log(as.numeric(air$values())), tolerance = 1e-8)
})

test_that("boxcox: with lambda = 1 is a linear shift (y - 1)", {
  out  <- milt_step_boxcox(air, lambda = 1)
  vals <- out$series$values()
  expect_equal(as.numeric(vals), as.numeric(air$values()) - 1, tolerance = 1e-8)
})

test_that("boxcox: auto-estimated lambda is within the search interval", {
  out <- milt_step_boxcox(air)
  expect_true(out$step$lambda() >= -2 && out$step$lambda() <= 2)
})

test_that("boxcox: errors on non-positive values", {
  s <- milt_series(c(-1, 2, 3, 4), frequency = "monthly", start = c(2020, 1))
  expect_error(milt_step_boxcox(s), class = "milt_error_invalid_arg")
})

test_that("boxcox: print() runs without error", {
  out <- milt_step_boxcox(air, lambda = 0.5)
  expect_output(print(out$step), "MiltBoxCoxStep")
})

test_that("boxcox: inverse_transform restores original values", {
  out      <- milt_step_boxcox(air)
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-6)
})

test_that("step_unboxcox: works like inverse_transform", {
  out      <- milt_step_boxcox(air, lambda = 0.3)
  restored <- milt_step_unboxcox(out$step, out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-6)
})

test_that("step_unboxcox: errors on non-MiltBoxCoxStep", {
  expect_error(milt_step_unboxcox("not_a_step", air), class = "milt_error_invalid_arg")
})

# ── milt_step_diff ────────────────────────────────────────────────────────────

test_that("diff: returns list with series and step", {
  out <- milt_step_diff(air)
  expect_named(out, c("series", "step"))
  expect_s3_class(out$series, "MiltSeries")
  expect_s3_class(out$step, "MiltDiffStep")
})

test_that("diff: single lag matches base::diff and shortens by 1", {
  out <- milt_step_diff(air, lags = 1L)
  expect_equal(out$series$n_timesteps(), air$n_timesteps() - 1L)
  expect_equal(as.numeric(out$series$values()), diff(as.numeric(air$values())))
})

test_that("diff: multi-stage lags c(1, 12) shortens by 13", {
  out <- milt_step_diff(air, lags = c(1L, 12L))
  expect_equal(out$series$n_timesteps(), air$n_timesteps() - 13L)
})

test_that("diff: errors on non-positive lags", {
  expect_error(milt_step_diff(air, lags = 0L), class = "milt_error_invalid_arg")
})

test_that("diff: errors when series is too short for the requested lags", {
  s <- milt_series(1:3, frequency = "monthly", start = c(2020, 1))
  expect_error(milt_step_diff(s, lags = 5L), class = "milt_error_insufficient_data")
})

test_that("diff: print() runs without error", {
  out <- milt_step_diff(air)
  expect_output(print(out$step), "MiltDiffStep")
})

test_that("diff: inverse_transform restores original values and time index", {
  out      <- milt_step_diff(air, lags = 1L)
  restored <- out$step$inverse_transform(out$series)
  expect_equal(restored$n_timesteps(), air$n_timesteps())
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-8)
  expect_equal(restored$times(), air$times())
})

test_that("diff: inverse_transform round-trips multi-stage lags", {
  out      <- milt_step_diff(air, lags = c(1L, 12L))
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-8)
})

test_that("step_undiff: works like inverse_transform", {
  out      <- milt_step_diff(air)
  restored <- milt_step_undiff(out$step, out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-8)
})

test_that("step_undiff: errors on non-MiltDiffStep", {
  expect_error(milt_step_undiff("not_a_step", air), class = "milt_error_invalid_arg")
})

# ── milt_step_map ─────────────────────────────────────────────────────────────

test_that("map: without inverse_fn returns NULL step", {
  out <- milt_step_map(air, fn = log1p)
  expect_s3_class(out$series, "MiltSeries")
  expect_null(out$step)
  expect_equal(as.numeric(out$series$values()), log1p(as.numeric(air$values())))
})

test_that("map: with inverse_fn returns a MiltMapStep", {
  out <- milt_step_map(air, fn = log1p, inverse_fn = expm1)
  expect_s3_class(out$step, "MiltMapStep")
})

test_that("map: inverse_transform restores original values", {
  out      <- milt_step_map(air, fn = log1p, inverse_fn = expm1)
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-8)
})

test_that("map: print() runs without error", {
  out <- milt_step_map(air, fn = log1p, inverse_fn = expm1)
  expect_output(print(out$step), "MiltMapStep")
})

test_that("map: errors when fn is not a function", {
  expect_error(milt_step_map(air, fn = "not_a_function"), class = "milt_error_invalid_arg")
})

test_that("map: errors when inverse_fn is not a function", {
  expect_error(milt_step_map(air, fn = log1p, inverse_fn = "nope"),
               class = "milt_error_invalid_arg")
})

# ── milt_step_map: time-aware (two-argument) mapping ──────────────────────────

test_that("map: detects and calls a two-argument (time, value) function", {
  out  <- milt_step_map(air, fn = function(time, value) {
    ifelse(lubridate::year(time) == 1949, 0, value)
  })
  vals <- as.numeric(out$series$values())
  years <- lubridate::year(air$times())
  expect_true(all(vals[years == 1949] == 0))
  expect_equal(vals[years != 1949], as.numeric(air$values())[years != 1949])
})

test_that("map: one-argument functions still work unchanged", {
  out <- milt_step_map(air, fn = function(value) value * 2)
  expect_equal(as.numeric(out$series$values()), as.numeric(air$values()) * 2)
})

test_that("map: time-aware inverse_fn round-trips", {
  fwd <- function(time, value) value - lubridate::year(time)
  inv <- function(time, value) value + lubridate::year(time)
  out <- milt_step_map(air, fn = fwd, inverse_fn = inv)
  restored <- out$step$inverse_transform(out$series)
  expect_equal(as.numeric(restored$values()), as.numeric(air$values()), tolerance = 1e-8)
})
