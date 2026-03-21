# Walk-forward backtesting: MiltBacktest R6 class + milt_backtest()

# ── MiltBacktest R6 ───────────────────────────────────────────────────────────

#' @title MiltBacktest — walk-forward evaluation results
#' @description
#' Returned by [milt_backtest()]. Stores per-fold forecast accuracy metrics and
#' provides helpers for summarising and visualising backtest results.
#'
#' Users do not instantiate this class directly; use [milt_backtest()] instead.
#'
#' @export
MiltBacktestR6 <- R6::R6Class(
  classname  = "MiltBacktest",
  cloneable  = FALSE,

  private = list(
    .model_name   = NULL,   # character
    .method       = NULL,   # "expanding" | "sliding"
    .horizon      = NULL,   # integer
    .fold_results = NULL,   # tibble: .fold, .train_n, .test_n, .<METRIC>, ...
    .summary_tbl  = NULL    # cached summary tibble
  ),

  public = list(

    #' @description Initialise (called internally by [milt_backtest()]).
    #' @param model_name Character scalar.
    #' @param method Character scalar: `"expanding"` or `"sliding"`.
    #' @param horizon Integer forecast horizon.
    #' @param fold_results Tibble with per-fold metrics.
    initialize = function(model_name, method, horizon, fold_results) {
      private$.model_name   <- model_name
      private$.method       <- method
      private$.horizon      <- as.integer(horizon)
      private$.fold_results <- fold_results
    },

    # ── Accessors ─────────────────────────────────────────────────────────────

    #' @description Model identifier string.
    model_name = function() private$.model_name,

    #' @description Backtesting method: `"expanding"` or `"sliding"`.
    method = function() private$.method,

    #' @description Forecast horizon used.
    horizon = function() private$.horizon,

    #' @description Number of folds evaluated.
    n_folds = function() nrow(private$.fold_results),

    #' @description Per-fold metric tibble.
    #'   Columns: `.fold`, `.train_n`, `.test_n`, plus one column per metric.
    metrics = function() private$.fold_results,

    #' @description Aggregated summary tibble.
    #'   Columns: `metric`, `mean`, `sd`, `min`, `max`.
    summary_tbl = function() {
      if (!is.null(private$.summary_tbl)) return(private$.summary_tbl)

      fd          <- private$.fold_results
      meta_cols   <- c(".fold", ".train_n", ".test_n")
      metric_cols <- setdiff(names(fd), meta_cols)
      metric_cols <- metric_cols[nchar(metric_cols) > 0L]

      rows <- lapply(metric_cols, function(col) {
        x <- fd[[col]]
        tibble::tibble(
          metric = sub("^\\.", "", col),
          mean   = mean(x, na.rm = TRUE),
          sd     = stats::sd(x, na.rm = TRUE),
          min    = min(x, na.rm = TRUE),
          max    = max(x, na.rm = TRUE)
        )
      })

      private$.summary_tbl <- do.call(rbind, rows)
      private$.summary_tbl
    },

    #' @description Return per-fold metric tibble (same as `metrics()`).
    as_tibble = function() private$.fold_results
  )
)

# ── S3 methods ────────────────────────────────────────────────────────────────

#' Print a MiltBacktest
#'
#' @param x A `MiltBacktest` object.
#' @param ... Ignored.
#' @export
print.MiltBacktest <- function(x, ...) {
  cli::cli_h2("MiltBacktest <{x$model_name()}>")
  cli::cli_bullets(c(
    "*" = "Method  : {x$method()}",
    "*" = "Horizon : {x$horizon()}",
    "*" = "Folds   : {x$n_folds()}"
  ))
  cat("\n")
  smry <- x$summary_tbl()
  if (!is.null(smry) && nrow(smry) > 0L) {
    cli::cli_h3("Summary (across folds)")
    print(smry, n = Inf)
  }
  invisible(x)
}

#' Summary of a MiltBacktest
#'
#' @param object A `MiltBacktest` object.
#' @param ... Ignored.
#' @export
summary.MiltBacktest <- function(object, ...) {
  print(object, ...)
}

