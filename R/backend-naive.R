# Naive, Seasonal Naive, and Drift baseline models (no external dependencies)

# ── Naive ─────────────────────────────────────────────────────────────────────

MiltNaive <- R6::R6Class(
  classname = "MiltNaive",
  inherit   = MiltModelBase,

  public = list(
    initialize = function(...) {
      super$initialize(name = "naive", ...)
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      v <- series$values()
      n <- length(v)
      diffs <- diff(v)
      private$.backend_model   <- list(
        last_value = v[[n]],
        sigma      = sqrt(mean(diffs^2, na.rm = TRUE)),
        n          = n
      )
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      bm    <- private$.backend_model
      mu    <- bm$last_value
      sigma <- bm$sigma
      times <- .future_times(private$.training_series, horizon)
      h_seq <- seq_len(horizon)

      pt <- tibble::tibble(time = times, value = rep(mu, horizon))

      # PI: mu ± z * sigma * sqrt(h)
      lower <- upper <- list()
      for (l in level) {
        z  <- stats::qnorm((1 + l / 100) / 2)
        mg <- z * sigma * sqrt(h_seq)
        nm <- as.character(l)
        lower[[nm]] <- tibble::tibble(time = times, value = mu - mg)
        upper[[nm]] <- tibble::tibble(time = times, value = mu + mg)
      }

      samples <- if (!is.null(num_samples)) {
        matrix(
          stats::rnorm(horizon * num_samples, mu, sigma * sqrt(h_seq)),
          nrow = horizon, ncol = num_samples
        )
      } else NULL

      MiltForecastR6$new(
        point_forecast  = pt, lower = lower, upper = upper,
        samples = samples, model_name = "naive", horizon = horizon,
        training_end    = private$.training_series$end_time(),
        training_series = private$.training_series
      )
    },

    predict = function(series = NULL, ...) {
      v <- private$.training_series$values()
      c(NA_real_, v[-length(v)])
    },

    residuals = function(...) {
      v <- private$.training_series$values()
      c(NA_real_, diff(v))
    }
  )
)

# ── Seasonal Naive ────────────────────────────────────────────────────────────

MiltSNaive <- R6::R6Class(
  classname = "MiltSNaive",
  inherit   = MiltModelBase,

  public = list(
    initialize = function(period = NULL, ...) {
      super$initialize(name = "snaive", period = period, ...)
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      p  <- private$.params$period %||%
              as.integer(.freq_label_to_numeric(as.character(series$freq())))
      if (is.na(p) || p <= 1L) {
        milt_abort(
          c(
            "Seasonal Naive requires a seasonal series (period > 1).",
            "i" = "Supply {.arg period} explicitly or use a series with a seasonal frequency."
          ),
          class = "milt_error_invalid_frequency"
        )
      }
      check_series_has_enough_data(series, p + 1L, "snaive")
      v <- series$values()
      n <- length(v)

      # Seasonal differences for sigma
      sdiffs <- v[(p + 1L):n] - v[seq_len(n - p)]
      sigma  <- sqrt(mean(sdiffs^2, na.rm = TRUE))

      private$.backend_model   <- list(
        v     = v,
        n     = n,
        period = as.integer(p),
        sigma  = sigma
      )
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      bm     <- private$.backend_model
      v      <- bm$v
      n      <- bm$n
      period <- bm$period
      sigma  <- bm$sigma
      times  <- .future_times(private$.training_series, horizon)

      # Seasonal index: v[n - period + ((h-1) %% period) + 1]
      point_vals <- vapply(seq_len(horizon), function(h) {
        idx <- n - period + ((h - 1L) %% period) + 1L
        v[[idx]]
      }, numeric(1L))

      pt <- tibble::tibble(time = times, value = point_vals)

      lower <- upper <- list()
      for (l in level) {
        z  <- stats::qnorm((1 + l / 100) / 2)
        k  <- floor((seq_len(horizon) - 1L) / period)   # number of full seasons ahead
        mg <- z * sigma * sqrt(k + 1L)
        nm <- as.character(l)
        lower[[nm]] <- tibble::tibble(time = times, value = point_vals - mg)
        upper[[nm]] <- tibble::tibble(time = times, value = point_vals + mg)
      }

      samples <- if (!is.null(num_samples)) {
        k <- floor((seq_len(horizon) - 1L) / period)
        matrix(
          stats::rnorm(horizon * num_samples, rep(point_vals, num_samples),
                       rep(sigma * sqrt(k + 1L), num_samples)),
          nrow = horizon, ncol = num_samples
        )
      } else NULL

      MiltForecastR6$new(
        point_forecast  = pt, lower = lower, upper = upper,
        samples = samples, model_name = "snaive", horizon = horizon,
        training_end    = private$.training_series$end_time(),
        training_series = private$.training_series
      )
    },

    predict = function(series = NULL, ...) {
      bm     <- private$.backend_model
      v      <- bm$v
      n      <- bm$n
      period <- bm$period
      fitted <- c(rep(NA_real_, period),
                  v[seq_len(n - period)])
      fitted
    },

    residuals = function(...) {
      bm     <- private$.backend_model
      v      <- bm$v
      n      <- bm$n
      period <- bm$period
      fitted <- self$predict()
      v - fitted
    }
  )
)

