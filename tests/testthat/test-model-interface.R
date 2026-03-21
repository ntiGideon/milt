# ── Mock backend ──────────────────────────────────────────────────────────────
# A minimal, self-contained backend used to exercise the framework without
# requiring a real statistical engine.

MockBackend <- R6::R6Class(
  classname = "MockModel",
  inherit   = MiltModelBase,

  public = list(
    initialize = function(constant = 0, ...) {
      super$initialize(name = "mock", constant = constant, ...)
    },

    fit = function(series, ...) {
      private$.fitted          <- TRUE
      private$.training_series <- series
      private$.backend_model   <- list(mean = mean(series$values(), na.rm = TRUE))
      invisible(self)
    },

    forecast = function(horizon, level = c(80, 95), num_samples = NULL, ...) {
      mu      <- private$.backend_model$mean + private$.params$constant
      tc      <- private$.training_series$.__enclos_env__$private$.time_col
      end_t   <- private$.training_series$end_time()
      times   <- seq(end_t, by = "month", length.out = horizon + 1L)[-1L]

      pt      <- tibble::tibble(time = times, value = rep(mu, horizon))

      lower <- stats::setNames(lapply(level, function(l) {
        tibble::tibble(time = times, value = rep(mu - l / 10, horizon))
      }), as.character(level))
      upper <- stats::setNames(lapply(level, function(l) {
        tibble::tibble(time = times, value = rep(mu + l / 10, horizon))
      }), as.character(level))

      samples <- if (!is.null(num_samples)) {
        matrix(rnorm(horizon * num_samples, mu), nrow = horizon, ncol = num_samples)
      } else NULL

      MiltForecastR6$new(
        point_forecast  = pt,
        lower           = lower,
        upper           = upper,
        samples         = samples,
        model_name      = "mock",
        horizon         = horizon,
        training_end    = end_t,
        training_series = private$.training_series
      )
    },

    predict = function(series = NULL, ...) {
      rep(private$.backend_model$mean, private$.training_series$n_timesteps())
    },

    residuals = function(...) {
      private$.training_series$values() - private$.backend_model$mean
    }
  )
)

# Register the mock so milt_model("mock") works
register_milt_model(
  "mock",
  MockBackend,
  description = "Mock backend for testing",
  supports    = list(probabilistic = TRUE)
)

# ── Shared fixtures ───────────────────────────────────────────────────────────

make_fitted_mock <- function(n = 60) {
  s <- milt_series(AirPassengers)[seq_len(n)]
  milt_model("mock") |> milt_fit(s)
}

# ── MiltModelBase & print ─────────────────────────────────────────────────────

test_that("MiltModelBase$new() creates a MiltModel", {
  m <- MiltModelBase$new(name = "base_test")
  expect_s3_class(m, "MiltModel")
})

test_that("is_fitted() is FALSE before fitting", {
  m <- MiltModelBase$new(name = "test")
  expect_false(m$is_fitted())
})

test_that("get_params() returns constructor params", {
  m <- MiltModelBase$new(name = "test", lags = 12, depth = 3)
  params <- m$get_params()
  expect_equal(params$lags,  12)
  expect_equal(params$depth,  3)
})

test_that("print.MiltModel outputs model name and status", {
  m <- MiltModelBase$new(name = "test_print")
  expect_output(print(m), "test_print")
  expect_output(print(m), "unfitted")
})

test_that("print.MiltModel shows 'fitted' after fitting", {
  m <- make_fitted_mock()
  expect_output(print(m), "fitted")
})

test_that("format.MiltModel returns a string", {
  m <- MiltModelBase$new(name = "fmt_test")
  expect_type(format(m), "character")
  expect_match(format(m), "MiltModel")
})

# ── milt_model ────────────────────────────────────────────────────────────────

test_that("milt_model() returns an unfitted MiltModel", {
  m <- milt_model("mock")
  expect_s3_class(m, "MiltModel")
  expect_false(m$is_fitted())
})

test_that("milt_model() passes hyperparameters to the backend", {
  m <- milt_model("mock", constant = 5)
  expect_equal(m$get_params()$constant, 5)
})

test_that("milt_model() errors for unregistered model", {
  expect_error(milt_model("totally_fake_model_xyz"),
               class = "milt_error_unknown_model")
})

test_that("milt_model() errors on non-string name", {
  expect_error(milt_model(42), class = "milt_error_invalid_arg")
})

# ── milt_fit ──────────────────────────────────────────────────────────────────

test_that("milt_fit() returns the model invisibly", {
  s <- milt_series(AirPassengers)[1:60]
  m <- milt_model("mock")
  expect_invisible(milt_fit(m, s))
})

