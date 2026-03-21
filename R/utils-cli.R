# CLI messaging helpers — always use these instead of stop/warning/message

#' Emit an informational message via cli
#'
#' @param msg A cli-formatted message string or character vector.
#' @param .envir Environment for glue substitution.
#' @noRd
milt_info <- function(msg, .envir = parent.frame()) {
  cli::cli_inform(msg, .envir = .envir)
}

#' Emit a warning via cli
#'
#' @param msg A cli-formatted message string or character vector.
#' @param .envir Environment for glue substitution.
#' @noRd
milt_warn <- function(msg, .envir = parent.frame()) {
  cli::cli_warn(msg, .envir = .envir)
}

#' Abort with a cli-formatted error
#'
#' @param msg A cli-formatted message string or character vector.
#' @param class Optional error subclass(es) for programmatic handling.
#' @param .envir Environment for glue substitution.
#' @param ... Additional arguments passed to [rlang::abort()].
#' @noRd
milt_abort <- function(msg, class = NULL, .envir = parent.frame(), ...) {
  cli::cli_abort(msg, class = c(class, "milt_error"), .envir = .envir, ...)
}
