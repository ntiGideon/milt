# Plumber API deployment
#
# milt_serve() wraps a fitted MiltModel (or any milt object) in a Plumber
# REST API with endpoints for /forecast, /detect (if detector), and /health.

#' Deploy a milt model as a REST API
#'
#' Generates a Plumber API with standardised endpoints and launches it on
#' the given host/port.  Requires the `plumber` package.
#'
#' **Endpoints generated:**
#' * `GET  /health` — returns package version and model name.
#' * `POST /forecast` — accepts JSON `{"horizon": <int>}`, returns forecast.
#' * `GET  /series_info` — returns metadata about the training series.
#'
#' @param model A fitted [MiltModel].
#' @param host Character. Bind address. Default `"127.0.0.1"`.
#' @param port Integer. TCP port. Default `8000L`.
#' @param launch Logical. If `TRUE` (default) the server is started
#'   interactively (blocking).  Set to `FALSE` to return the plumber router
#'   object without starting it.
#' @return The `plumber` router object (invisibly when `launch = TRUE`).
#' @seealso [milt_save()], [milt_dashboard()]
#' @family deploy
#' @examples
#' \donttest{
#' m <- milt_model("naive") |> milt_fit(milt_series(AirPassengers))
#' # milt_serve(m, launch = FALSE)  # returns router without starting
#' }
#' @export
milt_serve <- function(model,
                        host   = "127.0.0.1",
                        port   = 8000L,
                        launch = TRUE) {
  check_installed_backend("plumber", "milt_serve")
  if (!inherits(model, "MiltModel")) {
    milt_abort("{.arg model} must be a fitted {.cls MiltModel}.",
               class = "milt_error_invalid_arg")
  }
  if (!model$is_fitted()) {
    milt_abort("{.arg model} must be fitted before serving. Call {.fn milt_fit} first.",
               class = "milt_error_not_fitted")
  }

  # Capture references for the closure
  .model_ref  <- model
  .model_name <- model$.__enclos_env__$private$.name
  .train_s    <- model$.__enclos_env__$private$.training_series

  pr <- plumber::pr()

  # GET /health
  pr <- plumber::pr_get(pr, "/health", function() {
    list(
      status      = "ok",
      milt_version = as.character(utils::packageVersion("milt")),
      model       = .model_name
    )
  })

  # GET /series_info
  pr <- plumber::pr_get(pr, "/series_info", function() {
    s <- .train_s
    list(
      n_timesteps = s$n_timesteps(),
      start_time  = as.character(s$start_time()),
      end_time    = as.character(s$end_time()),
      frequency   = s$freq()
    )
  })

  # POST /forecast  body: {"horizon": <int>}
  pr <- plumber::pr_post(pr, "/forecast", function(req) {
    body <- tryCatch(jsonlite::fromJSON(req$postBody), error = function(e) NULL)
    h    <- body$horizon %||% 12L
    h    <- as.integer(h)
    if (is.na(h) || h < 1L) {
      plumber::pr_set_serializer(pr, plumber::serializer_json())
      return(list(error = "horizon must be a positive integer"))
    }
    fct <- tryCatch(
      milt_forecast(.model_ref, h),
      error = function(e) list(error = conditionMessage(e))
    )
    if (inherits(fct, "MiltForecast")) {
      tbl <- fct$as_tibble()
      tbl$time <- as.character(tbl$time)
      as.list(tbl)
    } else {
      fct
    }
  })

  if (launch) {
    milt_info("Starting milt API on http://{host}:{port}")
    plumber::pr_run(pr, host = host, port = as.integer(port))
    invisible(pr)
  } else {
    pr
  }
}
