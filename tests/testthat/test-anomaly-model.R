# Tests for milt_anomaly_score(), milt_anomaly_model(), milt_detect_anomalies()

air <- milt_series(AirPassengers)

# ── milt_anomaly_score ────────────────────────────────────────────────────────

test_that("anomaly_score: norm is the absolute value", {
  r <- c(-2, 0, 3, NA)
  expect_equal(milt_anomaly_score(r, "norm"), c(2, 0, 3, NA))
})

test_that("anomaly_score: difference is the signed residual", {
  r <- c(-2, 0, 3)
  expect_equal(milt_anomaly_score(r, "difference"), r)
})

test_that("anomaly_score: nll_gaussian is higher for more extreme residuals", {
  r <- c(0, 0.1, -0.1, 10, -10)
  scores <- milt_anomaly_score(r, "nll_gaussian")
  expect_true(scores[[4]] > scores[[1]])
  expect_true(scores[[5]] > scores[[1]])
})

test_that("anomaly_score: errors on non-numeric input", {
  expect_error(milt_anomaly_score("a"), class = "milt_error_invalid_metric_input")
})

test_that("anomaly_score: default method is norm", {
  r <- c(-2, 3)
  expect_equal(milt_anomaly_score(r), milt_anomaly_score(r, "norm"))
})

# ── milt_anomaly_model / milt_detect_anomalies ────────────────────────────────

test_that("anomaly_model: errors on non-MiltModel input", {
  expect_error(milt_anomaly_model("not_a_model"), class = "milt_error_not_milt_model")
})

test_that("anomaly_model: errors on invalid quantile", {
  expect_error(
    milt_anomaly_model(milt_model("naive"), quantile = 1.5),
    class = "milt_error_invalid_arg"
  )
})

test_that("anomaly_model: returns an unfitted MiltModel", {
  am <- milt_anomaly_model(milt_model("naive"))
  expect_s3_class(am, "MiltModel")
  expect_false(am$is_fitted())
})

test_that("anomaly_model: fitting does not mutate the original model object", {
  m  <- milt_model("naive")
  am <- milt_anomaly_model(m)
  milt_fit(am, air)
  expect_false(m$is_fitted())
})

test_that("anomaly_model: fit + detect returns a MiltAnomalies object", {
  am    <- milt_anomaly_model(milt_model("naive")) |> milt_fit(air)
  anoms <- milt_detect_anomalies(am)
  expect_s3_class(anoms, "MiltAnomalies")
  expect_equal(anoms$series()$n_timesteps(), air$n_timesteps())
})

test_that("anomaly_model: quantile detector flags roughly (1 - quantile) of scored points", {
  am    <- milt_anomaly_model(milt_model("naive"), detector = "quantile", quantile = 0.9) |>
    milt_fit(air)
  anoms <- milt_detect_anomalies(am)
  # ~10% of the scoreable (non-NA-residual) points should be flagged
  n_scoreable <- sum(!is.na(am$residuals()))
  expect_equal(anoms$n_anomalies(), round(0.1 * n_scoreable), tolerance = 2)
})

test_that("anomaly_model: threshold detector uses explicit bounds", {
  am <- milt_anomaly_model(
    milt_model("naive"), scorer = "difference", detector = "threshold",
    low = -1e6, high = 1e6
  ) |> milt_fit(air)
  anoms <- milt_detect_anomalies(am)
  # Bounds so wide nothing should be flagged
  expect_equal(anoms$n_anomalies(), 0L)
})

test_that("anomaly_model: an artificially injected spike is flagged as an anomaly", {
  vals <- as.numeric(AirPassengers)
  vals[[100L]] <- vals[[100L]] + 1000   # huge, obvious spike
  s <- milt_series(vals, frequency = "monthly", start = c(1949, 1))

  am    <- milt_anomaly_model(milt_model("naive"), detector = "quantile", quantile = 0.95) |>
    milt_fit(s)
  anoms <- milt_detect_anomalies(am)
  expect_true(anoms$is_anomaly()[[100L]])
})

test_that("anomaly_model: detect() errors before fit()", {
  am <- milt_anomaly_model(milt_model("naive"))
  expect_error(am$detect(), class = "milt_error_not_fitted")
})

test_that("milt_detect_anomalies: errors on non-MiltAnomalyModel", {
  expect_error(milt_detect_anomalies(milt_model("naive")), class = "milt_error_invalid_arg")
})

test_that("anomaly_model: model() accessor returns the fitted wrapped model", {
  am <- milt_anomaly_model(milt_model("naive")) |> milt_fit(air)
  expect_s3_class(am$model(), "MiltModel")
  expect_true(am$model()$is_fitted())
})

test_that("anomaly_model: works end-to-end with the ets backend", {
  skip_if_not_installed("forecast")
  am    <- milt_anomaly_model(milt_model("ets"), scorer = "nll_gaussian") |> milt_fit(air)
  anoms <- milt_detect_anomalies(am)
  expect_s3_class(anoms, "MiltAnomalies")
})
