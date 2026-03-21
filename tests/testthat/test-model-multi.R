# Tests for MiltLocalModel and milt_local_model()

air <- milt_series(AirPassengers)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("local_model: errors on non-MiltModel input", {
  expect_error(milt_local_model("not_a_model"),
               class = "milt_error_not_milt_model")
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("local_model: returns an unfitted MiltModel", {
  lm <- milt_local_model(milt_model("naive"))
  expect_s3_class(lm, "MiltModel")
  expect_false(lm$is_fitted())
})

# ── Single-series behaviour ───────────────────────────────────────────────────

test_that("local_model: fit on single series returns fitted model", {
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(air)
  expect_true(lm$is_fitted())
})

test_that("local_model: forecast on single series returns MiltForecast", {
  fct <- milt_local_model(milt_model("naive")) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("local_model: single series forecast matches unwrapped model", {
  fct_plain  <- milt_model("naive") |> milt_fit(air) |> milt_forecast(12)
  fct_local  <- milt_local_model(milt_model("naive")) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_equal(fct_plain$as_tibble()$.mean,
               fct_local$as_tibble()$.mean,
               tolerance = 1e-8)
})

test_that("local_model: horizon matches on single series", {
  fct <- milt_local_model(milt_model("naive")) |>
    milt_fit(air) |>
    milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("local_model: n_groups is 1 for single series", {
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(air)
  expect_equal(lm$n_groups(), 1L)
})

# ── Multi-series behaviour ────────────────────────────────────────────────────

.make_multi_series <- function() {
  set.seed(1L)
  tbl <- tibble::tibble(
    date     = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 36L), 2L),
    category = rep(c("A", "B"), each = 36L),
    value    = c(cumsum(rnorm(36L)), cumsum(rnorm(36L)) + 10)
  )
  milt_series(tbl, time_col = "date", value_cols = "value",
              group_col = "category")
}

test_that("local_model: fit on multi-series succeeds", {
  ms <- .make_multi_series()
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  expect_true(lm$is_fitted())
})

test_that("local_model: n_groups equals number of groups in multi-series", {
  ms <- .make_multi_series()
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  expect_equal(lm$n_groups(), 2L)
})

test_that("local_model: fitted_models() is a named list with one model per group", {
  ms <- .make_multi_series()
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  fm <- lm$fitted_models()
  expect_type(fm, "list")
  expect_equal(length(fm), 2L)
  expect_true(all(c("A", "B") %in% names(fm)))
})

test_that("local_model: each fitted member model is a fitted MiltModel", {
  ms <- .make_multi_series()
  lm <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  for (m in lm$fitted_models()) {
    expect_s3_class(m, "MiltModel")
    expect_true(m$is_fitted())
  }
})

test_that("local_model: forecast_all() returns named list of MiltForecast", {
  ms  <- .make_multi_series()
  lm  <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  all <- lm$forecast_all(12)
  expect_type(all, "list")
  expect_equal(length(all), 2L)
  for (fct in all) expect_s3_class(fct, "MiltForecast")
})

test_that("local_model: forecast_all() forecasts are different per group", {
  ms   <- .make_multi_series()
  lm   <- milt_local_model(milt_model("naive")) |> milt_fit(ms)
  all  <- lm$forecast_all(12)
  pt_A <- all[["A"]]$as_tibble()$.mean
  pt_B <- all[["B"]]$as_tibble()$.mean
  # Different series → different last values → different naive forecasts
  expect_false(all(abs(pt_A - pt_B) < 1e-10))
})

test_that("local_model: milt_forecast() returns MiltForecast on multi-series", {
  ms  <- .make_multi_series()
  fct <- milt_local_model(milt_model("naive")) |>
    milt_fit(ms) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("local_model: model name includes 'local'", {
  lm <- milt_local_model(milt_model("naive"))
  expect_true(grepl("local", lm$.__enclos_env__$private$.name))
})

# ── With forecast-package backend ─────────────────────────────────────────────

test_that("local_model: works with ets backend (single series)", {
  skip_if_not_installed("forecast")
  fct <- milt_local_model(milt_model("ets")) |>
    milt_fit(air) |>
    milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})
