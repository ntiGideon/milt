test_that("milt_pipeline() creates an empty MiltPipeline", {
  pipe <- milt_pipeline()
  expect_s3_class(pipe, "MiltPipeline")
  expect_equal(pipe$n_steps(), 0L)
  expect_false(pipe$is_fitted())
  expect_null(pipe$get_model())
})

test_that("milt_pipe_step_lag() adds a lag step", {
  pipe <- milt_pipeline() |> milt_pipe_step_lag(lags = 1:3)
  expect_equal(pipe$n_steps(), 1L)
  steps <- pipe$get_steps()
  expect_equal(steps[[1L]]$type, "lag")
  expect_equal(steps[[1L]]$params$lags, 1:3)
})

test_that("milt_pipe_step_rolling() adds a rolling step", {
  pipe <- milt_pipeline() |> milt_pipe_step_rolling(windows = c(3L, 7L))
  expect_equal(pipe$n_steps(), 1L)
  expect_equal(pipe$get_steps()[[1L]]$type, "rolling")
})

test_that("milt_pipe_step_fourier() adds a fourier step", {
  pipe <- milt_pipeline() |> milt_pipe_step_fourier(period = 12, K = 2L)
  steps <- pipe$get_steps()
  expect_equal(steps[[1L]]$type, "fourier")
  expect_equal(steps[[1L]]$params$K, 2L)
})

test_that("milt_pipe_step_calendar() adds a calendar step", {
  pipe <- milt_pipeline() |> milt_pipe_step_calendar()
  expect_equal(pipe$get_steps()[[1L]]$type, "calendar")
})

test_that("milt_pipe_step_scale() adds a scale step and rejects bad methods", {
  pipe <- milt_pipeline() |> milt_pipe_step_scale("zscore")
  expect_equal(pipe$get_steps()[[1L]]$type, "scale")

  expect_error(
    milt_pipeline() |> milt_pipe_step_scale("bad_method"),
    class = "milt_error_invalid_arg"
  )
})

test_that("milt_pipe_model() attaches a MiltModel", {
  skip_if_not_installed("forecast")
  pipe  <- milt_pipeline() |> milt_pipe_model("naive")
  model <- pipe$get_model()
  expect_s3_class(model, "MiltModel")
})

test_that("milt_pipe_model() accepts a string and creates the model", {
  pipe <- milt_pipeline() |> milt_pipe_model("naive")
  expect_false(pipe$get_model()$is_fitted())
})

test_that("multiple steps chain correctly", {
  pipe <- milt_pipeline() |>
    milt_pipe_step_lag(lags = 1:3) |>
    milt_pipe_step_scale("zscore") |>
    milt_pipe_model("naive")
  expect_equal(pipe$n_steps(), 2L)
  expect_false(is.null(pipe$get_model()))
})

test_that("milt_pipeline_fit() requires a model", {
  s    <- milt_series(AirPassengers)
  pipe <- milt_pipeline() |> milt_pipe_step_lag(lags = 1:3)
  expect_error(milt_pipeline_fit(pipe, s), class = "milt_error_no_model")
})

test_that("milt_pipeline_fit() fits the pipeline end-to-end", {
  skip_if_not_installed("forecast")
  s    <- milt_series(AirPassengers)
  pipe <- milt_pipeline() |>
    milt_pipe_model("naive") |>
    milt_pipeline_fit(s)
  expect_true(pipe$is_fitted())
  expect_true(pipe$get_model()$is_fitted())
})

test_that("milt_pipeline_forecast() returns a MiltForecast", {
  skip_if_not_installed("forecast")
  s    <- milt_series(AirPassengers)
  pipe <- milt_pipeline() |>
    milt_pipe_model("naive") |>
    milt_pipeline_fit(s)
  fct <- milt_pipeline_forecast(pipe, horizon = 6L)
  expect_s3_class(fct, "MiltForecast")
})

test_that("milt_pipeline_forecast() errors on unfitted pipeline", {
  pipe <- milt_pipeline() |> milt_pipe_model("naive")
  expect_error(
    milt_pipeline_forecast(pipe, horizon = 6L),
    class = "milt_error_not_fitted"
  )
})

test_that("print.MiltPipeline() does not error", {
  pipe <- milt_pipeline() |>
    milt_pipe_step_lag(lags = 1:3) |>
    milt_pipe_model("naive")
  expect_output(print(pipe), "MiltPipeline")
})

test_that("milt_pipeline_fit() with lag step transforms series correctly", {
  skip_if_not_installed("forecast")
  s <- milt_series(AirPassengers)
  pipe <- milt_pipeline() |>
    milt_pipe_step_lag(lags = 1:3) |>
    milt_pipe_model("naive") |>
    milt_pipeline_fit(s)
  expect_true(pipe$is_fitted())
})

test_that("milt_pipeline_transform() applies fitted steps to new data", {
  skip_if_not_installed("forecast")
  s   <- milt_series(AirPassengers)
  spl <- milt_split(s, 0.8)
  pipe <- milt_pipeline() |>
    milt_pipe_step_scale("zscore") |>
    milt_pipe_model("naive") |>
    milt_pipeline_fit(spl$train)
  transformed <- milt_pipeline_transform(pipe, spl$test)
  expect_s3_class(transformed, "MiltSeries")
})
