#' Hello, World!
#'
#' Prints a simple greeting.
#'
#' @return The greeting string, invisibly.
#' @examples
#' hello()
#' @export
hello <- function() {
  msg <- "Hello, world!"
  message(msg)
  invisible(msg)
}
