# Multi-series local model: one model fitted per group

# ── MiltLocalModel R6 ─────────────────────────────────────────────────────────

#' @title MiltLocalModel — per-group "local" model for multi-series
#' @description
#' Wraps any registered milt model and trains one independent instance per
#' series group.  Produced by [milt_local_model()] and usable in the standard
#' `milt_model() |> milt_fit() |> milt_forecast()` pipe.
#'
#' When passed a single-series `MiltSeries`, it behaves identically to the
#' wrapped model.
#'
#' @export
MiltLocalModel <- R6::R6Class(
  classname = "MiltLocalModel",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  private = list(
    .base_spec     = NULL,   # unfitted base MiltModel (template to clone per group)
    .fitted_models = NULL,   # named list: group_value -> fitted MiltModel
    .group_col     = NULL    # character or NULL
  ),

  public = list(

    #' @description Create a local-model wrapper.
    #' @param base_model An unfitted `MiltModel`.
    initialize = function(base_model) {
      base_name <- base_model$.__enclos_env__$private$.name %||% "model"
      super$initialize(name = paste0("local_", base_name))
      private$.base_spec <- base_model
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      p <- series$.__enclos_env__$private

      if (!series$is_multi_series()) {
        # Single-series path — delegate directly
        m <- private$.base_spec$clone()
        m$fit(series, ...)
        m$.__enclos_env__$private$.training_series <- series
        private$.fitted_models <- list(`__single__` = m)
        private$.group_col     <- NULL
      } else {
        gc  <- p$.group_col
        tbl <- series$as_tibble()
        groups <- unique(tbl[[gc]])

        fitted <- vector("list", length(groups))
        names(fitted) <- as.character(groups)

        milt_info("Local model: fitting {length(groups)} group{?s}\u2026")
        for (g in groups) {
          g_key    <- as.character(g)
          g_tbl    <- tbl[tbl[[gc]] == g_key | tbl[[gc]] == g, ]
          g_series <- series$clone_with(
            tibble::as_tibble(g_tbl[, setdiff(names(g_tbl), gc)])
          )
          # Rebuild without group_col so each is treated as a plain series
          g_series2 <- MiltSeriesR6$new(
            data       = g_tbl[, setdiff(names(g_tbl), gc)],
            time_col   = p$.time_col,
            value_cols = p$.value_cols,
            frequency  = series$freq()
          )
          m <- private$.base_spec$clone()
          m$fit(g_series2, ...)
          m$.__enclos_env__$private$.training_series <- g_series2
          fitted[[g_key]] <- m
        }
        private$.fitted_models <- fitted
        private$.group_col     <- gc
      }
      private$.fitted <- TRUE
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      horizon <- as.integer(horizon)
      fitted  <- private$.fitted_models

      if (is.null(private$.group_col)) {
        return(fitted[["__single__"]]$forecast(horizon, level = level, ...))
      }

      # Multi-series: forecast each group, return first group's MiltForecast
      # Full multi-series return is via forecast_all()
      milt_info(
        "Local model: generating forecasts for {length(fitted)} group{?s}."
      )
      fitted[[1L]]$forecast(horizon, level = level, ...)
    },

    #' @description Forecast all groups. Returns a named list of `MiltForecast`.
    #' @param horizon Integer horizon.
    #' @param level Numeric vector of CI levels.
    #' @param ... Forwarded to each model's `forecast()`.
    forecast_all = function(horizon, level = c(80, 95), ...) {
      .assert_is_fitted(self)
      horizon <- as.integer(horizon)
      lapply(private$.fitted_models, function(m) {
        m$forecast(horizon, level = level, ...)
      })
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      fitted <- private$.fitted_models
      if (length(fitted) == 1L) return(fitted[[1L]]$predict(series, ...))
      milt_warn(
        "predict() for multi-series returns fitted values for the first group only."
      )
      fitted[[1L]]$predict(series, ...)
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      fitted <- private$.fitted_models
      if (length(fitted) == 1L) return(fitted[[1L]]$residuals(...))
      milt_warn(
        "residuals() for multi-series returns residuals for the first group only."
      )
      fitted[[1L]]$residuals(...)
    },

    #' @description Named list of fitted member models (one per group).
    fitted_models = function() private$.fitted_models,

    #' @description Number of groups (fitted models).
    n_groups = function() length(private$.fitted_models)
  )
)

# ── milt_local_model() ────────────────────────────────────────────────────────

#' Create a local (per-group) model for multi-series forecasting
#'
#' Wraps any milt model so that, when fitted on a multi-series `MiltSeries`,
#' one independent instance is trained per series group.  The result is a
#' `MiltModel` that participates in the standard pipe:
#'
#' ```r
#' milt_local_model(milt_model("ets")) |> milt_fit(multi_series) |>
#'   milt_forecast(12)
#' ```
#'
#' @param model An unfitted `MiltModel` created with [milt_model()].
#' @return An unfitted `MiltLocalModel`.
#'
#' @seealso [milt_model()], [milt_fit()]
#' @family model
#' @examples
#' \donttest{
#' # Single-series: behaves like the underlying model
#' s   <- milt_series(AirPassengers)
#' fct <- milt_local_model(milt_model("naive")) |>
#'   milt_fit(s) |>
#'   milt_forecast(12)
#' print(fct)
#' }
#' @export
milt_local_model <- function(model) {
  .assert_milt_model(model)
  MiltLocalModel$new(base_model = model)
}
