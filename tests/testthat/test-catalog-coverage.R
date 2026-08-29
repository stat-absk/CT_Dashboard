# The completeness guarantee: the catalog must cover every exported rpact
# `get*` function, stay in sync with the installed package's signatures,
# and record the rpact version it was generated against.

catalog <- load_catalog()

test_that("catalog exists and has the expected structure", {
  expect_true(is.list(catalog))
  expect_named(catalog, c("meta", "functions"))
  expect_gt(length(catalog$functions), 50)
})

test_that("every exported rpact get* function is in the catalog", {
  exports <- sort(getNamespaceExports("rpact"))
  target <- exports[grepl("^get", exports)]
  target <- Filter(function(n) is.function(getExportedValue("rpact", n)), target)

  catalogued <- vapply(catalog$functions, function(f) f$name, character(1))

  missing <- setdiff(target, catalogued)
  expect_true(
    length(missing) == 0,
    info = paste(
      "Exported rpact functions missing from catalog:",
      paste(missing, collapse = ", "),
      "- regenerate with data-raw/build_catalog.R"
    )
  )
})

test_that("catalog contains no functions absent from the installed rpact", {
  exports <- getNamespaceExports("rpact")
  catalogued <- vapply(catalog$functions, function(f) f$name, character(1))
  stale <- setdiff(catalogued, exports)
  expect_true(
    length(stale) == 0,
    info = paste("Stale catalog entries:", paste(stale, collapse = ", "))
  )
})

test_that("catalog was generated against the installed rpact version", {
  expect_identical(
    catalog$meta$rpact_version,
    as.character(utils::packageVersion("rpact"))
  )
})

test_that("catalogued argument lists match the installed signatures", {
  for (entry in catalog$functions) {
    fn <- getExportedValue("rpact", entry$name)
    current_args <- names(formals(fn))
    if (is.null(current_args)) current_args <- character(0)
    catalogued_args <- vapply(entry$args, function(a) a$name, character(1))
    expect_identical(
      catalogued_args, current_args,
      info = paste("Signature drift in", entry$name)
    )
  }
})

test_that("every entry has a valid family and known families are populated", {
  families <- vapply(catalog$functions, function(f) f$family, character(1))
  expect_true(all(families %in%
    c("design", "samplesize_power", "simulation", "analysis", "utility")))
  # The families the dashboard is being built around must not be empty
  expect_gt(sum(families == "design"), 0)
  expect_gt(sum(families == "samplesize_power"), 0)
})

test_that("core design functions are classified as design", {
  by_name <- stats::setNames(
    vapply(catalog$functions, function(f) f$family, character(1)),
    vapply(catalog$functions, function(f) f$name, character(1))
  )
  expect_identical(unname(by_name["getDesignGroupSequential"]), "design")
  expect_identical(unname(by_name["getDesignInverseNormal"]), "design")
  expect_identical(unname(by_name["getSampleSizeMeans"]), "samplesize_power")
  expect_identical(unname(by_name["getPowerAndAverageSampleNumber"]), "design")
})
