# Series diagnostics: stationarity, seasonality, outliers, trend, gaps

# ── MiltDiagnosis class ───────────────────────────────────────────────────────

#' @title MiltDiagnosis — diagnostic report for a MiltSeries
#' @description Returned by [milt_diagnose()]. Use `print()`, `summary()`, or
#'   `plot()` to inspect results.
#' @keywords internal
#' @noRd
MiltDiagnosisR6 <- R6::R6Class(
  classname = "MiltDiagnosis",
  cloneable = FALSE,

  private = list(
    .series        = NULL,
    .stationarity  = NULL,  # list: stationary (lgl), recommendation (chr)
    .seasonality   = NULL,  # list: seasonal (lgl), strength (dbl), period (int)
    .trend         = NULL,  # list: has_trend (lgl), slope (dbl), p_value (dbl)
    .gaps          = NULL,  # tibble of gap locations (may be empty)
    .outliers      = NULL,  # list: n_outliers (int), indices (int vec)
    .recommendations = NULL # character vector
  ),

  public = list(
    #' @description Internal constructor — use [milt_diagnose()] instead.
    initialize = function(series, stationarity, seasonality, trend,
                          gaps, outliers, recommendations) {
      private$.series          <- series
      private$.stationarity    <- stationarity
      private$.seasonality     <- seasonality
      private$.trend           <- trend
      private$.gaps            <- gaps
      private$.outliers        <- outliers
      private$.recommendations <- recommendations
    },

    #' @description Return results as a named list.
    as_list = function() {
      list(
        stationarity    = private$.stationarity,
        seasonality     = private$.seasonality,
        trend           = private$.trend,
        gaps            = private$.gaps,
        outliers        = private$.outliers,
        recommendations = private$.recommendations
      )
    }
  )
)

# ── S3 methods for MiltDiagnosis ──────────────────────────────────────────────

#' @export
print.MiltDiagnosis <- function(x, ...) {
  p <- x$.__enclos_env__$private
  s <- p$.series

  cat("# MiltDiagnosis\n")
  cat(glue::glue("# Series    : {s$n_timesteps()} obs @ {s$freq()}\n"))
  cat(glue::glue("# Range     : {s$start_time()} \u2014 {s$end_time()}\n\n"))

  # Stationarity
  stat <- p$.stationarity
  stat_label <- if (stat$stationary) cli::col_green("stationary") else
    cli::col_red("non-stationary")
  cat(glue::glue("Stationarity : {stat_label}",
                  " (CV ratio = {round(stat$cv_ratio, 3)})\n"))

  # Seasonality
  seas <- p$.seasonality
  seas_label <- if (seas$seasonal) cli::col_green("seasonal") else "none detected"
  cat(glue::glue(
    "Seasonality  : {seas_label}",
    " (strength = {round(seas$strength, 3)}, period = {seas$period})\n"
  ))

  # Trend
  tr <- p$.trend
  tr_label <- if (tr$has_trend) cli::col_yellow("trend present") else "no trend"
  cat(glue::glue(
    "Trend        : {tr_label}",
    " (slope = {round(tr$slope, 4)}, p = {round(tr$p_value, 4)})\n"
  ))

  # Gaps
  n_gaps <- nrow(p$.gaps)
  gaps_label <- if (n_gaps == 0L) "none" else
    cli::col_red(glue::glue("{n_gaps} gap(s) detected"))
  cat(glue::glue("Gaps         : {gaps_label}\n"))

  # Outliers
  ol <- p$.outliers
  ol_label <- if (ol$n_outliers == 0L) "none" else
    cli::col_yellow(glue::glue("{ol$n_outliers} potential outlier(s) (IQR method)"))
  cat(glue::glue("Outliers     : {ol_label}\n"))

  # Recommendations
  if (length(p$.recommendations) > 0L) {
    cat("\nRecommendations:\n")
    for (r in p$.recommendations) cat(glue::glue("  \u2022 {r}\n"))
  }

  invisible(x)
}

#' @export
summary.MiltDiagnosis <- function(object, ...) print(object, ...)

#' Plot a MiltDiagnosis
#'
#' Displays a 2×2 panel: the raw series, ACF, residuals from linear trend, and
#' a value distribution histogram.
#'
#' @param x A `MiltDiagnosis` object.
#' @param ... Ignored.
#' @export
plot.MiltDiagnosis <- function(x, ...) {
  p      <- x$.__enclos_env__$private
  series <- p$.series
  if (!series$is_univariate()) {
    milt_warn("Diagnostic plot shows only the first component of a multivariate series.")
  }

  v    <- series$values()
  if (is.matrix(v)) v <- v[, 1L]
  n    <- length(v)
  idx  <- seq_len(n)
  tc   <- series$.__enclos_env__$private$.time_col
  times <- series$times()

  old_par <- graphics::par(mfrow = c(2L, 2L), mar = c(3, 3, 2, 1))
  on.exit(graphics::par(old_par))

  # Panel 1: raw series
  graphics::plot(times, v, type = "l", col = "#2166AC", lwd = 1.2,
                 main = "Series", xlab = "", ylab = "", las = 1)
  # Panel 2: ACF
  stats::acf(v, main = "ACF", na.action = stats::na.pass, lag.max = min(36L, n %/% 4L))
  # Panel 3: detrended (residuals from linear fit)
  fit   <- stats::lm(v ~ idx)
  resid <- stats::residuals(fit)
  graphics::plot(times, resid, type = "l", col = "#D6604D", lwd = 1.2,
                 main = "Detrended", xlab = "", ylab = "", las = 1)
  graphics::abline(h = 0, lty = 2, col = "grey60")
  # Panel 4: histogram
  graphics::hist(v, breaks = "Sturges", col = "#92C5DE", border = "white",
                 main = "Distribution", xlab = "")

  invisible(x)
}

