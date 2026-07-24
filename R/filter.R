# Filtering models — smooth/denoise an already-observed MiltSeries.
#
# Unlike milt_forecast(), a filter estimates the underlying signal at the
# SAME timestamps as the input; it does not extrapolate into the future.
# Mirrors darts.models.filtering (KalmanFilter, MovingAverageFilter,
# GaussianProcessFilter). All three are implemented on base R (stats) —
# no additional package dependencies.

#' Apply a filtering model to smooth a MiltSeries
#'
#' Filtering estimates the underlying signal from noisy observations at the
#' *same* timestamps as the input series — it does not forecast forward in
#' time. Use [milt_forecast()] to predict future values instead.
#'
#' @param series A univariate `MiltSeries` object.
#' @param method Character. One of `"moving_average"` (rolling-mean
#'   smoothing), `"kalman"` (state-space smoothing via [stats::StructTS()]),
#'   or `"gp"` (Gaussian Process smoothing with an RBF kernel).
#' @param ... Additional arguments forwarded to the chosen filter:
#'   - `moving_average`: `window` (default `3L`), `centered` (default `TRUE`)
#'   - `kalman`: `type`, one of `"level"`, `"trend"`, `"BSM"` (default `"level"`)
#'   - `gp`: `length_scale` (default `n / 20`), `noise` (default
#'     `0.1 * sd(values)`)
#' @return A `MiltSeries` with the same time index and value column(s),
#'   containing the filtered (smoothed) values.
#' @seealso [milt_fill_gaps()], [milt_plot_decomp()]
#' @family series
#' @examples
#' s   <- milt_series(AirPassengers)
#' sm1 <- milt_filter(s, "moving_average", window = 5L)
#' sm2 <- milt_filter(s, "kalman")
#' sm3 <- milt_filter(s, "gp")
#' @export
milt_filter <- function(series, method = c("moving_average", "kalman", "gp"), ...) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort("{.fn milt_filter} requires a univariate {.cls MiltSeries}.",
               class = "milt_error_not_univariate")
  }
  method <- match.arg(method)

  filtered <- switch(
    method,
    moving_average = .filter_moving_average(series, ...),
    kalman         = .filter_kalman(series, ...),
    gp             = .filter_gp(series, ...)
  )

  tbl <- series$as_tibble()
  vc  <- series$.__enclos_env__$private$.value_cols[[1L]]
  tbl[[vc]] <- filtered
  series$clone_with(tbl)
}

# ── Moving Average filter ─────────────────────────────────────────────────────

.filter_moving_average <- function(series, window = 3L, centered = TRUE, ...) {
  v <- series$values()
  n <- length(v)
  window <- as.integer(window)
  if (is.na(window) || window < 1L || window > n) {
    milt_abort(
      "{.arg window} must be a positive integer no larger than the series length.",
      class = "milt_error_invalid_arg"
    )
  }
  sides <- if (isTRUE(centered)) 2L else 1L
  as.numeric(stats::filter(v, rep(1 / window, window), sides = sides))
}

# ── Kalman filter (state-space smoothing via stats::StructTS) ────────────────

.filter_kalman <- function(series, type = c("level", "trend", "BSM"), ...) {
  type <- match.arg(type)
  v <- series$values()

  fit <- tryCatch(
    stats::StructTS(v, type = type),
    error = function(e) {
      milt_abort(
        c("Kalman filter failed to fit a state-space model.",
          "x" = conditionMessage(e)),
        class = "milt_error_fit_failed"
      )
    }
  )
  sm <- stats::tsSmooth(fit)
  as.numeric(sm[, "level"])
}

# ── Gaussian Process filter (RBF-kernel smoother) ─────────────────────────────

.filter_gp <- function(series, length_scale = NULL, noise = NULL, ...) {
  v <- series$values()
  n <- length(v)
  x <- seq_len(n)

  ls      <- length_scale %||% max(1, n / 20)
  sigma_f <- stats::sd(v, na.rm = TRUE)
  sigma_n <- noise %||% (0.1 * sigma_f)

  d2 <- outer(x, x, function(a, b) (a - b)^2)
  k  <- sigma_f^2 * exp(-d2 / (2 * ls^2))
  k_noisy <- k + diag(sigma_n^2, n)

  alpha <- tryCatch(
    solve(k_noisy, v),
    error = function(e) {
      milt_abort(
        c("Gaussian Process filter failed (singular kernel matrix).",
          "i" = "Try increasing {.arg noise}."),
        class = "milt_error_fit_failed"
      )
    }
  )
  as.numeric(k %*% alpha)
}
