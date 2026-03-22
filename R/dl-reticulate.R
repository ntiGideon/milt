# Reticulate bridge to Python Darts (Step 3.3)
#
# Provides a transparent milt_model() | milt_fit() | milt_forecast() interface
# to any Python Darts model via `reticulate`.  Useful for models not yet
# natively ported to torch-for-R.
#
# Setup: call milt_setup_darts() once per session (or per R process) to verify
# the Python environment and optionally install the `darts` package.

# ── Setup / verification ───────────────────────────────────────────────────────

#' Set up the Python Darts environment
#'
#' Verifies that Python and the `darts` package are available via
#' `reticulate`.  Optionally installs `darts` with `pip` when it is missing.
#' Call this once per session before using any `darts_*` model.
#'
#' @param install Logical. When `TRUE`, attempts `reticulate::py_install("darts")`
#'   if the package is not found. Default `FALSE`.
#' @return Invisible `NULL`.
#' @seealso [milt_model()], [list_milt_models()]
#' @family dl
#' @examples
#' \donttest{
#' milt_setup_darts()                      # check only
#' milt_setup_darts(install = TRUE)        # check + install if missing
#' }
#' @export
milt_setup_darts <- function(install = FALSE) {
  check_installed_backend("reticulate", "darts")

  if (!reticulate::py_available(initialize = TRUE)) {
    milt_abort(
      c(
        "No Python installation found.",
        "i" = "Install Python (>= 3.9) and point reticulate to it with",
        "i" = "{.code reticulate::use_python('/path/to/python')}.",
        "i" = "Then run: {.code pip install darts}"
      ),
      class = "milt_error_no_python"
    )
  }

  darts_ok <- tryCatch({
    reticulate::import("darts")
    TRUE
  }, error = function(e) FALSE)

  if (!darts_ok) {
    if (install) {
      milt_info("Installing Python {.pkg darts} \u2014 this may take a few minutes \u2026")
      reticulate::py_install("darts", pip = TRUE)
      milt_info("{.pkg darts} installed successfully.")
    } else {
      milt_abort(
        c(
          "The Python {.pkg darts} package is not installed.",
          "i" = "Run {.code milt_setup_darts(install = TRUE)} to install it automatically.",
          "i" = "Or manually from a terminal: {.code pip install darts}"
        ),
        class = "milt_error_no_darts"
      )
    }
  } else {
    darts  <- reticulate::import("darts")
    ver    <- tryCatch(darts[["__version__"]], error = function(e) "unknown")
    milt_info("Python {.pkg darts} {ver} is ready.")
  }
  invisible(NULL)
}

# Internal guard — called at the start of every Darts backend method.
.check_darts_available <- function() {
  check_installed_backend("reticulate", "darts (Darts bridge)")
  if (!reticulate::py_available(initialize = FALSE)) {
    milt_abort(
      c(
        "Python is not initialised in this session.",
        "i" = "Call {.fn milt_setup_darts} before using any {.code darts_*} model."
      ),
      class = "milt_error_no_python"
    )
  }
  tryCatch(
    reticulate::import("darts"),
    error = function(e) {
      milt_abort(
        c(
          "Cannot import Python {.pkg darts}.",
          "i" = "Run {.code milt_setup_darts(install = TRUE)} to install it."
        ),
        class = "milt_error_no_darts"
      )
    }
  )
}

# ── Conversion helpers ────────────────────────────────────────────────────────

# Convert a MiltSeries (univariate) to a Python Darts TimeSeries.
# Route: MiltSeries → stats::ts → pandas.Series (DatetimeIndex) → darts.TimeSeries
.milt_series_to_darts <- function(series) {
  ts_obj <- series$as_ts()
  freq   <- stats::frequency(ts_obj)
  start  <- stats::start(ts_obj)
  vals   <- as.numeric(ts_obj)

  pd         <- reticulate::import("pandas")
  darts_mod  <- reticulate::import("darts")
  start_date <- .darts_ts_start_to_date(start, freq)
  pd_freq    <- .darts_freq_to_pandas(freq)

  idx <- pd$date_range(
    start   = format(start_date, "%Y-%m-%d"),
    periods = reticulate::r_to_py(as.integer(length(vals))),
    freq    = pd_freq
  )
  s <- pd$Series(
    data  = reticulate::r_to_py(vals),
    index = idx
  )
  darts_mod$TimeSeries$from_series(s)
}

