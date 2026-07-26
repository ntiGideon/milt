make_s_with_dates <- function() {
  milt_series(AirPassengers)
}

# ── milt_add_covariates ───────────────────────────────────────────────────────

test_that("milt_add_covariates returns the series invisibly", {
  s     <- make_s_with_dates()
  dates <- s$as_tibble()$time
  cov   <- data.frame(time = dates, x = seq_along(dates))
  expect_invisible(milt_add_covariates(s, cov, type = "past", time_col = "time"))
})

test_that("milt_add_covariates stores past covariates", {
  s     <- make_s_with_dates()
  dates <- s$as_tibble()$time
  cov   <- data.frame(time = dates, x = seq_along(dates))
  milt_add_covariates(s, cov, type = "past", time_col = "time")
  stored <- milt_get_covariates(s, "past")
  expect_s3_class(stored, "data.frame")
  expect_equal(nrow(stored), length(dates))
})

test_that("milt_add_covariates stores future covariates", {
  s     <- make_s_with_dates()
  dates <- s$as_tibble()$time
  cov   <- data.frame(time = dates, x = rnorm(length(dates)))
  milt_add_covariates(s, cov, type = "future", time_col = "time")
  stored <- milt_get_covariates(s, "future")
  expect_false(is.null(stored))
})

test_that("milt_add_covariates errors on invalid type", {
  s   <- make_s_with_dates()
  cov <- data.frame(time = Sys.Date(), x = 1)
  expect_error(
    milt_add_covariates(s, cov, type = "magic"),
    class = "milt_error_invalid_covariate_type"
  )
})

test_that("milt_add_covariates errors on non-data-frame covariates", {
  s <- make_s_with_dates()
  expect_error(
    milt_add_covariates(s, covariates = 99, type = "past"),
    class = "milt_error_invalid_covariates"
  )
})

test_that("milt_add_covariates (static) errors without group_col", {
  s   <- make_s_with_dates()  # not multi-series
  cov <- data.frame(store = "A", size = 100)
  expect_error(
    milt_add_covariates(s, cov, type = "static"),
    class = "milt_error_invalid_covariates"
  )
})

test_that("milt_add_covariates (static) works for multi-series", {
  tbl <- tibble::tibble(
    date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 6), 2),
    value = 1:12,
    store = rep(c("A", "B"), each = 6)
  )
  s   <- milt_series(tbl, time_col = "date", value_cols = "value",
                     group_col = "store")
  cov <- data.frame(store = c("A", "B"), region = c("North", "South"))
  expect_invisible(milt_add_covariates(s, cov, type = "static"))
  stored <- milt_get_covariates(s, "static")
  expect_equal(nrow(stored), 2L)
})

test_that("milt_add_covariates errors when time_col is absent from covariates", {
  s   <- make_s_with_dates()
  cov <- data.frame(wrong_col = Sys.Date(), x = 1)
  expect_error(
    milt_add_covariates(s, cov, type = "past", time_col = "time"),
    class = "milt_error_invalid_covariates"
  )
})

# ── milt_get_covariates ───────────────────────────────────────────────────────

test_that("milt_get_covariates returns NULL when none attached", {
  s <- make_s_with_dates()
  expect_null(milt_get_covariates(s, "past"))
  expect_null(milt_get_covariates(s, "future"))
  expect_null(milt_get_covariates(s, "static"))
})

test_that("milt_get_covariates errors on invalid type", {
  s <- make_s_with_dates()
  expect_error(
    milt_get_covariates(s, "unknown"),
    class = "milt_error_invalid_covariate_type"
  )
})

test_that("milt_get_covariates errors on non-MiltSeries", {
  expect_error(milt_get_covariates(list()), class = "milt_error_not_milt_series")
})

# ── Covariate propagation through clone_with() ────────────────────────────────

test_that("past covariates survive milt_window() (which uses clone_with)", {
  s     <- make_s_with_dates()
  dates <- s$as_tibble()$time
  cov   <- data.frame(time = dates, x = seq_along(dates))
  milt_add_covariates(s, cov, type = "past", time_col = "time")

  windowed <- milt_window(s, start = as.Date("1955-01-01"), end = as.Date("1956-12-01"))
  stored   <- milt_get_covariates(windowed, "past")
  expect_false(is.null(stored))
  expect_equal(nrow(stored), length(dates))   # full covariate tibble carried through
})

test_that("future covariates survive [ subsetting (which uses clone_with)", {
  s     <- make_s_with_dates()
  dates <- s$as_tibble()$time
  cov   <- data.frame(time = dates, x = rnorm(length(dates)))
  milt_add_covariates(s, cov, type = "future", time_col = "time")

  sub <- s[1:24]
  expect_false(is.null(milt_get_covariates(sub, "future")))
})

test_that("static covariates survive milt_step_lag() (which uses clone_with)", {
  tbl <- tibble::tibble(
    date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24),
    value = rnorm(24),
    store = "A"
  )
  s   <- milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")
  cov <- data.frame(store = "A", region = "North")
  milt_add_covariates(s, cov, type = "static")

  lagged <- milt_step_lag(s, lags = 1)
  expect_false(is.null(milt_get_covariates(lagged, "static")))
})

# ── Static covariates propagated per-group by MiltLocalModel ──────────────────

test_that("MiltLocalModel splits static covariates per group", {
  tbl <- tibble::tibble(
    date  = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 24), 2),
    value = c(cumsum(rnorm(24, 1)), cumsum(rnorm(24, 2))),
    store = rep(c("A", "B"), each = 24)
  )
  s   <- milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")
  cov <- data.frame(store = c("A", "B"), region = c("North", "South"))
  milt_add_covariates(s, cov, type = "static")

  lm <- milt_local_model(milt_model("naive"))
  milt_fit(lm, s)

  m_a <- lm$fitted_models()[["A"]]
  m_b <- lm$fitted_models()[["B"]]
  cov_a <- milt_get_covariates(m_a$.__enclos_env__$private$.training_series, "static")
  cov_b <- milt_get_covariates(m_b$.__enclos_env__$private$.training_series, "static")

  expect_equal(nrow(cov_a), 1L)
  expect_equal(cov_a$region, "North")
  expect_equal(cov_b$region, "South")
})
