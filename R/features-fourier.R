# Fourier-term feature engineering step

# ── Internal helper ────────────────────────────────────────────────────────────

# Compute K pairs of sin/cos Fourier terms for a length-n sequence.
# t is an integer time index (starting at 1).
.compute_fourier <- function(t, period, K) {
  mat <- matrix(NA_real_, nrow = length(t), ncol = 2L * K)
  col_names <- character(2L * K)
  for (k in seq_len(K)) {
    sin_col <- (k - 1L) * 2L + 1L
    cos_col <- (k - 1L) * 2L + 2L
    mat[, sin_col] <- sin(2 * pi * k * t / period)
    mat[, cos_col] <- cos(2 * pi * k * t / period)
    col_names[[sin_col]] <- paste0(".fourier_sin_", k)
    col_names[[cos_col]] <- paste0(".fourier_cos_", k)
  }
  colnames(mat) <- col_names
  mat
}

# ── milt_step_fourier ─────────────────────────────────────────────────────────

#' Add Fourier-term features to a MiltSeries
#'
#' Appends `2 * K` columns of sine and cosine terms at harmonics
#' `k = 1, 2, ..., K` of the given seasonal `period`.  No rows are dropped
#' (all terms are defined for every time step).
#'
#' Fourier features are a compact, continuous representation of seasonality and
#' are particularly useful for ML and DL models that cannot natively model
#' seasonal patterns.
#'
#' @param series A `MiltSeries`.
#' @param period Positive number. The seasonal period in units of the series
#'   frequency (e.g. `12` for annual seasonality in monthly data, `7` for
#'   weekly seasonality in daily data).  Defaults to the series frequency
#'   when `NULL`.
#' @param K Positive integer. Number of Fourier pairs (harmonics) to include.
#'   Higher `K` captures more complex seasonal shapes. Must satisfy
#'   `K <= floor(period / 2)`. Default `4L`.
#' @return An augmented `MiltSeries` with columns `.fourier_sin_1`,
#'   `.fourier_cos_1`, ..., `.fourier_sin_K`, `.fourier_cos_K` appended.
#'   Attribute `"milt_step_fourier"` stores the step specification.
#' @seealso [milt_step_lag()], [milt_step_rolling()], [milt_step_calendar()]
#' @family features
#' @examples
#' s     <- milt_series(AirPassengers)
#' s_fft <- milt_step_fourier(s, period = 12, K = 2)
#' head(s_fft$as_tibble())
#' @export
milt_step_fourier <- function(series, period = NULL, K = 4L) {
  assert_milt_series(series)
  K <- as.integer(K)

  # Resolve period
  if (is.null(period)) {
    freq_num <- .freq_label_to_numeric(as.character(series$freq()))
    period   <- as.numeric(freq_num)
    if (is.na(period) || period <= 1) {
      milt_abort(
        c(
          "Cannot determine {.arg period} automatically for this series.",
          "i" = "Supply {.arg period} explicitly."
        ),
        class = "milt_error_invalid_arg"
      )
    }
  }
  period <- as.numeric(period)

  if (period <= 0) {
    milt_abort("{.arg period} must be a positive number.",
               class = "milt_error_invalid_arg")
  }
  if (K < 1L || K > floor(period / 2)) {
    milt_abort(
      c(
        "{.arg K} must satisfy {.code 1 <= K <= floor(period / 2)}.",
        "i" = "With period = {period}, K can be at most {floor(period / 2)}."
      ),
      class = "milt_error_invalid_arg"
    )
  }

  n      <- series$n_timesteps()
  t_idx  <- seq_len(n)
  ft_mat <- .compute_fourier(t_idx, period, K)
  tbl    <- series$as_tibble()

  for (j in seq_len(ncol(ft_mat))) {
    tbl[[colnames(ft_mat)[[j]]]] <- ft_mat[, j]
  }
  tbl <- tibble::as_tibble(tbl)

  result <- series$clone_with(tbl)
  attr(result, "milt_step_fourier") <- list(
    period   = period,
    K        = K,
    n_origin = n   # t_origin so new data can continue the index
  )
  result
}
