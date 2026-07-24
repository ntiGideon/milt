# Feature engineering: Box-Cox power transform, differencing, and a generic
# elementwise mapper. All follow the milt_step_scale()/milt_step_unscale()
# pattern: the public verb returns list(series =, step =), and the step
# object exposes inverse_transform() to undo the transform later.

# ── Box-Cox ────────────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltBoxCoxStepR6 <- R6::R6Class(
  classname = "MiltBoxCoxStep",
  cloneable = FALSE,

  private = list(.lambda = NULL),

  public = list(
    initialize = function(lambda) private$.lambda <- lambda,
    lambda = function() private$.lambda,

    inverse_transform = function(series) {
      assert_milt_series(series)
      tbl      <- series$as_tibble()
      val_cols <- series$.__enclos_env__$private$.value_cols
      for (col in val_cols) tbl[[col]] <- .boxcox_inverse(tbl[[col]], private$.lambda)
      series$clone_with(tbl)
    }
  )
)

.new_milt_boxcox_step <- function(lambda) {
  obj <- MiltBoxCoxStepR6$new(lambda)
  class(obj) <- c("MiltBoxCoxStep", class(obj))
  obj
}

#' @export
print.MiltBoxCoxStep <- function(x, ...) {
  cat(glue::glue("# MiltBoxCoxStep [lambda = {round(x$lambda(), 4)}]\n"))
  invisible(x)
}

.boxcox_transform <- function(y, lambda) {
  if (abs(lambda) < 1e-6) log(y) else (y^lambda - 1) / lambda
}

.boxcox_inverse <- function(y, lambda) {
  if (abs(lambda) < 1e-6) exp(y) else (y * lambda + 1)^(1 / lambda)
}

.boxcox_loglik <- function(lambda, y) {
  n  <- length(y)
  yt <- .boxcox_transform(y, lambda)
  -n / 2 * log(stats::var(yt)) + (lambda - 1) * sum(log(y))
}

#' Box-Cox power-transform a time series
#'
#' Stabilises variance by applying `(y^lambda - 1) / lambda` (or `log(y)`
#' when `lambda == 0`) to each value column. Requires strictly positive
#' values.
#'
#' @param series A `MiltSeries` object.
#' @param lambda Numeric power parameter. `NULL` (default) estimates it via
#'   profile-likelihood optimisation over `[-2, 2]`.
#' @return A named list:
#'   * `$series` — the transformed `MiltSeries`.
#'   * `$step`   — a `MiltBoxCoxStep` object for inverting the transform.
#' @seealso [milt_step_scale()], [milt_step_diff()]
#' @family features
#' @examples
#' s   <- milt_series(AirPassengers)
#' out <- milt_step_boxcox(s)
#' s_transformed <- out$series
#' s_original    <- out$step$inverse_transform(s_transformed)
#' @export
milt_step_boxcox <- function(series, lambda = NULL) {
  assert_milt_series(series)
  tbl      <- series$as_tibble()
  val_cols <- series$.__enclos_env__$private$.value_cols

  for (col in val_cols) {
    v <- tbl[[col]]
    if (any(v <= 0, na.rm = TRUE)) {
      milt_abort(
        c("{.fn milt_step_boxcox} requires strictly positive values.",
          "i" = "Column {.val {col}} contains a value <= 0."),
        class = "milt_error_invalid_arg"
      )
    }
  }

  # Estimate lambda from the first value column when not supplied
  lambda <- lambda %||% stats::optimize(
    .boxcox_loglik, interval = c(-2, 2), y = tbl[[val_cols[[1L]]]],
    maximum = TRUE
  )$maximum

  for (col in val_cols) tbl[[col]] <- .boxcox_transform(tbl[[col]], lambda)

  step        <- .new_milt_boxcox_step(lambda)
  transformed <- series$clone_with(tbl)
  list(series = transformed, step = step)
}

#' Invert a Box-Cox transform on a time series
#'
#' Convenience wrapper around `MiltBoxCoxStep$inverse_transform()`.
#'
#' @param step A `MiltBoxCoxStep` object returned by [milt_step_boxcox()].
#' @param series A `MiltSeries` to invert.
#' @return The original-scale `MiltSeries`.
#' @seealso [milt_step_boxcox()]
#' @family features
#' @export
milt_step_unboxcox <- function(step, series) {
  if (!inherits(step, "MiltBoxCoxStep")) {
    milt_abort(
      "{.arg step} must be a {.cls MiltBoxCoxStep} from {.fn milt_step_boxcox}.",
      class = "milt_error_invalid_arg"
    )
  }
  step$inverse_transform(series)
}

