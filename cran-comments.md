# CRAN submission comments

## Test environments

* Local: Windows 11, R 4.5.3
* GitHub Actions (`R-CMD-check.yaml`):
  * ubuntu-latest (release, devel, oldrel-1)
  * macos-latest (release)
  * windows-latest (release)

## R CMD check results

0 errors | 1 warning | 3 notes

* This is a new release (first CRAN submission).

* The WARNING and two of the three NOTEs are artifacts of the local check
  environment, not the package:
  * `WARNING: 'qpdf' is needed for checks on size reduction of PDFs` — `qpdf`
    is not installed on the local machine used for this check; not expected
    to occur on CRAN's own check infrastructure.
  * `NOTE: Skipping checking HTML validation: no command 'tidy' found.` — same
    cause, missing local tool (`HTML Tidy`).
  * `NOTE: Found the following files/directories: 'lastMiKTeXException'` —
    stray temp-directory detritus left by the local MiKTeX installation
    while building the PDF manual; unrelated to package contents.

* The remaining NOTE is expected for a first submission:
  * `New submission` — this package has not been submitted to CRAN before.

* `checking package dependencies` reports several Suggests packages as
  "not available for checking" in this environment (`prophet`, `xgboost`,
  `lightgbm`, `ranger`, `glmnet`, `e1071`, `torch`, `reticulate`, `arrow`,
  `isotree`, `dbscan`, `dtw`, `changepoint`, `CausalImpact`, `plumber`,
  `tseries`, `xts`, `covr`, `lintr`). All of these are optional backends
  behind `check_installed_backend()` guards; every exported function and
  example that depends on one is wrapped in
  `if (requireNamespace(..., quietly = TRUE))` and/or `\donttest{}`, so the
  package installs, loads, and passes its full test suite without any of
  them present.

## Downstream dependencies

This is a new package with no reverse dependencies.
