# Backend installation helper
#
# milt_install_backends() lets users install the optional packages that power
# milt's model backends in a single call, grouped by use-case.

# Packages whose CRAN binary depends on compiled C++ source that must be built
# from source on Windows (requires Rtools).  When these fail we emit a targeted
# help message instead of the generic one.
.NEEDS_COMPILATION <- c("CausalImpact", "Boom", "BoomSpikeSlab")

# ── Internal registry ─────────────────────────────────────────────────────────

.MILT_BACKEND_GROUPS <- list(

  forecasting = list(
    desc     = "Classical forecasting (ARIMA, ETS, TBATS, Theta, STL, Croston, Prophet)",
    packages = c("forecast", "prophet")
  ),

  ml = list(
    desc     = "Machine-learning backends (XGBoost, LightGBM, Elastic Net, Random Forest, SVM)",
    packages = c("xgboost", "lightgbm", "glmnet", "ranger", "e1071")
  ),

  deep_learning = list(
    desc     = "Deep-learning backends via torch (DeepAR, N-BEATS, N-HiTS, PatchTST, TCN, TFT)",
    packages = c("torch")
  ),

  extras = list(
    desc     = "Extras: anomaly detection, clustering, causal impact, changepoints",
    packages = c("isotree", "dbscan", "dtw", "CausalImpact", "changepoint")
  ),

  reporting = list(
    desc     = "Reporting and serving (rmarkdown, shiny, plumber)",
    packages = c("rmarkdown", "shiny", "plumber", "jsonlite")
  )
)

# Expand group name(s) or bare package names into a unique package vector.
.resolve_backends <- function(backends) {
  all_group_names <- names(.MILT_BACKEND_GROUPS)

  if (identical(backends, "all")) {
    pkgs <- unlist(lapply(.MILT_BACKEND_GROUPS, `[[`, "packages"),
                   use.names = FALSE)
    return(unique(pkgs))
  }

  pkgs <- character(0)
  for (b in backends) {
    if (b %in% all_group_names) {
      pkgs <- c(pkgs, .MILT_BACKEND_GROUPS[[b]]$packages)
    } else {
      # Treat as a bare package name
      pkgs <- c(pkgs, b)
    }
  }
  unique(pkgs)
}

# ── Public function ───────────────────────────────────────────────────────────

