skip_if_not_installed("torch")

air <- milt_series(AirPassengers)

# ── Registration ──────────────────────────────────────────────────────────────

test_that("patch_tst: model is registered", {
  expect_true(is_registered_model("patch_tst"))
})

# ── Fit ───────────────────────────────────────────────────────────────────────

.patch_tst_small <- function() {
  milt_model("patch_tst",
             input_chunk_length  = 12L,
             output_chunk_length = 6L,
             patch_len = 4L,
             d_model   = 16L,
             n_heads   = 2L,
             n_layers  = 1L,
             dropout   = 0.0,
             n_epochs  = 5L,
             patience  = 3L)
}

test_that("patch_tst: fit returns fitted MiltModel", {
  m <- .patch_tst_small() |> milt_fit(air)
  expect_s3_class(m, "MiltModel")
  expect_true(m$is_fitted())
})

test_that("patch_tst: errors on multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 60),
    a = rnorm(60), b = rnorm(60)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(
    milt_fit(milt_model("patch_tst"), s),
    class = "milt_error_not_univariate"
  )
})

test_that("patch_tst: errors on insufficient data", {
  tiny <- milt_series(1:10)
  expect_error(
    milt_model("patch_tst",
               input_chunk_length = 8L,
               output_chunk_length = 8L) |>
      milt_fit(tiny),
    class = "milt_error_insufficient_data"
  )
})

test_that("patch_tst: errors when patch_len > input_chunk_length", {
  expect_error(
    milt_model("patch_tst",
               input_chunk_length = 12L,
               patch_len = 16L) |>
      milt_fit(air),
    class = "milt_error_invalid_params"
  )
})

test_that("patch_tst: errors when not fitted", {
  expect_error(milt_forecast(milt_model("patch_tst"), 12),
               class = "milt_error_not_fitted")
})

# ── Forecast ──────────────────────────────────────────────────────────────────

test_that("patch_tst: forecast returns MiltForecast", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("patch_tst: horizon matches requested value", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(24)
  expect_equal(fct$horizon(), 24L)
})

test_that("patch_tst: point forecast has no NAs", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("patch_tst: point forecast is numeric", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  expect_type(fct$as_tibble()$.mean, "double")
})

test_that("patch_tst: lower_80 <= mean + 1e-8", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_80 <= tbl$.mean + 1e-8))
})

test_that("patch_tst: 95% interval at least as wide as 80%", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  tbl <- fct$as_tibble()
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80 + 1e-8))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95 + 1e-8))
})

test_that("patch_tst: non-divisible input_chunk_length padded correctly", {
  # input_chunk_length=13 is not divisible by patch_len=4 → padded to 16
  m <- milt_model("patch_tst",
                  input_chunk_length  = 13L,
                  output_chunk_length = 6L,
                  patch_len = 4L, d_model = 8L,
                  n_heads = 2L, n_layers = 1L,
                  n_epochs = 3L, patience = 2L)
  fct <- m |> milt_fit(air) |> milt_forecast(6)
  expect_equal(fct$horizon(), 6L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

test_that("patch_tst: recursive horizon longer than output_chunk_length", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(18)
  expect_equal(fct$horizon(), 18L)
  expect_false(any(is.na(fct$as_tibble()$.mean)))
})

# ── Residuals / Predict ───────────────────────────────────────────────────────

test_that("patch_tst: residuals have correct length", {
  m <- .patch_tst_small() |> milt_fit(air)
  expect_length(milt_residuals(m), 144L)
})

test_that("patch_tst: predict returns correct length", {
  m <- .patch_tst_small() |> milt_fit(air)
  expect_length(milt_predict(m), 144L)
})

# ── Params ────────────────────────────────────────────────────────────────────

test_that("patch_tst: params are stored correctly", {
  m <- milt_model("patch_tst", patch_len = 6L, d_model = 32L)
  p <- m$get_params()
  expect_equal(p$patch_len, 6L)
  expect_equal(p$d_model,   32L)
})

# ── Model name ────────────────────────────────────────────────────────────────

test_that("patch_tst: full pipe produces correct model name", {
  fct <- .patch_tst_small() |> milt_fit(air) |> milt_forecast(12)
  expect_equal(fct$model_name(), "patch_tst")
})
