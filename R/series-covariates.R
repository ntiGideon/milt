# Attaching covariates to a MiltSeries

#' Add covariates to a MiltSeries
#'
#' Attaches external covariate data to a `MiltSeries`. Three types are
#' supported:
#'
#' - **past**: time-varying covariates observed in the past (same time range as
#'   the series). Used for in-sample feature enrichment.
#' - **future**: time-varying covariates available beyond the series end (e.g.,
#'   calendar, weather forecasts). Used by models to produce covariate-informed
#'   forecasts.
#' - **static**: scalar attributes per group that do not vary over time (e.g.,
#'   store size, region). Only meaningful for multi-series.
#'
#' @param series A `MiltSeries` object.
#' @param covariates A data frame or tibble containing the covariate columns.
#'   For `"past"` and `"future"` types it must include a time column matching
#'   `time_col`. For `"static"` it must include a column matching `group_col`.
#' @param type One of `"past"`, `"future"`, or `"static"`.
#' @param time_col Name of the time column in `covariates`. Defaults to the
#'   same time column name as the series.
#' @param group_col Name of the group column in `covariates` (static only).
#'   Defaults to the group column of the series.
#' @return The same `MiltSeries` with covariates stored internally. The
#'   underlying data tibble is **not** modified; covariates are kept separate
#'   and accessed by models via the private fields.
#' @seealso [milt_series()]
#' @family series
#' @examples
#' s <- milt_series(AirPassengers)
#' dates <- s$as_tibble()$time
#' cov_df <- data.frame(time = dates, month_num = as.integer(format(dates, "%m")))
#' s2 <- milt_add_covariates(s, cov_df, type = "past", time_col = "time")
#' @export
milt_add_covariates <- function(series,
                                 covariates,
                                 type,
                                 time_col  = NULL,
                                 group_col = NULL) {
  assert_milt_series(series)

  valid_types <- c("past", "future", "static")
  if (!is_scalar_character(type) || !type %in% valid_types) {
    milt_abort(
      "{.arg type} must be one of {.val {valid_types}}, not {.val {type}}.",
      class = "milt_error_invalid_covariate_type"
    )
  }
  if (!is.data.frame(covariates)) {
    milt_abort(
      "{.arg covariates} must be a data frame or tibble.",
      class = "milt_error_invalid_covariates"
    )
  }

  p   <- series$.__enclos_env__$private
  cov <- tibble::as_tibble(covariates)

  if (type == "static") {
    gc <- group_col %||% p$.group_col
    if (is.null(gc)) {
      milt_abort(
        c(
          "Static covariates require a multi-series {.cls MiltSeries}.",
          "i" = "Supply {.arg group_col} or use a series with a group column."
        ),
        class = "milt_error_invalid_covariates"
      )
    }
    if (!gc %in% names(cov)) {
      milt_abort(
        "Column {.val {gc}} not found in {.arg covariates}.",
        class = "milt_error_invalid_covariates"
      )
    }
    p$.static_covs <- cov
  } else {
    # "past" or "future"
    tc <- time_col %||% p$.time_col
    check_covariates_aligned(series, cov, tc)
    if (type == "past") {
      p$.past_covs   <- cov
    } else {
      p$.future_covs <- cov
    }
  }

  milt_info(
    "Added {type} covariates to {.cls MiltSeries} \\
     ({ncol(cov) - 1L} covariate column{?s})."
  )
  invisible(series)
}

#' Retrieve covariates attached to a MiltSeries
#'
#' @param series A `MiltSeries` object.
#' @param type One of `"past"`, `"future"`, or `"static"`. Default `"past"`.
#' @return A tibble of covariates, or `NULL` if none have been attached.
#' @family series
#' @export
milt_get_covariates <- function(series, type = "past") {
  assert_milt_series(series)
  valid_types <- c("past", "future", "static")
  if (!is_scalar_character(type) || !type %in% valid_types) {
    milt_abort(
      "{.arg type} must be one of {.val {valid_types}}.",
      class = "milt_error_invalid_covariate_type"
    )
  }
  p <- series$.__enclos_env__$private
  switch(type,
    past    = p$.past_covs,
    future  = p$.future_covs,
    static  = p$.static_covs
  )
}
