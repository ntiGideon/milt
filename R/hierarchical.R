# Hierarchical time series reconciliation
#
# milt_reconcile() wraps the fable / hts / FoReco approach to reconciling
# a set of bottom-up forecasts so they are coherent with their aggregates.
# The function accepts a named list of MiltForecast objects (one per node)
# and a summing matrix S, then applies the chosen reconciliation method.

# ── Internal helpers ──────────────────────────────────────────────────────────

#' Build forecast matrix from a list of MiltForecast objects
#'
#' @param forecasts Named list of MiltForecast objects (must all share horizon).
#' @return Numeric matrix (horizon × n_series), columns named by list names.
#' @noRd
.forecasts_to_matrix <- function(forecasts) {
  mats <- lapply(forecasts, function(f) f$as_tibble()$.mean)
  do.call(cbind, mats)
}

#' MinT (minimum trace) reconciliation: yhat_rec = S(S'WS)^{-1} S' W^{-1} yhat
#'
#' @param Y_hat Matrix (h × n_all) of base forecasts.
#' @param S     Summing matrix (n_all × n_bottom).
#' @param W_inv Inverse of the error covariance proxy (n_all × n_all).
#' @return Reconciled matrix (h × n_all).
#' @noRd
.mint_reconcile <- function(Y_hat, S, W_inv) {
  P <- S %*% solve(t(S) %*% W_inv %*% S) %*% t(S) %*% W_inv
  t(P %*% t(Y_hat))
}

# ── Result class ──────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltReconciliationR6 <- R6::R6Class(
  classname = "MiltReconciliation",
  cloneable = FALSE,

  private = list(
    .forecasts_rec = NULL,   # named list: reconciled numeric matrices (h × 1)
    .method        = NULL,   # character
    .series_names  = NULL    # character vector
  ),

  public = list(

    initialize = function(forecasts_rec, method, series_names) {
      private$.forecasts_rec <- forecasts_rec
      private$.method        <- as.character(method)
      private$.series_names  <- as.character(series_names)
    },

    #' @return Character: reconciliation method.
    method = function() private$.method,

    #' @return Character vector of series names.
    series_names = function() private$.series_names,

    #' @return Named list of numeric vectors (reconciled point forecasts).
    forecasts = function() private$.forecasts_rec,

    #' @return A tibble with columns `series`, `h`, and `.mean`.
    as_tibble = function() {
      rows <- lapply(private$.series_names, function(nm) {
        fc  <- private$.forecasts_rec[[nm]]
        tibble::tibble(
          series = nm,
          h      = seq_along(fc),
          .mean  = as.numeric(fc)
        )
      })
      do.call(rbind, rows)
    }
  )
)

