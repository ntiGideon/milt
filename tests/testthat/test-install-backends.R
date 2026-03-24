test_that(".resolve_backends('all') returns all packages", {
  pkgs <- milt:::.resolve_backends("all")
  expect_true(is.character(pkgs))
  expect_true(length(pkgs) > 0L)
  expect_true("prophet"  %in% pkgs)
  expect_true("torch"    %in% pkgs)
  expect_true("forecast" %in% pkgs)
  expect_true("xgboost"  %in% pkgs)
})

test_that(".resolve_backends handles group names", {
  pkgs <- milt:::.resolve_backends("forecasting")
  expect_true("forecast" %in% pkgs)
  expect_true("prophet"  %in% pkgs)
  expect_false("torch"   %in% pkgs)
})

test_that(".resolve_backends handles bare package names", {
  pkgs <- milt:::.resolve_backends("prophet")
  expect_identical(pkgs, "prophet")
})

test_that(".resolve_backends deduplicates across groups", {
  pkgs <- milt:::.resolve_backends(c("ml", "ml"))
  expect_equal(length(pkgs), length(unique(pkgs)))
})

test_that("milt_install_backends returns invisible named logical for already-installed pkg", {
  # 'stats' is always available — use it as a stand-in for a known package
  res <- milt_install_backends("stats")
  expect_true(is.logical(res))
  expect_true(!is.null(names(res)))
})

test_that("milt_install_backends accepts a vector of groups", {
  # Just check it doesn't error with valid group names
  # (won't actually install in test environment)
  expect_no_error(
    suppressMessages(milt_install_backends(c("forecasting", "ml")))
  )
})
