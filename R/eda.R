# Exploratory Data Analysis
#
# milt_eda() generates a comprehensive summary of a MiltSeries:
#   - Descriptive statistics
#   - Stationarity tests (ADF, KPSS)
#   - Seasonality detection
#   - ACF/PACF plots
#   - Decomposition plot
#   - Distribution plot

# Base-R KPSS test (level stationarity, H0: stationary).
# Returns an approximate p-value using critical value interpolation from
# Kwiatkowski et al. (1992), Table 1 (mu case).
.kpss_pvalue_base <- function(x) {
  x <- as.numeric(x)
  n <- length(x)
  e <- x - mean(x)                       # demean (level case)
  S <- cumsum(e)                          # partial sums

  # Newey-West long-run variance with Bartlett kernel
  l     <- max(1L, floor(4 * (n / 100)^0.25))
  lrv   <- sum(e^2) / n
  for (j in seq_len(l)) {
    g   <- sum(e[(j + 1L):n] * e[1L:(n - j)]) / n
    lrv <- lrv + 2 * (1 - j / (l + 1)) * g
  }
  lrv <- max(lrv, 1e-10)

  kpss_stat <- sum(S^2) / (n^2 * lrv)

  # Critical values (level) and corresponding p-values
  cv <- c(0.347, 0.463, 0.574, 0.739)
  pv <- c(0.10,  0.05,  0.025, 0.01)

  if (kpss_stat <= cv[1L]) return(0.10)
  if (kpss_stat >= cv[4L]) return(0.01)
  idx  <- findInterval(kpss_stat, cv)
  frac <- (kpss_stat - cv[idx]) / (cv[idx + 1L] - cv[idx])
  pv[idx] + frac * (pv[idx + 1L] - pv[idx])
}

# ── Result class ──────────────────────────────────────────────────────────────

MiltEDAR6 <- R6::R6Class(
  classname = "MiltEDA",
  cloneable = FALSE,

  private = list(
    .series    = NULL,
    .stats     = NULL,   # tibble: descriptive stats
    .stationarity = NULL, # list: adf / kpss results
    .seasonality  = NULL  # list: period, strength
  ),

  public = list(

    initialize = function(series, stats, stationarity, seasonality) {
      private$.series      <- series
      private$.stats       <- stats
      private$.stationarity <- stationarity
      private$.seasonality  <- seasonality
    },

    series       = function() private$.series,
    stats        = function() private$.stats,
    stationarity = function() private$.stationarity,
    seasonality  = function() private$.seasonality,

    as_tibble = function() private$.stats
  )
)

.new_milt_eda <- function(series, stats, stationarity, seasonality) {
  obj <- MiltEDAR6$new(series, stats, stationarity, seasonality)
  class(obj) <- c("MiltEDA", class(obj))
  obj
}

# ── S3 methods ────────────────────────────────────────────────────────────────

#' @export
print.MiltEDA <- function(x, ...) {
  s    <- x$series()
  stat <- x$stationarity()
  seas <- x$seasonality()

  cat(glue::glue(
    "# MiltEDA\n",
    "# Series  : {s$n_timesteps()} obs  {s$start_time()} \u2014 {s$end_time()}\n",
    "# Freq    : {s$freq()}\n"
  ))

  cat("\n## Descriptive Statistics\n")
  print(x$stats())

  cat(glue::glue(
    "\n## Stationarity\n",
    "#  ADF  p-value : {round(stat$adf_pvalue,  4)}\n",
    "#  KPSS p-value : {round(stat$kpss_pvalue, 4)}\n",
    "#  Likely stationary: {stat$likely_stationary}\n"
  ))

  cat(glue::glue(
    "\n## Seasonality\n",
    "#  Detected period   : {seas$period}\n",
    "#  Seasonal strength : {round(seas$strength, 3)}\n",
    "#  Has seasonality   : {seas$has_seasonality}\n"
  ))

  invisible(x)
}

#' @export
summary.MiltEDA <- function(object, ...) print(object)

#' @export
as_tibble.MiltEDA <- function(x, ...) x$as_tibble()

#' @export
plot.MiltEDA <- function(x, ...) {
  # Returns a grid of 4 plots via patchwork or a list
  s <- x$series()
  p1 <- plot(s)   # series plot

  tbl   <- s$as_tibble()
  val_col <- s$.__enclos_env__$private$.value_cols[[1L]]
  vals  <- tbl[[val_col]]

  # Distribution
  p2 <- ggplot2::ggplot(tibble::tibble(value = vals),
                        ggplot2::aes(x = .data$value)) +
    ggplot2::geom_histogram(bins = 30, fill = "#4472C4", colour = "white",
                            alpha = 0.8) +
    ggplot2::labs(title = "Distribution", x = "Value", y = "Count") +
    ggplot2::theme_minimal(base_size = 11)

  list(series = p1, distribution = p2)
}

