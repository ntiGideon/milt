# Input validation functions for series state and backend availability

#' Check that a suggested package is installed before using a feature
#'
#' @param pkg Package name string.
#' @param feature Human-readable feature/model name for the error message.
#' @noRd
check_installed_backend <- function(pkg, feature) {
  rlang::check_installed(
    pkg,
    reason = glue::glue("to use the '{feature}' feature in milt.")
  )
}

#' Check that a MiltSeries has no time gaps
#'
#' @param series A `MiltSeries` object.
#' @noRd
check_series_has_no_gaps <- function(series) {
  assert_milt_series(series)
  if (series$has_gaps()) {
    gap_tbl <- series$gaps()
    n_gaps <- nrow(gap_tbl)
    milt_abort(
      c(
        "{.arg series} has {n_gaps} gap{?s} in the time index.",
        "i" = "Use {.fn milt_fill_gaps} to impute missing time steps before
               fitting a model."
      ),
      class = "milt_error_has_gaps"
    )
  }
  invisible(series)
}

#' Check that a MiltSeries has enough observations
#'
#' @param series A `MiltSeries` object.
#' @param min_obs Minimum number of observations required.
#' @param context Short description of what needs the data (e.g. model name).
#' @noRd
check_series_has_enough_data <- function(series, min_obs, context = "this operation") {
  assert_milt_series(series)
  n <- series$n_timesteps()
  if (n < min_obs) {
    milt_abort(
      c(
        "{.arg series} has only {n} observation{?s}, but {context} requires
         at least {min_obs}.",
        "i" = "Provide a longer series or reduce the required horizon / lags."
      ),
      class = "milt_error_insufficient_data"
    )
  }
  invisible(series)
}

#' Check that covariates align with the series time index
#'
#' @param series A `MiltSeries` object.
#' @param covariates A tibble with a time column.
#' @param time_col Name of the time column in `covariates`.
#' @noRd
check_covariates_aligned <- function(series, covariates, time_col) {
  assert_milt_series(series)

  if (!is.data.frame(covariates)) {
    milt_abort(
      "{.arg covariates} must be a data frame or tibble.",
      class = "milt_error_invalid_covariates"
    )
  }
  if (!time_col %in% names(covariates)) {
    milt_abort(
      c(
        "Column {.val {time_col}} not found in {.arg covariates}.",
        "i" = "Set {.arg time_col} to match the name of the time column in
               your covariate data."
      ),
      class = "milt_error_invalid_covariates"
    )
  }

  series_times <- series$times()
  cov_times <- covariates[[time_col]]

  missing_from_cov <- setdiff(as.character(series_times), as.character(cov_times))
  if (length(missing_from_cov) > 0L) {
    n_missing <- length(missing_from_cov)
    milt_abort(
      c(
        "{.arg covariates} is missing {n_missing} time point{?s} present in
         {.arg series}.",
        "i" = "Ensure covariates cover every time step in the series."
      ),
      class = "milt_error_misaligned_covariates"
    )
  }

  invisible(covariates)
}