# Extract a 3-D R array from a Darts TimeSeries.
# Shape: [n_time, n_components, n_samples].
# For deterministic (1 sample) output: [horizon, 1, 1].
.darts_to_r_array <- function(darts_ts) {
  arr_py <- darts_ts$all_values()   # numpy ndarray (time, components, samples)
  reticulate::py_to_r(arr_py)
}

# Map a stats::ts start + frequency to a Date.
.darts_ts_start_to_date <- function(start, freq) {
  year  <- start[1L]
  cycle <- if (length(start) > 1L) start[2L] else 1L
  if (freq == 12L) {
    as.Date(paste0(year, "-", sprintf("%02d", cycle), "-01"))
  } else if (freq == 4L) {
    month <- (cycle - 1L) * 3L + 1L
    as.Date(paste0(year, "-", sprintf("%02d", month), "-01"))
  } else if (freq == 52L) {
    as.Date(paste0(year, "-01-01")) + (cycle - 1L) * 7L
  } else if (freq == 1L) {
    as.Date(paste0(year, "-01-01"))
  } else {
    as.Date(paste0(year, "-01-01")) + as.integer(cycle - 1L)
  }
}

# Map a stats::ts frequency integer to a pandas offset alias.
.darts_freq_to_pandas <- function(freq) {
  switch(as.character(as.integer(freq)),
    "12"  = "MS",    # Month Start
    "4"   = "QS",    # Quarter Start
    "52"  = "W",     # Weekly
    "1"   = "YS",    # Annual
    "365" = "D",     # Daily
    "24"  = "h",     # Hourly
    "D"              # fallback
  )
}

# ── Generic MiltDartsModel base class ─────────────────────────────────────────

