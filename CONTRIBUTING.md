# Contributing to milt

Thank you for considering a contribution to **milt**. This document
covers the mechanics of making a pull request, writing tests, and
following the project’s coding standards. Please also read the [Code of
Conduct](https://ntiGideon.github.io/milt/CODE_OF_CONDUCT.md).

------------------------------------------------------------------------

## Quick start

``` bash
# 1. Fork and clone
git clone https://github.com/<your-username>/milt.git
cd milt

# 2. Restore the renv snapshot
Rscript -e "renv::restore()"

# 3. Load the package
Rscript -e "devtools::load_all()"

# 4. Run checks before you start
Rscript -e "devtools::check()"
```

------------------------------------------------------------------------

## What to work on

- **Bug reports** — search existing
  [issues](https://github.com/gideon-ntiboateng/milt/issues) first. If
  your bug isn’t there, open one with the *bug report* template before
  submitting a fix.
- **Feature requests** — open a *feature request* issue first so we can
  discuss the design before you invest time writing code.
- **Documentation** — typos, clarifications, and new examples are always
  welcome as small PRs without an issue.

------------------------------------------------------------------------

## Development workflow

``` r
# Regenerate NAMESPACE + man/ after editing roxygen2 docs
devtools::document()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-MiltSeries.R")

# Check CRAN compliance (aim for 0 errors, 0 warnings, 0 notes)
devtools::check()

# Build and preview the pkgdown site locally
pkgdown::build_site()
```

------------------------------------------------------------------------

## Code standards

### Architecture rules

- **S3 outside, R6 inside.** All user-facing functions are S3 generics
  or plain functions. Internal state lives in R6 classes. Users must
  never need to call `$method()` on a returned object.
- **Function prefix `milt_`, class prefix `Milt`.** No exceptions.
- **Pipe-friendly.** Every exported function takes the main object as
  its first argument and returns something pipeable.
- **Fail loudly.** Use `milt_abort()` (wraps
  [`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html))
  with a message that says *what* went wrong and *how to fix it*.

### Adding a new model backend

1.  Create `R/backend-<name>.R`.
2.  Define an R6 class that inherits `MiltModelBase`.
3.  Implement `initialize()`, `fit()`, `forecast()`, and `refit()`.
4.  Add an `.onLoad_<name>()` function that calls
    `ModelRegistry$register("<name>", <Class>)`.
5.  Call `.onLoad_<name>()` from `.milt_register_builtins()` in
    `R/zzz.R`.
6.  Add `@export` roxygen tag to any user-facing constructor if needed.
7.  Create `tests/testthat/test-backend-<name>.R` with at least 5 tests.

### Documentation requirements

Every exported function must have:

- One-sentence `@description`.
- All `@param` entries.
- `@return` describing the class or value returned.
- At least one `@examples` block (use `\dontrun{}` only for interactive
  or long-running examples).
- `@seealso` cross-references to related functions.

### Messages and errors

``` r
# Good
milt_abort("Expected a {.cls MiltSeries}, not {.cls {class(x)[1L]}}.")
milt_warn("Horizon {.val {h}} exceeds training length; forecasts may be unreliable.")
milt_info("Fitted {.fn milt_model} {.val {name}} on {.val {n}} observations.")

# Bad — plain stop() / warning() / message()
stop("wrong class")
```

### Tests

- One test file per source file: `tests/testthat/test-<source-name>.R`.
- Use `testthat` edition 3 (`Config/testthat/edition: 3`).
- Gate tests that require optional packages with
  `testthat::skip_if_not_installed("<pkg>")`.
- Test error paths as well as happy paths.
- Avoid network calls in tests.

------------------------------------------------------------------------

## Pull request checklist

Before submitting:

`devtools::check()` passes with 0 errors, 0 warnings, 0 notes.

New or changed behaviour is covered by tests.

All exported functions have complete roxygen2 docs.

`NEWS.md` has an entry under `# milt (development version)`.

Branch is up-to-date with `main`.

------------------------------------------------------------------------

## Commit message style

    <type>: <short imperative summary>

    Optional body (wrap at 72 chars).

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.

Example:

    feat: add ROCKET classifier backend

    Implements random convolutional kernel transform for fast time-series
    classification without requiring any external package beyond base R.

------------------------------------------------------------------------

## Getting help

Open a
[discussion](https://github.com/gideon-ntiboateng/milt/discussions) for
questions that don’t fit into a bug report or feature request.