# ── Main function ─────────────────────────────────────────────────────────────

#' Diagnose a MiltSeries
#'
#' Runs a suite of statistical checks and returns a `MiltDiagnosis` report
#' with stationarity, seasonality, trend, gap, and outlier information, plus
#' actionable recommendations.
#'
#' @param series A `MiltSeries` object. For multi-component series, diagnostics
#'   are computed on the first component.
#' @param alpha Significance level for the trend test. Default `0.05`.
#' @param seasonality_threshold ACF strength above which seasonality is
#'   reported. Default `0.3`.
#' @param iqr_multiplier IQR multiplier for outlier detection. Default `1.5`.
#' @return A `MiltDiagnosis` object.
#' @seealso [milt_fill_gaps()], [milt_plot_acf()], [milt_plot_decomp()]
#' @family series
#' @examples
#' s <- milt_series(AirPassengers)
#' diag <- milt_diagnose(s)
#' print(diag)
#' @export
milt_diagnose <- function(series,
                           alpha                  = 0.05,
                           seasonality_threshold  = 0.3,
                           iqr_multiplier         = 1.5) {
  assert_milt_series(series)

  v <- series$values()
  if (is.matrix(v)) {
    milt_info("Using first component for diagnostics.")
    v <- v[, 1L]
  }
  n   <- length(v)
  idx <- seq_len(n)

  # ── Stationarity: coefficient of variation check ──────────────────────────
  # Compare CV of raw series vs first-differenced series.
  # If differencing reduces dispersion substantially, series is non-stationary.
  cv <- function(x) {
    m <- mean(x, na.rm = TRUE)
    if (abs(m) < .Machine$double.eps) return(Inf)
    stats::sd(x, na.rm = TRUE) / abs(m)
  }
  cv_raw  <- cv(v)
  cv_diff <- cv(diff(v))
  cv_ratio <- if (is.finite(cv_diff) && cv_diff > 0) cv_raw / cv_diff else 1
  stationary <- cv_ratio < 2  # heuristic: differencing helps a lot if ratio > 2

  stationarity <- list(stationary = stationary, cv_ratio = cv_ratio)

  # ── Seasonality: STL-based strength ──────────────────────────────────────
  freq_num <- .freq_label_to_numeric(as.character(series$freq()))
  if (!is.na(freq_num) && freq_num > 1 && n >= 2L * as.integer(round(freq_num))) {
    period <- as.integer(round(freq_num))
    seas_strength <- tryCatch({
      ts_obj <- series$as_ts()
      dcmp   <- stats::stl(ts_obj, s.window = "periodic", robust = TRUE)
      var_s  <- stats::var(dcmp$time.series[, "seasonal"],  na.rm = TRUE)
      var_r  <- stats::var(dcmp$time.series[, "remainder"], na.rm = TRUE)
      max(0, 1 - var_r / (var_s + var_r + 1e-10))
    }, error = function(e) 0)
    seasonal <- seas_strength > seasonality_threshold
  } else {
    seas_strength <- 0
    seasonal      <- FALSE
    period        <- NA_integer_
  }
  seasonality <- list(seasonal = seasonal, strength = seas_strength, period = period)

  # ── Trend: linear regression slope test ──────────────────────────────────
  fit     <- stats::lm(v ~ idx)
  co      <- summary(fit)$coefficients
  slope   <- co[2L, 1L]
  p_val   <- co[2L, 4L]
  has_trend <- p_val < alpha

  trend <- list(has_trend = has_trend, slope = slope, p_value = p_val)

  # ── Gaps ──────────────────────────────────────────────────────────────────
  gaps <- series$gaps()

  # ── Outliers: IQR method ─────────────────────────────────────────────────
  q1     <- stats::quantile(v, 0.25, na.rm = TRUE)
  q3     <- stats::quantile(v, 0.75, na.rm = TRUE)
  iqr    <- q3 - q1
  lower  <- q1 - iqr_multiplier * iqr
  upper  <- q3 + iqr_multiplier * iqr
  out_idx <- which(v < lower | v > upper)
  outliers <- list(n_outliers = length(out_idx), indices = out_idx)

  # ── Recommendations ───────────────────────────────────────────────────────
  recs <- character(0L)
  if (nrow(gaps) > 0L) {
    recs <- c(recs, glue::glue(
      "Fill {nrow(gaps)} gap(s) with `milt_fill_gaps()` before modelling."
    ))
  }
  if (!stationary) {
    recs <- c(recs, paste0(
      "Series appears non-stationary. Consider differencing or a log ",
      "transform before using ARIMA-class models."
    ))
  }
  if (has_trend) {
    recs <- c(recs,
      "Significant linear trend detected. Models without detrending may underfit."
    )
  }
  if (seasonal) {
    recs <- c(recs, glue::glue(
      "Seasonality detected (strength = {round(seas_strength, 2)}, ",
      "period = {period}). Use a seasonal model (ETS, SARIMA, STL)."
    ))
  }
  if (length(out_idx) > 0L) {
    recs <- c(recs, glue::glue(
      "{length(out_idx)} potential outlier(s) found at index/indices: ",
      "{paste(head(out_idx, 5), collapse = ', ')}",
      "{if (length(out_idx) > 5) ', ...' else ''}. Inspect before modelling."
    ))
  }
  if (length(recs) == 0L) recs <- "No issues detected. Series looks model-ready."

  MiltDiagnosisR6$new(
    series          = series,
    stationarity    = stationarity,
    seasonality     = seasonality,
    trend           = trend,
    gaps            = gaps,
    outliers        = outliers,
    recommendations = recs
  )
}
