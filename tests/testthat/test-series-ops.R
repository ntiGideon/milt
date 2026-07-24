air <- milt_series(AirPassengers)

# ── Arithmetic (Ops.MiltSeries) ───────────────────────────────────────────────

test_that("arithmetic: MiltSeries + scalar adds to every value", {
  s2 <- air + 10
  expect_s3_class(s2, "MiltSeries")
  expect_equal(as.numeric(s2$values()), as.numeric(air$values()) + 10)
})

test_that("arithmetic: scalar + MiltSeries is commutative for addition", {
  s2 <- 10 + air
  expect_equal(as.numeric(s2$values()), as.numeric(air$values()) + 10)
})

test_that("arithmetic: MiltSeries * scalar scales every value", {
  s2 <- air * 2
  expect_equal(as.numeric(s2$values()), as.numeric(air$values()) * 2)
})

test_that("arithmetic: MiltSeries - MiltSeries with identical time index", {
  diff_s <- air - air
  expect_true(all(abs(diff_s$values()) < 1e-10))
})

test_that("arithmetic: division and power work", {
  expect_equal(as.numeric((air / 2)$values()), as.numeric(air$values()) / 2)
  expect_equal(as.numeric((air ^ 2)$values()), as.numeric(air$values()) ^ 2)
})

test_that("arithmetic: errors on unsupported operator", {
  expect_error(air == air, class = "milt_error_unsupported_op")
})

test_that("arithmetic: errors when non-numeric operand supplied", {
  expect_error(air + "a", class = "milt_error_invalid_arg")
})

test_that("arithmetic: errors on mismatched time index between two series", {
  short <- milt_series(head(as.numeric(AirPassengers), 100), frequency = "monthly", start = c(1949, 1))
  expect_error(air + short, class = "milt_error_incompatible_series")
})

# ── milt_stack ────────────────────────────────────────────────────────────────

test_that("stack: combines two series into one multivariate series", {
  sma     <- milt_filter(air, "moving_average", window = 3L)
  sma_tbl <- sma$as_tibble()
  names(sma_tbl)[names(sma_tbl) == "value"] <- "smoothed"
  sma2    <- milt_series(sma_tbl, time_col = "time", value_cols = "smoothed", frequency = "monthly")

  stacked <- milt_stack(air, sma2)
  expect_s3_class(stacked, "MiltSeries")
  expect_equal(stacked$n_components(), 2L)
  expect_false(stacked$is_univariate())
})

test_that("stack: disambiguates colliding column names", {
  stacked <- milt_stack(air, air)
  expect_equal(stacked$n_components(), 2L)
})

test_that("stack: requires at least two series", {
  expect_error(milt_stack(air), class = "milt_error_invalid_arg")
})

test_that("stack: errors on mismatched time index", {
  short <- milt_series(head(as.numeric(AirPassengers), 100), frequency = "monthly", start = c(1949, 1))
  expect_error(milt_stack(air, short), class = "milt_error_incompatible_series")
})

# ── milt_add_datetime_component ───────────────────────────────────────────────

test_that("add_datetime_component: adds a raw month column", {
  s2 <- milt_add_datetime_component(air, "month")
  expect_false(s2$is_univariate())
  tbl <- s2$as_tibble()
  expect_true("month" %in% names(tbl))
  expect_equal(tbl$month, lubridate::month(air$times()))
})

test_that("add_datetime_component: cyclic mode adds sin/cos pair", {
  s2  <- milt_add_datetime_component(air, "month", cyclic = TRUE)
  tbl <- s2$as_tibble()
  expect_true(all(c("month_sin", "month_cos") %in% names(tbl)))
  expect_equal(s2$n_components(), 3L)
})

test_that("add_datetime_component: errors on unsupported attribute", {
  expect_error(milt_add_datetime_component(air, "not_a_thing"), class = "milt_error_invalid_arg")
})

test_that("add_datetime_component: cyclic errors for attributes with no natural period", {
  expect_error(milt_add_datetime_component(air, "year", cyclic = TRUE),
               class = "milt_error_invalid_arg")
})

# ── milt_add_holidays ─────────────────────────────────────────────────────────

test_that("add_holidays: adds a binary column via built-in US calendar", {
  s2  <- milt_add_holidays(air, country = "US")
  tbl <- s2$as_tibble()
  expect_true("is_holiday" %in% names(tbl))
  expect_true(all(tbl$is_holiday %in% c(0L, 1L)))
  expect_false(s2$is_univariate())
})

test_that("add_holidays: flags a known custom holiday date", {
  s2  <- milt_add_holidays(air, dates = as.Date("1955-01-01"), name = "hol")
  tbl <- s2$as_tibble()
  flagged_time <- tbl$time[tbl$hol == 1L]
  expect_true(as.Date("1955-01-01") %in% as.Date(flagged_time))
})

test_that("add_holidays: errors when neither dates nor country supplied", {
  expect_error(milt_add_holidays(air), class = "milt_error_invalid_arg")
})

test_that("add_holidays: errors for unsupported country", {
  expect_error(milt_add_holidays(air, country = "FR"), class = "milt_error_invalid_arg")
})