#' @keywords internal
#' @noRd
MiltDartsModel <- R6::R6Class(
  classname = "MiltDartsModel",
  inherit   = MiltModelBase,
  cloneable = FALSE,   # Python objects are not safely R-cloneable

  private = list(
    .darts_model  = NULL,   # Python Darts model instance
    .model_class  = NULL    # Darts model class name string
  ),

  public = list(

    #' @param name Character. The milt model identifier (e.g. `"darts_rnn"`).
    #' @param model_class Character. The Darts Python class name
    #'   (e.g. `"RNNModel"`).
    #' @param ... Hyperparameters forwarded verbatim to the Darts constructor.
    initialize = function(name, model_class, ...) {
      private$.model_class <- model_class
      super$initialize(name = name, ...)
    },

    fit = function(series, ...) {
      .check_darts_available()
      assert_milt_series(series)
      if (!series$is_univariate()) {
        milt_abort(
          "Darts models currently require a univariate {.cls MiltSeries}.",
          class = "milt_error_not_univariate"
        )
      }

      # Convert to Darts TimeSeries
      darts_ts <- .milt_series_to_darts(series)

      # Instantiate the Darts model class with stored hyperparameters
      darts_models <- reticulate::import("darts.models")
      model_cls    <- darts_models[[private$.model_class]]
      if (is.null(model_cls)) {
        milt_abort(
          c(
            "Darts model class {.val {private$.model_class}} not found.",
            "i" = "Check {.url https://unit8co.github.io/darts/generated_api/darts.models.html} for valid class names."
          ),
          class = "milt_error_invalid_model_class"
        )
      }

      # Build Python kwargs from stored params
      py_kwargs <- reticulate::r_to_py(private$.params)
      py_model  <- do.call(model_cls, private$.params)

      milt_info("Fitting Darts {.cls {private$.model_class}} via reticulate \u2026")
      py_model$fit(darts_ts)

      private$.darts_model <- py_model
      private$.fitted      <- TRUE
    },

    forecast = function(horizon, level = c(80, 95),
                        num_samples = 500L,
                        future_covariates = NULL, ...) {
      .assert_is_fitted(self)
      horizon     <- as.integer(horizon)
      num_samples <- as.integer(num_samples %||% 500L)

      pred_ts <- private$.darts_model$predict(
        n           = reticulate::r_to_py(horizon),
        num_samples = reticulate::r_to_py(num_samples)
      )

      # vals: [horizon, 1, num_samples] array
      vals <- .darts_to_r_array(pred_ts)
      # Point forecast = sample mean across 3rd dimension
      pt_vals <- apply(vals[, 1L, , drop = FALSE], 1L, mean)

      training_series <- private$.training_series
      times  <- .future_times(training_series, horizon)
      pt_tbl <- tibble::tibble(time = times, value = pt_vals)

      # Quantile-based prediction intervals
      .pi_bounds <- function(q_lo, q_hi) {
        list(
          lower = tibble::tibble(
            time  = times,
            value = apply(vals[, 1L, , drop = FALSE], 1L,
                          stats::quantile, probs = q_lo)
          ),
          upper = tibble::tibble(
            time  = times,
            value = apply(vals[, 1L, , drop = FALSE], 1L,
                          stats::quantile, probs = q_hi)
          )
        )
      }
      pi80 <- .pi_bounds(0.10, 0.90)
      pi95 <- .pi_bounds(0.025, 0.975)

      MiltForecastR6$new(
        point_forecast  = pt_tbl,
        lower           = list("80" = pi80$lower, "95" = pi95$lower),
        upper           = list("80" = pi80$upper, "95" = pi95$upper),
        model_name      = private$.name,
        horizon         = horizon,
        training_end    = training_series$end_time(),
        training_series = training_series
      )
    },

    predict = function(series = NULL, ...) {
      .assert_is_fitted(self)
      # Darts historical_forecasts() requires retraining per window, which is
      # expensive.  Return NAs with a warning and point users to milt_forecast().
      milt_warn(
        c(
          "In-sample {.fn predict} is not supported for Darts-backed models.",
          "i" = "Use {.fn milt_forecast} on a held-out test set instead."
        )
      )
      rep(NA_real_, length(private$.training_series$values()))
    },

    residuals = function(...) {
      .assert_is_fitted(self)
      milt_warn(
        c(
          "Residuals are not available for Darts-backed models.",
          "i" = "Evaluate forecast quality with {.fn milt_accuracy} or {.fn milt_backtest}."
        )
      )
      rep(NA_real_, length(private$.training_series$values()))
    }
  )
)

# ── Registered Darts-backed models ────────────────────────────────────────────
# Add one R6 subclass here per Darts model to be exposed to users.
# Users call: milt_model("darts_rnn", hidden_dim = 128L, n_epochs = 50L)

#' Darts RNN model (LSTM / GRU)
#'
#' Wraps Darts' `RNNModel` via `reticulate`.  Requires Python and the `darts`
#' package; call [milt_setup_darts()] first.
#'
#' @param model Character. RNN cell type: `"LSTM"` (default) or `"GRU"`.
#' @param hidden_dim Integer. Hidden size. Default `64L`.
#' @param n_rnn_layers Integer. Number of recurrent layers. Default `2L`.
#' @param input_chunk_length Integer. Lookback window. Default `24L`.
#' @param training_length Integer. Length of sequences used in training.
#'   Must be `> input_chunk_length`. Default `36L`.
#' @param n_epochs Integer. Training epochs. Default `100L`.
#' @param ... Further arguments passed to `darts.models.RNNModel`.
#' @keywords internal
#' @noRd
MiltDartsRNN <- R6::R6Class(
  classname = "MiltDartsRNN",
  inherit   = MiltDartsModel,
  cloneable = FALSE,
  public = list(
    initialize = function(model             = "LSTM",
                          hidden_dim        = 64L,
                          n_rnn_layers      = 2L,
                          input_chunk_length = 24L,
                          training_length   = 36L,
                          n_epochs          = 100L,
                          ...) {
      super$initialize(
        name               = "darts_rnn",
        model_class        = "RNNModel",
        model              = model,
        hidden_dim         = as.integer(hidden_dim),
        n_rnn_layers       = as.integer(n_rnn_layers),
        input_chunk_length = as.integer(input_chunk_length),
        training_length    = as.integer(training_length),
        n_epochs           = as.integer(n_epochs),
        ...
      )
    }
  )
)

