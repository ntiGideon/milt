# Model comparison: MiltComparison R6 + milt_compare()

#

#' @title MiltComparison - results of milt_compare()
#' @description
#' Stores per-model backtest results and provides a ranked summary table.
#' Produced by [milt_compare()]. Use `print()`, `plot()`, or `as_tibble()` to
#' inspect results.
#'
#' @export
MiltComparisonR6 <- R6::R6Class(
  classname = "MiltComparison",
  cloneable = FALSE,

  private = list(
    .backtests = NULL,
    .rank_metric = NULL,
    .summary_tbl = NULL
  ),

  public = list(

    #' @description Initialise (called by [milt_compare()]).
    #' @param backtests Named list of `MiltBacktest` objects.
    #' @param rank_metric Character scalar: metric column (without leading `.`)
    #'   used to rank models.
    initialize = function(backtests, rank_metric) {
      private$.backtests <- backtests
      private$.rank_metric <- rank_metric
    },

    #

    #' @description Named list of `MiltBacktest` objects, one per model.
    backtests = function() private$.backtests,

    #' @description Metric used for ranking.
    rank_metric = function() private$.rank_metric,

    #' @description Number of models compared.
    n_models = function() length(private$.backtests),

    #' @description Ranked summary tibble.
    #'   Columns: `model`, one column per metric (mean across folds), `rank`.
    summary_tbl = function() {
      if (!is.null(private$.summary_tbl)) {
        return(private$.summary_tbl)
      }

      rows <- lapply(names(private$.backtests), function(nm) {
        bt <- private$.backtests[[nm]]
        smry <- bt$summary_tbl()
        if (is.null(smry) || nrow(smry) == 0L) {
          return(NULL)
        }
        row <- tibble::tibble(model = nm)
        for (i in seq_len(nrow(smry))) {
          row[[smry$metric[[i]]]] <- smry$mean[[i]]
        }
        row
      })
      rows <- rows[!vapply(rows, is.null, logical(1L))]
      tbl <- do.call(rbind, rows)

      rm_col <- private$.rank_metric
      if (rm_col %in% names(tbl)) {
        tbl[["rank"]] <- rank(tbl[[rm_col]], ties.method = "min")
        tbl <- tbl[order(tbl[["rank"]]), ]
      }

      private$.summary_tbl <- tbl
      tbl
    },

    #' @description Return the ranked summary tibble (same as `summary_tbl()`).
    as_tibble = function() self$summary_tbl()
  )
)

#

#' Print a MiltComparison
#'
#' @param x A `MiltComparison` object.
#' @param ... Ignored.
#' @export
print.MiltComparison <- function(x, ...) {
  cli::cli_h2("MiltComparison - {x$n_models()} model{?s}")
  cli::cli_bullets(c(
    "*" = "Rank metric : {x$rank_metric()}",
    "*" = "Models      : {paste(names(x$backtests()), collapse = ', ')}"
  ))
  cat("\n")
  cli::cli_h3("Ranked by {x$rank_metric()} (mean across folds)")
  print(x$summary_tbl(), n = Inf)
  invisible(x)
}

#' Summary of a MiltComparison
#'
#' @param object A `MiltComparison` object.
#' @param ... Ignored.
#' @export
summary.MiltComparison <- function(object, ...) {
  print(object, ...)
}

#' Coerce a MiltComparison to a tibble
#'
#' Returns the ranked model summary tibble.
#'
#' @param x A `MiltComparison` object.
#' @param ... Ignored.
#' @return A `tibble` with columns `model`, one column per metric mean, `rank`.
#' @export
as_tibble.MiltComparison <- function(x, ...) {
  x$as_tibble()
}

