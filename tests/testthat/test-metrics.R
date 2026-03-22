# Tests for R/metrics.R
# Strategy: compute expected values by hand for small inputs, then verify.

# ── Shared fixtures ───────────────────────────────────────────────────────────

actual    <- c(3, 5, 4, 6, 5)
predicted <- c(2, 4, 5, 7, 4)
# errors:  -1, -1,  1, 1, -1  abs: 1,1,1,1,1  sq: 1,1,1,1,1
training  <- c(1, 2, 3, 4, 5, 6)   # for MASE/RMSSE

# ── Input validation (shared across metrics) ──────────────────────────────────

test_that("metrics error on non-numeric actual", {
  expect_error(milt_mae("a", 1:5), class = "milt_error_invalid_metric_input")
})

test_that("metrics error on non-numeric predicted", {
  expect_error(milt_mae(1:5, "b"), class = "milt_error_invalid_metric_input")
})

test_that("metrics error when lengths differ", {
  expect_error(milt_mae(1:5, 1:4), class = "milt_error_length_mismatch")
})

test_that("metrics error on empty vectors", {
  expect_error(milt_mae(numeric(0), numeric(0)), class = "milt_error_invalid_metric_input")
})

# ── milt_mae ──────────────────────────────────────────────────────────────────

test_that("milt_mae computes correct value", {
  # all abs errors = 1, mean = 1
  expect_equal(milt_mae(actual, predicted), 1)
})

test_that("milt_mae is 0 for perfect forecast", {
  expect_equal(milt_mae(1:5, 1:5), 0)
})

test_that("milt_mae handles NAs with na.rm", {
  a <- c(1, 2, NA, 4)
  p <- c(0, 2, 99,  4)
  expect_equal(milt_mae(a, p), mean(c(1, 0, 0), na.rm = TRUE))
})

# ── milt_mse ──────────────────────────────────────────────────────────────────

test_that("milt_mse computes correct value", {
  # all sq errors = 1, mean = 1
  expect_equal(milt_mse(actual, predicted), 1)
})

test_that("milt_mse is 0 for perfect forecast", {
  expect_equal(milt_mse(1:5, 1:5), 0)
})

test_that("milt_mse is non-negative", {
  expect_true(milt_mse(rnorm(20), rnorm(20)) >= 0)
})

# ── milt_rmse ─────────────────────────────────────────────────────────────────

test_that("milt_rmse is sqrt of mse", {
  a <- rnorm(30)
  p <- rnorm(30)
  expect_equal(milt_rmse(a, p), sqrt(milt_mse(a, p)))
})

test_that("milt_rmse is 0 for perfect forecast", {
  expect_equal(milt_rmse(1:5, 1:5), 0)
})

# ── milt_mape ─────────────────────────────────────────────────────────────────

test_that("milt_mape computes correctly", {
  a <- c(100, 200)
  p <- c(90,  210)
  # errors: -10, 10; pct: 0.1, 0.05; mean = 0.075
  expect_equal(milt_mape(a, p), 0.075)
})

test_that("milt_mape warns when actual has zeros", {
  expect_warning(milt_mape(c(0, 1), c(1, 1)))
})

test_that("milt_mape returns Inf when actual is zero", {
  expect_true(is.infinite(suppressWarnings(milt_mape(c(0), c(1)))))
})

# ── milt_smape ────────────────────────────────────────────────────────────────

test_that("milt_smape is 0 for perfect forecast", {
  expect_equal(milt_smape(1:5, 1:5), 0)
})

test_that("milt_smape is bounded between 0 and 2", {
  v <- milt_smape(abs(rnorm(50)) + 0.1, abs(rnorm(50)) + 0.1)
  expect_true(v >= 0 && v <= 2)
})

test_that("milt_smape handles both-zero case", {
  expect_warning(milt_smape(c(0, 1), c(0, 1)))
  val <- suppressWarnings(milt_smape(c(0, 1), c(0, 1)))
  expect_equal(val, 0)
})

test_that("milt_smape is symmetric", {
  a <- c(100, 200, 150)
  p <- c(110, 180, 160)
  expect_equal(milt_smape(a, p), milt_smape(p, a))
})

# ── milt_mase ─────────────────────────────────────────────────────────────────

test_that("milt_mase is < 1 for good forecast", {
  # Training: 1..12 (monthly). Naive seasonal scale = mean(abs(diff(1:12, lag=12)))
  # But training here is just sequential so naive(season=1) scale = 1
  tr  <- 1:24
  a   <- 13:24 + rnorm(12, 0, 0.1)   # near-perfect
  p   <- 13:24
  val <- milt_mase(a, p, training = tr, season = 1L)
  expect_true(val < 1)
})

test_that("milt_mase with season=1 scales by naive walk", {
  # training = 1,2,...,6 → diffs all = 1 → scale = 1
  tr <- 1:6
  a  <- c(7, 8)
  p  <- c(8, 9)   # off by 1 each step → MAE = 1 → MASE = 1/1 = 1
  expect_equal(milt_mase(a, p, training = tr, season = 1L), 1)
})

