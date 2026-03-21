# Tests for milt_causal_impact() / MiltCausalImpact

air <- milt_series(AirPassengers)   # 144 monthly obs 1949-01 to 1960-12

# ── Input validation (no CausalImpact needed) ─────────────────────────────────

test_that("causal_impact: non-MiltSeries input errors", {
  skip_if_not_installed("CausalImpact")
  expect_error(milt_causal_impact(AirPassengers, event_time = as.Date("1956-01-01")),
               class = "milt_error_not_milt_series")
})

test_that("causal_impact: event_time not in series errors", {
  skip_if_not_installed("CausalImpact")
  # AirPassengers uses integer/ts time; milt_series wraps it
  # Use a Date-based series instead
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    value = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_error(
    milt_causal_impact(s, event_time = as.Date("1990-01-01")),
    class = "milt_error_invalid_arg"
  )
})

test_that("causal_impact: event_time at index 1 errors (no pre-period)", {
  skip_if_not_installed("CausalImpact")
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    value = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_error(
    milt_causal_impact(s, event_time = as.Date("2020-01-01")),
    class = "milt_error_invalid_arg"
  )
})

test_that("causal_impact: multivariate series errors", {
  skip_if_not_installed("CausalImpact")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a    = rnorm(24),
    b    = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_causal_impact(s, event_time = as.Date("2022-01-01")),
    class = "milt_error_not_univariate"
  )
})

# ── Basic round-trip ──────────────────────────────────────────────────────────

make_ci_series <- function(n = 36L) {
  # Simple series with a step-change at index 25
  set.seed(42L)
  vals <- c(rnorm(24, mean = 5, sd = 0.5),
            rnorm(n - 24L, mean = 8, sd = 0.5))
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = n),
    value = vals
  )
  milt_series(tbl, time_col = "date", value_cols = "value")
}

test_that("causal_impact: returns MiltCausalImpact", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  evt <- as.Date("2022-01-01")   # index 25
  ci  <- milt_causal_impact(s, event_time = evt)
  expect_s3_class(ci, "MiltCausalImpact")
})

test_that("causal_impact: series() returns original MiltSeries", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  expect_s3_class(ci$series(), "MiltSeries")
})

test_that("causal_impact: event_index() is correct", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  expect_equal(ci$event_index(), 25L)
})

test_that("causal_impact: raw() returns CausalImpact object", {
  skip_if_not_installed("CausalImpact")
  s  <- make_ci_series()
  ci <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  expect_true(inherits(ci$raw(), "CausalImpact"))
})

# ── as_tibble ─────────────────────────────────────────────────────────────────

test_that("causal_impact: as_tibble() has correct columns", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  tbl <- ci$as_tibble()
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("time", "actual", "predicted", "lower", "upper", "effect")
                  %in% names(tbl)))
})

test_that("causal_impact: as_tibble() row count matches series length", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series(36L)
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  tbl <- ci$as_tibble()
  expect_equal(nrow(tbl), 36L)
})

test_that("causal_impact: S3 as_tibble dispatch works", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  expect_s3_class(tibble::as_tibble(ci), "tbl_df")
})

# ── summary_stats ─────────────────────────────────────────────────────────────

test_that("causal_impact: summary_stats() returns named numeric vector", {
  skip_if_not_installed("CausalImpact")
  s   <- make_ci_series()
  ci  <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  ss  <- ci$summary_stats()
  expect_type(ss, "double")
  expect_true(all(c("actual", "predicted", "absolute_effect", "relative_effect")
                  %in% names(ss)))
})

# ── print / summary / plot ────────────────────────────────────────────────────

test_that("causal_impact: print() runs without error", {
  skip_if_not_installed("CausalImpact")
  s  <- make_ci_series()
  ci <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  expect_output(print(ci), "MiltCausalImpact")
})

test_that("causal_impact: plot() returns ggplot object", {
  skip_if_not_installed("CausalImpact")
  s  <- make_ci_series()
  ci <- milt_causal_impact(s, event_time = as.Date("2022-01-01"))
  p  <- plot(ci)
  expect_s3_class(p, "gg")
})
