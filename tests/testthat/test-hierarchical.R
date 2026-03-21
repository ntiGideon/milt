# Tests for milt_reconcile() / MiltReconciliation

# ── Shared fixture ────────────────────────────────────────────────────────────
#
# Two-level hierarchy:
#   Total = A + B
#
# S matrix (3 x 2):
#   Total  [1 1]
#   A      [1 0]
#   B      [0 1]

make_hier_forecasts <- function(h = 6L) {
  make_fc <- function(vals) {
    tbl <- tibble::tibble(
      .mean     = vals,
      .lower_80 = vals - 1,
      .upper_80 = vals + 1,
      .lower_95 = vals - 2,
      .upper_95 = vals + 2
    )
    s_air <- milt_series(AirPassengers)
    structure(
      list(
        as_tibble  = function() tbl,
        horizon    = function() h,
        has_samples = function() FALSE
      ),
      class = c("MiltForecast", "list")
    )
  }
  list(
    Total = make_fc(rep(10, h)),
    A     = make_fc(rep(6,  h)),
    B     = make_fc(rep(5,  h))    # intentionally incoherent (6+5 != 10)
  )
}

S_mat <- matrix(c(1, 1, 1, 0, 0, 1), nrow = 3L, ncol = 2L,
                dimnames = list(c("Total", "A", "B"), c("A", "B")))

# ── Input validation ──────────────────────────────────────────────────────────

test_that("reconcile: empty forecast list errors", {
  expect_error(milt_reconcile(list(), S_mat),
               class = "milt_error_invalid_arg")
})

test_that("reconcile: unnamed forecast list errors", {
  fcs <- make_hier_forecasts()
  names(fcs) <- NULL
  expect_error(milt_reconcile(fcs, S_mat),
               class = "milt_error_invalid_arg")
})

test_that("reconcile: non-MiltForecast element errors", {
  fcs <- make_hier_forecasts()
  fcs$Total <- "not_a_forecast"
  expect_error(milt_reconcile(fcs, S_mat),
               class = "milt_error_invalid_arg")
})

test_that("reconcile: non-numeric S matrix errors", {
  fcs <- make_hier_forecasts()
  expect_error(milt_reconcile(fcs, as.character(S_mat)),
               class = "milt_error_invalid_arg")
})

test_that("reconcile: S nrow mismatch errors", {
  fcs  <- make_hier_forecasts()
  S_bad <- S_mat[1:2, ]
  expect_error(milt_reconcile(fcs, S_bad),
               class = "milt_error_invalid_arg")
})

test_that("reconcile: mint_shrink without residuals errors", {
  fcs <- make_hier_forecasts()
  expect_error(milt_reconcile(fcs, S_mat, method = "mint_shrink"),
               class = "milt_error_invalid_arg")
})

# ── OLS ───────────────────────────────────────────────────────────────────────

test_that("reconcile: ols returns MiltReconciliation", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  expect_s3_class(rc, "MiltReconciliation")
})

test_that("reconcile: ols method() equals 'ols'", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  expect_equal(rc$method(), "ols")
})

test_that("reconcile: ols series_names() matches forecast names", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  expect_equal(rc$series_names(), c("Total", "A", "B"))
})

test_that("reconcile: ols forecasts() list has correct length", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  expect_length(rc$forecasts(), 3L)
})

test_that("reconcile: ols each reconciled forecast has length h", {
  h   <- 6L
  fcs <- make_hier_forecasts(h)
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  for (nm in rc$series_names()) {
    expect_length(rc$forecasts()[[nm]], h)
  }
})

test_that("reconcile: ols as_tibble() has columns series, h, .mean", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  tbl <- rc$as_tibble()
  expect_true(all(c("series", "h", ".mean") %in% names(tbl)))
})

test_that("reconcile: ols as_tibble() has 3 * h rows", {
  h   <- 6L
  fcs <- make_hier_forecasts(h)
  rc  <- milt_reconcile(fcs, S_mat, method = "ols")
  expect_equal(nrow(rc$as_tibble()), 3L * h)
})

# ── WLS struct ────────────────────────────────────────────────────────────────

test_that("reconcile: wls_struct returns MiltReconciliation", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat, method = "wls_struct")
  expect_s3_class(rc, "MiltReconciliation")
})

# ── MinT shrink ───────────────────────────────────────────────────────────────

test_that("reconcile: mint_shrink returns MiltReconciliation with residuals", {
  fcs <- make_hier_forecasts()
  res <- list(
    Total = rnorm(100),
    A     = rnorm(100),
    B     = rnorm(100)
  )
  rc <- milt_reconcile(fcs, S_mat, method = "mint_shrink", residuals = res)
  expect_s3_class(rc, "MiltReconciliation")
})

# ── print / summary ───────────────────────────────────────────────────────────

test_that("reconcile: print() mentions method and series", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat)
  expect_output(print(rc), "ols")
  expect_output(print(rc), "Total")
})

test_that("reconcile: as_tibble S3 dispatch works", {
  fcs <- make_hier_forecasts()
  rc  <- milt_reconcile(fcs, S_mat)
  tbl <- tibble::as_tibble(rc)
  expect_s3_class(tbl, "tbl_df")
})