#' Coerce a MiltBacktest to a tibble
#'
#' Returns the per-fold metric tibble.
#'
#' @param x A `MiltBacktest` object.
#' @param ... Ignored.
#' @return A `tibble` with columns `.fold`, `.train_n`, `.test_n`, and one
#'   column per requested metric.
#' @export
as_tibble.MiltBacktest <- function(x, ...) {
  x$as_tibble()
}

#' Plot a MiltBacktest
#'
#' Draws a faceted line chart of each metric across folds.
#'
#' @param x A `MiltBacktest` object.
#' @param ... Ignored.
#' @return A `ggplot2` object, invisibly.
#' @export
plot.MiltBacktest <- function(x, ...) {
  fd          <- x$as_tibble()
  meta_cols   <- c(".fold", ".train_n", ".test_n")
  metric_cols <- setdiff(names(fd), meta_cols)

  if (length(metric_cols) == 0L) {
    milt_warn("No metric columns found; nothing to plot.")
    return(invisible(NULL))
  }

  long <- tidyr::pivot_longer(
    fd,
    cols      = dplyr::all_of(metric_cols),
    names_to  = "metric",
    values_to = "value"
  )
  long$metric <- sub("^\\.", "", long$metric)

  p <- ggplot2::ggplot(long, ggplot2::aes(x = .data$.fold, y = .data$value)) +
    ggplot2::geom_line(colour = "#2C7BB6") +
    ggplot2::geom_point(colour = "#2C7BB6", size = 2L) +
    ggplot2::facet_wrap(~ .data$metric, scales = "free_y") +
    ggplot2::labs(
      title    = paste0("Backtest: ", x$model_name(),
                        " [", x$method(), ", h=", x$horizon(), "]"),
      x        = "Fold",
      y        = "Metric value"
    ) +
    ggplot2::theme_minimal()

  print(p)
  invisible(p)
}

# ── milt_backtest() ───────────────────────────────────────────────────────────

