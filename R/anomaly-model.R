# Anomaly detection via forecast residuals — "fit a forecasting model on
# normal data, then flag deviations from its own prediction." Mirrors darts'
# ForecastingAnomalyModel: a Scorer turns (actual, fitted) into a continuous
# anomaly score, and a threshold ("detector") turns that score into a binary
# flag. Reuses the existing MiltAnomalies result class, so all of its
# print/plot/as_tibble methods work automatically on the output.

# ── Scorer ─────────────────────────────────────────────────────────────────────

#' Compute a per-timestep anomaly score from residuals
#'
#' Turns a vector of forecast residuals (actual minus fitted/predicted) into a
#' continuous anomaly score, where a larger value means "more anomalous".
#'
#' @param residuals Numeric vector of residuals (e.g. from [milt_residuals()]).
#' @param method Character. One of:
#'   - `"norm"` (default): absolute residual, `abs(residuals)`.
#'   - `"difference"`: the signed residual itself (useful for
#'     [milt_check_seasonality()]-style directional analysis).
#'   - `"nll_gaussian"`: negative log-likelihood of each residual under a
#'     Gaussian fit to the whole residual distribution — penalises residuals
#'     that are unlikely even relative to the model's own typical error.
#' @return A numeric vector the same length as `residuals` (with `NA`
#'   preserved where `residuals` is `NA`).
#' @seealso [milt_anomaly_model()]
#' @family anomaly
#' @examples
#' s   <- milt_series(AirPassengers)
#' m   <- milt_model("naive") |> milt_fit(s)
#' milt_anomaly_score(milt_residuals(m), method = "norm")
#' @export
milt_anomaly_score <- function(residuals, method = c("norm", "difference", "nll_gaussian")) {
  if (!is.numeric(residuals)) {
    milt_abort("{.arg residuals} must be a numeric vector.",
               class = "milt_error_invalid_metric_input")
  }
  method <- match.arg(method)
  switch(
    method,
    norm         = abs(residuals),
    difference   = residuals,
    nll_gaussian = {
      mu    <- mean(residuals, na.rm = TRUE)
      sigma <- stats::sd(residuals, na.rm = TRUE)
      if (is.na(sigma) || sigma < 1e-8) sigma <- 1e-8
      -stats::dnorm(residuals, mean = mu, sd = sigma, log = TRUE)
    }
  )
}

# Fit a threshold from an in-sample score distribution.
.anomaly_threshold <- function(scores, method, quantile, low, high) {
  if (method == "quantile") {
    list(low = -Inf, high = stats::quantile(scores, quantile, na.rm = TRUE, names = FALSE))
  } else {
    list(low = low %||% -Inf, high = high %||% Inf)
  }
}

# ── MiltAnomalyModel ───────────────────────────────────────────────────────────

#' @title MiltAnomalyModel — flag anomalies via forecast residuals
#' @description
#' Wraps any `MiltModel` with a [milt_anomaly_score()] scorer and a threshold
#' ("detector"), fit entirely from the wrapped model's in-sample residuals.
#' Produced by [milt_anomaly_model()].
#' @keywords internal
#' @noRd
MiltAnomalyModel <- R6::R6Class(
  classname = "MiltAnomalyModel",
  inherit   = MiltModelBase,

  private = list(
    .base_model = NULL,  # the wrapped (cloned) MiltModel
    .scores     = NULL,  # in-sample anomaly scores
    .threshold  = NULL   # list(low =, high =)
  ),

  public = list(

    initialize = function(model, scorer = "norm", detector = "quantile",
                          quantile = 0.95, low = NULL, high = NULL, ...) {
      base_name <- model$.__enclos_env__$private$.name %||% "model"
      super$initialize(
        name = paste0("anomaly_", base_name), scorer = scorer, detector = detector,
        quantile = quantile, low = low, high = high, ...
      )
      private$.base_model <- model$clone()
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      p <- private$.params
      m <- private$.base_model
      m$fit(series, ...)
      m$.__enclos_env__$private$.fitted          <- TRUE
      m$.__enclos_env__$private$.training_series <- series

      resid  <- m$residuals()
      scores <- milt_anomaly_score(resid, method = p$scorer)
      thr    <- .anomaly_threshold(scores, p$detector, p$quantile, p$low, p$high)

      private$.base_model      <- m
      private$.scores          <- scores
      private$.threshold       <- thr
      private$.training_series <- series
      invisible(self)
    },

    #' @description Flag in-sample anomalies as a `MiltAnomalies` object.
    detect = function() {
      .assert_is_fitted(self)
      scores  <- private$.scores
      thr     <- private$.threshold
      is_anom <- (scores < thr$low) | (scores > thr$high)
      is_anom[is.na(is_anom)] <- FALSE

      base_name <- private$.base_model$.__enclos_env__$private$.name %||% "model"
      .new_milt_anomalies(
        series        = private$.training_series,
        is_anomaly    = is_anom,
        anomaly_score = ifelse(is.na(scores), 0, scores),
        method        = paste0(base_name, "+", private$.params$scorer)
      )
    },

    #' @description The wrapped, fitted `MiltModel`.
    model = function() private$.base_model,

    #' @description In-sample anomaly scores.
    scores = function() private$.scores,

    forecast = function(horizon, ...) private$.base_model$forecast(horizon, ...),
    predict  = function(series = NULL, ...) private$.base_model$predict(series, ...),
    residuals = function(...) private$.base_model$residuals(...)
  )
)

