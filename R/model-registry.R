# Internal model registration system
# All backends call register_milt_model() on load; users call list_milt_models()

# ── Registry access ───────────────────────────────────────────────────────────

# The registry lives in .milt_env$registry (set up in zzz.R .onLoad).
# Each entry is a named list with: class, description, supports.

#' Register a model backend with the milt model registry
#'
#' Called once per backend file, typically from a `.onLoad_<name>()` function
#' invoked in `zzz.R`'s `.milt_register_builtins()`.
#'
#' @param name Character scalar. The model identifier passed to [milt_model()].
#' @param class An R6 class generator that inherits from `MiltModelBase`.
#' @param description One-sentence description shown in [list_milt_models()].
#' @param supports Named list of logical flags. Recognised keys:
#'   `multivariate`, `probabilistic`, `covariates`, `multi_series`.
#' @return Invisibly returns `name`.
#' @keywords internal
#' @export
register_milt_model <- function(name, class, description = "", supports = list()) {
  if (!is_scalar_character(name)) {
    milt_abort("{.arg name} must be a single string.", class = "milt_error_registry")
  }
  if (!inherits(class, "R6ClassGenerator")) {
    milt_abort(
      "{.arg class} must be an R6 class generator (created with {.fn R6::R6Class}).",
      class = "milt_error_registry"
    )
  }

  default_supports <- list(
    multivariate  = FALSE,
    probabilistic = FALSE,
    covariates    = FALSE,
    multi_series  = FALSE
  )
  supports <- utils::modifyList(default_supports, supports)

  .milt_env$registry[[name]] <- list(
    class       = class,
    description = description,
    supports    = supports
  )
  invisible(name)
}

#' List all registered milt models
#'
#' @return A tibble with columns `name`, `description`, `multivariate`,
#'   `probabilistic`, `covariates`, `multi_series`.
#' @examples
#' list_milt_models()
#' @export
list_milt_models <- function() {
  reg <- as.list(.milt_env$registry)
  if (length(reg) == 0L) {
    milt_info("No models are currently registered. Have you loaded a backend?")
    return(tibble::tibble(
      name          = character(),
      description   = character(),
      multivariate  = logical(),
      probabilistic = logical(),
      covariates    = logical(),
      multi_series  = logical()
    ))
  }
  tibble::tibble(
    name          = names(reg),
    description   = vapply(reg, `[[`, character(1L), "description"),
    multivariate  = vapply(reg, function(x) isTRUE(x$supports$multivariate),  logical(1L)),
    probabilistic = vapply(reg, function(x) isTRUE(x$supports$probabilistic), logical(1L)),
    covariates    = vapply(reg, function(x) isTRUE(x$supports$covariates),    logical(1L)),
    multi_series  = vapply(reg, function(x) isTRUE(x$supports$multi_series),  logical(1L))
  )
}

#' Retrieve a registered model's R6 class generator
#'
#' @param name Character scalar. Model identifier.
#' @return The R6 class generator for the requested model.
#' @keywords internal
#' @export
get_milt_model_class <- function(name) {
  if (!is_scalar_character(name)) {
    milt_abort("{.arg name} must be a single string.", class = "milt_error_registry")
  }
  entry <- .milt_env$registry[[name]]
  if (is.null(entry)) {
    registered <- ls(.milt_env$registry)
    hint <- if (length(registered) > 0L) {
      glue::glue("Registered models: {paste(registered, collapse = ', ')}.")
    } else {
      "No models are currently registered."
    }
    milt_abort(
      c(
        "Model {.val {name}} is not registered.",
        "i" = hint,
        "i" = "Check spelling or install/load the required backend package."
      ),
      class = "milt_error_unknown_model"
    )
  }
  entry$class
}

#' Check whether a model name is registered
#'
#' @param name Character scalar.
#' @return `TRUE` / `FALSE`.
#' @keywords internal
#' @export
is_registered_model <- function(name) {
  is_scalar_character(name) && !is.null(.milt_env$registry[[name]])
}
