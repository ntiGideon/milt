# Tests for milt_ensemble() and MiltEnsemble

air <- milt_series(AirPassengers)

# ── Input validation ──────────────────────────────────────────────────────────

test_that("ensemble: errors on empty models list", {
  expect_error(milt_ensemble(list()), class = "milt_error_invalid_arg")
})

test_that("ensemble: errors on unnamed models list", {
  expect_error(
    milt_ensemble(list(milt_model("naive"), milt_model("drift"))),
    class = "milt_error_invalid_arg"
  )
})

test_that("ensemble: errors on non-MiltModel in list", {
  expect_error(
    milt_ensemble(list(good = milt_model("naive"), bad = "string")),
    class = "milt_error_not_milt_model"
  )
})

test_that("ensemble: errors on invalid method", {
  expect_error(
    milt_ensemble(list(naive = milt_model("naive")), method = "voting"),
    regexp = "should be one of"
  )
})

test_that("ensemble: weighted method errors when weights length mismatches", {
  expect_error(
    milt_ensemble(
      list(naive = milt_model("naive"), drift = milt_model("drift")),
      method = "weighted", weights = c(1)
    ),
    class = "milt_error_invalid_arg"
  )
})

test_that("ensemble: weighted method errors on negative weights", {
  expect_error(
    milt_ensemble(
      list(naive = milt_model("naive"), drift = milt_model("drift")),
      method = "weighted", weights = c(-1, 2)
    ),
    class = "milt_error_invalid_arg"
  )
})

# ── Return type ───────────────────────────────────────────────────────────────

test_that("ensemble: returns an unfitted MiltModel", {
  ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  )
  expect_s3_class(ens, "MiltModel")
  expect_false(ens$is_fitted())
})

# ── Fit ───────────────────────────────────────────────────────────────────────

test_that("ensemble: milt_fit() returns fitted MiltModel", {
  ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  ) |> milt_fit(air)
  expect_true(ens$is_fitted())
})

test_that("ensemble: errors when forecasting unfitted ensemble", {
  ens <- milt_ensemble(list(naive = milt_model("naive")))
  expect_error(milt_forecast(ens, 12), class = "milt_error_not_fitted")
})

# ── Forecast ─────────────────────────────────────────────────────────────────

test_that("ensemble: mean method forecast returns MiltForecast", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    method = "mean"
  ) |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("ensemble: median method forecast returns MiltForecast", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"),
         snaive = milt_model("snaive")),
    method = "median"
  ) |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("ensemble: weighted method forecast returns MiltForecast", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    method = "weighted", weights = c(0.7, 0.3)
  ) |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("ensemble: horizon matches requested value", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  ) |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("ensemble: point forecast has no NAs", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  ) |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("ensemble: lower_80 <= mean <= upper_80", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"),
         snaive = milt_model("snaive")),
    method = "mean"
  ) |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
  expect_true(all(tbl$.mean     <= tbl$.upper_80 + 1e-8))
})

# ── member_models() ───────────────────────────────────────────────────────────

test_that("ensemble: member_models() returns named list after fit", {
  ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  ) |> milt_fit(air)
  mm <- ens$member_models()
  expect_type(mm, "list")
  expect_true(all(c("naive", "drift") %in% names(mm)))
})

test_that("ensemble: member_models() are all fitted", {
  ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift"))
  ) |> milt_fit(air)
  for (m in ens$member_models()) {
    expect_true(m$is_fitted())
  }
})

# ── Aggregation correctness ───────────────────────────────────────────────────

test_that("ensemble (mean of 1 model) matches single model forecast", {
  s     <- milt_series(AirPassengers)
  solo  <- milt_model("naive") |> milt_fit(s) |> milt_forecast(12)
  ens   <- milt_ensemble(list(naive = milt_model("naive")), method = "mean") |>
    milt_fit(s) |>
    milt_forecast(12)
  expect_equal(ens$as_tibble()$.mean, solo$as_tibble()$.mean, tolerance = 1e-8)
})

test_that("ensemble (equal weights) matches mean ensemble", {
  s     <- milt_series(AirPassengers)
  mean_ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    method = "mean"
  ) |> milt_fit(s) |> milt_forecast(12)

  wt_ens <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    method = "weighted", weights = c(1, 1)
  ) |> milt_fit(s) |> milt_forecast(12)

  expect_equal(
    mean_ens$as_tibble()$.mean,
    wt_ens$as_tibble()$.mean,
    tolerance = 1e-8
  )
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("ensemble: model_name encodes method", {
  fct <- milt_ensemble(
    list(naive = milt_model("naive"), drift = milt_model("drift")),
    method = "median"
  ) |> milt_fit(air) |> milt_forecast(12)
  expect_true(grepl("median", fct$model_name()))
})
