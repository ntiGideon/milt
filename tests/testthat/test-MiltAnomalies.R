# ── Shared fixture ────────────────────────────────────────────────────────────

air  <- milt_series(AirPassengers)
vals <- air$values()
n    <- air$n_timesteps()

# Build a minimal MiltAnomalies directly for unit testing of the class itself
make_anoms <- function(n_anom = 3L) {
  is_anom <- rep(FALSE, n)
  is_anom[c(1L, 50L, 100L)] <- TRUE
  scores  <- seq(0, 1, length.out = n)
  .new_milt_anomalies(
    series        = air,
    is_anomaly    = is_anom,
    anomaly_score = scores,
    method        = "test_method"
  )
}

# ── Class structure ────────────────────────────────────────────────────────────

test_that("MiltAnomalies: .new_milt_anomalies returns correct classes", {
  a <- make_anoms()
  expect_s3_class(a, "MiltAnomalies")
  expect_true(inherits(a, "R6"))
})

test_that("MiltAnomalies: series() returns the original MiltSeries", {
  a <- make_anoms()
  expect_s3_class(a$series(), "MiltSeries")
  expect_equal(a$series()$n_timesteps(), n)
})

test_that("MiltAnomalies: is_anomaly() returns logical vector of correct length", {
  a <- make_anoms()
  v <- a$is_anomaly()
  expect_type(v, "logical")
  expect_length(v, n)
})

test_that("MiltAnomalies: anomaly_score() returns numeric vector of correct length", {
  a <- make_anoms()
  s <- a$anomaly_score()
  expect_type(s, "double")
  expect_length(s, n)
})

test_that("MiltAnomalies: method() returns character string", {
  a <- make_anoms()
  expect_type(a$method(), "character")
  expect_equal(a$method(), "test_method")
})

test_that("MiltAnomalies: n_anomalies() returns correct count", {
  a <- make_anoms(3L)
  expect_equal(a$n_anomalies(), 3L)
})

test_that("MiltAnomalies: n_anomalies() is 0 for no anomalies", {
  is_anom <- rep(FALSE, n)
  a <- .new_milt_anomalies(air, is_anom, rep(0, n), "none")
  expect_equal(a$n_anomalies(), 0L)
})

# ── as_tibble ─────────────────────────────────────────────────────────────────

test_that("MiltAnomalies: as_tibble() returns tibble with correct columns", {
  a   <- make_anoms()
  tbl <- a$as_tibble()
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("time", "value", ".is_anomaly", ".anomaly_score") %in%
                    names(tbl)))
})

test_that("MiltAnomalies: as_tibble() has correct row count", {
  a   <- make_anoms()
  tbl <- a$as_tibble()
  expect_equal(nrow(tbl), n)
})

test_that("MiltAnomalies: as_tibble S3 dispatch works", {
  a   <- make_anoms()
  tbl <- tibble::as_tibble(a)
  expect_s3_class(tbl, "tbl_df")
  expect_equal(nrow(tbl), n)
})

test_that("MiltAnomalies: as_tibble().is_anomaly matches is_anomaly()", {
  a   <- make_anoms()
  tbl <- a$as_tibble()
  expect_equal(tbl$.is_anomaly, a$is_anomaly())
})

# ── print / summary ───────────────────────────────────────────────────────────

test_that("MiltAnomalies: print() runs without error", {
  a <- make_anoms()
  expect_output(print(a), "MiltAnomalies")
})

test_that("MiltAnomalies: print() shows anomaly count", {
  a <- make_anoms()
  expect_output(print(a), "3")
})

test_that("MiltAnomalies: summary() is identical to print()", {
  a   <- make_anoms()
  out_print   <- capture.output(print(a))
  out_summary <- capture.output(summary(a))
  expect_equal(out_print, out_summary)
})

# ── plot ──────────────────────────────────────────────────────────────────────

test_that("MiltAnomalies: plot() returns a ggplot object", {
  a <- make_anoms()
  p <- plot(a)
  expect_s3_class(p, "gg")
})

test_that("MiltAnomalies: plot() title mentions method", {
  a <- make_anoms()
  p <- plot(a)
  expect_true(grepl("test_method", p$labels$title))
})

test_that("MiltAnomalies: autoplot() returns same structure as plot()", {
  a  <- make_anoms()
  p1 <- plot(a)
  p2 <- ggplot2::autoplot(a)
  expect_s3_class(p2, "gg")
  expect_equal(p1$labels$title, p2$labels$title)
})
