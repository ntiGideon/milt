# Tests for MiltGlobalModel and milt_global_model()

air <- milt_series(AirPassengers)

.make_multi_series <- function(n = 36L) {
  set.seed(1L)
  tbl <- tibble::tibble(
    date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = n), 3L),
    store = rep(c("A", "B", "C"), each = n),
    value = c(cumsum(rnorm(n, 1, 2)), cumsum(rnorm(n, 3, 2)), cumsum(rnorm(n, -1, 2)))
  )
  milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")
}

# ── Input validation ──────────────────────────────────────────────────────────

test_that("global_model: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_global_model("knn", lags = 1:3) |> milt_fit(s),
    class = "milt_error_not_univariate"
  )
})

test_that("global_model: errors on unsupported method", {
  gm <- MiltGlobalModel$new(method = "not_a_method")
  expect_error(gm$fit(air), class = "milt_error_invalid_arg")
})

test_that("global_model: errors when a group is too short for the requested lags", {
  ms <- .make_multi_series(n = 5L)
  expect_error(
    milt_global_model("knn", lags = 1:12) |> milt_fit(ms),
    class = "milt_error_insufficient_data"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("global_model: returns an unfitted MiltModel", {
  gm <- milt_global_model("knn")
  expect_s3_class(gm, "MiltModel")
  expect_false(gm$is_fitted())
})

test_that("global_model: model name includes 'global'", {
  gm <- milt_global_model("knn")
  expect_true(grepl("global", gm$.__enclos_env__$private$.name))
})

# ── Single-series (degenerate) behaviour ──────────────────────────────────────

test_that("global_model: fits and forecasts a single (ungrouped) series", {
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(air)
  expect_true(gm$is_fitted())
  fct <- gm$forecast(12)
  expect_s3_class(fct, "MiltForecast")
  expect_equal(fct$horizon(), 12L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Multi-series (real global training) ───────────────────────────────────────

test_that("global_model: fits across all groups with one shared model", {
  ms <- .make_multi_series()
  gm <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  expect_true(gm$is_fitted())
  expect_equal(sort(gm$groups()), c("A", "B", "C"))
})

test_that("global_model: forecast_all() returns one MiltForecast per group", {
  ms  <- .make_multi_series()
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  all <- gm$forecast_all(horizon = 6)
  expect_type(all, "list")
  expect_equal(length(all), 3L)
  for (fct in all) expect_s3_class(fct, "MiltForecast")
})

test_that("global_model: different groups produce different forecasts from the shared model", {
  ms  <- .make_multi_series()
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  all <- gm$forecast_all(horizon = 6)
  pt_a <- all[["A"]]$as_tibble()$.mean
  pt_c <- all[["C"]]$as_tibble()$.mean
  # Group A trends up, group C trends down — the shared model must still
  # differentiate them via the per-group history + group indicator feature.
  expect_false(all(abs(pt_a - pt_c) < 1e-8))
})

test_that("global_model: forecast() defaults to the first group and accepts an explicit group", {
  ms  <- .make_multi_series()
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  fct_default <- gm$forecast(horizon = 6)
  fct_b       <- gm$forecast(horizon = 6, group = "B")
  expect_equal(fct_default$as_tibble()$.mean, gm$forecast_all(6)[["A"]]$as_tibble()$.mean)
  expect_equal(fct_b$as_tibble()$.mean, gm$forecast_all(6)[["B"]]$as_tibble()$.mean)
})

test_that("global_model: forecast() errors on an unknown group", {
  ms <- .make_multi_series()
  gm <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  expect_error(gm$forecast(6, group = "not_a_group"), class = "milt_error_invalid_arg")
})

test_that("global_model: predict()/residuals() return pooled numeric vectors", {
  ms  <- .make_multi_series()
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  prd <- milt_predict(gm)
  res <- milt_residuals(gm)
  expect_type(prd, "double")
  expect_type(res, "double")
  expect_equal(length(prd), length(res))
})

# ── Static covariates ─────────────────────────────────────────────────────────

test_that("global_model: fits successfully with static covariates attached", {
  ms  <- .make_multi_series()
  cov <- data.frame(store = c("A", "B", "C"), region = c(1, 2, 3))
  milt_add_covariates(ms, cov, type = "static")

  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  all <- gm$forecast_all(horizon = 6)
  expect_equal(length(all), 3L)
  for (fct in all) expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Intervals ─────────────────────────────────────────────────────────────────

test_that("global_model: prediction intervals are valid (lower <= mean <= upper)", {
  ms  <- .make_multi_series()
  gm  <- milt_global_model("knn", lags = 1:6, k = 3L) |> milt_fit(ms)
  fct <- gm$forecast(6, group = "A")
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
})