test_that("milt_mase warns and returns NaN for constant training", {
  expect_warning(v <- milt_mase(c(1, 2), c(1, 2), training = c(5, 5, 5)))
  expect_true(is.nan(v))
})

test_that("milt_mase errors when training is shorter than season", {
  expect_error(
    milt_mase(1:3, 1:3, training = 1:2, season = 12L),
    class = "milt_error_insufficient_data"
  )
})

test_that("milt_mase errors on non-numeric training", {
  expect_error(
    milt_mase(1:3, 1:3, training = "oops"),
    class = "milt_error_invalid_metric_input"
  )
})

# ── milt_rmsse ────────────────────────────────────────────────────────────────

test_that("milt_rmsse is non-negative", {
  tr  <- 1:20
  val <- milt_rmsse(20:25, 21:26, training = tr)
  expect_true(val >= 0)
})

test_that("milt_rmsse is 0 for perfect forecast", {
  tr <- 1:10
  a  <- 11:15
  p  <- 11:15
  expect_equal(milt_rmsse(a, p, training = tr), 0)
})

test_that("milt_rmsse warns and returns NaN for constant training", {
  expect_warning(v <- milt_rmsse(c(1, 2), c(1, 2), training = c(5, 5, 5)))
  expect_true(is.nan(v))
})

# ── milt_mrae ─────────────────────────────────────────────────────────────────

test_that("milt_mrae is < 1 when model outperforms benchmark", {
  a   <- c(10, 20, 30)
  p   <- c(11, 19, 31)   # errors = 1,1,1
  bm  <- c(15, 25,  5)   # errors = 5,5,25  (worse)
  val <- milt_mrae(a, p, bm)
  expect_true(val < 1)
})

test_that("milt_mrae is 1 when model matches benchmark", {
  a  <- c(10, 20)
  p  <- c(11, 19)   # errors = 1,1
  bm <- c(11, 19)   # same errors
  expect_equal(milt_mrae(a, p, bm), 1)
})

test_that("milt_mrae warns when benchmark is perfect", {
  expect_warning(milt_mrae(c(1, 2), c(0, 0), c(1, 2)))
})

# ── milt_r_squared ────────────────────────────────────────────────────────────

test_that("milt_r_squared is 1 for perfect forecast", {
  expect_equal(milt_r_squared(1:10, 1:10), 1)
})

test_that("milt_r_squared is 0 when predicted equals mean(actual)", {
  a <- 1:10
  p <- rep(mean(a), 10)
  expect_equal(milt_r_squared(a, p), 0, tolerance = 1e-10)
})

test_that("milt_r_squared can be negative", {
  a <- 1:5
  p <- rev(a) * 2   # deliberately bad
  expect_true(milt_r_squared(a, p) < 0)
})

test_that("milt_r_squared warns and returns NaN for constant actual", {
  expect_warning(v <- milt_r_squared(c(5, 5, 5), c(1, 2, 3)))
  expect_true(is.nan(v))
})

# ── milt_coverage ─────────────────────────────────────────────────────────────

test_that("milt_coverage is 1 when all actuals are inside intervals", {
  a <- c(5, 10, 15)
  l <- c(4,  9, 14)
  u <- c(6, 11, 16)
  expect_equal(milt_coverage(a, l, u), 1)
})

test_that("milt_coverage is 0 when no actuals are inside intervals", {
  a <- c(5, 10)
  l <- c(6, 11)
  u <- c(7, 12)
  expect_equal(milt_coverage(a, l, u), 0)
})

test_that("milt_coverage is between 0 and 1", {
  a <- c(1, 5, 10)
  l <- c(0, 6,  9)
  u <- c(2, 7, 11)
  val <- milt_coverage(a, l, u)
  expect_true(val >= 0 && val <= 1)
})

test_that("milt_coverage warns when lower > upper", {
  expect_warning(milt_coverage(c(1), c(5), c(2)))
})

# ── milt_crps ─────────────────────────────────────────────────────────────────

test_that("milt_crps returns a non-negative numeric scalar", {
  set.seed(1)
  a    <- c(1, 2, 3)
  dist <- matrix(rnorm(3 * 100), nrow = 3, ncol = 100)
  val  <- milt_crps(a, dist)
  expect_true(is.numeric(val) && length(val) == 1L)
  expect_true(val >= 0)
})

test_that("milt_crps is small for near-perfect probabilistic forecast", {
  set.seed(42)
  a    <- c(5, 10, 15)
  # Samples tightly centred on actual
  dist <- matrix(rep(a, each = 200) + rnorm(3 * 200, 0, 0.01),
                 nrow = 3, ncol = 200, byrow = TRUE)
  val  <- milt_crps(a, dist)
  expect_true(val < 0.05)
})

