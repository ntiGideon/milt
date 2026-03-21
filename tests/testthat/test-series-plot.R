test_that("plot.MiltSeries returns a ggplot invisibly", {
  skip_if_not_installed("ggplot2")
  s   <- milt_series(AirPassengers)
  plt <- plot(s)
  expect_s3_class(plt, "ggplot")
})

test_that("autoplot.MiltSeries returns the same ggplot as plot", {
  skip_if_not_installed("ggplot2")
  s <- milt_series(AirPassengers)
  expect_s3_class(autoplot(s), "ggplot")
})

test_that("plot.MiltSeries works for multivariate series", {
  skip_if_not_installed("ggplot2")
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a    = rnorm(24),
    b    = rnorm(24)
  )
  s   <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  plt <- plot(s)
  expect_s3_class(plt, "ggplot")
})

test_that("plot.MiltSeries works for multi-series (faceted)", {
  skip_if_not_installed("ggplot2")
  tbl <- tibble::tibble(
    date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 12), 2),
    value = rnorm(24),
    store = rep(c("A", "B"), each = 12)
  )
  s   <- milt_series(tbl, time_col = "date", value_cols = "value",
                     group_col = "store")
  plt <- plot(s)
  expect_s3_class(plt, "ggplot")
})

test_that("plot.MiltSeries custom title is used", {
  skip_if_not_installed("ggplot2")
  s   <- milt_series(AirPassengers)
  plt <- plot(s, title = "My Custom Title")
  expect_equal(plt$labels$title, "My Custom Title")
})

test_that("milt_plot_acf does not error for univariate", {
  s <- milt_series(AirPassengers)
  expect_invisible(milt_plot_acf(s))
})

test_that("milt_plot_acf errors for multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 12),
    a = rnorm(12), b = rnorm(12)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_plot_acf(s), class = "milt_error_not_univariate")
})

test_that("milt_plot_acf returns list with acf and pacf", {
  s   <- milt_series(AirPassengers)
  out <- milt_plot_acf(s)
  expect_named(out, c("acf", "pacf"))
})

test_that("milt_plot_decomp does not error for seasonal series", {
  s <- milt_series(AirPassengers)
  expect_invisible(milt_plot_decomp(s))
})

test_that("milt_plot_decomp errors for non-seasonal series", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "year", length.out = 10),
    value = rnorm(10)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value",
                   frequency = "annual")
  expect_error(milt_plot_decomp(s), class = "milt_error_invalid_frequency")
})

test_that("milt_plot_decomp errors for multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    a = rnorm(24), b = rnorm(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = c("a", "b"))
  expect_error(milt_plot_decomp(s), class = "milt_error_not_univariate")
})
