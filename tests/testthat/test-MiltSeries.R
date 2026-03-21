# Tests for the MiltSeriesR6 class (R/MiltSeries.R)

# ── Construction ──────────────────────────────────────────────────────────────

make_monthly_tbl <- function(n = 24) {
  tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = n),
    value = as.numeric(seq_len(n))
  )
}

make_series <- function(n = 24) {
  MiltSeriesR6$new(
    data       = make_monthly_tbl(n),
    time_col   = "date",
    value_cols = "value",
    frequency  = "monthly"
  )
}

test_that("MiltSeriesR6$new() creates a MiltSeries object", {
  s <- make_series()
  expect_s3_class(s, "MiltSeries")
})

test_that("initialize errors when time_col is missing from data", {
  tbl <- make_monthly_tbl()
  expect_error(
    MiltSeriesR6$new(tbl, time_col = "wrong", value_cols = "value"),
    class = "milt_error_invalid_series"
  )
})

test_that("initialize errors when value_cols are missing from data", {
  tbl <- make_monthly_tbl()
  expect_error(
    MiltSeriesR6$new(tbl, time_col = "date", value_cols = "nope"),
    class = "milt_error_invalid_series"
  )
})

test_that("initialize errors when group_col is missing from data", {
  tbl <- make_monthly_tbl()
  expect_error(
    MiltSeriesR6$new(tbl, time_col = "date", value_cols = "value",
                     group_col = "store"),
    class = "milt_error_invalid_series"
  )
})

# ── Dimension accessors ───────────────────────────────────────────────────────

test_that("n_timesteps() returns correct count", {
  s <- make_series(24)
  expect_equal(s$n_timesteps(), 24L)
})

test_that("n_components() returns 1 for univariate", {
  s <- make_series()
  expect_equal(s$n_components(), 1L)
})

test_that("n_components() returns > 1 for multivariate", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 12),
    a    = 1:12,
    b    = 13:24
  )
  s <- MiltSeriesR6$new(tbl, "date", c("a", "b"), frequency = "monthly")
  expect_equal(s$n_components(), 2L)
})

test_that("n_series() returns 1 for single series", {
  expect_equal(make_series()$n_series(), 1L)
})

test_that("n_series() returns group count for multi-series", {
  tbl <- tibble::tibble(
    date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 6), 2),
    value = 1:12,
    store = rep(c("A", "B"), each = 6)
  )
  s <- MiltSeriesR6$new(tbl, "date", "value", group_col = "store",
                         frequency = "monthly")
  expect_equal(s$n_series(), 2L)
})

test_that("start_time() and end_time() are correct", {
  s <- make_series(12)
  expect_equal(s$start_time(), as.Date("2020-01-01"))
  expect_equal(s$end_time(),   as.Date("2020-12-01"))
})

test_that("freq() returns the supplied frequency label", {
  s <- make_series()
  expect_equal(s$freq(), "monthly")
})

# ── Type predicates ───────────────────────────────────────────────────────────

test_that("is_univariate() / is_multivariate() are mutually exclusive", {
  s_uni  <- make_series()
  tbl    <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 12),
    a = 1:12, b = 1:12
  )
  s_multi <- MiltSeriesR6$new(tbl, "date", c("a", "b"), frequency = "monthly")
  expect_true(s_uni$is_univariate())
  expect_false(s_uni$is_multivariate())
  expect_false(s_multi$is_univariate())
  expect_true(s_multi$is_multivariate())
})

test_that("is_multi_series() reflects presence of group_col", {
  s <- make_series()
  expect_false(s$is_multi_series())
})

# ── Gap detection ─────────────────────────────────────────────────────────────

test_that("has_gaps() returns FALSE for complete series", {
  expect_false(make_series()$has_gaps())
})

test_that("has_gaps() returns TRUE when a month is missing", {
  tbl <- make_monthly_tbl(24)
  tbl_gap <- tbl[-10, ]  # remove January 2020's 10th month
  s <- MiltSeriesR6$new(tbl_gap, "date", "value", frequency = "monthly")
  expect_true(s$has_gaps())
})

test_that("gaps() returns an empty tibble when no gaps exist", {
  g <- make_series()$gaps()
  expect_s3_class(g, "tbl_df")
  expect_equal(nrow(g), 0L)
  expect_true(all(c("gap_start", "gap_end") %in% names(g)))
})

test_that("gaps() identifies the correct gap location", {
  tbl     <- make_monthly_tbl(12)
  tbl_gap <- tbl[-5, ]   # remove May 2020
  s <- MiltSeriesR6$new(tbl_gap, "date", "value", frequency = "monthly")
  g <- s$gaps()
  expect_equal(nrow(g), 1L)
  expect_equal(g$gap_start, as.Date("2020-04-01"))
  expect_equal(g$gap_end,   as.Date("2020-06-01"))
})

