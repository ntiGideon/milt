# Tests for milt_cv()

air <- milt_series(AirPassengers)   # 144 monthly obs

# ── Input validation ──────────────────────────────────────────────────────────

test_that("cv: errors on non-MiltModel input", {
  expect_error(milt_cv("not_model", air), class = "milt_error_not_milt_model")
})

test_that("cv: errors on non-MiltSeries input", {
  expect_error(milt_cv(milt_model("naive"), AirPassengers),
               class = "milt_error_not_milt_series")
})

test_that("cv: errors on folds < 1", {
  expect_error(milt_cv(milt_model("naive"), air, folds = 0L),
               class = "milt_error_invalid_arg")
})

test_that("cv: errors on insufficient data", {
  tiny <- milt_series(1:5)
  expect_error(
    milt_cv(milt_model("naive"), tiny, folds = 5L, horizon = 3L),
    class = "milt_error_insufficient_data"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("cv: returns a MiltBacktest", {
  cv <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L)
  expect_s3_class(cv, "MiltBacktest")
})

# ── Fold count ────────────────────────────────────────────────────────────────

test_that("cv: produces exactly folds folds (folds > 1)", {
  cv <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L)
  expect_equal(cv$n_folds(), 3L)
})

test_that("cv: folds = 1 produces exactly 1 fold", {
  cv <- milt_cv(milt_model("naive"), air, folds = 1L, horizon = 12L)
  expect_equal(cv$n_folds(), 1L)
})

test_that("cv: folds = 5 produces exactly 5 folds", {
  cv <- milt_cv(milt_model("naive"), air, folds = 5L, horizon = 6L)
  expect_equal(cv$n_folds(), 5L)
})

# ── Method is expanding ───────────────────────────────────────────────────────

test_that("cv: method is 'expanding'", {
  cv <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L)
  expect_equal(cv$method(), "expanding")
})

test_that("cv: train_n grows across folds", {
  cv   <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L)
  tns  <- cv$metrics()$.train_n
  expect_true(all(diff(tns) >= 0L))
})

# ── Horizon ───────────────────────────────────────────────────────────────────

test_that("cv: horizon() matches requested value", {
  cv <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L)
  expect_equal(cv$horizon(), 12L)
})

# ── No data leakage ───────────────────────────────────────────────────────────

test_that("cv: train_n < total n for all folds", {
  cv  <- milt_cv(milt_model("naive"), air, folds = 4L, horizon = 6L)
  n   <- air$n_timesteps()
  tns <- cv$metrics()$.train_n
  expect_true(all(tns < n))
})

# ── Metric values ─────────────────────────────────────────────────────────────

test_that("cv: MAE values are non-negative", {
  cv <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L,
                metrics = "MAE")
  expect_true(all(cv$metrics()$.MAE >= 0, na.rm = TRUE))
})

# ── custom initial_window ─────────────────────────────────────────────────────

test_that("cv: custom initial_window is respected", {
  cv  <- milt_cv(milt_model("naive"), air, folds = 2L, horizon = 12L,
                 initial_window = 100L)
  expect_equal(cv$metrics()$.train_n[[1L]], 100L)
})

# ── Summary ───────────────────────────────────────────────────────────────────

test_that("cv: summary_tbl() has correct structure", {
  cv   <- milt_cv(milt_model("naive"), air, folds = 3L, horizon = 12L,
                  metrics = c("MAE", "RMSE"))
  smry <- cv$summary_tbl()
  expect_true(all(c("metric", "mean", "sd", "min", "max") %in% names(smry)))
  expect_equal(nrow(smry), 2L)
})
