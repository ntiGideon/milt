# ── Helpers ───────────────────────────────────────────────────────────────────

make_forecast <- function(horizon     = 12,
                           with_intervals = TRUE,
                           with_samples   = FALSE,
                           n_samples      = 50L) {
  times <- seq(as.Date("2020-01-01"), by = "month", length.out = horizon)
  pt    <- tibble::tibble(time = times, value = seq(100, by = 2, length.out = horizon))

  if (with_intervals) {
    make_bound <- function(offset) {
      stats::setNames(
        lapply(c(80, 95), function(l) {
          tibble::tibble(time = times, value = pt$value + offset * (l / 10))
        }),
        c("80", "95")
      )
    }
    lower <- make_bound(-1)
    upper <- make_bound( 1)
  } else {
    lower <- list()
    upper <- list()
  }

  samples <- if (with_samples) {
    matrix(rnorm(horizon * n_samples, 100), nrow = horizon, ncol = n_samples)
  } else NULL

  MiltForecastR6$new(
    point_forecast = pt,
    lower          = lower,
    upper          = upper,
    samples        = samples,
    model_name     = "test_model",
    horizon        = horizon,
    training_end   = as.Date("2019-12-01")
  )
}

# ── Construction ──────────────────────────────────────────────────────────────

test_that("MiltForecastR6$new() creates a MiltForecast", {
  fct <- make_forecast()
  expect_s3_class(fct, "MiltForecast")
})

test_that("horizon() returns the requested horizon", {
  fct <- make_forecast(horizon = 24)
  expect_equal(fct$horizon(), 24L)
})

test_that("model_name() returns the model name", {
  fct <- make_forecast()
  expect_equal(fct$model_name(), "test_model")
})

test_that("has_intervals() is TRUE when lower/upper supplied", {
  fct <- make_forecast(with_intervals = TRUE)
  expect_true(fct$has_intervals())
})

test_that("has_intervals() is FALSE when no intervals", {
  fct <- make_forecast(with_intervals = FALSE)
  expect_false(fct$has_intervals())
})

test_that("has_samples() is FALSE by default", {
  fct <- make_forecast()
  expect_false(fct$has_samples())
})

test_that("has_samples() is TRUE when samples supplied", {
  fct <- make_forecast(with_samples = TRUE, n_samples = 100L)
  expect_true(fct$has_samples())
})

test_that("levels() returns numeric confidence levels", {
  fct <- make_forecast()
  lvls <- fct$levels()
  expect_type(lvls, "double")
  expect_setequal(lvls, c(80, 95))
})

test_that("point_forecast() returns a tibble", {
  fct <- make_forecast()
  expect_s3_class(fct$point_forecast(), "tbl_df")
})

test_that("point_forecast() has correct number of rows", {
  fct <- make_forecast(horizon = 18)
  expect_equal(nrow(fct$point_forecast()), 18L)
})

# ── Validation errors ─────────────────────────────────────────────────────────

test_that("MiltForecastR6$new() errors when point_forecast rows != horizon", {
  times <- seq(as.Date("2020-01-01"), by = "month", length.out = 5)
  pt    <- tibble::tibble(time = times, value = 1:5)
  expect_error(
    MiltForecastR6$new(pt, horizon = 10),
    class = "milt_error_invalid_forecast"
  )
})

test_that("MiltForecastR6$new() errors when samples rows != horizon", {
  times <- seq(as.Date("2020-01-01"), by = "month", length.out = 6)
  pt    <- tibble::tibble(time = times, value = 1:6)
  bad   <- matrix(rnorm(3 * 10), nrow = 3, ncol = 10)   # 3 rows, not 6
  expect_error(
    MiltForecastR6$new(pt, samples = bad, horizon = 6),
    class = "milt_error_invalid_forecast"
  )
})

# ── as_tibble ─────────────────────────────────────────────────────────────────

test_that("as_tibble.MiltForecast returns a tibble", {
  fct <- make_forecast()
  tbl <- tibble::as_tibble(fct)
  expect_s3_class(tbl, "tbl_df")
})

test_that("as_tibble.MiltForecast has correct rows", {
  fct <- make_forecast(horizon = 10)
  expect_equal(nrow(tibble::as_tibble(fct)), 10L)
})

test_that("as_tibble.MiltForecast has .model and .mean columns", {
  fct <- make_forecast()
  tbl <- tibble::as_tibble(fct)
  expect_true(".model" %in% names(tbl))
  expect_true(".mean"  %in% names(tbl))
})

test_that("as_tibble.MiltForecast includes interval columns", {
  fct <- make_forecast()
  tbl <- tibble::as_tibble(fct)
  expect_true(".lower_80" %in% names(tbl))
  expect_true(".upper_80" %in% names(tbl))
  expect_true(".lower_95" %in% names(tbl))
  expect_true(".upper_95" %in% names(tbl))
})

test_that("as_tibble.MiltForecast: lower < mean < upper", {
  fct <- make_forecast()
  tbl <- tibble::as_tibble(fct)
  expect_true(all(tbl$.lower_80 <= tbl$.mean))
  expect_true(all(tbl$.mean     <= tbl$.upper_80))
  expect_true(all(tbl$.lower_95 <= tbl$.lower_80))
  expect_true(all(tbl$.upper_80 <= tbl$.upper_95))
})

test_that("as.data.frame.MiltForecast returns a data.frame", {
  fct <- make_forecast()
  expect_s3_class(as.data.frame(fct), "data.frame")
})

# ── print / summary ───────────────────────────────────────────────────────────

test_that("print.MiltForecast outputs model name", {
  fct <- make_forecast()
  expect_output(print(fct), "test_model")
})

test_that("print.MiltForecast outputs horizon", {
  fct <- make_forecast(horizon = 6)
  expect_output(print(fct), "6")
})

test_that("print.MiltForecast outputs confidence levels", {
  fct <- make_forecast()
  expect_output(print(fct), "80")
  expect_output(print(fct), "95")
})

test_that("summary.MiltForecast does not error", {
  fct <- make_forecast()
  expect_output(summary(fct), "MiltForecast")
})

# ── plot ──────────────────────────────────────────────────────────────────────

test_that("plot.MiltForecast returns a ggplot", {
  skip_if_not_installed("ggplot2")
  fct <- make_forecast()
  plt <- plot(fct)
  expect_s3_class(plt, "ggplot")
})

test_that("plot.MiltForecast works without intervals", {
  skip_if_not_installed("ggplot2")
  fct <- make_forecast(with_intervals = FALSE)
  expect_s3_class(plot(fct), "ggplot")
})

test_that("plot.MiltForecast includes history when training_series is provided", {
  skip_if_not_installed("ggplot2")
  s   <- milt_series(AirPassengers)
  fct <- milt_model("naive") |> milt_fit(s) |> milt_forecast(horizon = 12)
  plt <- plot(fct)
  # When training series is attached there should be 2+ layers (history + forecast)
  expect_true(length(plt$layers) >= 2L)
})

# ── Integration: milt_accuracy with MiltForecast output ──────────────────────

test_that("milt_accuracy works with as_tibble output", {
  fct    <- make_forecast(horizon = 12)
  tbl    <- tibble::as_tibble(fct)
  actual <- tbl$.mean + rnorm(12, 0, 1)
  acc    <- milt_accuracy(actual, tbl$.mean)
  expect_s3_class(acc, "tbl_df")
  expect_true("MAE" %in% acc$metric)
})