#' Plot a MiltComparison
#'
#' Draws a grouped bar chart comparing models across metrics.
#'
#' @param x A `MiltComparison` object.
#' @param ... Ignored.
#' @return A `ggplot2` object, invisibly.
#' @export
plot.MiltComparison <- function(x, ...) {
  tbl <- x$summary_tbl()
  if (is.null(tbl) || nrow(tbl) == 0L) {
    milt_warn("No comparison data to plot.")
    return(invisible(NULL))
  }

  meta_cols <- c("model", "rank")
  metric_cols <- setdiff(names(tbl), meta_cols)

  if (length(metric_cols) == 0L) {
    milt_warn("No metric columns found; nothing to plot.")
    return(invisible(NULL))
  }

  long <- tidyr::pivot_longer(
    tbl,
    cols = dplyr::all_of(metric_cols),
    names_to = "metric",
    values_to = "value"
  )

  p <- ggplot2::ggplot(
    long,
    ggplot2::aes(x = .data$model, y = .data$value, fill = .data$model)
  ) +
    ggplot2::geom_col(show.legend = FALSE) +
    ggplot2::facet_wrap(~ .data$metric, scales = "free_y") +
    ggplot2::labs(
      title = "Model Comparison (mean across folds)",
      x = NULL,
      y = "Mean metric value"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))

  print(p)
  invisible(p)
}

#

#' Compare multiple milt models via walk-forward backtesting
#'
#' Runs [milt_backtest()] on each model and collects results into a ranked
#' comparison table.
#'
#' @param models A **named** list of unfitted `MiltModel` objects created with
#'   [milt_model()]. Names become the model labels in the comparison table.
#' @param series A `MiltSeries` object.
#' @param horizon Positive integer. Forecast horizon for each fold.
#' @param initial_window Positive integer or `NULL`. Passed to
#'   [milt_backtest()].
#' @param stride Positive integer. Steps between consecutive folds. Default
#'   `1L`.
#' @param method `"expanding"` or `"sliding"`. Default `"expanding"`.
#' @param metrics Character vector of metric names. Default
#'   `c("MAE", "RMSE", "MAPE")`.
#' @param rank_metric Character scalar. Metric used to rank models in the
#'   summary. Must be one of `metrics`. Default `metrics[[1L]]`.
#' @return A `MiltComparison` object.
#'
#' @seealso [milt_backtest()], [milt_model()]
#' @family model
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' cmp <- milt_compare(
#'   models = list(naive = milt_model("naive"), drift = milt_model("drift")),
#'   series = s, horizon = 12,
#'   initial_window = 120L, stride = 12L
#' )
#' print(cmp)
#' }
#' @export
milt_compare <- function(models,
                         series,
                         horizon,
                         initial_window = NULL,
                         stride = 1L,
                         method = c("expanding", "sliding"),
                         metrics = c("MAE", "RMSE", "MAPE"),
                         rank_metric = metrics[[1L]]) {
  #
  if (!is.list(models) || length(models) == 0L) {
    milt_abort("{.arg models} must be a non-empty named list of MiltModel objects.",
               class = "milt_error_invalid_arg")
  }
  if (is.null(names(models)) || any(nchar(names(models)) == 0L)) {
    milt_abort("{.arg models} must be a **named** list (each name becomes the model label).",
               class = "milt_error_invalid_arg")
  }
  for (nm in names(models)) {
    .assert_milt_model(models[[nm]], arg = glue::glue("models${nm}"))
  }
  assert_milt_series(series)
  method <- match.arg(method)
  if (!rank_metric %in% metrics) {
    milt_abort(
      c(
        "{.arg rank_metric} must be one of the requested {.arg metrics}.",
        "i" = "Got {.val {rank_metric}}; available: {.val {metrics}}."
      ),
      class = "milt_error_invalid_arg"
    )
  }

  #
  n_models <- length(models)
  backtests <- vector("list", n_models)
  names(backtests) <- names(models)

  milt_info("Comparing {n_models} model{?s}: {paste(names(models), collapse = ', ')}")

  for (nm in names(models)) {
    milt_info("  Running backtest for {.val {nm}}...")
    backtests[[nm]] <- milt_backtest(
      model = models[[nm]],
      series = series,
      horizon = horizon,
      initial_window = initial_window,
      stride = as.integer(stride),
      method = method,
      metrics = metrics
    )
  }

  MiltComparisonR6$new(
    backtests = backtests,
    rank_metric = rank_metric
  )
}
