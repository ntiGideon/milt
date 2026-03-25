# Causal impact analysis
#
# milt_causal_impact() wraps the CausalImpact package (Brodersen et al. 2015).
# It estimates the counterfactual of a time series intervention using a
# Bayesian structural time-series model fit on the pre-intervention period.

# ── Result class ──────────────────────────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltCausalImpactR6 <- R6::R6Class(
  classname = "MiltCausalImpact",
  cloneable = FALSE,

  private = list(
    .series       = NULL,   # MiltSeries (full)
    .event_index  = NULL,   # integer: 1-based index of first post-intervention obs
    .ci_obj       = NULL,   # raw CausalImpact result
    .method       = "causal_impact"
  ),

  public = list(

    initialize = function(series, event_index, ci_obj) {
      private$.series      <- series
      private$.event_index <- as.integer(event_index)
      private$.ci_obj      <- ci_obj
    },

    #' @return The original `MiltSeries`.
    series = function() private$.series,

    #' @return Integer: index of the first post-intervention observation.
    event_index = function() private$.event_index,

    #' @return The raw `CausalImpact` object from the `CausalImpact` package.
    raw = function() private$.ci_obj,

    #' @return A tibble with columns `time`, `actual`, `predicted`,
    #'   `lower`, `upper`, and `effect`.
    as_tibble = function() {
      s    <- private$.series
      ci   <- private$.ci_obj
      smry <- ci$series
      tibble::tibble(
        time      = s$times(),
        actual    = as.numeric(smry$response),
        predicted = as.numeric(smry$point.pred),
        lower     = as.numeric(smry$point.pred.lower),
        upper     = as.numeric(smry$point.pred.upper),
        effect    = as.numeric(smry$point.effect)
      )
    },

    #' @return A named numeric vector with keys `actual`, `predicted`,
    #'   `absolute_effect`, and `relative_effect` (post period averages).
    summary_stats = function() {
      ci   <- private$.ci_obj
      smry <- ci$summary
      c(
        actual           = smry["Average", "Actual"],
        predicted        = smry["Average", "Pred"],
        absolute_effect  = smry["Average", "AbsEffect"],
        relative_effect  = smry["Average", "RelEffect"]
      )
    }
  )
)