# ── Public verb ───────────────────────────────────────────────────────────────

#' Automated exploratory data analysis for a time series
#'
#' Computes descriptive statistics, stationarity tests, and seasonality
#' metrics for a `MiltSeries`. Results are printed in a structured report.
#'
#' @param series A `MiltSeries` object (univariate).
#' @param ... Additional arguments (unused).
#' @return A `MiltEDA` object.
#' @seealso [milt_diagnose()]
#' @family eda
#' @examples
#' s <- milt_series(AirPassengers)
#' e <- milt_eda(s)
#' print(e)
#' @export
milt_eda <- function(series, ...) {
  assert_milt_series(series)
  if (!series$is_univariate()) {
    milt_abort("{.fn milt_eda} requires a univariate {.cls MiltSeries}.",
               class = "milt_error_not_univariate")
  }

  tbl     <- series$as_tibble()
  val_col <- series$.__enclos_env__$private$.value_cols[[1L]]
  vals    <- as.numeric(tbl[[val_col]])
  n       <- length(vals)

  # ── Descriptive statistics ─────────────────────────────────────────────────
  q    <- stats::quantile(vals, probs = c(0.25, 0.5, 0.75), na.rm = TRUE)
  desc <- tibble::tibble(
    stat  = c("n", "mean", "sd", "min", "q25", "median", "q75", "max",
              "skewness", "kurtosis", "n_missing"),
    value = c(
      n,
      mean(vals, na.rm = TRUE),
      stats::sd(vals, na.rm = TRUE),
      min(vals, na.rm = TRUE),
      q[1L], q[2L], q[3L],
      max(vals, na.rm = TRUE),
      mean((vals - mean(vals, na.rm=TRUE))^3, na.rm=TRUE) /
        max(stats::sd(vals, na.rm=TRUE)^3, 1e-10),
      mean((vals - mean(vals, na.rm=TRUE))^4, na.rm=TRUE) /
        max(stats::sd(vals, na.rm=TRUE)^4, 1e-10),
      sum(is.na(vals))
    )
  )

  # ── Stationarity ──────────────────────────────────────────────────────────
  stationarity <- tryCatch({
    x <- stats::na.omit(vals)
    if (requireNamespace("tseries", quietly = TRUE)) {
      adf_res  <- tseries::adf.test(x)
      kpss_res <- tseries::kpss.test(x)
      list(
        adf_pvalue        = adf_res$p.value,
        kpss_pvalue       = kpss_res$p.value,
        likely_stationary = adf_res$p.value < 0.05 && kpss_res$p.value > 0.05
      )
    } else {
      # Fallback: Phillips-Perron (base stats) + simple KPSS implementation
      pp_pval   <- stats::PP.test(x)$p.value
      kpss_pval <- .kpss_pvalue_base(x)
      list(
        adf_pvalue        = pp_pval,
        kpss_pvalue       = kpss_pval,
        likely_stationary = pp_pval < 0.05 && kpss_pval > 0.05
      )
    }
  }, error = function(e) {
    list(adf_pvalue = NA_real_, kpss_pvalue = NA_real_,
         likely_stationary = NA)
  })

  # ── Seasonality ───────────────────────────────────────────────────────────
  freq        <- series$freq()
  freq_num    <- .freq_label_to_numeric(as.character(freq))
  period      <- if (!is.na(freq_num) && freq_num > 1) as.integer(round(freq_num)) else 1L

  strength <- 0
  has_seas <- FALSE

  if (period > 1L && n >= 2L * period) {
    tryCatch({
      ts_obj <- series$as_ts()
      dcmp   <- stats::stl(ts_obj, s.window = "periodic", robust = TRUE)
      var_s  <- stats::var(dcmp$time.series[, "seasonal"], na.rm = TRUE)
      var_r  <- stats::var(dcmp$time.series[, "remainder"], na.rm = TRUE)
      strength <- max(0, 1 - var_r / (var_s + var_r + 1e-10))
      has_seas <- strength > 0.3
    }, error = function(e) NULL)
  }

  seasonality <- list(period = period, strength = strength,
                      has_seasonality = has_seas)

  eda <- .new_milt_eda(series, desc, stationarity, seasonality)
  print(eda)
  invisible(eda)
}