#' Wrap a model with residual-based anomaly detection
#'
#' Fits `model` on a series, scores its in-sample residuals with
#' [milt_anomaly_score()], and fits a threshold from that score distribution —
#' "flag the points where my own model's prediction was most wrong." Mirrors
#' darts' `ForecastingAnomalyModel`.
#'
#' @param model An unfitted `MiltModel` (created with [milt_model()]). Cloned
#'   internally; the object passed in is not modified.
#' @param scorer Character. Passed to [milt_anomaly_score()]: `"norm"`
#'   (default), `"difference"`, or `"nll_gaussian"`.
#' @param detector Character. `"quantile"` (default): threshold at the
#'   `quantile` quantile of in-sample scores. `"threshold"`: use explicit
#'   `low`/`high` bounds.
#' @param quantile Numeric in `(0, 1)`. Used when `detector = "quantile"`.
#'   Default `0.95`.
#' @param low,high Numeric bounds used when `detector = "threshold"`.
#' @param ... Additional arguments forwarded to `model$fit()`.
#' @return An unfitted `MiltModel`. Fit it with [milt_fit()], then call
#'   [milt_detect_anomalies()] to get a `MiltAnomalies` result.
#' @seealso [milt_detect_anomalies()], [milt_anomaly_score()],
#'   [milt_detector()]
#' @family anomaly
#' @examples
#' \donttest{
#' s  <- milt_series(AirPassengers)
#' am <- milt_anomaly_model(milt_model("naive"), scorer = "norm") |> milt_fit(s)
#' anoms <- milt_detect_anomalies(am)
#' plot(anoms)
#' }
#' @export
milt_anomaly_model <- function(model,
                                scorer   = c("norm", "difference", "nll_gaussian"),
                                detector = c("quantile", "threshold"),
                                quantile = 0.95,
                                low      = NULL,
                                high     = NULL,
                                ...) {
  .assert_milt_model(model)
  scorer   <- match.arg(scorer)
  detector <- match.arg(detector)
  if (detector == "quantile" && (!is_scalar_numeric(quantile) || quantile <= 0 || quantile >= 1)) {
    milt_abort("{.arg quantile} must be a number strictly between 0 and 1.",
               class = "milt_error_invalid_arg")
  }
  MiltAnomalyModel$new(
    model = model, scorer = scorer, detector = detector,
    quantile = quantile, low = low, high = high, ...
  )
}

#' Detect anomalies from a fitted MiltAnomalyModel
#'
#' @param model A fitted `MiltAnomalyModel`, created by [milt_anomaly_model()]
#'   and fit with [milt_fit()].
#' @return A `MiltAnomalies` object.
#' @seealso [milt_anomaly_model()]
#' @family anomaly
#' @export
milt_detect_anomalies <- function(model) {
  if (!inherits(model, "MiltAnomalyModel")) {
    milt_abort(
      "{.arg model} must be a {.cls MiltAnomalyModel} created by {.fn milt_anomaly_model}.",
      class = "milt_error_invalid_arg"
    )
  }
  model$detect()
}
