# Prophet backend (requires prophet package)
#
# Wraps Facebook Prophet for trend + seasonality decomposition.
# Converts MiltSeries times to Date and formats as Prophet's ds/y columns.

#' @keywords internal
#' @noRd
MiltProphet <- R6::R6Class(
  classname = "MiltProphet",
  inherit   = MiltModelBase,
  cloneable = TRUE,

  public = list(

    #' @param yearly_seasonality Logical or `"auto"`. Default `"auto"`.
    #' @param weekly_seasonality Logical or `"auto"`. Default `"auto"`.
    #' @param daily_seasonality  Logical or `"auto"`. Default `"auto"`.
    #' @param seasonality_mode  Character. `"additive"` (default) or
    #'   `"multiplicative"`.
    #' @param changepoint_prior_scale Numeric. Flexibility of the trend.
    #'   Default `0.05`.
    #' @param ... Additional arguments forwarded to `prophet::prophet()`.
    initialize = function(yearly_seasonality      = "auto",
                          weekly_seasonality      = "auto",
                          daily_seasonality       = "auto",
                          seasonality_mode        = "additive",
                          changepoint_prior_scale = 0.05,
                          ...) {
      super$initialize(
        name                    = "prophet",
        yearly_seasonality      = yearly_seasonality,
        weekly_seasonality      = weekly_seasonality,
        daily_seasonality       = daily_seasonality,
        seasonality_mode        = seasonality_mode,
        changepoint_prior_scale = as.numeric(changepoint_prior_scale),
        ...
      )
    },

    fit = function(series) {
      check_installed_backend("prophet", "prophet")
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort("Prophet requires a univariate {.cls MiltSeries}.",
                   class = "milt_error_not_univariate")
      }

      p <- private$.params

      # Prophet expects a data.frame with ds (datetime) and y columns
      tbl <- series$as_tibble()
      val_col  <- series$.__enclos_env__$private$.value_cols[[1L]]
      time_col <- series$.__enclos_env__$private$.time_col

      df <- data.frame(
        ds = as.POSIXct(tbl[[time_col]]),
        y  = as.numeric(tbl[[val_col]])
      )

      m <- prophet::prophet(
        yearly.seasonality      = p$yearly_seasonality,
        weekly.seasonality      = p$weekly_seasonality,
        daily.seasonality       = p$daily_seasonality,
        seasonality.mode        = p$seasonality_mode,
        changepoint.prior.scale = p$changepoint_prior_scale
      )

      suppressMessages(
        private$.backend_model <- prophet::fit.prophet(m, df)
      )
      private$.train_df <- df
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), ...) {
      m   <- private$.backend_model
      ts  <- private$.training_series

      future_df <- prophet::make_future_dataframe(
        m,
        periods = as.integer(horizon),
        freq    = .prophet_freq(ts)
      )

      pred <- predict(m, future_df)

      # Last `horizon` rows are the actual forecast
      pred_fc  <- utils::tail(pred, horizon)
      times    <- .future_times(ts, horizon)
      pt_vals  <- as.numeric(pred_fc$yhat)

      pt_tbl <- tibble::tibble(time = times, value = pt_vals)

      # Prophet gives yhat_lower / yhat_upper (80% interval by default)
      # We approximate 95% from the prophet uncertainty using a scale factor
      pi_80 <- list(
        lower = tibble::tibble(time = times, value = as.numeric(pred_fc$yhat_lower)),
        upper = tibble::tibble(time = times, value = as.numeric(pred_fc$yhat_upper))
      )
      # Crude 95% approximation: stretch interval by 1.96/1.28
      scale <- stats::qnorm(0.975) / stats::qnorm(0.9)
      mid   <- pt_vals
      half_80 <- (pi_80$upper$value - pi_80$lower$value) / 2
      pi_95 <- list(
        lower = tibble::tibble(time = times, value = mid - scale * half_80),
        upper = tibble::tibble(time = times, value = mid + scale * half_80)
      )

      lower <- list("80" = pi_80$lower, "95" = pi_95$lower)
      upper <- list("80" = pi_80$upper, "95" = pi_95$upper)

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = lower,
        upper           = upper,
        model_name      = "prophet",
        horizon         = as.integer(horizon),
        training_end    = ts$end_time(),
        training_series = ts
      )
    },

    predict = function(series = NULL) {
      df   <- private$.train_df
      pred <- predict(private$.backend_model, df)
      as.numeric(pred$yhat)
    },

    residuals = function() {
      fitted <- self$predict()
      as.numeric(private$.train_df$y) - fitted
    }
  ),

  private = list(
    .train_df = NULL
  )
)

# Map MiltSeries frequency string to Prophet freq string
.prophet_freq <- function(series) {
  freq <- series$freq()
  if (is.character(freq)) {
    switch(tolower(freq),
      "daily"   = "day",
      "weekly"  = "week",
      "monthly" = "month",
      "quarterly" = "quarter",
      "annual"  = "year",
      "hourly"  = "hour",
      "day"     # default
    )
  } else {
    # numeric frequency: map period to string
    switch(as.character(round(freq)),
      "365" = "day",
      "52"  = "week",
      "12"  = "month",
      "4"   = "quarter",
      "1"   = "year",
      "day"
    )
  }
}

.onLoad_prophet <- function() {
  register_milt_model(
    name        = "prophet",
    class       = MiltProphet,
    description = "Facebook Prophet for trend + seasonality decomposition",
    supports    = list(
      multivariate  = FALSE,
      probabilistic = TRUE,
      covariates    = FALSE,
      multi_series  = FALSE
    )
  )
}
