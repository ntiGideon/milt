make_s <- function(n = 36) milt_series(AirPassengers)[seq_len(n)]

# ── milt_split ────────────────────────────────────────────────────────────────

test_that("milt_split returns a list with train and test", {
  s   <- make_s(36)
  out <- milt_split(s, ratio = 0.8)
  expect_named(out, c("train", "test"))
  expect_s3_class(out$train, "MiltSeries")
  expect_s3_class(out$test,  "MiltSeries")
})

test_that("milt_split train + test covers all observations", {
  s   <- make_s(36)
  out <- milt_split(s)
  expect_equal(out$train$n_timesteps() + out$test$n_timesteps(), 36L)
})

test_that("milt_split respects the ratio", {
  s   <- make_s(100)
  out <- milt_split(s, ratio = 0.75)
  expect_equal(out$train$n_timesteps(), 75L)
  expect_equal(out$test$n_timesteps(),  25L)
})

test_that("milt_split errors on non-MiltSeries input", {
  expect_error(milt_split(42), class = "milt_error_not_milt_series")
})

test_that("milt_split errors on invalid ratio", {
  s <- make_s()
  expect_error(milt_split(s, 0),   class = "milt_error_invalid_proportion")
  expect_error(milt_split(s, 1),   class = "milt_error_invalid_proportion")
  expect_error(milt_split(s, 1.1), class = "milt_error_invalid_proportion")
})

test_that("milt_split train end time < test start time (no leakage)", {
  s   <- make_s(24)
  out <- milt_split(s)
  expect_true(out$train$end_time() < out$test$start_time())
})

# ── milt_split_at ─────────────────────────────────────────────────────────────

test_that("milt_split_at splits at the correct point", {
  s      <- milt_series(AirPassengers)
  cutoff <- as.Date("1955-01-01")
  out    <- milt_split_at(s, cutoff)
  expect_true(out$train$end_time() < cutoff)
  expect_true(out$test$start_time() >= cutoff)
})

test_that("milt_split_at train + test covers full series", {
  s   <- milt_series(AirPassengers)
  out <- milt_split_at(s, as.Date("1955-01-01"))
  expect_equal(
    out$train$n_timesteps() + out$test$n_timesteps(),
    s$n_timesteps()
  )
})

test_that("milt_split_at errors on non-scalar time", {
  s <- make_s()
  expect_error(
    milt_split_at(s, as.Date(c("2020-01-01", "2021-01-01"))),
    class = "milt_error_invalid_time"
  )
})

# ── milt_window ───────────────────────────────────────────────────────────────

test_that("milt_window subsets correctly with both bounds", {
  s  <- milt_series(AirPassengers)
  w  <- milt_window(s, start = as.Date("1952-01-01"),
                       end   = as.Date("1954-12-01"))
  expect_true(w$start_time() >= as.Date("1952-01-01"))
  expect_true(w$end_time()   <= as.Date("1954-12-01"))
})

test_that("milt_window with only start bound works", {
  s <- milt_series(AirPassengers)
  w <- milt_window(s, start = as.Date("1958-01-01"))
  expect_equal(w$start_time(), as.Date("1958-01-01"))
  expect_equal(w$end_time(),   s$end_time())
})

test_that("milt_window with only end bound works", {
  s <- milt_series(AirPassengers)
  w <- milt_window(s, end = as.Date("1951-12-01"))
  expect_equal(w$start_time(), s$start_time())
  expect_equal(w$end_time(),   as.Date("1951-12-01"))
})

test_that("milt_window errors when window contains no data", {
  s <- milt_series(AirPassengers)
  expect_error(
    milt_window(s, start = as.Date("2099-01-01")),
    class = "milt_error_empty_window"
  )
})

test_that("milt_window filters by group for grouped series", {
  tbl <- tibble::tibble(
    store = rep(c("A", "B"), each = 12),
    date = rep(seq(as.Date("2020-01-01"), by = "month", length.out = 12), 2),
    value = seq_len(24)
  )
  s <- milt_series(tbl, time_col = "date", value_cols = "value", group_col = "store")
  w <- milt_window(s, group = "A")
  expect_true(all(w$as_tibble()$store == "A"))
})

# ── milt_resample ─────────────────────────────────────────────────────────────

test_that("milt_resample to annual reduces row count", {
  s <- milt_series(AirPassengers)   # 144 monthly obs = 12 years
  r <- milt_resample(s, "annual", sum)
  expect_equal(r$n_timesteps(), 12L)
  expect_equal(r$freq(), "annual")
})

test_that("milt_resample sum preserves total for non-overlapping groups", {
  s    <- milt_series(AirPassengers)
  orig <- sum(s$values())
  r    <- milt_resample(s, "annual", sum)
  expect_equal(sum(r$values()), orig, tolerance = 1e-6)
})

test_that("milt_resample errors on invalid period", {
  s <- milt_series(AirPassengers)
  expect_error(milt_resample(s, "decadely"), class = "milt_error_unknown_period")
})

test_that("milt_resample errors when agg_fn is not a function", {
  s <- milt_series(AirPassengers)
  expect_error(milt_resample(s, "annual", "sum"), class = "milt_error_invalid_arg")
})

# ── milt_head / milt_tail ─────────────────────────────────────────────────────

test_that("milt_head returns first n observations", {
  s <- milt_series(AirPassengers)
  h <- milt_head(s, 10)
  expect_equal(h$n_timesteps(), 10L)
  expect_equal(h$start_time(), s$start_time())
})

test_that("milt_tail returns last n observations", {
  s <- milt_series(AirPassengers)
  t <- milt_tail(s, 10)
  expect_equal(t$n_timesteps(), 10L)
  expect_equal(t$end_time(), s$end_time())
})

test_that("milt_head errors on non-positive n", {
  s <- milt_series(AirPassengers)
  expect_error(milt_head(s, 0), class = "milt_error_invalid_integer")
})

# ── milt_concat ───────────────────────────────────────────────────────────────

test_that("milt_concat reconstructs original from split parts", {
  s      <- milt_series(AirPassengers)
  splits <- milt_split(s)
  s_back <- milt_concat(splits$train, splits$test)
  expect_equal(s_back$n_timesteps(), s$n_timesteps())
  expect_equal(s_back$values(),      s$values())
})

test_that("milt_concat errors with fewer than 2 series", {
  s <- milt_series(AirPassengers)
  expect_error(milt_concat(s), class = "milt_error_invalid_arg")
})

test_that("milt_concat errors on incompatible value columns", {
  tbl1 <- tibble::tibble(
    date = seq(as.Date("2020-01-01"), by = "month", length.out = 6),
    a    = 1:6
  )
  tbl2 <- tibble::tibble(
    date = seq(as.Date("2020-07-01"), by = "month", length.out = 6),
    b    = 7:12
  )
  s1 <- milt_series(tbl1, time_col = "date", value_cols = "a")
  s2 <- milt_series(tbl2, time_col = "date", value_cols = "b")
  expect_error(milt_concat(s1, s2), class = "milt_error_incompatible_series")
})

test_that("milt_concat deduplicates overlapping time points", {
  s  <- milt_series(AirPassengers)
  s_back <- milt_concat(s, s)
  expect_equal(s_back$n_timesteps(), s$n_timesteps())
})