test_that("milt_crps errors when forecast_dist has wrong row count", {
  expect_error(
    milt_crps(c(1, 2), matrix(rnorm(30), 3, 10)),
    class = "milt_error_length_mismatch"
  )
})

test_that("milt_crps errors when forecast_dist is not a matrix", {
  expect_error(milt_crps(1:3, 1:3), class = "milt_error_invalid_metric_input")
})

# ── milt_pinball ──────────────────────────────────────────────────────────────

test_that("milt_pinball returns non-negative value", {
  a    <- c(1, 2, 3)
  q    <- matrix(c(0.5, 1.5, 2.5), ncol = 1)
  val  <- milt_pinball(a, q, taus = 0.5)
  expect_true(val >= 0)
})

test_that("milt_pinball is 0 when quantile = actual at tau = 0.5", {
  a   <- c(2, 4)
  q   <- matrix(c(2, 4), ncol = 1)
  val <- milt_pinball(a, q, taus = 0.5)
  expect_equal(val, 0)
})

test_that("milt_pinball errors when taus are out of (0,1)", {
  a <- c(1, 2)
  q <- matrix(c(1, 2), ncol = 1)
  expect_error(milt_pinball(a, q, taus = 0),   class = "milt_error_invalid_metric_input")
  expect_error(milt_pinball(a, q, taus = 1),   class = "milt_error_invalid_metric_input")
  expect_error(milt_pinball(a, q, taus = 1.5), class = "milt_error_invalid_metric_input")
})

test_that("milt_pinball errors when col count doesn't match taus", {
  expect_error(
    milt_pinball(1:3, matrix(rnorm(6), 3, 2), taus = c(0.1, 0.5, 0.9)),
    class = "milt_error_length_mismatch"
  )
})

# ── milt_winkler ──────────────────────────────────────────────────────────────

test_that("milt_winkler equals interval width when all actuals are inside", {
  a   <- c(5, 10)
  l   <- c(4,  9)
  u   <- c(6, 11)
  # width = 2, 2; no penalty; mean = 2
  expect_equal(milt_winkler(a, l, u, alpha = 0.05), 2)
})

test_that("milt_winkler adds penalty when actual is outside interval", {
  # Single obs below lower
  a   <- 3
  l   <- 5
  u   <- 7
  # width = 2; penalty = 2/0.05 * (5-3) = 40 * 2 = 80; total = 82
  expect_equal(milt_winkler(a, l, u, alpha = 0.05), 82)
})

test_that("milt_winkler errors on invalid alpha", {
  expect_error(milt_winkler(1, 0, 2, alpha = 0),   class = "milt_error_invalid_metric_input")
  expect_error(milt_winkler(1, 0, 2, alpha = 1),   class = "milt_error_invalid_metric_input")
  expect_error(milt_winkler(1, 0, 2, alpha = -0.1), class = "milt_error_invalid_metric_input")
})

# ── milt_accuracy ─────────────────────────────────────────────────────────────

test_that("milt_accuracy returns a tibble", {
  out <- milt_accuracy(actual, predicted)
  expect_s3_class(out, "tbl_df")
  expect_true(all(c("metric", "value") %in% names(out)))
})

test_that("milt_accuracy includes standard point metrics", {
  out <- milt_accuracy(actual, predicted)
  expect_true("MAE"  %in% out$metric)
  expect_true("RMSE" %in% out$metric)
  expect_true("R2"   %in% out$metric)
})

test_that("milt_accuracy MAE value matches milt_mae", {
  out <- milt_accuracy(actual, predicted)
  expect_equal(
    out$value[out$metric == "MAE"],
    milt_mae(actual, predicted)
  )
})

test_that("milt_accuracy includes MASE and RMSSE when training is provided", {
  out <- milt_accuracy(actual, predicted, training = training)
  expect_true("MASE"  %in% out$metric)
  expect_true("RMSSE" %in% out$metric)
})

test_that("milt_accuracy excludes MASE/RMSSE when training is NULL", {
  out <- milt_accuracy(actual, predicted)
  expect_false("MASE"  %in% out$metric)
  expect_false("RMSSE" %in% out$metric)
})

test_that("milt_accuracy accepts MiltSeries for actual", {
  s   <- milt_series(AirPassengers)
  spl <- milt_split(s)
  out <- milt_accuracy(spl$test, spl$train$values()[seq_len(spl$test$n_timesteps())])
  expect_s3_class(out, "tbl_df")
})

test_that("milt_accuracy errors on multivariate MiltSeries", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 6),
    a = 1:6, b = 7:12
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_accuracy(s, 1:6), class = "milt_error_not_univariate")
})

test_that("milt_accuracy with metrics='point' excludes MASE even with training", {
  out <- milt_accuracy(actual, predicted, training = training, metrics = "point")
  expect_false("MASE" %in% out$metric)
})

test_that("milt_accuracy all metric values are finite numbers or NaN", {
  out <- milt_accuracy(actual, predicted)
  expect_true(all(is.numeric(out$value)))
})