#' Install optional backend packages for milt
#'
#' @description
#' milt keeps heavy dependencies (Prophet, XGBoost, torch, …) in `Suggests` so
#' that installing milt itself is always fast and reliable.  Call
#' `milt_install_backends()` to install whichever backend groups you need.
#'
#' ## Backend groups
#'
#' | Group | Packages installed |
#' |---|---|
#' | `"forecasting"` | forecast, prophet |
#' | `"ml"` | xgboost, lightgbm, glmnet, ranger, e1071 |
#' | `"deep_learning"` | torch |
#' | `"extras"` | isotree, dbscan, dtw, CausalImpact, changepoint |
#' | `"reporting"` | rmarkdown, shiny, plumber, jsonlite |
#' | `"all"` | everything above |
#'
#' You can also pass individual package names directly (e.g.
#' `milt_install_backends("prophet")`).
#'
#' ## torch / GPU note
#' After installing the `"deep_learning"` group (or `"torch"` directly), run
#' `torch::install_torch()` once to download the Lantern runtime.
#'
#' @param backends Character vector of group name(s) or package name(s) to
#'   install.  Use `"all"` (default) to install every optional backend.
#' @param upgrade Logical.  If `TRUE`, upgrade packages that are already
#'   installed to their latest CRAN version.  Default `FALSE`.
#' @param quiet Logical.  Suppress per-package install output.  Default `FALSE`.
#'
#' @return Invisibly returns a named logical vector indicating which packages
#'   were newly installed (`TRUE`) vs already present (`FALSE`).
#'
#' @examples
#' \dontrun{
#' # Install everything
#' milt_install_backends()
#'
#' # Just the classical forecasting backends
#' milt_install_backends("forecasting")
#'
#' # Just prophet
#' milt_install_backends("prophet")
#'
#' # ML + deep learning together
#' milt_install_backends(c("ml", "deep_learning"))
#' }
#'
#' @seealso [milt_model()], [milt_fit()], [milt_forecast()]
#' @export
milt_install_backends <- function(backends = "all",
                                  upgrade  = FALSE,
                                  quiet    = FALSE) {
  pkgs <- .resolve_backends(backends)

  if (length(pkgs) == 0L) {
    milt_info("No packages matched {.val {backends}}.")
    return(invisible(logical(0)))
  }

  already   <- pkgs[vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  to_install <- if (upgrade) pkgs else setdiff(pkgs, already)

  # ── Print plan ──────────────────────────────────────────────────────────────
  cli::cli_h1("milt backend installation")

  if (length(already) > 0L && !upgrade) {
    cli::cli_inform(
      c("i" = "Already installed (skipping): {.pkg {already}}")
    )
  }

  if (length(to_install) == 0L) {
    cli::cli_inform(c("v" = "All requested backends are already installed."))
    return(invisible(stats::setNames(rep(FALSE, length(pkgs)), pkgs)))
  }

  cli::cli_inform(c("i" = "Installing: {.pkg {to_install}}"))

  # ── Installer: prefer pak (better binary fallback), otherwise base ───────────
  .install_one <- function(pkg, quiet) {
    if (requireNamespace("pak", quietly = TRUE)) {
      pak::pkg_install(pkg, ask = FALSE, upgrade = FALSE)
    } else {
      utils::install.packages(pkg, quiet = quiet, verbose = !quiet,
                              dependencies = TRUE)
    }
    requireNamespace(pkg, quietly = TRUE)
  }

  # ── Install loop ─────────────────────────────────────────────────────────────
  newly_installed <- character(0)
  failed          <- character(0)

  for (pkg in to_install) {
    ok <- tryCatch(
      .install_one(pkg, quiet),
      error   = function(e) FALSE,
      warning = function(w) requireNamespace(pkg, quietly = TRUE)
    )

    if (isTRUE(ok)) {
      newly_installed <- c(newly_installed, pkg)
    } else {
      failed <- c(failed, pkg)
    }
  }

  # ── Summary ─────────────────────────────────────────────────────────────────
  if (length(newly_installed) > 0L) {
    cli::cli_inform(c("v" = "Successfully installed: {.pkg {newly_installed}}"))
  }

  if (length(failed) > 0L) {
    needs_compile <- intersect(failed, .NEEDS_COMPILATION)
    other_failed  <- setdiff(failed, .NEEDS_COMPILATION)

    if (length(needs_compile) > 0L) {
      on_windows <- .Platform$OS.type == "windows"
      cli::cli_warn(c(
        "!" = "Failed to install: {.pkg {needs_compile}}",
        "i" = "{.pkg {needs_compile}} depends on compiled C++ code ({.pkg Boom}).",
        if (on_windows) c(
          "i" = "On Windows you need {.strong Rtools} installed first:",
          " " = "{.url https://cran.r-project.org/bin/windows/Rtools/}",
          "i" = "Then retry with {.code install.packages(\"Boom\", type = \"source\")} followed by",
          " " = "{.code install.packages(\"CausalImpact\")}"
        ) else c(
          "i" = "Ensure you have a C++ compiler available, then retry:",
          " " = "{.code install.packages(\"CausalImpact\", dependencies = TRUE)}"
        )
      ))
    }

    if (length(other_failed) > 0L) {
      cli::cli_warn(
        c("!" = "Failed to install: {.pkg {other_failed}}",
          "i" = "Retry manually: {.code install.packages(c({paste0('\"', other_failed, '\"', collapse=', ')}))}")
      )
    }
  }

  # ── torch post-install note ──────────────────────────────────────────────────
  if ("torch" %in% newly_installed) {
    cli::cli_inform(c(
      "i" = "{.pkg torch} was installed. Run the following to download the",
      " " = "Lantern runtime before using deep-learning backends:",
      " " = "{.code torch::install_torch()}"
    ))
  }

  result <- stats::setNames(
    pkgs %in% newly_installed,
    pkgs
  )
  invisible(result)
}
