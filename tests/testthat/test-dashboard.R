test_that("milt_dashboard() rejects unfitted models", {
  skip_if_not_installed("shiny")

  model <- milt_model("naive")

  expect_error(
    milt_dashboard(model, launch_browser = FALSE),
    class = "milt_error_not_fitted"
  )
})

test_that("milt_dashboard() rejects non-model input", {
  skip_if_not_installed("shiny")

  expect_error(
    milt_dashboard("not-a-model", launch_browser = FALSE),
    class = "milt_error_invalid_arg"
  )
})
