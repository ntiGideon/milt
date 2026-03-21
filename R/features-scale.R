# Feature engineering: scaling / normalisation
#
# milt_step_scale() normalises all value columns in a MiltSeries.
# The result carries scaling parameters so that milt_step_unscale() can
# revert the transformation (important for forecast post-processing).

# ── Internal scale step object ────────────────────────────────────────────────

MiltScaleStepR6 <- R6::R6Class(
  classname = "MiltScaleStep",
  cloneable = FALSE,

  private = list(
    .method = NULL,   # "zscore", "minmax", or "robust"
    .center = NULL,   # named numeric: per-column centering value
    .scale  = NULL    # named numeric: per-column scaling value
  ),

  public = list(

    initialize = function(method, center, scale) {
      private$.method <- as.character(method)
      private$.center <- center
      private$.scale  <- scale
    },

    method  = function() private$.method,
    center  = function() private$.center,
    scale   = function() private$.scale,

    #' Apply the learned scaling to a new series.
    transform = function(series) {
      assert_milt_series(series)
      tbl       <- series$as_tibble()
      time_col  <- series$.__enclos_env__$private$.time_col
      val_cols  <- series$.__enclos_env__$private$.value_cols

      for (col in val_cols) {
        if (col %in% names(private$.center)) {
          tbl[[col]] <- (tbl[[col]] - private$.center[[col]]) /
            pmax(private$.scale[[col]], 1e-10)
        }
      }
      series$clone_with(tbl)
    },

    #' Reverse the scaling on a series.
    inverse_transform = function(series) {
      assert_milt_series(series)
      tbl      <- series$as_tibble()
      val_cols <- series$.__enclos_env__$private$.value_cols

      for (col in val_cols) {
        if (col %in% names(private$.center)) {
          tbl[[col]] <- tbl[[col]] * private$.scale[[col]] + private$.center[[col]]
        }
      }
      series$clone_with(tbl)
    },

    #' Reverse-scale a numeric vector using the FIRST value column's parameters.
    inverse_transform_vector = function(x, col = NULL) {
      nm <- col %||% names(private$.center)[[1L]]
      x * private$.scale[[nm]] + private$.center[[nm]]
    }
  )
)

.new_milt_scale_step <- function(method, center, scale) {
  obj <- MiltScaleStepR6$new(method, center, scale)
  class(obj) <- c("MiltScaleStep", class(obj))
  obj
}

#' @export
print.MiltScaleStep <- function(x, ...) {
  cat(glue::glue(
    "# MiltScaleStep [{x$method()}]\n",
    "# Columns: {paste(names(x$center()), collapse = ', ')}\n"
  ))
  invisible(x)
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Scale a time series
#'
#' Normalises the value column(s) of a [MiltSeries] and returns both the
#' scaled series and a [MiltScaleStep] object that can be used to invert the
#' transformation.
#'
#' @param series A [MiltSeries] object.
#' @param method Character. Scaling method:
#'   * `"zscore"` (default): subtract mean, divide by SD.
#'   * `"minmax"`: scale to `[0, 1]`.
#'   * `"robust"`: subtract median, divide by IQR.
#' @return A named list:
#'   * `$series` — the scaled [MiltSeries].
#'   * `$step`   — a `MiltScaleStep` object for inverting the transform.
#' @seealso [milt_step_lag()], [milt_step_rolling()]
#' @family features
#' @examples
#' s   <- milt_series(AirPassengers)
#' out <- milt_step_scale(s, method = "zscore")
#' s_scaled   <- out$series
#' s_original <- out$step$inverse_transform(s_scaled)
#' @export
milt_step_scale <- function(series, method = "zscore") {
  assert_milt_series(series)
  method <- match.arg(method, c("zscore", "minmax", "robust"))

  tbl      <- series$as_tibble()
  time_col <- series$.__enclos_env__$private$.time_col
  val_cols <- series$.__enclos_env__$private$.value_cols

  center_list <- list()
  scale_list  <- list()

  for (col in val_cols) {
    v <- as.numeric(tbl[[col]])
    if (method == "zscore") {
      ctr <- mean(v, na.rm = TRUE)
      scl <- stats::sd(v, na.rm = TRUE)
    } else if (method == "minmax") {
      rng <- range(v, na.rm = TRUE)
      ctr <- rng[1L]
      scl <- diff(rng)
    } else {  # robust
      ctr <- stats::median(v, na.rm = TRUE)
      scl <- stats::IQR(v, na.rm = TRUE)
    }
    if (is.na(scl) || scl < 1e-10) scl <- 1
    tbl[[col]]      <- (v - ctr) / scl
    center_list[[col]] <- ctr
    scale_list[[col]]  <- scl
  }

  step   <- .new_milt_scale_step(method, center_list, scale_list)
  scaled <- series$clone_with(tbl)
  list(series = scaled, step = step)
}

#' Invert a scaling step on a time series
#'
#' Convenience wrapper around [MiltScaleStep]`$inverse_transform()`.
#'
#' @param step A `MiltScaleStep` object returned by [milt_step_scale()].
#' @param series A [MiltSeries] to unscale.
#' @return The unscaled [MiltSeries].
#' @seealso [milt_step_scale()]
#' @family features
#' @export
milt_step_unscale <- function(step, series) {
  if (!inherits(step, "MiltScaleStep")) {
    milt_abort(
      "{.arg step} must be a {.cls MiltScaleStep} from {.fn milt_step_scale}.",
      class = "milt_error_invalid_arg"
    )
  }
  step$inverse_transform(series)
}
