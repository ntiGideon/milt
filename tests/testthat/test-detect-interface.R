# ── Shared fixture ────────────────────────────────────────────────────────────

air <- milt_series(AirPassengers)

# ── milt_detector() construction ──────────────────────────────────────────────

test_that("milt_detector: returns MiltDetector for each named backend", {
  for (nm in c("iqr", "gesd", "grubbs")) {
    d <- milt_detector(nm)
    expect_s3_class(d, "MiltDetector")
    expect_equal(d$name(), nm)
  }
})

test_that("milt_detector: unknown name gives milt_error_unknown_detector", {
  expect_error(milt_detector("no_such_detector"),
               class = "milt_error_unknown_detector")
})

test_that("milt_detector: non-string name gives milt_error_invalid_arg", {
  expect_error(milt_detector(123), class = "milt_error_invalid_arg")
})

test_that("milt_detector: hyperparameters are stored and retrievable", {
  d <- milt_detector("iqr", k = 3.0)
  expect_equal(d$get_params()$k, 3.0)
})

test_that("milt_detector: print outputs detector name", {
  d <- milt_detector("iqr")
  expect_output(print(d), "iqr")
})

test_that("milt_detector: print outputs params when present", {
  d <- milt_detector("iqr", k = 2.5)
  expect_output(print(d), "2.5")
})

# ── milt_detect() dispatch ────────────────────────────────────────────────────

test_that("milt_detect: returns MiltAnomalies", {
  d <- milt_detector("iqr")
  a <- milt_detect(d, air)
  expect_s3_class(a, "MiltAnomalies")
})

test_that("milt_detect: anomaly vector length matches series length", {
  d <- milt_detector("iqr")
  a <- milt_detect(d, air)
  expect_length(a$is_anomaly(), air$n_timesteps())
})

test_that("milt_detect: non-detector input gives milt_error_not_milt_detector", {
  expect_error(milt_detect("not_a_detector", air),
               class = "milt_error_not_milt_detector")
})

test_that("milt_detect: non-series input gives milt_error_not_milt_series", {
  d <- milt_detector("iqr")
  expect_error(milt_detect(d, AirPassengers),
               class = "milt_error_not_milt_series")
})

# ── MiltDetectorBase abstract detect() ────────────────────────────────────────

test_that("MiltDetectorBase: calling detect() on base class raises error", {
  base <- MiltDetectorBase$new("base_test")
  expect_error(base$detect(air), class = "milt_error_not_implemented")
})

# ── IQR: basic correctness ────────────────────────────────────────────────────

test_that("iqr: injects outlier and detects it", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    value = c(rep(10, 12), 1000, rep(10, 11))  # spike at index 13
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  a <- milt_detect(milt_detector("iqr", k = 1.5), s)
  expect_true(a$is_anomaly()[[13L]])
})

# ── GESD: runs on univariate series ───────────────────────────────────────────

test_that("gesd: returns MiltAnomalies for AirPassengers", {
  d <- milt_detector("gesd", max_anoms = 5L, alpha = 0.05)
  a <- milt_detect(d, air)
  expect_s3_class(a, "MiltAnomalies")
  expect_length(a$is_anomaly(), 144L)
})

# ── Grubbs: single outlier ─────────────────────────────────────────────────────

test_that("grubbs: injects extreme outlier and detects it", {
  vals    <- c(rep(5, 30), 999, rep(5, 29))
  tbl     <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "day", length.out = 60),
    value = vals
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value")
  a <- milt_detect(milt_detector("grubbs"), s)
  expect_true(a$is_anomaly()[[31L]])
})