#' Darts Transformer model
#'
#' Wraps Darts' `TransformerModel` via `reticulate`.  Requires Python and the
#' `darts` package; call [milt_setup_darts()] first.
#'
#' @param input_chunk_length Integer. Encoder lookback. Default `24L`.
#' @param output_chunk_length Integer. Decoder output length. Default `12L`.
#' @param d_model Integer. Model dimension. Default `64L`.
#' @param nhead Integer. Attention heads. Default `4L`.
#' @param num_encoder_layers Integer. Encoder depth. Default `2L`.
#' @param num_decoder_layers Integer. Decoder depth. Default `2L`.
#' @param n_epochs Integer. Training epochs. Default `100L`.
#' @param ... Further arguments passed to `darts.models.TransformerModel`.
#' @keywords internal
#' @noRd
MiltDartsTransformer <- R6::R6Class(
  classname = "MiltDartsTransformer",
  inherit   = MiltDartsModel,
  cloneable = FALSE,
  public = list(
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          d_model             = 64L,
                          nhead               = 4L,
                          num_encoder_layers  = 2L,
                          num_decoder_layers  = 2L,
                          n_epochs            = 100L,
                          ...) {
      super$initialize(
        name                = "darts_transformer",
        model_class         = "TransformerModel",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        d_model             = as.integer(d_model),
        nhead               = as.integer(nhead),
        num_encoder_layers  = as.integer(num_encoder_layers),
        num_decoder_layers  = as.integer(num_decoder_layers),
        n_epochs            = as.integer(n_epochs),
        ...
      )
    }
  )
)

#' Darts N-BEATS model (Darts implementation)
#'
#' Wraps Darts' `NBEATSModel` via `reticulate`.  Useful as a cross-check
#' against the native torch-for-R `"nbeats"` backend.  Requires Python and
#' the `darts` package; call [milt_setup_darts()] first.
#'
#' @param input_chunk_length Integer. Lookback window. Default `24L`.
#' @param output_chunk_length Integer. Forecast horizon per pass. Default `12L`.
#' @param num_stacks Integer. Number of stacks. Default `30L`.
#' @param num_blocks Integer. Blocks per stack. Default `1L`.
#' @param num_layers Integer. FC depth per block. Default `4L`.
#' @param layer_widths Integer. FC layer width. Default `256L`.
#' @param n_epochs Integer. Training epochs. Default `100L`.
#' @param ... Further arguments passed to `darts.models.NBEATSModel`.
#' @keywords internal
#' @noRd
MiltDartsNBeats <- R6::R6Class(
  classname = "MiltDartsNBeats",
  inherit   = MiltDartsModel,
  cloneable = FALSE,
  public = list(
    initialize = function(input_chunk_length  = 24L,
                          output_chunk_length = 12L,
                          num_stacks          = 30L,
                          num_blocks          = 1L,
                          num_layers          = 4L,
                          layer_widths        = 256L,
                          n_epochs            = 100L,
                          ...) {
      super$initialize(
        name                = "darts_nbeats",
        model_class         = "NBEATSModel",
        input_chunk_length  = as.integer(input_chunk_length),
        output_chunk_length = as.integer(output_chunk_length),
        num_stacks          = as.integer(num_stacks),
        num_blocks          = as.integer(num_blocks),
        num_layers          = as.integer(num_layers),
        layer_widths        = as.integer(layer_widths),
        n_epochs            = as.integer(n_epochs),
        ...
      )
    }
  )
)

# ── Registration ──────────────────────────────────────────────────────────────

.onLoad_dl_reticulate <- function() {
  register_milt_model("darts_rnn",         MiltDartsRNN)
  register_milt_model("darts_transformer", MiltDartsTransformer)
  register_milt_model("darts_nbeats",      MiltDartsNBeats)
}
