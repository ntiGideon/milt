# Time series clustering
#
# milt_cluster() partitions a multi-series MiltSeries (or a list of
# MiltSeries) into k groups using one of four methods:
#   "dtw_kmeans"    — k-means with Dynamic Time Warping distance (dtw package)
#   "kshape"        — k-Shape: shape-based clustering on z-normalised series
#   "feature_based" — extract TSfeatures, then standard k-means
#   "euclidean"     — plain k-means on equal-length aligned series

# ── Result class ──────────────────────────────────────────────────────────────

MiltClustersR6 <- R6::R6Class(
  classname = "MiltClusters",
  cloneable = FALSE,

  private = list(
    .series_list = NULL,   # list of MiltSeries
    .labels      = NULL,   # integer: cluster per series
    .method      = NULL,   # character
    .k           = NULL    # integer
  ),

  public = list(

    initialize = function(series_list, labels, method, k) {
      private$.series_list <- series_list
      private$.labels      <- as.integer(labels)
      private$.method      <- as.character(method)
      private$.k           <- as.integer(k)
    },

    #' @return Character: clustering method.
    method  = function() private$.method,

    #' @return Integer: number of clusters.
    k       = function() private$.k,

    #' @return Integer vector of cluster labels (1-based).
    labels  = function() private$.labels,

    #' @return Tibble with `series_index`, `cluster`, and any name attribute.
    as_tibble = function() {
      tibble::tibble(
        series_index = seq_along(private$.labels),
        cluster      = private$.labels
      )
    }
  )
)

