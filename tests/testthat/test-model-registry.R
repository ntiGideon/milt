# ── Helpers ───────────────────────────────────────────────────────────────────

# A minimal valid R6 class for testing registration
make_mock_generator <- function(model_name = "test_mock") {
  R6::R6Class(
    classname = paste0("Mock_", model_name),
    inherit   = MiltModelBase,
    public    = list(
      initialize = function(...) super$initialize(name = model_name, ...)
    )
  )
}

# Clean up any test models we register (restore registry after each test)
with_clean_registry <- function(code) {
  before <- ls(.milt_env$registry)
  on.exit({
    for (nm in setdiff(ls(.milt_env$registry), before)) {
      rm(list = nm, envir = .milt_env$registry)
    }
  })
  force(code)
}

# ── register_milt_model ───────────────────────────────────────────────────────

test_that("register_milt_model adds a model to the registry", {
  with_clean_registry({
    gen <- make_mock_generator("reg_test_1")
    register_milt_model("reg_test_1", gen, description = "Test model 1")
    expect_true(is_registered_model("reg_test_1"))
  })
})

test_that("register_milt_model returns the name invisibly", {
  with_clean_registry({
    gen <- make_mock_generator("reg_test_2")
    result <- register_milt_model("reg_test_2", gen)
    expect_equal(result, "reg_test_2")
  })
})

test_that("register_milt_model errors on non-string name", {
  gen <- make_mock_generator()
  expect_error(register_milt_model(123, gen), class = "milt_error_registry")
})

test_that("register_milt_model errors on non-R6 class", {
  expect_error(
    register_milt_model("bad_class", list(fit = function() NULL)),
    class = "milt_error_registry"
  )
})

test_that("register_milt_model stores supports defaults correctly", {
  with_clean_registry({
    gen <- make_mock_generator("reg_test_3")
    register_milt_model("reg_test_3", gen)
    entry <- .milt_env$registry[["reg_test_3"]]
    expect_false(entry$supports$multivariate)
    expect_false(entry$supports$probabilistic)
    expect_false(entry$supports$covariates)
    expect_false(entry$supports$multi_series)
  })
})

test_that("register_milt_model stores provided supports flags", {
  with_clean_registry({
    gen <- make_mock_generator("reg_test_4")
    register_milt_model("reg_test_4", gen,
                        supports = list(multivariate = TRUE, probabilistic = TRUE))
    entry <- .milt_env$registry[["reg_test_4"]]
    expect_true(entry$supports$multivariate)
    expect_true(entry$supports$probabilistic)
    expect_false(entry$supports$covariates)
  })
})

# ── list_milt_models ──────────────────────────────────────────────────────────

test_that("list_milt_models returns a tibble", {
  tbl <- list_milt_models()
  expect_s3_class(tbl, "tbl_df")
})

test_that("list_milt_models has correct column names", {
  tbl <- list_milt_models()
  expect_true(all(c("name", "description", "multivariate",
                    "probabilistic", "covariates", "multi_series") %in% names(tbl)))
})

test_that("list_milt_models includes registered model", {
  with_clean_registry({
    gen <- make_mock_generator("reg_list_test")
    register_milt_model("reg_list_test", gen, description = "A list test model")
    tbl <- list_milt_models()
    expect_true("reg_list_test" %in% tbl$name)
    expect_equal(tbl$description[tbl$name == "reg_list_test"], "A list test model")
  })
})

# ── get_milt_model_class ──────────────────────────────────────────────────────

test_that("get_milt_model_class returns the R6 class generator", {
  with_clean_registry({
    gen <- make_mock_generator("reg_get_test")
    register_milt_model("reg_get_test", gen)
    retrieved <- get_milt_model_class("reg_get_test")
    expect_identical(retrieved, gen)
  })
})

test_that("get_milt_model_class errors for unknown model", {
  expect_error(
    get_milt_model_class("does_not_exist_xyz"),
    class = "milt_error_unknown_model"
  )
})

test_that("get_milt_model_class errors on non-string name", {
  expect_error(get_milt_model_class(99), class = "milt_error_registry")
})

# ── is_registered_model ───────────────────────────────────────────────────────

test_that("is_registered_model returns TRUE for registered model", {
  with_clean_registry({
    gen <- make_mock_generator("reg_bool_test")
    register_milt_model("reg_bool_test", gen)
    expect_true(is_registered_model("reg_bool_test"))
  })
})

test_that("is_registered_model returns FALSE for unknown model", {
  expect_false(is_registered_model("not_a_real_model_xyz"))
})

test_that("is_registered_model returns FALSE for non-string input", {
  expect_false(is_registered_model(42))
})
