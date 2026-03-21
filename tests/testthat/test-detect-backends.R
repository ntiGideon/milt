# Tests for STL, IQR, GESD, Grubbs, IForest, LOF, Ensemble detectors
#
# "detect-interface.R" already covers the milt_detector/milt_detect API.
# This file focuses on backend-specific behaviour and correctness.

# ── Shared fixtures ────────────────────────────────────────────────────────────

air <- milt_series(AirPassengers)  # 144 monthly obs, seasonal

make_spike_series <- function(n = 60, pos = 31, spike = 999) {
  vals <- c(rep(5, pos - 1L), spike, rep(5, n - pos))
  tbl  <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "day", length.out = n),
    value = vals
  )
  milt_series(tbl, time_col = "date", value_cols = "value")
}

make_non_seasonal <- function(n = 30) {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "year", length.out = n),
    value = rnorm(n)
  )
  milt_series(tbl, time_col = "date", value_cols = "value",
              frequency = "annual")
}

# ── STL ───────────────────────────────────────────────────────────────────────

test_that("stl detector: returns MiltAnomalies for seasonal series", {
  d <- milt_detector("stl")
  a <- milt_detect(d, air)
  expect_s3_class(a, "MiltAnomalies")
  expect_length(a$is_anomaly(), 144L)
})

test_that("stl detector: method name is 'stl'", {
  a <- milt_detect(milt_detector("stl"), air)
  expect_equal(a$method(), "stl")
})

test_that("stl detector: anomaly_score is numeric with correct length", {
  a <- milt_detect(milt_detector("stl"), air)
  expect_type(a$anomaly_score(), "double")
  expect_length(a$anomaly_score(), 144L)
})

test_that("stl detector: errors on non-seasonal series", {
  s <- make_non_seasonal()
  d <- milt_detector("stl")
  expect_error(milt_detect(d, s), class = "milt_error_insufficient_data")
})

test_that("stl detector: threshold parameter is respected", {
  # Very low threshold => more anomalies; very high => fewer
  a_low  <- milt_detect(milt_detector("stl", threshold = 0.1), air)
  a_high <- milt_detect(milt_detector("stl", threshold = 10), air)
  expect_gte(a_low$n_anomalies(), a_high$n_anomalies())
})

# ── IQR ───────────────────────────────────────────────────────────────────────

test_that("iqr detector: method name is 'iqr'", {
  a <- milt_detect(milt_detector("iqr"), air)
  expect_equal(a$method(), "iqr")
})

test_that("iqr detector: anomaly score is non-negative", {
  a <- milt_detect(milt_detector("iqr"), air)
  expect_true(all(a$anomaly_score() >= 0))
})

test_that("iqr detector: k=0 flags everything outside the IQR itself", {
  s <- make_spike_series()
  a <- milt_detect(milt_detector("iqr", k = 0), s)
  expect_true(a$is_anomaly()[[31L]])
})

test_that("iqr detector: large k flags nothing in stable series", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "day", length.out = 50),
    value = rep(5, 50)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  a <- milt_detect(milt_detector("iqr", k = 100), s)
  expect_equal(a$n_anomalies(), 0L)
})

# ── GESD ──────────────────────────────────────────────────────────────────────

test_that("gesd detector: method name is 'gesd'", {
  a <- milt_detect(milt_detector("gesd"), air)
  expect_equal(a$method(), "gesd")
})

test_that("gesd detector: detects injected extreme spike", {
  s <- make_spike_series(spike = 9999)
  a <- milt_detect(milt_detector("gesd", max_anoms = 3L), s)
  expect_true(a$is_anomaly()[[31L]])
})

test_that("gesd detector: n_anomalies <= max_anoms", {
  d <- milt_detector("gesd", max_anoms = 2L)
  a <- milt_detect(d, air)
  expect_lte(a$n_anomalies(), 2L)
})

test_that("gesd detector: max_anoms=0 returns zero anomalies", {
  d <- milt_detector("gesd", max_anoms = 0L)
  a <- milt_detect(d, air)
  expect_equal(a$n_anomalies(), 0L)
})

# ── Grubbs ────────────────────────────────────────────────────────────────────

test_that("grubbs detector: method name is 'grubbs'", {
  a <- milt_detect(milt_detector("grubbs"), air)
  expect_equal(a$method(), "grubbs")
})

test_that("grubbs detector: anomaly_score is proportional to z-score", {
  s <- make_spike_series()
  a <- milt_detect(milt_detector("grubbs"), s)
  # The spike should have the highest score
  expect_equal(which.max(a$anomaly_score()), 31L)
})