# ── Differencing ──────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltDiffStepR6 <- R6::R6Class(
  classname = "MiltDiffStep",
  cloneable = FALSE,

  private = list(
    .lags        = NULL,  # integer vector, applied in order
    .seeds       = NULL,  # named list (per value col) of list-of-numeric (per stage)
    .time_prefix = NULL   # first sum(lags) timestamps of the original series
  ),

  public = list(
    initialize = function(lags, seeds, time_prefix) {
      private$.lags        <- lags
      private$.seeds       <- seeds
      private$.time_prefix <- time_prefix
    },
    lags = function() private$.lags,

    inverse_transform = function(series) {
      assert_milt_series(series)
      tbl      <- series$as_tibble()
      time_col <- series$.__enclos_env__$private$.time_col
      val_cols <- series$.__enclos_env__$private$.value_cols

      restored <- list()
      for (col in val_cols) {
        v      <- tbl[[col]]
        stages <- private$.seeds[[col]]
        for (i in rev(seq_along(private$.lags))) {
          lag  <- private$.lags[[i]]
          seed <- stages[[i]]
          out  <- c(seed, numeric(length(v)))
          for (j in seq_len(length(v))) out[[lag + j]] <- out[[j]] + v[[j]]
          v <- out
        }
        restored[[col]] <- v
      }

      new_times <- c(private$.time_prefix, tbl[[time_col]])
      new_tbl   <- tibble::tibble(.rows = length(new_times))
      new_tbl[[time_col]] <- new_times
      for (col in val_cols) new_tbl[[col]] <- restored[[col]]
      series$clone_with(new_tbl)
    }
  )
)

.new_milt_diff_step <- function(lags, seeds, time_prefix) {
  obj <- MiltDiffStepR6$new(lags, seeds, time_prefix)
  class(obj) <- c("MiltDiffStep", class(obj))
  obj
}

#' @export
print.MiltDiffStep <- function(x, ...) {
  cat(glue::glue("# MiltDiffStep [lags = {paste(x$lags(), collapse = ', ')}]\n"))
  invisible(x)
}

#' Difference a time series
#'
#' Applies sequential lagged differencing (e.g. `lags = c(1, 12)` removes a
#' trend then a yearly seasonal pattern) to stabilise the mean. Differencing
#' shortens the series by `sum(lags)` observations.
#'
#' @param series A `MiltSeries` object.
#' @param lags Integer vector of lag orders, applied in sequence. Default
#'   `1L` (first difference).
#' @return A named list:
#'   * `$series` — the differenced `MiltSeries` (shorter than the input).
#'   * `$step`   — a `MiltDiffStep` object for inverting the transform back
#'     to the original series.
#' @seealso [milt_step_boxcox()], [milt_step_scale()]
#' @family features
#' @examples
#' s   <- milt_series(AirPassengers)
#' out <- milt_step_diff(s, lags = 1L)
#' s_diffed   <- out$series
#' s_original <- out$step$inverse_transform(s_diffed)
#' @export
milt_step_diff <- function(series, lags = 1L) {
  assert_milt_series(series)
  lags <- as.integer(lags)
  if (any(is.na(lags)) || any(lags < 1L)) {
    milt_abort("{.arg lags} must be a vector of positive integers.",
               class = "milt_error_invalid_arg")
  }

  tbl      <- series$as_tibble()
  time_col <- series$.__enclos_env__$private$.time_col
  val_cols <- series$.__enclos_env__$private$.value_cols
  total_drop <- sum(lags)

  if (nrow(tbl) <= total_drop) {
    milt_abort(
      c("Series has too few observations for the requested {.arg lags}.",
        "i" = "Need more than {total_drop} observations, have {nrow(tbl)}."),
      class = "milt_error_insufficient_data"
    )
  }

  seeds       <- list()
  diffed_cols <- list()
  for (col in val_cols) {
    v <- tbl[[col]]
    stage_seeds <- list()
    for (lag in lags) {
      stage_seeds[[length(stage_seeds) + 1L]] <- utils::head(v, lag)
      v <- diff(v, lag = lag)
    }
    seeds[[col]]       <- stage_seeds
    diffed_cols[[col]] <- v
  }

  new_tbl <- tbl[(total_drop + 1L):nrow(tbl), , drop = FALSE]
  for (col in val_cols) new_tbl[[col]] <- diffed_cols[[col]]

  step     <- .new_milt_diff_step(lags, seeds, utils::head(tbl[[time_col]], total_drop))
  diffed   <- series$clone_with(new_tbl)
  list(series = diffed, step = step)
}

