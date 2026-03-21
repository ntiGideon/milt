# ── Helpers ───────────────────────────────────────────────────────────────────

make_gapped <- function(remove = 5:6) {
  s   <- milt_series(AirPassengers)
  tbl <- s$as_tibble()[-remove, ]
  milt_series(tbl, time_col = "time", value_cols = "value", frequency = "monthly")
}

# ── milt_fill_gaps ────────────────────────────────────────────────────────────

test_that("milt_fill_gaps returns a MiltSeries with no gaps", {
  s_gap    <- make_gapped()
  s_filled <- milt_fill_gaps(s_gap)
  expect_false(s_filled$has_gaps())
})

test_that("milt_fill_gaps preserves original row count", {
  s        <- milt_series(AirPassengers)
  s_gap    <- make_gapped()
  s_filled <- milt_fill_gaps(s_gap)
  expect_equal(s_filled$n_timesteps(), s$n_timesteps())
})

test_that("milt_fill_gaps returns unchanged series when no gaps", {
  s <- milt_series(AirPassengers)
  expect_message(out <- milt_fill_gaps(s), "no gaps")
  expect_equal(out$n_timesteps(), s$n_timesteps())
})

test_that("milt_fill_gaps errors on invalid method", {
  s <- make_gapped()
  expect_error(milt_fill_gaps(s, method = "fairy_dust"),
               class = "milt_error_invalid_method")
})

test_that("milt_fill_gaps errors on non-MiltSeries", {
  expect_error(milt_fill_gaps(list()), class = "milt_error_not_milt_series")
})

# ── Method: linear ────────────────────────────────────────────────────────────

test_that("linear fill produces values strictly between neighbours", {
  s_gap    <- make_gapped(remove = 6)   # remove 1 gap row
  s_filled <- milt_fill_gaps(s_gap, "linear")
  v        <- s_filled$values()
  expect_false(any(is.na(v)))
  # The filled value at position 6 should be between positions 5 and 7
  expect_true(v[6] >= min(v[5], v[7]) - 1e-6)
  expect_true(v[6] <= max(v[5], v[7]) + 1e-6)
})

# ── Method: spline ────────────────────────────────────────────────────────────

test_that("spline fill produces no NAs", {
  s_filled <- milt_fill_gaps(make_gapped(), "spline")
  expect_false(any(is.na(s_filled$values())))
})

# ── Method: locf ──────────────────────────────────────────────────────────────

test_that("locf carries last observed value forward", {
  s_gap    <- make_gapped(remove = 6)
  before   <- milt_series(AirPassengers)$values()[5]
  s_filled <- milt_fill_gaps(s_gap, "locf")
  expect_equal(s_filled$values()[6], before)
})

# ── Method: nocb ──────────────────────────────────────────────────────────────

test_that("nocb carries next observed value backward", {
  s_gap    <- make_gapped(remove = 6)
  after    <- milt_series(AirPassengers)$values()[7]
  s_filled <- milt_fill_gaps(s_gap, "nocb")
  expect_equal(s_filled$values()[6], after)
})

# ── Method: mean ──────────────────────────────────────────────────────────────

test_that("mean fill uses the column mean", {
  s_gap    <- make_gapped(remove = 6)
  expected <- mean(s_gap$values(), na.rm = TRUE)
  s_filled <- milt_fill_gaps(s_gap, "mean")
  expect_equal(s_filled$values()[6], expected, tolerance = 1e-6)
})

# ── Method: zero ─────────────────────────────────────────────────────────────

test_that("zero fill inserts 0 at gap positions", {
  s_gap    <- make_gapped(remove = 6)
  s_filled <- milt_fill_gaps(s_gap, "zero")
  expect_equal(s_filled$values()[6], 0)
})

# ── Internal helpers ──────────────────────────────────────────────────────────

test_that(".locf carries value forward correctly", {
  x <- c(1, NA, NA, 4, NA)
  expect_equal(.locf(x), c(1, 1, 1, 4, 4))
})

test_that(".locf leaves leading NAs as NA", {
  x <- c(NA, NA, 3, NA)
  expect_equal(.locf(x), c(NA, NA, 3, 3))
})

test_that(".impute zero replaces all NAs with 0", {
  x <- c(1, NA, 3, NA)
  expect_equal(.impute(x, "zero"), c(1, 0, 3, 0))
})

test_that(".impute mean uses column mean", {
  x <- c(2, NA, 4)
  expect_equal(.impute(x, "mean"), c(2, 3, 4))
})
