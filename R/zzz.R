# Package-level mutable state — avoids <<- (CRAN compliant)
.milt_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # Initialise the model registry
  .milt_env$registry <- new.env(parent = emptyenv())

  # Register built-in backends (functions added as backends are implemented)
  .milt_register_builtins()
}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "milt ", utils::packageVersion("milt"),
    " \u2014 Modern Integrated Library for Timeseries\n",
    "Use `list_milt_models()` to see available models."
  )
}

# Called by .onLoad — registers all built-in backends.
# Add one line here each time a new backend file is created.
.milt_register_builtins <- function() {
  # Classical backends (Round 7)
  .onLoad_naive()
  .onLoad_arima()
  .onLoad_ets()
  .onLoad_theta()
  .onLoad_stl()
  # ML backends (Round 10)
  .onLoad_xgboost()
  .onLoad_lightgbm()
  .onLoad_random_forest()
  .onLoad_elastic_net()
  # DL backends (Round 11–12)
  .onLoad_nbeats()
  .onLoad_nhits()
  .onLoad_tcn()
  .onLoad_deepar()
  .onLoad_tft()
  .onLoad_patch_tst()
  # Reticulate / Darts bridge (Step 3.3)
  .onLoad_dl_reticulate()
  # Additional classical backends (Round 13)
  .onLoad_tbats()
  .onLoad_prophet()
  .onLoad_croston()
  # Additional ML backends (Round 13)
  .onLoad_svm()
  .onLoad_knn()
}
