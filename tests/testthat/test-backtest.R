# Tests for milt_backtest() and MiltBacktest class

air <- milt_series(AirPassengers)   # 144 monthly obs

# ── Input validation ──────────────────────────────────────────────────────────

test_that("backtest: errors on non-MiltModel input", {
  expect_error(milt_backtest("not_a_model", air, 12),
               class = "milt_error_not_milt_model")
})

test_that("backtest: errors on non-MiltSeries input", {
  expect_error(milt_backtest(milt_model("naive"), AirPassengers, 12),
               class = "milt_error_not_milt_series")
})

test_that("backtest: errors on invalid stride", {
  m <- milt_model("naive")
  expect_error(milt_backtest(m, air, 12, stride = 0L),
               class = "milt_error_invalid_arg")
})

test_that("backtest: errors when insufficient data", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 10),
    value = 1:10
  )
  s_small <- milt_series(tbl, time_col = "date", value_cols = "value")
  expect_error(
    milt_backtest(milt_model("naive"), s_small, horizon = 9, initial_window = 8),
    class = "milt_error_insufficient_data"
  )
})

test_that("backtest: errors on invalid method argument", {
  expect_error(
    milt_backtest(milt_model("naive"), air, 12, method = "random"),
    regexp = "should be one of"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("backtest: returns a MiltBacktest object", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_s3_class(bt, "MiltBacktest")
})

# ── Fold count ────────────────────────────────────────────────────────────────

test_that("backtest: expanding window fold count is correct", {
  # initial_window=120, horizon=12, n=144, stride=12 → fold_ends = c(120, 132)
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_equal(bt$n_folds(), 2L)
})

test_that("backtest: stride=1 produces many folds", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 6,
                      initial_window = 120L, stride = 1L)
  # fold_ends from 120 to 138 (144-6=138), step 1 → 19 folds
  expect_equal(bt$n_folds(), 19L)
})

test_that("backtest: sliding window same fold count as expanding (same params)", {
  bt_exp <- milt_backtest(milt_model("naive"), air, horizon = 12,
                           initial_window = 120L, stride = 12L,
                           method = "expanding")
  bt_sld <- milt_backtest(milt_model("naive"), air, horizon = 12,
                           initial_window = 120L, stride = 12L,
                           method = "sliding", window = 120L)
  expect_equal(bt_exp$n_folds(), bt_sld$n_folds())
})

# ── Accessor consistency ──────────────────────────────────────────────────────

test_that("backtest: model_name() matches model used", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_equal(bt$model_name(), "naive")
})

test_that("backtest: horizon() matches requested value", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 6,
                      initial_window = 120L, stride = 12L)
  expect_equal(bt$horizon(), 6L)
})

test_that("backtest: method() is 'expanding' by default", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_equal(bt$method(), "expanding")
})

test_that("backtest: method() reflects sliding when specified", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      method = "sliding")
  expect_equal(bt$method(), "sliding")
})

# ── Fold results tibble ───────────────────────────────────────────────────────

test_that("backtest: metrics() returns a tibble with expected columns", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = c("MAE", "RMSE"))
  tbl <- bt$metrics()
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c(".fold", ".train_n", ".test_n", ".MAE", ".RMSE") %in% names(tbl)))
})

test_that("backtest: as_tibble() is identical to metrics()", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_identical(bt$as_tibble(), bt$metrics())
})

test_that("backtest: .fold column is sequential integers starting at 1", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_equal(bt$metrics()$.fold, seq_len(bt$n_folds()))
})

test_that("backtest: .train_n is strictly positive in every fold", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_true(all(bt$metrics()$.train_n > 0L))
})

test_that("backtest: expanding window — .train_n increases across folds", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 108L, stride = 12L,
                      method = "expanding")
  train_ns <- bt$metrics()$.train_n
  expect_true(all(diff(train_ns) >= 0L))
})

test_that("backtest: sliding window — .train_n is constant across folds", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 108L, stride = 12L,
                      method = "sliding", window = 108L)
  train_ns <- bt$metrics()$.train_n
  expect_true(all(train_ns == train_ns[[1L]]))
})

# ── No data leakage ───────────────────────────────────────────────────────────

test_that("backtest: expanding window train_n for fold k = initial + (k-1)*stride", {
  iw <- 108L; s  <- 12L; h <- 12L
  bt <- milt_backtest(milt_model("naive"), air, horizon = h,
                      initial_window = iw, stride = s,
                      method = "expanding")
  tbl <- bt$metrics()
  expected <- iw + (seq_len(bt$n_folds()) - 1L) * s
  expect_equal(tbl$.train_n, as.integer(expected))
})

# ── Metric values ─────────────────────────────────────────────────────────────

test_that("backtest: MAE values are non-negative", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = "MAE")
  expect_true(all(bt$metrics()$.MAE >= 0, na.rm = TRUE))
})

test_that("backtest: RMSE >= MAE in every fold", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = c("MAE", "RMSE"))
  tbl <- bt$metrics()
  expect_true(all(tbl$.RMSE >= tbl$.MAE - 1e-10, na.rm = TRUE))
})

# ── Summary ───────────────────────────────────────────────────────────────────

test_that("backtest: summary_tbl() has columns metric, mean, sd, min, max", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = c("MAE", "RMSE"))
  smry <- bt$summary_tbl()
  expect_s3_class(smry, "tbl_df")
  expect_true(all(c("metric", "mean", "sd", "min", "max") %in% names(smry)))
})

test_that("backtest: summary_tbl() has one row per metric", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = c("MAE", "RMSE", "MAPE"))
  expect_equal(nrow(bt$summary_tbl()), 3L)
})

test_that("backtest: summary mean >= summary min", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 108L, stride = 12L,
                      metrics = "MAE")
  smry <- bt$summary_tbl()
  expect_true(all(smry$mean >= smry$min - 1e-10))
})

# ── Print / S3 ────────────────────────────────────────────────────────────────

test_that("backtest: print() produces output without error", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_output(print(bt), regexp = "MiltBacktest")
})

test_that("backtest: summary() produces same output as print()", {
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12,
                      initial_window = 120L, stride = 12L)
  expect_output(summary(bt), regexp = "MiltBacktest")
})

# ── Default initial_window ────────────────────────────────────────────────────

test_that("backtest: default initial_window = floor(n * 0.5)", {
  # n=144, floor(144*0.5)=72, horizon=12 → fold_ends from 72 to 132, stride 12 → 6 folds
  bt <- milt_backtest(milt_model("naive"), air, horizon = 12, stride = 12L)
  expect_equal(bt$metrics()$.train_n[[1L]], 72L)
})

# ── End-to-end with forecast-package backend ──────────────────────────────────

test_that("backtest: works with ets backend", {
  skip_if_not_installed("forecast")
  bt <- milt_backtest(milt_model("ets"), air, horizon = 12,
                      initial_window = 120L, stride = 12L,
                      metrics = c("MAE", "RMSE"))
  expect_s3_class(bt, "MiltBacktest")
  expect_equal(bt$model_name(), "ets")
  expect_false(any(is.na(bt$metrics()$.MAE)))
})