#' Walk-forward backtesting of a milt model
#'
#' Performs time series cross-validation using either an **expanding** or a
#' **sliding** window strategy, computing forecast accuracy metrics for each
#' fold.
#'
#' @param model An unfitted `MiltModel` (created with [milt_model()]).
#'   The model is cloned and re-fitted from scratch on each fold's training
#'   window; the original object is not modified.
#' @param series A `MiltSeries` object containing the full time series.
#' @param horizon Positive integer. Forecast horizon for each fold.
#' @param initial_window Positive integer. Size of the first training window.
#'   Defaults to `max(floor(n * 0.5), horizon + 1L)`.
#' @param stride Positive integer. Number of steps to advance the training
#'   cutoff between consecutive folds. Default `1L`.
#' @param method Character scalar: `"expanding"` (training window grows each
#'   fold) or `"sliding"` (training window is of fixed size, specified by
#'   `window`). Default `"expanding"`.
#' @param window Positive integer. Only used when `method = "sliding"`.
#'   Size of the sliding training window. Defaults to `initial_window`.
#' @param metrics Character vector of metric names to compute. Supported:
#'   `"MAE"`, `"RMSE"`, `"MSE"`, `"MAPE"`, `"SMAPE"`. Default
#'   `c("MAE", "RMSE", "MAPE")`.
#' @return A `MiltBacktest` object.
#'
#' @seealso [milt_model()], [milt_fit()], [milt_forecast()], [milt_accuracy()]
#' @family model
#' @examples
#' \donttest{
#' s  <- milt_series(AirPassengers)
#' bt <- milt_backtest(milt_model("naive"), s, horizon = 12)
#' print(bt)
#' as_tibble(bt)
#' }
#' @export
milt_backtest <- function(model,
                           series,
                           horizon,
                           initial_window = NULL,
                           stride         = 1L,
                           method         = c("expanding", "sliding"),
                           window         = NULL,
                           metrics        = c("MAE", "RMSE", "MAPE")) {

  # ── Validate inputs ─────────────────────────────────────────────────────────
  .assert_milt_model(model)
  assert_milt_series(series)
  assert_positive_integer(horizon, "horizon")

  method  <- match.arg(method)
  stride  <- as.integer(stride)
  metrics <- match.arg(
    metrics,
    choices    = c("MAE", "RMSE", "MSE", "MAPE", "SMAPE"),
    several.ok = TRUE
  )

  if (stride < 1L) {
    milt_abort("{.arg stride} must be a positive integer.",
               class = "milt_error_invalid_arg")
  }

  n <- series$n_timesteps()

  if (is.null(initial_window)) {
    initial_window <- max(floor(n * 0.5), as.integer(horizon) + 1L)
  }
  initial_window <- as.integer(initial_window)

  if (initial_window < 2L) {
    milt_abort("{.arg initial_window} must be at least 2.",
               class = "milt_error_invalid_arg")
  }

  # Resolve sliding window
  if (method == "sliding") {
    if (is.null(window)) window <- initial_window
    window <- as.integer(window)
    if (window < 2L) {
      milt_abort("{.arg window} must be at least 2 for method = 'sliding'.",
                 class = "milt_error_invalid_arg")
    }
  }

  # Check feasibility
  if (initial_window + as.integer(horizon) > n) {
    milt_abort(
      c(
        "Not enough data to run backtesting.",
        "i" = paste0("Need at least {initial_window + horizon} observations;",
                     " series has {n}."),
        "i" = "Decrease {.arg initial_window} or {.arg horizon}."
      ),
      class = "milt_error_insufficient_data"
    )
  }

  # ── Compute fold cutpoints ───────────────────────────────────────────────────
  # fold_ends[k]: last training index for fold k
  fold_ends <- seq(
    from = initial_window,
    to   = n - as.integer(horizon),
    by   = stride
  )
  n_folds <- length(fold_ends)

  if (n_folds == 0L) {
    milt_abort(
      c(
        "Backtesting produces zero folds.",
        "i" = paste0("Increase series length, decrease {.arg horizon},",
                     " or decrease {.arg stride}.")
      ),
      class = "milt_error_insufficient_data"
    )
  }

  model_name_str <- model$.__enclos_env__$private$.name %||% class(model)[[1L]]

  milt_info(
    "Running {method} backtest ({n_folds} fold{?s}): {model_name_str}, h={horizon}"
  )

  # ── Grab the full data tibble once ──────────────────────────────────────────
  full_tbl <- series$as_tibble()

  # ── Iterate folds ───────────────────────────────────────────────────────────
  results <- vector("list", n_folds)

  for (k in seq_len(n_folds)) {
    train_end <- fold_ends[[k]]

    train_start <- if (method == "expanding") {
      1L
    } else {
      max(1L, train_end - window + 1L)
    }

    test_start <- train_end + 1L
    test_end   <- min(train_end + as.integer(horizon), n)
    actual_h   <- test_end - train_end   # may be < horizon at tail

    train_tbl <- full_tbl[seq(train_start, train_end), ]
    test_tbl  <- full_tbl[seq(test_start,  test_end),  ]

    train_series <- series$clone_with(train_tbl)
    test_series  <- series$clone_with(test_tbl)

    results[[k]] <- tryCatch({
      m <- model$clone()
      m$fit(train_series)
      fct      <- m$forecast(actual_h)
      fct_vals <- fct$as_tibble()$.mean
      act_vals <- test_series$values()

      row <- tibble::tibble(
        .fold    = k,
        .train_n = as.integer(train_end - train_start + 1L),
        .test_n  = as.integer(actual_h)
      )
      for (met in metrics) {
        row[[paste0(".", met)]] <- switch(met,
          MAE   = milt_mae(act_vals, fct_vals),
          RMSE  = milt_rmse(act_vals, fct_vals),
          MSE   = milt_mse(act_vals, fct_vals),
          MAPE  = suppressWarnings(milt_mape(act_vals, fct_vals)),
          SMAPE = milt_smape(act_vals, fct_vals)
        )
      }
      row

    }, error = function(e) {
      milt_warn("Fold {k} failed: {conditionMessage(e)}")
      row <- tibble::tibble(
        .fold    = k,
        .train_n = as.integer(train_end - train_start + 1L),
        .test_n  = as.integer(actual_h)
      )
      for (met in metrics) row[[paste0(".", met)]] <- NA_real_
      row
    })
  }

  fold_tbl <- do.call(rbind, results)

  MiltBacktestR6$new(
    model_name   = model_name_str,
    method       = method,
    horizon      = as.integer(horizon),
    fold_results = fold_tbl
  )
}
