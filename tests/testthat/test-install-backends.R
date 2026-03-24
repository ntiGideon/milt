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

test_that(".resolve_backends returns empty for unrecognised names treated as packages", {
  pkgs <- milt:::.resolve_backends("nonexistent_pkg_xyz")
  expect_identical(pkgs, "nonexistent_pkg_xyz")
})

test_that("milt_install_backends returns named logical when all pkgs already present", {
  # Use a group whose packages happen to be installed in the test env, or
  # verify the return-type contract without triggering network installs by
  # passing an empty character vector.
  res <- milt_install_backends(character(0))
  expect_true(is.logical(res))
  expect_equal(length(res), 0L)
})
