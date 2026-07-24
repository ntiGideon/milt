air <- milt_series(AirPassengers)

test_that("grid_search: errors on non-MiltSeries input", {
  expect_error(
    milt_grid_search("naive", list(x = 1), AirPassengers, horizon = 12),
    class = "milt_error_not_milt_series"
  )
})

test_that("grid_search: errors on non-string model_name", {
  expect_error(
    milt_grid_search(123, list(x = 1), air, horizon = 12),
    class = "milt_error_invalid_arg"
  )
})

test_that("grid_search: errors on empty param_grid", {
  expect_error(
    milt_grid_search("naive", list(), air, horizon = 12),
    class = "milt_error_invalid_arg"
  )
})

test_that("grid_search: errors on unnamed param_grid", {
  expect_error(
    milt_grid_search("naive", list(1, 2), air, horizon = 12),
    class = "milt_error_invalid_arg"
  )
})

test_that("grid_search: returns one row per combination, ordered best-first", {
  out <- milt_grid_search(
    "moving_average",
    param_grid = list(window = c(2L, 3L, 5L)),
    series = air, horizon = 6,
    initial_window = 120L, stride = 6L
  )
  expect_equal(nrow(out), 3L)
  expect_true("window" %in% names(out))
  expect_true("MAE" %in% names(out))
  expect_true(all(diff(out$MAE) >= 0))
})

test_that("grid_search: supports multiple parameters (full Cartesian product)", {
  out <- milt_grid_search(
    "moving_average",
    param_grid = list(window = c(2L, 3L)),
    series = air, horizon = 6, metric = "RMSE",
    initial_window = 120L, stride = 6L
  )
  expect_equal(nrow(out), 2L)
})
