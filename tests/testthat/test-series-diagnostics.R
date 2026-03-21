# ── milt_diagnose ─────────────────────────────────────────────────────────────

test_that("milt_diagnose returns a MiltDiagnosis object", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  expect_s3_class(diag, "MiltDiagnosis")
})

test_that("milt_diagnose errors on non-MiltSeries", {
  expect_error(milt_diagnose(42), class = "milt_error_not_milt_series")
})

test_that("milt_diagnose$as_list() contains all expected keys", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  keys <- names(diag$as_list())
  expect_true(all(c("stationarity", "seasonality", "trend",
                    "gaps", "outliers", "recommendations") %in% keys))
})

# ── Stationarity ──────────────────────────────────────────────────────────────

test_that("stationarity result is a list with stationary flag and cv_ratio", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  stat <- diag$as_list()$stationarity
  expect_true(is.logical(stat$stationary))
  expect_true(is.numeric(stat$cv_ratio))
})

test_that("a stationary series is flagged correctly", {
  # White noise should be stationary
  set.seed(42)
  v <- rnorm(120)
  tbl <- tibble::tibble(
    date  = seq(as.Date("2010-01-01"), by = "month", length.out = 120),
    value = v
  )
  s    <- milt_series(tbl, time_col = "date", value_cols = "value")
  diag <- milt_diagnose(s)
  expect_true(diag$as_list()$stationarity$stationary)
})

# ── Seasonality ───────────────────────────────────────────────────────────────

test_that("AirPassengers is detected as seasonal", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  seas <- diag$as_list()$seasonality
  expect_true(seas$seasonal)
  expect_equal(seas$period, 12L)
})

test_that("seasonality result has strength and period fields", {
  s    <- milt_series(AirPassengers)
  seas <- milt_diagnose(s)$as_list()$seasonality
  expect_true("strength" %in% names(seas))
  expect_true("period"   %in% names(seas))
})

# ── Trend ────────────────────────────────────────────────────────────────────

test_that("AirPassengers has a significant trend", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  tr   <- diag$as_list()$trend
  expect_true(tr$has_trend)
  expect_true(tr$slope > 0)
})

test_that("trend result has has_trend, slope, and p_value", {
  s  <- milt_series(AirPassengers)
  tr <- milt_diagnose(s)$as_list()$trend
  expect_true(all(c("has_trend", "slope", "p_value") %in% names(tr)))
})

# ── Gaps ─────────────────────────────────────────────────────────────────────

test_that("AirPassengers has no gaps in diagnosis", {
  s    <- milt_series(AirPassengers)
  gaps <- milt_diagnose(s)$as_list()$gaps
  expect_equal(nrow(gaps), 0L)
})

test_that("gaps are reported in diagnosis for a gapped series", {
  s   <- milt_series(AirPassengers)
  tbl <- s$as_tibble()[-10, ]
  s_g <- milt_series(tbl, time_col = "time", value_cols = "value",
                     frequency = "monthly")
  gaps <- milt_diagnose(s_g)$as_list()$gaps
  expect_equal(nrow(gaps), 1L)
})

# ── Outliers ──────────────────────────────────────────────────────────────────

test_that("outlier count is non-negative integer", {
  s  <- milt_series(AirPassengers)
  ol <- milt_diagnose(s)$as_list()$outliers
  expect_true(ol$n_outliers >= 0L)
  expect_true(is.integer(ol$indices) || is.numeric(ol$indices))
})

test_that("series with extreme spike is flagged as having outliers", {
  v <- as.numeric(AirPassengers)
  v[50] <- v[50] * 10   # inject a gross outlier
  tbl <- tibble::tibble(
    date  = seq(as.Date("1949-01-01"), by = "month", length.out = 144),
    value = v
  )
  s  <- milt_series(tbl, time_col = "date", value_cols = "value")
  ol <- milt_diagnose(s)$as_list()$outliers
  expect_true(ol$n_outliers > 0L)
  expect_true(50L %in% ol$indices)
})

# ── Recommendations ───────────────────────────────────────────────────────────

test_that("recommendations is a non-empty character vector", {
  s    <- milt_series(AirPassengers)
  recs <- milt_diagnose(s)$as_list()$recommendations
  expect_type(recs, "character")
  expect_true(length(recs) >= 1L)
})

# ── S3 methods ────────────────────────────────────────────────────────────────

test_that("print.MiltDiagnosis does not error", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  expect_output(print(diag), "MiltDiagnosis")
})

test_that("summary.MiltDiagnosis does not error", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  expect_output(summary(diag), "MiltDiagnosis")
})

test_that("plot.MiltDiagnosis does not error", {
  s    <- milt_series(AirPassengers)
  diag <- milt_diagnose(s)
  expect_silent(plot(diag))
})
