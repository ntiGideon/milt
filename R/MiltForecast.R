# R6 class for forecast results + S3 methods

# ── R6 class ──────────────────────────────────────────────────────────────────

#' @title MiltForecast — results of milt_forecast()
#' @description
#' Stores point forecasts, prediction intervals, and optional sample paths.
#' Produced by every model's `forecast()` method. Use `print()`, `plot()`, or
#' `as_tibble()` to inspect results.
#'
#' @export
MiltForecastR6 <- R6::R6Class(
  classname = "MiltForecast",
  cloneable = FALSE,

  private = list(
    .point_forecast  = NULL,  # tibble: time + value column(s)
    .lower           = NULL,  # named list of tibbles: level -> tibble(time, value)
    .upper           = NULL,  # named list of tibbles: level -> tibble(time, value)
    .samples         = NULL,  # matrix (horizon × n_samples) or NULL
    .model_name      = NULL,  # character
    .horizon         = NULL,  # integer
    .training_end    = NULL,  # Date/POSIXct or NULL
    .training_series = NULL   # MiltSeries (for history in plot) or NULL
  ),

  public = list(

    #' @description Create a MiltForecast. Called by model backends.
    #' @param point_forecast Tibble: must contain `time` and at least one
    #'   value column.
    #' @param lower Named list of tibbles (one per CI level, e.g. `"80"`, `"95"`).
    #'   Each tibble must have `time` and `value` columns.
    #' @param upper Same structure as `lower`.
    #' @param samples Numeric matrix (`horizon` rows × `n_samples` cols) or
    #'   `NULL`.
    #' @param model_name Character scalar.
    #' @param horizon Positive integer.
    #' @param training_end Start of the forecast horizon (end of training).
    #' @param training_series The `MiltSeries` used for training (for plotting
    #'   history alongside forecasts). Optional.
    initialize = function(point_forecast,
                          lower           = list(),
                          upper           = list(),
                          samples         = NULL,
                          model_name      = "unknown",
                          horizon         = nrow(point_forecast),
                          training_end    = NULL,
                          training_series = NULL) {

      if (!tibble::is_tibble(point_forecast)) {
        point_forecast <- tibble::as_tibble(point_forecast)
      }
      if (nrow(point_forecast) != horizon) {
        milt_abort(
          "Number of rows in {.arg point_forecast} must equal {.arg horizon}.",
          class = "milt_error_invalid_forecast"
        )
      }
      if (!is.null(samples) &&
          (!is.matrix(samples) || nrow(samples) != horizon)) {
        milt_abort(
          "{.arg samples} must be a matrix with {horizon} rows.",
          class = "milt_error_invalid_forecast"
        )
      }

      private$.point_forecast  <- point_forecast
      private$.lower           <- lower
      private$.upper           <- upper
      private$.samples         <- samples
      private$.model_name      <- model_name
      private$.horizon         <- as.integer(horizon)
      private$.training_end    <- training_end
      private$.training_series <- training_series
    },

    #' @description Return point forecasts as a tibble.
    point_forecast = function() private$.point_forecast,

    #' @description `TRUE` if prediction intervals are stored.
    has_intervals = function() length(private$.lower) > 0L,

    #' @description `TRUE` if sample paths are stored.
    has_samples = function() !is.null(private$.samples),

    #' @description Return confidence levels stored in the forecast.
    levels = function() as.numeric(names(private$.lower)),

    #' @description Return the forecast horizon.
    horizon = function() private$.horizon,

    #' @description Return the model name.
    model_name = function() private$.model_name,

    #' @description Convert to a wide tibble with all intervals.
    as_tibble = function() {
      pf       <- private$.point_forecast
      tc       <- names(pf)[[1L]]       # first column = time
      val_col  <- names(pf)[[2L]]       # second column = point forecast value

      out <- tibble::tibble(
        time   = pf[[tc]],
        .model = private$.model_name,
        .mean  = pf[[val_col]]
      )

      for (lvl in names(private$.lower)) {
        out[[paste0(".lower_", lvl)]] <- private$.lower[[lvl]][["value"]]
        out[[paste0(".upper_", lvl)]] <- private$.upper[[lvl]][["value"]]
      }
      out
    }
  )
)

# ── S3 methods ────────────────────────────────────────────────────────────────