# ── Drift ─────────────────────────────────────────────────────────────────────

MiltDrift <- R6::R6Class(
  classname = "MiltDrift",
  inherit   = MiltModelBase,

  public = list(
    initialize = function(...) {
      super$initialize(name = "drift", ...)
    },

    fit = function(series, ...) {
      assert_milt_series(series)
      check_series_has_enough_data(series, 3L, "drift")
      v     <- series$values()
      n     <- length(v)
      slope <- (v[[n]] - v[[1L]]) / (n - 1L)

      # Fitted values from drift line
      fitted <- v[[1L]] + (seq_len(n) - 1L) * slope
      resid  <- v - fitted
      sigma  <- sqrt(sum(resid^2, na.rm = TRUE) / max(1L, n - 2L))

      private$.backend_model   <- list(
        last_value = v[[n]],
        slope      = slope,
        sigma      = sigma,
        n          = n
      )
      private$.fitted          <- TRUE
      private$.training_series <- series
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = NULL, future_covariates = NULL, ...) {
      bm    <- private$.backend_model
      mu    <- bm$last_value
      slope <- bm$slope
      sigma <- bm$sigma
      n_tr  <- bm$n
      times <- .future_times(private$.training_series, horizon)
      h_seq <- seq_len(horizon)

      point_vals <- mu + h_seq * slope
      pt <- tibble::tibble(time = times, value = point_vals)

      # PI: Hyndman & Athanasopoulos: se(h) = sigma * sqrt(h*(1 + h/T))
      lower <- upper <- list()
      for (l in level) {
        z  <- stats::qnorm((1 + l / 100) / 2)
        se <- sigma * sqrt(h_seq * (1 + h_seq / n_tr))
        nm <- as.character(l)
        lower[[nm]] <- tibble::tibble(time = times, value = point_vals - z * se)
        upper[[nm]] <- tibble::tibble(time = times, value = point_vals + z * se)
      }

      samples <- if (!is.null(num_samples)) {
        se <- sigma * sqrt(h_seq * (1 + h_seq / n_tr))
        matrix(
          stats::rnorm(horizon * num_samples, rep(point_vals, num_samples),
                       rep(se, num_samples)),
          nrow = horizon, ncol = num_samples
        )
      } else NULL

      MiltForecastR6$new(
        point_forecast  = pt, lower = lower, upper = upper,
        samples = samples, model_name = "drift", horizon = horizon,
        training_end    = private$.training_series$end_time(),
        training_series = private$.training_series
      )
    },

    predict = function(series = NULL, ...) {
      bm <- private$.backend_model
      bm$last_value - (bm$n - seq_len(bm$n)) * bm$slope
    },

    residuals = function(...) {
      private$.training_series$values() - self$predict()
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_naive <- function() {
  register_milt_model("naive",  MiltNaive,
    description = "Naive forecast: repeats last observed value.",
    supports    = list(probabilistic = TRUE))

  register_milt_model("snaive", MiltSNaive,
    description = "Seasonal Naive: repeats last seasonal period.",
    supports    = list(probabilistic = TRUE))

  register_milt_model("drift",  MiltDrift,
    description = "Drift: linear extrapolation from first to last observed value.",
    supports    = list(probabilistic = TRUE))
}
