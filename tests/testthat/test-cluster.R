# Tests for milt_cluster() / MiltClusters

make_series_list <- function(n_series = 6L, n_obs = 36L) {
  lapply(seq_len(n_series), function(i) {
    tbl <- tibble::tibble(
      date  = seq(as.Date("2020-01-01"), by = "month", length.out = n_obs),
      value = rnorm(n_obs, mean = i * 5, sd = 1)
    )
    milt_series(tbl, time_col = "date", value_cols = "value")
  })
}

sl <- make_series_list()

# ── Input validation ──────────────────────────────────────────────────────────

test_that("cluster: single series errors", {
  expect_error(milt_cluster(sl[1L], k = 2L),
               class = "milt_error_invalid_arg")
})

test_that("cluster: non-MiltSeries element errors", {
  bad <- c(sl[1:2], list("not_a_series"))
  expect_error(milt_cluster(bad, k = 2L),
               class = "milt_error_invalid_arg")
})

test_that("cluster: k < 2 errors", {
  expect_error(milt_cluster(sl, k = 1L),
               class = "milt_error_invalid_arg")
})

test_that("cluster: k > n_series errors", {
  expect_error(milt_cluster(sl, k = 10L),
               class = "milt_error_invalid_arg")
})

test_that("cluster: euclidean unequal-length errors", {
  sl_unequal <- c(sl[1:3],
                  list(milt_series(AirPassengers)))
  expect_error(milt_cluster(sl_unequal, k = 2L, method = "euclidean"),
               class = "milt_error_invalid_arg")
})

# ── Euclidean ─────────────────────────────────────────────────────────────────

test_that("cluster: euclidean returns MiltClusters", {
  cl <- milt_cluster(sl, k = 2L, method = "euclidean")
  expect_s3_class(cl, "MiltClusters")
})

test_that("cluster: euclidean labels length matches n_series", {
  cl <- milt_cluster(sl, k = 3L, method = "euclidean")
  expect_length(cl$labels(), 6L)
})

test_that("cluster: euclidean k() matches requested k", {
  cl <- milt_cluster(sl, k = 2L, method = "euclidean")
  expect_equal(cl$k(), 2L)
})

test_that("cluster: euclidean method() is 'euclidean'", {
  cl <- milt_cluster(sl, k = 2L, method = "euclidean")
  expect_equal(cl$method(), "euclidean")
})

test_that("cluster: euclidean labels are in 1:k", {
  k  <- 3L
  cl <- milt_cluster(sl, k = k, method = "euclidean")
  expect_true(all(cl$labels() %in% seq_len(k)))
})

test_that("cluster: as_tibble() has series_index and cluster", {
  cl  <- milt_cluster(sl, k = 2L, method = "euclidean")
  tbl <- cl$as_tibble()
  expect_true(all(c("series_index", "cluster") %in% names(tbl)))
  expect_equal(nrow(tbl), 6L)
})

test_that("cluster: print() runs without error", {
  cl <- milt_cluster(sl, k = 2L, method = "euclidean")
  expect_output(print(cl), "MiltClusters")
})

test_that("cluster: plot() returns ggplot", {
  cl <- milt_cluster(sl, k = 2L, method = "euclidean")
  p  <- plot(cl)
  expect_s3_class(p, "gg")
})

# ── kShape ────────────────────────────────────────────────────────────────────

test_that("cluster: kshape returns MiltClusters", {
  cl <- milt_cluster(sl, k = 2L, method = "kshape")
  expect_s3_class(cl, "MiltClusters")
  expect_equal(cl$method(), "kshape")
})

# ── Feature-based ─────────────────────────────────────────────────────────────

test_that("cluster: feature_based returns MiltClusters", {
  cl <- milt_cluster(sl, k = 2L, method = "feature_based")
  expect_s3_class(cl, "MiltClusters")
})