.new_milt_clusters <- function(series_list, labels, method, k) {
  obj <- MiltClustersR6$new(series_list, labels, method, k)
  class(obj) <- c("MiltClusters", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltClusters <- function(x, ...) {
  cat(glue::glue(
    "# MiltClusters [{x$method()}]\n",
    "# Series: {length(x$labels())}   Clusters: {x$k()}\n"
  ))
  tbl <- x$as_tibble()
  cat("# Cluster sizes:\n")
  print(table(tbl$cluster))
  invisible(x)
}

#' @export
summary.MiltClusters <- function(object, ...) print(object)

#' @export
as_tibble.MiltClusters <- function(x, ...) x$as_tibble()

#' @export
plot.MiltClusters <- function(x, ...) {
  tbl  <- x$as_tibble()
  tbl$cluster <- factor(tbl$cluster)
  ggplot2::ggplot(tbl, ggplot2::aes(x = .data$series_index,
                                     y = .data$cluster,
                                     colour = .data$cluster)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::labs(
      title  = paste0("Time Series Clustering [", x$method(), "]"),
      x      = "Series Index",
      y      = "Cluster",
      colour = "Cluster"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.title = ggplot2::element_text(face = "bold"))
}

# ── Internal clustering algorithms ───────────────────────────────────────────

# kShape cross-correlation alignment (SBD distance) — no external package
.sbd_distance <- function(a, b) {
  n  <- max(length(a), length(b))
  cc <- stats::ccf(a, b, lag.max = n - 1L, plot = FALSE)$acf
  1 - max(cc)
}

.kshape_cluster <- function(mat, k, max_iter = 100L) {
  n <- nrow(mat)
  # z-normalise rows
  mat_z <- t(apply(mat, 1, function(x) {
    m <- mean(x); s <- stats::sd(x); if (s < 1e-10) s <- 1; (x - m) / s
  }))
  labels <- sample.int(k, n, replace = TRUE)
  for (iter in seq_len(max_iter)) {
    # Compute centroids as means within clusters
    centroids <- lapply(seq_len(k), function(cl) {
      idx <- which(labels == cl)
      if (length(idx) == 0L) return(mat_z[sample.int(n, 1L), ])
      colMeans(mat_z[idx, , drop = FALSE])
    })
    # Assign each series to nearest centroid (SBD)
    new_labels <- vapply(seq_len(n), function(i) {
      dists <- vapply(centroids, function(c) .sbd_distance(mat_z[i, ], c), numeric(1L))
      which.min(dists)
    }, integer(1L))
    if (all(new_labels == labels)) break
    labels <- new_labels
  }
  labels
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Cluster multiple time series
#'
#' Partitions a list of [MiltSeries] objects into `k` groups using one of
#' four algorithms.
#'
#' @param series_list A list of [MiltSeries] objects (each univariate).
#' @param k Integer. Number of clusters.
#' @param method Character. Clustering method:
#'   * `"dtw_kmeans"` — k-means with DTW distance (requires `dtw` package).
#'   * `"kshape"` — shape-based clustering (no extra package).
#'   * `"feature_based"` — extract time series features then k-means.
#'   * `"euclidean"` — k-means on raw aligned series (all must be equal length).
#' @param max_iter Integer. Maximum k-means iterations. Default `100L`.
#' @param ... Additional arguments (unused).
#' @return A `MiltClusters` object.
#' @seealso [milt_classify()]
#' @family cluster
#' @examples
#' \donttest{
#' # Create 4 slightly different series
#' make_s <- function(offset) {
#'   milt_series(AirPassengers + offset)
#' }
#' series_list <- lapply(c(0, 10, 20, 30), make_s)
#' cl <- milt_cluster(series_list, k = 2, method = "euclidean")
#' print(cl)
#' }
#' @export
milt_cluster <- function(series_list,
                          k,
                          method   = "euclidean",
                          max_iter = 100L,
                          ...) {
  if (!is.list(series_list) || length(series_list) < 2L) {
    milt_abort(
      "{.arg series_list} must be a list of at least 2 {.cls MiltSeries} objects.",
      class = "milt_error_invalid_arg"
    )
  }
  if (!all(vapply(series_list, inherits, logical(1L), "MiltSeries"))) {
    milt_abort(
      "All elements of {.arg series_list} must be {.cls MiltSeries} objects.",
      class = "milt_error_invalid_arg"
    )
  }
  k <- as.integer(k)
  if (k < 2L || k > length(series_list)) {
    milt_abort(
      "{.arg k} must be between 2 and {length(series_list)} (number of series).",
      class = "milt_error_invalid_arg"
    )
  }
  method <- match.arg(method, c("dtw_kmeans", "kshape", "feature_based", "euclidean"))

  n_lens <- vapply(series_list, function(s) s$n_timesteps(), integer(1L))

  labels <- switch(method,
    "euclidean" = {
      if (length(unique(n_lens)) != 1L) {
        milt_abort(
          c(
            "{.val euclidean} clustering requires all series to have equal length.",
            "i" = "Series lengths: {paste(n_lens, collapse=', ')}."
          ),
          class = "milt_error_invalid_arg"
        )
      }
      mat <- do.call(rbind, lapply(series_list, function(s) as.numeric(s$values())))
      km  <- stats::kmeans(mat, centers = k, iter.max = as.integer(max_iter))
      km$cluster
    },

    "kshape" = {
      # Pad shorter series with NA if needed, then trim to min length
      min_len <- min(n_lens)
      mat     <- do.call(rbind, lapply(series_list, function(s) {
        v <- as.numeric(s$values())
        v[seq_len(min_len)]
      }))
      .kshape_cluster(mat, k, max_iter = as.integer(max_iter))
    },

    "dtw_kmeans" = {
      check_installed_backend("dtw", "dtw_kmeans clustering")
      min_len <- min(n_lens)
      mat <- do.call(rbind, lapply(series_list, function(s) {
        v <- as.numeric(s$values())
        v[seq_len(min_len)]
      }))
      n_s   <- nrow(mat)
      # Build DTW distance matrix
      dist_mat <- matrix(0, nrow = n_s, ncol = n_s)
      for (i in seq_len(n_s - 1L)) {
        for (j in (i + 1L):n_s) {
          d <- dtw::dtw(mat[i, ], mat[j, ], distance.only = TRUE)$distance
          dist_mat[i, j] <- d
          dist_mat[j, i] <- d
        }
      }
      km <- stats::kmeans(dist_mat, centers = k, iter.max = as.integer(max_iter))
      km$cluster
    },

    "feature_based" = {
      # Extract simple features: mean, sd, skew, kurtosis, acf1, trend strength
      features <- do.call(rbind, lapply(series_list, function(s) {
        v    <- as.numeric(s$values())
        acf1 <- tryCatch(stats::acf(v, lag.max = 1L, plot = FALSE)$acf[2L, 1L, 1L],
                         error = function(e) 0)
        # Trend via OLS slope
        t_idx <- seq_along(v)
        slope <- tryCatch(
          stats::coef(stats::lm(v ~ t_idx))[[2L]],
          error = function(e) 0
        )
        c(
          mean_v    = mean(v, na.rm = TRUE),
          sd_v      = stats::sd(v, na.rm = TRUE),
          skew      = mean((v - mean(v, na.rm=TRUE))^3, na.rm=TRUE) /
                        max(stats::sd(v, na.rm=TRUE)^3, 1e-10),
          acf1      = acf1,
          trend_slope = slope
        )
      }))
      km <- stats::kmeans(features, centers = k, iter.max = as.integer(max_iter),
                          nstart = 10L)
      km$cluster
    }
  )

  .new_milt_clusters(series_list, labels, method, k)
}
