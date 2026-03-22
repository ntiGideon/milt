# Plotting S3 methods for MiltSeries (and stubs for future result classes)

.milt_plot_theme <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "#5B6573"),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold")
    )
}

# ── MiltSeries ────────────────────────────────────────────────────────────────

#' Plot a MiltSeries
#'
#' Produces a ggplot2 line chart of the series values over time. Automatically
#' facets for multi-series data and uses coloured lines for multivariate series.
#'
#' @param x A `MiltSeries` object.
#' @param title Optional plot title. Defaults to `"MiltSeries [<freq>]"`.
#' @param color Single hex colour string used for univariate series.
#' @param ... Ignored.
#' @return A `ggplot` object, invisibly.
#' @seealso [autoplot.MiltSeries()], [milt_plot_acf()], [milt_plot_decomp()]
#' @family series
#' @export
plot.MiltSeries <- function(x,
                             title = NULL,
                             color = "#2166AC",
                             ...) {
  assert_milt_series(x)
  p   <- x$.__enclos_env__$private
  tbl <- x$as_tibble()
  tc  <- p$.time_col
  vcs <- p$.value_cols
  gc  <- p$.group_col

  long <- tidyr::pivot_longer(
    tbl,
    cols      = tidyr::all_of(vcs),
    names_to  = "component",
    values_to = "value"
  )
  long$series_type <- "Actual"

  plt_title <- title %||% glue::glue("MiltSeries [{x$freq()}]")
  plt_subtitle <- if (!is.null(gc)) {
    glue::glue("Grouped by {gc}")
  } else if (!x$is_univariate()) {
    "Multiple components"
  } else {
    "Observed values"
  }

  plt <- ggplot2::ggplot(
    long,
    ggplot2::aes(
      x     = .data[[tc]],
      y     = .data[["value"]]
    )
  ) +
    ggplot2::labs(
      x = NULL,
      y = NULL,
      title = plt_title,
      subtitle = plt_subtitle
    ) +
    .milt_plot_theme()

  if (!is.null(gc)) {
    plt <- plt +
      ggplot2::facet_wrap(ggplot2::vars(.data[[gc]]), scales = "free_y")
  }

  if (x$is_univariate()) {
    plt <- plt +
      ggplot2::geom_line(
        ggplot2::aes(
          color = .data[["series_type"]],
          linetype = .data[["series_type"]]
        ),
        linewidth = 0.9,
        lineend = "round",
        na.rm = TRUE
      ) +
      ggplot2::scale_color_manual(values = c(Actual = color), name = NULL) +
      ggplot2::scale_linetype_manual(values = c(Actual = "solid"), name = NULL)
  } else {
    plt <- plt +
      ggplot2::geom_line(
        ggplot2::aes(color = .data[["component"]]),
        linewidth = 0.85,
        lineend = "round",
        na.rm = TRUE
      ) +
      ggplot2::labs(color = "Component")
  }

  print(plt)
  invisible(plt)
}

#' @rdname plot.MiltSeries
#' @param object A `MiltSeries` object.
#' @export
autoplot.MiltSeries <- function(object, ...) plot.MiltSeries(object, ...)

# ── Supplementary plot helpers ────────────────────────────────────────────────

#' Plot the ACF and PACF of a MiltSeries
#'
#' Displays autocorrelation and partial autocorrelation side-by-side using base
#' R graphics.
#'
#' @param series A univariate `MiltSeries` object.
#' @param lag.max Maximum lag to compute. Default 36.
#' @param ... Additional arguments passed to [stats::acf()].
#' @return Invisibly returns a list with `acf` and `pacf` objects.
#' @seealso [milt_diagnose()]
#' @family series
#' @export
milt_plot_acf <- function(series, lag.max = 36L, ...) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_plot_acf} requires a univariate {.cls MiltSeries}.",
      class = "milt_error_not_univariate"
    )
  }
  v <- series$values()
  old_par <- graphics::par(mfrow = c(1L, 2L))
  on.exit(graphics::par(old_par))
  acf_obj  <- stats::acf(v,  lag.max = lag.max, plot = TRUE,
                          main = "ACF", na.action = stats::na.pass, ...)
  pacf_obj <- stats::pacf(v, lag.max = lag.max, plot = TRUE,
                           main = "PACF", na.action = stats::na.pass, ...)
  invisible(list(acf = acf_obj, pacf = pacf_obj))
}

#' Plot a simple STL-style decomposition of a MiltSeries
#'
#' Decomposes the series into trend, seasonal, and remainder components using
#' [stats::stl()] and plots each panel.
#'
#' @param series A univariate `MiltSeries` object. Must have a numeric
#'   frequency > 1.
#' @param ... Additional arguments passed to [stats::stl()].
#' @return The `stl` decomposition object, invisibly.
#' @seealso [milt_diagnose()]
#' @family series
#' @export
milt_plot_decomp <- function(series, ...) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort(
      "{.fn milt_plot_decomp} requires a univariate {.cls MiltSeries}.",
      class = "milt_error_not_univariate"
    )
  }
  freq <- .freq_label_to_numeric(as.character(series$freq()))
  if (is.na(freq) || freq <= 1) {
    milt_abort(
      c(
        "{.fn milt_plot_decomp} requires a seasonal series (frequency > 1).",
        "i" = "This series has frequency {.val {series$freq()}}."
      ),
      class = "milt_error_invalid_frequency"
    )
  }
  ts_obj <- series$as_ts()
  dcmp   <- stats::stl(ts_obj, s.window = "periodic", ...)
  plot(dcmp, main = glue::glue("STL Decomposition [{series$freq()}]"))
  invisible(dcmp)
}
