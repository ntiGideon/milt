# Tests for milt_classifier() / milt_classify_fit() / milt_classify_predict()

make_labelled_series <- function(n_per_class = 10L) {
  make_one <- function(pattern) {
    t_idx <- seq(0, 4 * pi, length.out = 24L)
    vals  <- switch(pattern,
      "sine"     = sin(t_idx) * 5 + 20,
      "trend"    = seq(10, 30, length.out = 24L) + rnorm(24L),
      "constant" = rep(15, 24L) + rnorm(24L, sd = 0.5)
    )
    tbl <- tibble::tibble(
      date  = seq(as.Date("2020-01-01"), by = "month", length.out = 24L),
      value = vals
    )
    milt_series(tbl, time_col = "date", value_cols = "value")
  }

  patterns <- rep(c("sine", "trend", "constant"), each = n_per_class)
  list(
    series = lapply(patterns, make_one),
    labels = patterns
  )
}

dat <- make_labelled_series(5L)

# ── milt_classifier() ────────────────────────────────────────────────────────

test_that("classifier: creates MiltClassifier", {
  clf <- milt_classifier("feature_based")
  expect_s3_class(clf, "MiltClassifier")
})

test_that("classifier: default method is feature_based", {
  clf <- milt_classifier()
  expect_equal(clf$method(), "feature_based")
})

test_that("classifier: is_fitted is FALSE before fitting", {
  clf <- milt_classifier()
  expect_false(clf$is_fitted())
})

test_that("classifier: print() runs without error", {
  clf <- milt_classifier()
  expect_output(print(clf), "MiltClassifier")
})

test_that("classifier: unknown method errors", {
  expect_error(milt_classifier("unknown_method"))
})

# ── milt_classify_fit() ───────────────────────────────────────────────────────

test_that("classify_fit: requires ranger, fits without error", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier("feature_based")
  milt_classify_fit(clf, dat$series, dat$labels)
  expect_true(clf$is_fitted())
})

test_that("classify_fit: classes stored correctly", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier()
  milt_classify_fit(clf, dat$series, dat$labels)
  expect_setequal(clf$classes(), c("constant", "sine", "trend"))
})

test_that("classify_fit: mismatched lengths errors", {
  clf <- milt_classifier()
  expect_error(
    milt_classify_fit(clf, dat$series, dat$labels[1:5]),
    class = "milt_error_invalid_arg"
  )
})

test_that("classify_fit: non-MiltClassifier errors", {
  expect_error(
    milt_classify_fit("not_a_clf", dat$series, dat$labels),
    class = "milt_error_invalid_arg"
  )
})

# ── milt_classify_predict() ───────────────────────────────────────────────────

test_that("classify_predict: returns labels of correct length", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier()
  milt_classify_fit(clf, dat$series, dat$labels)
  test_data <- dat$series[1:6]
  res <- milt_classify_predict(clf, test_data)
  expect_length(res$labels, 6L)
})

test_that("classify_predict: labels are valid class names", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier()
  milt_classify_fit(clf, dat$series, dat$labels)
  res <- milt_classify_predict(clf, dat$series[1:3])
  expect_true(all(res$labels %in% c("sine", "trend", "constant")))
})

test_that("classify_predict: probabilities matrix has correct shape", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier()
  milt_classify_fit(clf, dat$series, dat$labels)
  res <- milt_classify_predict(clf, dat$series[1:6])
  expect_equal(nrow(res$probabilities), 6L)
  expect_equal(ncol(res$probabilities), 3L)
})

test_that("classify_predict: unfitted classifier errors", {
  clf <- milt_classifier()
  expect_error(milt_classify_predict(clf, dat$series[1:3]),
               class = "milt_error_not_fitted")
})

# ── ROCKET method ─────────────────────────────────────────────────────────────

test_that("classifier: rocket method fits and predicts", {
  skip_if_not_installed("ranger")
  clf <- milt_classifier("rocket")
  milt_classify_fit(clf, dat$series, dat$labels)
  res <- milt_classify_predict(clf, dat$series[1:4])
  expect_length(res$labels, 4L)
})
