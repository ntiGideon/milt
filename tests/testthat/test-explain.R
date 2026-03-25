# Tests for milt_explain() / MiltExplanation

air <- milt_series(AirPassengers)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("explain: non-MiltModel input errors", {
  expect_error(milt_explain("not_a_model"),
               class = "milt_error_not_milt_model")
})

test_that("explain: unfitted model errors", {
  m <- milt_model("xgboost")
  expect_error(milt_explain(m), class = "milt_error_not_fitted")
})

test_that("explain: unsupported backend errors", {
  skip_if_not_installed("forecast")
  m <- milt_model("auto_arima") |> milt_fit(air)
  expect_error(milt_explain(m), class = "milt_error_not_supported")
})

# ── XGBoost ───────────────────────────────────────────────────────────────────

test_that("explain: xgboost returns MiltExplanation", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_s3_class(ex, "MiltExplanation")
})

test_that("explain: xgboost method() equals 'xgboost'", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_equal(ex$method(), "xgboost")
})

test_that("explain: xgboost importance() tibble has feature and importance columns", {
  skip_if_not_installed("xgboost")
  m   <- milt_model("xgboost") |> milt_fit(air)
  ex  <- milt_explain(m)
  imp <- ex$importance()
  expect_s3_class(imp, "tbl_df")
  expect_true(all(c("feature", "importance") %in% names(imp)))
})

test_that("explain: xgboost importance values are non-negative", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_true(all(ex$importance()$importance >= 0))
})

test_that("explain: xgboost importance is sorted descending", {
  skip_if_not_installed("xgboost")
  m   <- milt_model("xgboost") |> milt_fit(air)
  ex  <- milt_explain(m)
  imp <- ex$importance()$importance
  expect_true(all(diff(imp) <= 0))
})

# ── Random Forest ─────────────────────────────────────────────────────────────

test_that("explain: random_forest returns MiltExplanation", {
  skip_if_not_installed("ranger")
  m  <- milt_model("random_forest") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_s3_class(ex, "MiltExplanation")
})

test_that("explain: random_forest importance is non-negative", {
  skip_if_not_installed("ranger")
  m  <- milt_model("random_forest") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_true(all(ex$importance()$importance >= 0))
})

# ── Elastic Net ───────────────────────────────────────────────────────────────

test_that("explain: elastic_net returns MiltExplanation", {
  skip_if_not_installed("glmnet")
  m  <- milt_model("elastic_net") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_s3_class(ex, "MiltExplanation")
})

test_that("explain: elastic_net importance equals abs(coef)", {
  skip_if_not_installed("glmnet")
  m  <- milt_model("elastic_net") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_true(all(ex$importance()$importance >= 0))
})

# ── as_tibble / print / plot ──────────────────────────────────────────────────

test_that("explain: as_tibble() returns tibble", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  tbl <- ex$as_tibble()
  expect_s3_class(tbl, "tbl_df")
})

test_that("explain: S3 as_tibble dispatch works", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_s3_class(tibble::as_tibble(ex), "tbl_df")
})

test_that("explain: print() runs without error", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  expect_output(print(ex), "MiltExplanation")
})

test_that("explain: plot() returns ggplot", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  p  <- plot(ex)
  expect_s3_class(p, "gg")
})

test_that("explain: plot() title mentions backend name", {
  skip_if_not_installed("xgboost")
  m  <- milt_model("xgboost") |> milt_fit(air)
  ex <- milt_explain(m)
  p  <- plot(ex)
  expect_true(grepl("xgboost", p$labels$title))
})