# ── Data extraction ───────────────────────────────────────────────────────────

test_that("values() returns a numeric vector for univariate", {
  s <- make_series(12)
  expect_type(s$values(), "double")
  expect_length(s$values(), 12L)
})

test_that("values() returns a matrix for multivariate", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 6),
    a = 1:6, b = 7:12
  )
  s <- MiltSeriesR6$new(tbl, "date", c("a", "b"), frequency = "monthly")
  v <- s$values()
  expect_true(is.matrix(v))
  expect_equal(dim(v), c(6L, 2L))
})

test_that("times() returns the time column vector", {
  s     <- make_series(6)
  times <- s$times()
  expect_length(times, 6L)
  expect_equal(times[1L], as.Date("2020-01-01"))
})

test_that("as_tibble() returns a tibble", {
  s <- make_series()
  expect_s3_class(s$as_tibble(), "tbl_df")
})

test_that("as_ts() works for univariate series", {
  s  <- make_series(12)
  ts_obj <- s$as_ts()
  expect_s3_class(ts_obj, "ts")
  expect_length(ts_obj, 12L)
})

test_that("as_ts() errors for multivariate series", {
  tbl <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 6),
    a = 1:6, b = 7:12
  )
  s <- MiltSeriesR6$new(tbl, "date", c("a", "b"), frequency = "monthly")
  expect_error(s$as_ts(), class = "milt_error_not_univariate")
})

test_that("as_tsibble() returns a tsibble", {
  skip_if_not_installed("tsibble")
  s <- make_series(12)
  expect_s3_class(s$as_tsibble(), "tbl_ts")
})

test_that("clone_with() returns a new MiltSeries with different data", {
  s    <- make_series(12)
  tbl2 <- make_monthly_tbl(6)
  s2   <- s$clone_with(tbl2)
  expect_s3_class(s2, "MiltSeries")
  expect_equal(s2$n_timesteps(), 6L)
  expect_equal(s$n_timesteps(),  12L)  # original unchanged
})

# ── S3 methods ────────────────────────────────────────────────────────────────

test_that("print.MiltSeries does not error", {
  s <- make_series()
  expect_output(print(s), "MiltSeries")
})

test_that("print.MiltSeries shows frequency", {
  s <- make_series()
  expect_output(print(s), "monthly")
})

test_that("summary.MiltSeries does not error", {
  s <- make_series()
  expect_output(summary(s), "MiltSeries")
})

test_that("length.MiltSeries returns n_timesteps", {
  s <- make_series(20)
  expect_equal(length(s), 20L)
})

test_that("dim.MiltSeries returns c(n_timesteps, n_components)", {
  s <- make_series(20)
  expect_equal(dim(s), c(20L, 1L))
})

test_that("[.MiltSeries integer subset returns correct rows", {
  s  <- make_series(12)
  s2 <- s[1:6]
  expect_s3_class(s2, "MiltSeries")
  expect_equal(s2$n_timesteps(), 6L)
})

test_that("[.MiltSeries logical subset works", {
  s    <- make_series(12)
  mask <- rep(c(TRUE, FALSE), 6)
  s2   <- s[mask]
  expect_equal(s2$n_timesteps(), 6L)
})

test_that("[.MiltSeries date-range subset works", {
  s    <- make_series(12)
  rng  <- as.Date(c("2020-03-01", "2020-06-01"))
  s2   <- s[rng]
  expect_equal(s2$n_timesteps(), 4L)
})

test_that("head.MiltSeries returns first n rows", {
  s <- make_series(12)
  expect_equal(head(s, 3)$n_timesteps(), 3L)
})

test_that("tail.MiltSeries returns last n rows", {
  s   <- make_series(12)
  s_t <- tail(s, 4)
  expect_equal(s_t$n_timesteps(), 4L)
  expect_equal(s_t$start_time(), as.Date("2020-09-01"))
})

test_that("as.data.frame.MiltSeries returns a data.frame", {
  s <- make_series()
  expect_s3_class(as.data.frame(s), "data.frame")
})

test_that("as_tibble.MiltSeries returns a tibble", {
  s <- make_series()
  expect_s3_class(tibble::as_tibble(s), "tbl_df")
})

test_that("plot.MiltSeries returns a ggplot invisibly", {
  skip_if_not_installed("ggplot2")
  s   <- make_series()
  plt <- plot(s)
  expect_s3_class(plt, "ggplot")
})