test_that("grubbs detector: max_iter=1 returns at most 1 anomaly", {
  d <- milt_detector("grubbs", max_iter = 1L)
  a <- milt_detect(d, air)
  expect_lte(a$n_anomalies(), 1L)
})

test_that("grubbs detector: alpha=1 flags the most extreme point", {
  # alpha=1 always rejects; we get exactly 1 anomaly (max_iter default=1)
  s <- make_spike_series()
  a <- milt_detect(milt_detector("grubbs", alpha = 1), s)
  expect_equal(a$n_anomalies(), 1L)
  expect_true(a$is_anomaly()[[31L]])
})

# ── IForest ───────────────────────────────────────────────────────────────────

test_that("iforest detector: returns MiltAnomalies (requires isotree)", {
  skip_if_not_installed("isotree")
  d <- milt_detector("iforest", n_trees = 20L)
  a <- milt_detect(d, air)
  expect_s3_class(a, "MiltAnomalies")
  expect_equal(a$method(), "iforest")
})

test_that("iforest detector: scores in [0, 1]", {
  skip_if_not_installed("isotree")
  a <- milt_detect(milt_detector("iforest", n_trees = 20L), air)
  expect_true(all(a$anomaly_score() >= 0 & a$anomaly_score() <= 1))
})

test_that("iforest detector: threshold=0 flags everything", {
  skip_if_not_installed("isotree")
  a <- milt_detect(milt_detector("iforest", n_trees = 20L, threshold = 0), air)
  expect_equal(a$n_anomalies(), air$n_timesteps())
})

test_that("iforest detector: threshold=1 flags nothing (or near-nothing)", {
  skip_if_not_installed("isotree")
  a <- milt_detect(milt_detector("iforest", n_trees = 20L, threshold = 1), air)
  expect_lte(a$n_anomalies(), 1L)
})

test_that("iforest detector: n_lags adds lag features without error", {
  skip_if_not_installed("isotree")
  d <- milt_detector("iforest", n_trees = 20L, n_lags = 3L)
  expect_no_error(milt_detect(d, air))
})

# ── LOF ───────────────────────────────────────────────────────────────────────

test_that("lof detector: returns MiltAnomalies (requires dbscan)", {
  skip_if_not_installed("dbscan")
  d <- milt_detector("lof", k = 5L)
  a <- milt_detect(d, air)
  expect_s3_class(a, "MiltAnomalies")
  expect_equal(a$method(), "lof")
})

test_that("lof detector: anomaly_score non-negative", {
  skip_if_not_installed("dbscan")
  a <- milt_detect(milt_detector("lof"), air)
  expect_true(all(a$anomaly_score() >= 0))
})

test_that("lof detector: use_time=TRUE runs without error", {
  skip_if_not_installed("dbscan")
  d <- milt_detector("lof", k = 5L, use_time = TRUE)
  expect_no_error(milt_detect(d, air))
})

test_that("lof detector: low threshold flags more than high threshold", {
  skip_if_not_installed("dbscan")
  a_low  <- milt_detect(milt_detector("lof", threshold = 1.0), air)
  a_high <- milt_detect(milt_detector("lof", threshold = 5.0), air)
  expect_gte(a_low$n_anomalies(), a_high$n_anomalies())
})

# ── Ensemble ──────────────────────────────────────────────────────────────────

test_that("ensemble detector: majority vote returns MiltAnomalies", {
  d1 <- milt_detector("iqr")
  d2 <- milt_detector("grubbs")
  ens <- milt_detector("ensemble", detectors = list(d1, d2), method = "majority")
  a   <- milt_detect(ens, air)
  expect_s3_class(a, "MiltAnomalies")
  expect_equal(a$method(), "ensemble")
})

test_that("ensemble detector: mean score method returns MiltAnomalies", {
  d1  <- milt_detector("iqr")
  d2  <- milt_detector("grubbs")
  ens <- milt_detector("ensemble", detectors = list(d1, d2),
                        method = "mean", threshold = 0.3)
  a   <- milt_detect(ens, air)
  expect_s3_class(a, "MiltAnomalies")
})

test_that("ensemble detector: empty detectors list errors", {
  expect_error(
    milt_detector("ensemble", detectors = list()),
    class = "milt_error_invalid_arg"
  )
})

test_that("ensemble detector: non-MiltDetector element errors", {
  expect_error(
    milt_detector("ensemble", detectors = list("not_a_detector")),
    class = "milt_error_invalid_arg"
  )
})

test_that("ensemble detector: anomaly vector length matches series", {
  d1  <- milt_detector("iqr")
  d2  <- milt_detector("gesd")
  ens <- milt_detector("ensemble", detectors = list(d1, d2))
  a   <- milt_detect(ens, air)
  expect_length(a$is_anomaly(), air$n_timesteps())
})
