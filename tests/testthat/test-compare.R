# Tests for milt_compare() and MiltComparison

air <- milt_series(AirPassengers)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("compare: errors on non-list models", {
  expect_error(milt_compare(milt_model("naive"), air, 12),
               class = "milt_error_invalid_arg")
})

test_that("compare: errors on unnamed models list", {
  expect_error(
    milt_compare(list(milt_model("naive"), milt_model("drift")), air, 12),
    class = "milt_error_invalid_arg"
  )
})

test_that("compare: errors on non-MiltModel in list", {
  expect_error(
    milt_compare(list(good = milt_model("naive"), bad = "not_a_model"), air, 12),
    class = "milt_error_not_milt_model"
  )
})

test_that("compare: errors when rank_metric not in metrics", {
  expect_error(
    milt_compare(
      list(naive = milt_model("naive")),
      air, 12,
      initial_window = 120L, stride = 12L,
      metrics = "MAE", rank_metric = "RMSE"
    ),
    class = "milt_error_invalid_arg"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("compare: returns a MiltComparison", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, horizon = 12,
    initial_window = 120L, stride = 12L,
    metrics = "MAE"
  )
  expect_s3_class(cmp, "MiltComparison")
})

# ── Accessors ─────────────────────────────────────────────────────────────────

test_that("compare: n_models() matches number of models supplied", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  expect_equal(cmp$n_models(), 2L)
})

test_that("compare: backtests() is a named list", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  bt <- cmp$backtests()
  expect_type(bt, "list")
  expect_true(all(c("naive", "drift") %in% names(bt)))
})

test_that("compare: each element of backtests() is a MiltBacktest", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  for (bt in cmp$backtests()) {
    expect_s3_class(bt, "MiltBacktest")
  }
})

test_that("compare: rank_metric() is recorded correctly", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L,
    metrics = c("MAE", "RMSE"), rank_metric = "RMSE"
  )
  expect_equal(cmp$rank_metric(), "RMSE")
})

# ── Summary table ─────────────────────────────────────────────────────────────

test_that("compare: summary_tbl() has one row per model", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  tbl <- cmp$summary_tbl()
  expect_equal(nrow(tbl), 2L)
})

test_that("compare: summary_tbl() has model and rank columns", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  tbl <- cmp$summary_tbl()
  expect_true(all(c("model", "rank") %in% names(tbl)))
})

test_that("compare: summary_tbl() contains MAE column", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  expect_true("MAE" %in% names(cmp$summary_tbl()))
})

test_that("compare: as_tibble() equals summary_tbl()", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  expect_identical(cmp$as_tibble(), cmp$summary_tbl())
})

test_that("compare: rank column is 1 and 2 for two models", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  ranks <- sort(cmp$summary_tbl()$rank)
  expect_equal(ranks, c(1L, 2L))
})

# ── Print ─────────────────────────────────────────────────────────────────────

test_that("compare: print() outputs without error", {
  cmp <- milt_compare(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  expect_output(print(cmp), regexp = "MiltComparison")
})

# ── Three models ──────────────────────────────────────────────────────────────

test_that("compare: three models returns MiltComparison with n_models == 3", {
  cmp <- milt_compare(
    list(naive  = milt_model("naive"),
         drift  = milt_model("drift"),
         snaive = milt_model("snaive")),
    air, 12, initial_window = 120L, stride = 12L, metrics = "MAE"
  )
  expect_equal(cmp$n_models(), 3L)
  expect_equal(nrow(cmp$summary_tbl()), 3L)
})
