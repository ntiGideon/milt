test_that("%||% returns left-hand side when not NULL", {
  expect_equal("a" %||% "b", "a")
  expect_equal(0L %||% 99L, 0L)
  expect_equal(FALSE %||% TRUE, FALSE)
})

test_that("%||% returns right-hand side when NULL", {
  expect_equal(NULL %||% "b", "b")
  expect_equal(NULL %||% 42L, 42L)
})

# ── is_scalar_* ───────────────────────────────────────────────────────────────

test_that("is_scalar_character works", {
  expect_true(is_scalar_character("hello"))
  expect_false(is_scalar_character(c("a", "b")))
  expect_false(is_scalar_character(NA_character_))
  expect_false(is_scalar_character(1L))
})

test_that("is_scalar_numeric works", {
  expect_true(is_scalar_numeric(3.14))
  expect_true(is_scalar_numeric(0L))   # integers are numeric
  expect_false(is_scalar_numeric(c(1, 2)))
  expect_false(is_scalar_numeric(NA_real_))
  expect_false(is_scalar_numeric("x"))
})

test_that("is_scalar_logical works", {
  expect_true(is_scalar_logical(TRUE))
  expect_true(is_scalar_logical(FALSE))
  expect_false(is_scalar_logical(c(TRUE, FALSE)))
  expect_false(is_scalar_logical(NA))
  expect_false(is_scalar_logical(1L))
})

test_that("is_scalar_integer accepts whole numbers", {
  expect_true(is_scalar_integer(5L))
  expect_true(is_scalar_integer(5.0))   # 5.0 == floor(5.0)
  expect_false(is_scalar_integer(5.1))
  expect_false(is_scalar_integer(c(1L, 2L)))
  expect_false(is_scalar_integer(NA_integer_))
})

# ── assert_milt_series ────────────────────────────────────────────────────────

test_that("assert_milt_series passes for MiltSeries objects", {
  # We need a minimal MiltSeries — use a ts until MiltSeries exists.
  # These tests will be enriched once MiltSeries is available.
  # For now just verify the error path.
  expect_error(
    assert_milt_series(42),
    class = "milt_error_not_milt_series"
  )
  expect_error(
    assert_milt_series("oops"),
    class = "milt_error_not_milt_series"
  )
})

# ── assert_positive_integer ───────────────────────────────────────────────────

test_that("assert_positive_integer passes for valid inputs", {
  expect_invisible(assert_positive_integer(1L))
  expect_invisible(assert_positive_integer(100L))
  expect_invisible(assert_positive_integer(12.0))  # whole number double
})

test_that("assert_positive_integer errors on invalid inputs", {
  expect_error(assert_positive_integer(0L),   class = "milt_error_invalid_integer")
  expect_error(assert_positive_integer(-1L),  class = "milt_error_invalid_integer")
  expect_error(assert_positive_integer(1.5),  class = "milt_error_invalid_integer")
  expect_error(assert_positive_integer("x"),  class = "milt_error_invalid_integer")
})

# ── assert_proportion ─────────────────────────────────────────────────────────

test_that("assert_proportion passes for values in (0, 1)", {
  expect_invisible(assert_proportion(0.8))
  expect_invisible(assert_proportion(0.01))
  expect_invisible(assert_proportion(0.99))
})

test_that("assert_proportion errors on boundary and invalid values", {
  expect_error(assert_proportion(0),   class = "milt_error_invalid_proportion")
  expect_error(assert_proportion(1),   class = "milt_error_invalid_proportion")
  expect_error(assert_proportion(1.5), class = "milt_error_invalid_proportion")
  expect_error(assert_proportion(-0.1), class = "milt_error_invalid_proportion")
})

# ── .period_to_frequency ──────────────────────────────────────────────────────

test_that(".period_to_frequency maps known periods correctly", {
  expect_equal(.period_to_frequency("monthly"),   12)
  expect_equal(.period_to_frequency("quarterly"),  4)
  expect_equal(.period_to_frequency("annual"),     1)
  expect_equal(.period_to_frequency("weekly"),    52)
  expect_equal(.period_to_frequency("daily"),    365)
  # Case insensitive
  expect_equal(.period_to_frequency("Monthly"),  12)
})

test_that(".period_to_frequency errors on unknown period", {
  expect_error(.period_to_frequency("decadely"), class = "milt_error_unknown_period")
})

# ── .ts_freq_label ────────────────────────────────────────────────────────────

test_that(".ts_freq_label returns correct labels", {
  expect_equal(.ts_freq_label(12),  "monthly")
  expect_equal(.ts_freq_label(4),   "quarterly")
  expect_equal(.ts_freq_label(1),   "annual")
  expect_equal(.ts_freq_label(52),  "weekly")
  expect_equal(.ts_freq_label(365), "daily")
  expect_equal(.ts_freq_label(24),  "24")  # fallback: character conversion
})

# ── .guess_frequency ──────────────────────────────────────────────────────────

test_that(".guess_frequency detects monthly dates", {
  dates <- seq(as.Date("2020-01-01"), by = "month", length.out = 24)
  expect_equal(.guess_frequency(dates), "monthly")
})

test_that(".guess_frequency detects daily dates", {
  dates <- seq(as.Date("2020-01-01"), by = "day", length.out = 30)
  expect_equal(.guess_frequency(dates), "daily")
})

test_that(".guess_frequency returns NA for single-element vector", {
  expect_true(is.na(.guess_frequency(as.Date("2020-01-01"))))
})
