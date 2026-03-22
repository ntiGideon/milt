# Model serialisation — milt_save() / milt_load()
#
# Serialises any milt object (MiltSeries, MiltModel, MiltForecast, detector,
# pipeline, etc.) to an `.milt` file using R's native serialisation (saveRDS).
# The file stores the object plus metadata (milt version, R version, timestamp).

#' Save a milt object to disk
#'
#' Serialises `object` together with version metadata to `path`.  The file is
#' a standard RDS file with the `.milt` extension (by convention).
#'
#' @param object Any milt object: `MiltSeries`, a fitted `MiltModel`,
#'   `MiltForecast`, `MiltDetector`, etc.
#' @param path Character. File path.  The `.milt` extension is appended if
#'   not already present.
#' @param compress Logical or character. Compression type passed to
#'   [saveRDS()]. Default `TRUE` (gzip).
#' @return `path` (invisibly).
#' @seealso [milt_load()]
#' @family save
#' @examples
#' \donttest{
#' s <- milt_series(AirPassengers)
#' tmp <- tempfile(fileext = ".milt")
#' milt_save(s, tmp)
#' s2 <- milt_load(tmp)
#' }
#' @export
milt_save <- function(object, path, compress = TRUE) {
  if (!is.character(path) || length(path) != 1L) {
    milt_abort("{.arg path} must be a single character string.",
               class = "milt_error_invalid_arg")
  }
  if (!grepl("\\.milt$", path)) path <- paste0(path, ".milt")

  container <- list(
    object       = object,
    milt_version = utils::packageVersion("milt"),
    r_version    = paste(R.version$major, R.version$minor, sep = "."),
    created_at   = Sys.time()
  )

  tryCatch(
    saveRDS(container, file = path, compress = compress),
    error = function(e) {
      milt_abort(
        c("Failed to save object to {.file {path}}.", "x" = conditionMessage(e)),
        class = "milt_error_io"
      )
    }
  )
  milt_info("Saved to {.file {path}}.")
  invisible(path)
}

#' Load a milt object from disk
#'
#' Reads an `.milt` file previously written by [milt_save()] and returns the
#' stored object.  Issues a warning if the saved `milt` version differs from
#' the installed version.
#'
#' @param path Character. Path to an `.milt` file.
#' @return The deserialised milt object.
#' @seealso [milt_save()]
#' @family save
#' @examples
#' \donttest{
#' tmp <- tempfile(fileext = ".milt")
#' milt_save(milt_series(AirPassengers), tmp)
#' s <- milt_load(tmp)
#' }
#' @export
milt_load <- function(path) {
  if (!file.exists(path)) {
    milt_abort("File not found: {.file {path}}.", class = "milt_error_io")
  }

  container <- tryCatch(
    readRDS(path),
    error = function(e) {
      milt_abort(
        c("Failed to load object from {.file {path}}.", "x" = conditionMessage(e)),
        class = "milt_error_io"
      )
    }
  )

  if (!is.list(container) || is.null(container$object)) {
    milt_abort(
      "{.file {path}} does not appear to be a valid {.pkg milt} file.",
      class = "milt_error_io"
    )
  }

  saved_ver   <- container$milt_version
  current_ver <- utils::packageVersion("milt")
  if (!is.null(saved_ver) && saved_ver != current_ver) {
    milt_warn(
      c(
        "Version mismatch: file was saved with milt {saved_ver},",
        "current version is {current_ver}."
      )
    )
  }

  container$object
}