.new_milt_causal_impact <- function(series, event_index, ci_obj) {
  obj <- MiltCausalImpactR6$new(series, event_index, ci_obj)
  class(obj) <- c("MiltCausalImpact", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltCausalImpact <- function(x, ...) {
  s    <- x$series()
  ei   <- x$event_index()
  tms  <- s$times()
  cat(glue::glue(
    "# MiltCausalImpact\n",
    "# Series        : {s$n_timesteps()} obs  {s$start_time()} \u2014 {s$end_time()}\n",
    "# Pre-period    : {tms[[1L]]} \u2014 {tms[[ei - 1L]]}\n",
    "# Post-period   : {tms[[ei]]} \u2014 {tms[[s$n_timesteps()]]}\n"
  ))
  ss <- x$summary_stats()
  cat(glue::glue(
    "# Avg actual    : {round(ss['actual'], 4)}\n",
    "# Avg predicted : {round(ss['predicted'], 4)}\n",
    "# Abs effect    : {round(ss['absolute_effect'], 4)}\n",
    "# Rel effect    : {round(100 * ss['relative_effect'], 2)}%\n"
  ))
  invisible(x)
}

#' @export
summary.MiltCausalImpact <- function(object, ...) print(object)

#' @export
as_tibble.MiltCausalImpact <- function(x, ...) x$as_tibble()

#' @export
plot.MiltCausalImpact <- function(x, ...) {
  tbl <- x$as_tibble()
  ei  <- x$event_index()
  t0  <- tbl$time[[ei]]

  tbl_long <- tibble::tibble(
    time  = rep(tbl$time, 2L),
    value = c(tbl$actual, tbl$predicted),
    type  = rep(c("Actual", "Predicted"), each = nrow(tbl))
  )

  ggplot2::ggplot(tbl_long,
                  ggplot2::aes(x     = .data$time,
                               y     = .data$value,
                               colour = .data$type,
                               linetype = .data$type)) +
    ggplot2::geom_ribbon(
      data = tbl,
      ggplot2::aes(x = .data$time, ymin = .data$lower, ymax = .data$upper),
      inherit.aes = FALSE,
      fill = "#4472C4", alpha = 0.15
    ) +
    ggplot2::geom_line(linewidth = 0.7) +
    ggplot2::geom_vline(xintercept = as.numeric(t0),
                        linetype = "dashed", colour = "#E05C5C", linewidth = 0.8) +
    ggplot2::scale_colour_manual(values = c(Actual = "#222222", Predicted = "#4472C4")) +
    ggplot2::scale_linetype_manual(values = c(Actual = "solid", Predicted = "dashed")) +
    ggplot2::labs(
      title    = "Causal Impact Analysis",
      subtitle = paste0("Intervention at ", t0),
      x        = "Time", y = "Value",
      colour   = NULL, linetype = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Estimate the causal impact of an intervention
#'
#' Fits a Bayesian structural time-series model on the pre-intervention period
#' of `series` and extrapolates it as the counterfactual for the
#' post-intervention period.  The difference between actual and counterfactual
#' estimates the causal effect.
#'
#' Requires the `CausalImpact` package (>= 1.2.7).
#'
#' @param series A `MiltSeries` object (univariate).
#' @param event_time The time at which the intervention occurred.  Must be a
#'   value present in `series$times()`.  The pre-period is everything strictly
#'   before `event_time`; the post-period is `event_time` onwards.
#' @param covariates Optional `MiltSeries` object (or numeric matrix with the
#'   same number of rows as `series`) providing control covariates.  Passed
#'   to `CausalImpact` as additional columns in the data matrix.
#' @param n_seasons Integer.  Number of seasons for the seasonal component.
#'   `0L` (default) disables seasonality.
#' @param ... Additional arguments forwarded to `CausalImpact::CausalImpact()`.
#' @return A `MiltCausalImpact` object.
#' @seealso [milt_changepoints()]
#' @family anomaly
#' @examples
#' \donttest{
#' if (requireNamespace("CausalImpact", quietly = TRUE)) {
#'   s <- milt_series(AirPassengers)
#'   ci <- milt_causal_impact(s, event_time = as.Date("1956-01-01"))
#'   plot(ci)
#' }
#' }
#' @export
milt_causal_impact <- function(series,
                                event_time,
                                covariates = NULL,
                                n_seasons  = 0L,
                                ...) {
  check_installed_backend("CausalImpact", "milt_causal_impact")
  assert_milt_series(series)

  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_causal_impact} requires a univariate {.cls MiltSeries}.",
      class = "milt_error_not_univariate"
    )
  }

  times <- series$times()
  n     <- series$n_timesteps()

  # Locate event_time in the series
  event_index <- match(event_time, times)
  if (is.na(event_index)) {
    milt_abort(
      c(
        "{.arg event_time} ({.val {event_time}}) was not found in the series.",
        "i" = "The series spans {times[[1L]]} to {times[[n]]}."
      ),
      class = "milt_error_invalid_arg"
    )
  }
  if (event_index < 2L) {
    milt_abort(
      "{.arg event_time} must leave at least one pre-intervention observation.",
      class = "milt_error_invalid_arg"
    )
  }
  if (event_index > n) {
    milt_abort(
      "{.arg event_time} must not be after the last observation.",
      class = "milt_error_invalid_arg"
    )
  }

  # Build data matrix for CausalImpact: first column = outcome
  vals <- series$values()
  dat  <- matrix(vals, ncol = 1L)

  if (!is.null(covariates)) {
    if (inherits(covariates, "MiltSeries")) {
      cov_mat <- as.matrix(covariates$as_tibble()[, covariates$.__enclos_env__$private$.value_cols])
    } else {
      cov_mat <- as.matrix(covariates)
    }
    if (nrow(cov_mat) != n) {
      milt_abort(
        "{.arg covariates} must have the same number of rows as {.arg series} ({n}).",
        class = "milt_error_invalid_arg"
      )
    }
    dat <- cbind(dat, cov_mat)
  }

  pre_period  <- c(1L, event_index - 1L)
  post_period <- c(event_index, n)

  model_args <- list(
    data       = dat,
    pre.period  = pre_period,
    post.period = post_period
  )

  # Pass n_seasons if > 0
  if (n_seasons > 0L) {
    model_args$model.args <- list(nseasons = as.integer(n_seasons))
  }

  extra <- list(...)
  if (length(extra) > 0L) {
    model_args[names(extra)] <- extra
  }

  ci_obj <- tryCatch(
    do.call(CausalImpact::CausalImpact, model_args),
    error = function(e) {
      milt_abort(
        c("CausalImpact estimation failed.", "x" = conditionMessage(e)),
        class = "milt_error_detection_failed"
      )
    }
  )

  .new_milt_causal_impact(series, event_index, ci_obj)
}
