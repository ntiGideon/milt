.onLoad <- function(libname, pkgname) {
  # Initialize the model registry environment
  .milt_env$registry <- new.env(parent = emptyenv())

  # Register built-in model backends
  # These are called after all R files are sourced, so backends are available
  .onLoad_naive()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "milt ", utils::packageVersion("milt"),
    " \u2014 Modern Integrated Library for Timeseries\n",
    "Use `list_milt_models()` to see available models."
  )
}

# Package-level environment for mutable state (avoids <<-)
.milt_env <- new.env(parent = emptyenv())