test_that("milt_fit() sets is_fitted() to TRUE", {
  s <- milt_series(AirPassengers)[1:60]
  m <- milt_model("mock") |> milt_fit(s)
  expect_true(m$is_fitted())
})

test_that("milt_fit() errors on non-MiltModel input", {
  s <- milt_series(AirPassengers)
  expect_error(milt_fit(list(), s), class = "milt_error_not_milt_model")
})

test_that("milt_fit() errors on non-MiltSeries series", {
  m <- milt_model("mock")
  expect_error(milt_fit(m, AirPassengers), class = "milt_error_not_milt_series")
})

test_that("milt_fit() errors when series has gaps", {
  s   <- milt_series(AirPassengers)
  tbl <- s$as_tibble()[-10, ]
  s_g <- milt_series(tbl, time_col = "time", value_cols = "value",
                     frequency = "monthly")
  m   <- milt_model("mock")
  expect_error(milt_fit(m, s_g), class = "milt_error_has_gaps")
})

test_that("milt_fit() records fit time", {
  m <- make_fitted_mock()
  ft <- m$.__enclos_env__$private$.fit_time
  expect_true(!is.null(ft))
  expect_true(as.numeric(ft) >= 0)
})

# ── milt_forecast ─────────────────────────────────────────────────────────────

test_that("milt_forecast() returns a MiltForecast", {
  m   <- make_fitted_mock()
  fct <- milt_forecast(m, horizon = 12)
  expect_s3_class(fct, "MiltForecast")
})

test_that("milt_forecast() horizon matches requested value", {
  m   <- make_fitted_mock()
  fct <- milt_forecast(m, horizon = 24)
  expect_equal(fct$horizon(), 24L)
})

test_that("milt_forecast() errors on unfitted model", {
  m <- milt_model("mock")
  expect_error(milt_forecast(m, horizon = 12), class = "milt_error_not_fitted")
})

test_that("milt_forecast() errors on non-positive horizon", {
  m <- make_fitted_mock()
  expect_error(milt_forecast(m, horizon = 0),  class = "milt_error_invalid_integer")
  expect_error(milt_forecast(m, horizon = -1), class = "milt_error_invalid_integer")
})

test_that("milt_forecast() errors on non-MiltModel", {
  expect_error(milt_forecast(list(), horizon = 5), class = "milt_error_not_milt_model")
})

test_that("milt_forecast() generates samples when num_samples is set", {
  m   <- make_fitted_mock()
  fct <- milt_forecast(m, horizon = 6, num_samples = 50)
  expect_true(fct$has_samples())
})

# ── milt_predict ──────────────────────────────────────────────────────────────

test_that("milt_predict() returns a numeric vector", {
  m   <- make_fitted_mock()
  prd <- milt_predict(m)
  expect_type(prd, "double")
})

test_that("milt_predict() returns same length as training series", {
  s   <- milt_series(AirPassengers)[1:60]
  m   <- milt_model("mock") |> milt_fit(s)
  prd <- milt_predict(m)
  expect_length(prd, 60L)
})

test_that("milt_predict() errors on unfitted model", {
  expect_error(milt_predict(milt_model("mock")), class = "milt_error_not_fitted")
})

# ── milt_residuals ────────────────────────────────────────────────────────────

test_that("milt_residuals() returns a numeric vector", {
  m <- make_fitted_mock()
  r <- milt_residuals(m)
  expect_type(r, "double")
})

test_that("milt_residuals() has correct length", {
  s <- milt_series(AirPassengers)[1:60]
  m <- milt_model("mock") |> milt_fit(s)
  expect_length(milt_residuals(m), 60L)
})

test_that("milt_residuals() errors on unfitted model", {
  expect_error(milt_residuals(milt_model("mock")), class = "milt_error_not_fitted")
})

# ── milt_refit ────────────────────────────────────────────────────────────────

test_that("milt_refit() works on a new series", {
  s1 <- milt_series(AirPassengers)[1:60]
  s2 <- milt_series(AirPassengers)[61:120]
  m  <- milt_model("mock") |> milt_fit(s1)
  expect_invisible(milt_refit(m, s2))
  expect_equal(
    m$.__enclos_env__$private$.training_series$start_time(),
    s2$start_time()
  )
})

# ── End-to-end pipe ───────────────────────────────────────────────────────────

test_that("milt_model |> milt_fit |> milt_forecast pipeline works", {
  s   <- milt_series(AirPassengers)
  fct <- milt_model("mock") |> milt_fit(s) |> milt_forecast(horizon = 12)
  expect_s3_class(fct, "MiltForecast")
  expect_equal(fct$horizon(), 12L)
})