#' Print a MiltForecast
#'
#' @param x A `MiltForecast` object.
#' @param n Number of rows to preview. Default 6.
#' @param ... Ignored.
#' @export
print.MiltForecast <- function(x, n = 6L, ...) {
  p <- x$.__enclos_env__$private

  cat(glue::glue(
    "# A MiltForecast <{p$.model_name}>: horizon = {p$.horizon}\n"
  ))

  if (!is.null(p$.training_end)) {
    cat(glue::glue("# Forecast from: {p$.training_end}\n"))
  }

  lvls <- names(p$.lower)
  if (length(lvls) > 0L) {
    cat(glue::glue("# Intervals    : {paste(lvls, collapse = ', ')}%\n"))
  }

  if (!is.null(p$.samples)) {
    cat(glue::glue("# Samples      : {ncol(p$.samples)}\n"))
  }

  cat("#\n")

  tbl    <- x$as_tibble()
  n_show <- min(n, nrow(tbl))
  print(tbl[seq_len(n_show), ], n = n_show)

  if (nrow(tbl) > n_show) {
    cat(glue::glue("# \u2026 with {nrow(tbl) - n_show} more rows\n"))
  }
  invisible(x)
}

#' Summarise a MiltForecast
#'
#' @param object A `MiltForecast` object.
#' @param ... Ignored.
#' @export
summary.MiltForecast <- function(object, ...) {
  tbl <- object$as_tibble()
  cat(glue::glue(
    "MiltForecast <{object$model_name()}>: {object$horizon()} steps\n\n"
  ))
  print(summary(tbl$.mean))
  invisible(object)
}

#' Convert a MiltForecast to a tibble
#'
#' @param x A `MiltForecast` object.
#' @param ... Ignored.
#' @return A wide tibble with columns `time`, `.model`, `.mean`, and one pair
#'   of `.lower_<level>` / `.upper_<level>` columns per confidence level.
#' @export
as_tibble.MiltForecast <- function(x, ...) x$as_tibble()

#' Plot a MiltForecast
#'
#' Renders the point forecast with optional prediction interval ribbons. If the
#' forecast was produced by [milt_fit()] (which stores the training series), the
#' historical data is shown to the left.
#'
#' @param x A `MiltForecast` object.
#' @param history Number of historical observations to display alongside the
#'   forecast. `NULL` shows all available history.
#' @param title Optional plot title.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @export
plot.MiltForecast <- function(x, history = 50L, title = NULL, ...) {
  p  <- x$.__enclos_env__$private
  tbl <- x$as_tibble()
  tc  <- "time"

  plt_title <- title %||%
    glue::glue("Forecast: {p$.model_name} (h = {p$.horizon})")

  # Start building ggplot
  plt <- ggplot2::ggplot() +
    ggplot2::labs(x = NULL, y = NULL, title = plt_title) +
    ggplot2::theme_minimal(base_size = 11)

  # ── Historical series (if stored) ─────────────────────────────────────────
  if (!is.null(p$.training_series)) {
    hist_tbl <- p$.training_series$as_tibble()
    hist_tc  <- p$.training_series$.__enclos_env__$private$.time_col
    hist_vc  <- p$.training_series$.__enclos_env__$private$.value_cols[[1L]]

    if (!is.null(history)) {
      hist_tbl <- utils::tail(hist_tbl, history)
    }

    plt <- plt +
      ggplot2::geom_line(
        data    = hist_tbl,
        mapping = ggplot2::aes(x = .data[[hist_tc]], y = .data[[hist_vc]]),
        colour  = "#555555",
        linewidth = 0.7
      )
  }

  # ── Prediction interval ribbons (widest → narrowest = darkest) ────────────
  lvls <- sort(as.numeric(names(p$.lower)), decreasing = TRUE)
  alpha_steps <- if (length(lvls) > 0L) seq(0.15, 0.35, length.out = length(lvls)) else NULL

  for (i in seq_along(lvls)) {
    lvl <- as.character(lvls[[i]])
    ribbon_df <- tibble::tibble(
      time  = p$.lower[[lvl]][["time"]],
      lower = p$.lower[[lvl]][["value"]],
      upper = p$.upper[[lvl]][["value"]]
    )
    plt <- plt +
      ggplot2::geom_ribbon(
        data    = ribbon_df,
        mapping = ggplot2::aes(x = .data[["time"]],
                               ymin = .data[["lower"]],
                               ymax = .data[["upper"]]),
        fill    = "#2166AC",
        alpha   = alpha_steps[[i]]
      )
  }

  # ── Point forecast line ───────────────────────────────────────────────────
  plt <- plt +
    ggplot2::geom_line(
      data    = tbl,
      mapping = ggplot2::aes(x = .data[[tc]], y = .data[[".mean"]]),
      colour  = "#2166AC",
      linewidth = 0.9,
      linetype  = "dashed"
    )

  print(plt)
  invisible(plt)
}

#' @export
as.data.frame.MiltForecast <- function(x, ...) as.data.frame(x$as_tibble())