.new_milt_reconciliation <- function(forecasts_rec, method, series_names) {
  obj <- MiltReconciliationR6$new(forecasts_rec, method, series_names)
  class(obj) <- c("MiltReconciliation", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltReconciliation <- function(x, ...) {
  cat(glue::glue(
    "# MiltReconciliation [{x$method()}]\n",
    "# Series: {paste(x$series_names(), collapse = ', ')}\n"
  ))
  invisible(x)
}

#' @export
summary.MiltReconciliation <- function(object, ...) print(object)

#' @export
as_tibble.MiltReconciliation <- function(x, ...) x$as_tibble()

# ── Public verb ───────────────────────────────────────────────────────────────

#' Reconcile hierarchical time series forecasts
#'
#' Adjusts a set of base forecasts so that they are coherent with a
#' user-supplied summing matrix `S`.  Three methods are available:
#'
#' * `"ols"` — ordinary-least-squares reconciliation (equal weights).
#' * `"wls_struct"` — WLS with structural scaling (diagonal of `S %*% t(S)`).
#' * `"mint_shrink"` — MinT with shrinkage covariance estimate (requires the
#'   in-sample residuals supplied via `residuals`).
#'
#' @param forecasts A named list of `MiltForecast` objects, one per node
#'   (both aggregate and bottom-level).  All must share the same horizon.
#' @param S Integer/numeric matrix.  Summing matrix with `nrow(S)` equal to the
#'   total number of series (length of `forecasts`) and `ncol(S)` equal to the
#'   number of bottom-level series.
#' @param method Character.  Reconciliation method: `"ols"` (default),
#'   `"wls_struct"`, or `"mint_shrink"`.
#' @param residuals Optional named list of numeric vectors (in-sample residuals
#'   per series).  Required for `"mint_shrink"`.
#' @return A `MiltReconciliation` object.
#' @seealso [milt_forecast()]
#' @family hierarchical
#' @examples
#' \donttest{
#' # Two-level hierarchy: Total = A + B
#' S <- matrix(c(1, 1, 1, 0, 0, 1), nrow = 3, ncol = 2,
#'             dimnames = list(c("Total", "A", "B"), c("A", "B")))
#' # (forecast each series first, then reconcile)
#' }
#' @export
milt_reconcile <- function(forecasts,
                            S,
                            method    = "ols",
                            residuals = NULL) {
  # ── validate inputs ────────────────────────────────────────────────────────
  if (!is.list(forecasts) || length(forecasts) == 0L) {
    milt_abort(
      "{.arg forecasts} must be a non-empty named list of {.cls MiltForecast} objects.",
      class = "milt_error_invalid_arg"
    )
  }
  if (is.null(names(forecasts)) || any(names(forecasts) == "")) {
    milt_abort(
      "All elements of {.arg forecasts} must be named.",
      class = "milt_error_invalid_arg"
    )
  }
  if (!all(vapply(forecasts, inherits, logical(1L), "MiltForecast"))) {
    milt_abort(
      "All elements of {.arg forecasts} must be {.cls MiltForecast} objects.",
      class = "milt_error_invalid_arg"
    )
  }
  if (!is.matrix(S) || !is.numeric(S)) {
    milt_abort("{.arg S} must be a numeric matrix.", class = "milt_error_invalid_arg")
  }
  n_series <- length(forecasts)
  if (nrow(S) != n_series) {
    milt_abort(
      c(
        "{.arg S} must have {n_series} row(s) (one per forecast series).",
        "x" = "{.arg S} has {nrow(S)} row(s)."
      ),
      class = "milt_error_invalid_arg"
    )
  }

  method <- match.arg(method, c("ols", "wls_struct", "mint_shrink"))

  # Ensure all forecasts share the same horizon
  horizons <- vapply(forecasts, function(f) f$horizon(), integer(1L))
  if (length(unique(horizons)) != 1L) {
    milt_abort(
      "All forecasts must share the same horizon. Got: {paste(horizons, collapse=', ')}.",
      class = "milt_error_invalid_arg"
    )
  }

  if (method == "mint_shrink" && is.null(residuals)) {
    milt_abort(
      "{.arg residuals} is required for {.val mint_shrink} reconciliation.",
      class = "milt_error_invalid_arg"
    )
  }

  # ── build base forecast matrix Y_hat (h x n_series) ──────────────────────
  Y_hat <- .forecasts_to_matrix(forecasts)

  # ── build weight matrix W_inv ─────────────────────────────────────────────
  W_inv <- switch(method,
    "ols" = diag(n_series),

    "wls_struct" = {
      w <- diag(S %*% t(S))
      diag(1 / pmax(w, 1e-10))
    },

    "mint_shrink" = {
      if (!is.list(residuals) || length(residuals) != n_series) {
        milt_abort(
          "{.arg residuals} must be a list with one element per forecast series.",
          class = "milt_error_invalid_arg"
        )
      }
      res_mat <- do.call(cbind, lapply(residuals, as.numeric))
      T_  <- nrow(res_mat)
      # Sample covariance
      W_hat <- stats::cov(res_mat)
      # Ledoit-Wolf-style shrinkage: blend toward scaled identity
      mu_sq <- mean(diag(W_hat))
      rho   <- min(1, (sum(W_hat ^ 2) + mu_sq ^ 2) /
                     ((T_ + 1) * (sum(W_hat ^ 2) - mu_sq ^ 2 / n_series)))
      W_shrink <- (1 - rho) * W_hat + rho * mu_sq * diag(n_series)
      solve(W_shrink + diag(n_series) * 1e-8)  # small ridge for stability
    }
  )

  # ── reconcile ─────────────────────────────────────────────────────────────
  Y_rec <- .mint_reconcile(Y_hat, S, W_inv)

  # Build named list of reconciled vectors
  series_nms  <- names(forecasts)
  forecasts_r <- stats::setNames(
    lapply(seq_len(n_series), function(i) Y_rec[, i]),
    series_nms
  )

  .new_milt_reconciliation(forecasts_r, method, series_nms)
}