#' Invert a differencing step on a time series
#'
#' Convenience wrapper around `MiltDiffStep$inverse_transform()`. Reconstructs
#' the original series from its differenced version — it does not invert a
#' *forecast* made in the differenced domain (that requires the training
#' series' trailing values, not its leading ones, as the reconstruction seed).
#'
#' @param step A `MiltDiffStep` object returned by [milt_step_diff()].
#' @param series The differenced `MiltSeries` to invert.
#' @return The original-scale `MiltSeries`.
#' @seealso [milt_step_diff()]
#' @family features
#' @export
milt_step_undiff <- function(step, series) {
  if (!inherits(step, "MiltDiffStep")) {
    milt_abort(
      "{.arg step} must be a {.cls MiltDiffStep} from {.fn milt_step_diff}.",
      class = "milt_error_invalid_arg"
    )
  }
  step$inverse_transform(series)
}

# ── Generic elementwise mapper ────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltMapStepR6 <- R6::R6Class(
  classname = "MiltMapStep",
  cloneable = FALSE,

  private = list(.inverse_fn = NULL),

  public = list(
    initialize = function(inverse_fn) private$.inverse_fn <- inverse_fn,

    inverse_transform = function(series) {
      assert_milt_series(series)
      tbl      <- series$as_tibble()
      time_col <- series$.__enclos_env__$private$.time_col
      val_cols <- series$.__enclos_env__$private$.value_cols
      time_aware <- length(formals(args(private$.inverse_fn))) >= 2L
      for (col in val_cols) {
        tbl[[col]] <- if (time_aware) {
          private$.inverse_fn(tbl[[time_col]], tbl[[col]])
        } else {
          private$.inverse_fn(tbl[[col]])
        }
      }
      series$clone_with(tbl)
    }
  )
)

.new_milt_map_step <- function(inverse_fn) {
  obj <- MiltMapStepR6$new(inverse_fn)
  class(obj) <- c("MiltMapStep", class(obj))
  obj
}

#' @export
print.MiltMapStep <- function(x, ...) {
  cat("# MiltMapStep [invertible]\n")
  invisible(x)
}

#' Apply an arbitrary elementwise function to a time series
#'
#' Applies `fn` to every value in each value column. `fn` may take either one
#' argument (the values only, e.g. `log1p`) or two arguments (the timestamps
#' and the values, e.g. `function(time, value) value / lubridate::year(time)`)
#' — the number of arguments `fn` declares is detected automatically, mirroring
#' darts' dual-mode `TimeSeries.map()`. Supply `inverse_fn` to get back an
#' invertible `MiltMapStep`.
#'
#' @param series A `MiltSeries` object.
#' @param fn A function of one argument (`value`) or two arguments (`time`,
#'   `value`).
#' @param inverse_fn Optional function satisfying `inverse_fn(fn(x)) == x`
#'   (or the two-argument equivalent), e.g. `expm1` to invert `log1p`. When
#'   `NULL` (default), `$step` is `NULL`.
#' @return A named list:
#'   * `$series` — the mapped `MiltSeries`.
#'   * `$step`   — a `MiltMapStep` for inverting the transform, or `NULL`
#'     when `inverse_fn` was not supplied.
#' @seealso [milt_step_boxcox()], [milt_step_diff()]
#' @family features
#' @examples
#' s   <- milt_series(AirPassengers)
#' out <- milt_step_map(s, fn = log1p, inverse_fn = expm1)
#' s_mapped   <- out$series
#' s_original <- out$step$inverse_transform(s_mapped)
#'
#' # time-aware mapping: zero out the first year of observations
#' out2 <- milt_step_map(s, fn = function(time, value) {
#'   ifelse(lubridate::year(time) == lubridate::year(min(time)), 0, value)
#' })
#' @export
milt_step_map <- function(series, fn, inverse_fn = NULL) {
  assert_milt_series(series)
  if (!is.function(fn)) {
    milt_abort("{.arg fn} must be a function.", class = "milt_error_invalid_arg")
  }
  if (!is.null(inverse_fn) && !is.function(inverse_fn)) {
    milt_abort("{.arg inverse_fn} must be a function.", class = "milt_error_invalid_arg")
  }

  tbl        <- series$as_tibble()
  time_col   <- series$.__enclos_env__$private$.time_col
  val_cols   <- series$.__enclos_env__$private$.value_cols
  time_aware <- length(formals(args(fn))) >= 2L
  for (col in val_cols) {
    tbl[[col]] <- if (time_aware) fn(tbl[[time_col]], tbl[[col]]) else fn(tbl[[col]])
  }

  mapped <- series$clone_with(tbl)
  step   <- if (!is.null(inverse_fn)) .new_milt_map_step(inverse_fn) else NULL
  list(series = mapped, step = step)
}
