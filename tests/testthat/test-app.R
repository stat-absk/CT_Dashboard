test_that("app UI builds", {
  ui <- app_ui()
  expect_s3_class(ui, "bslib_page")
})

test_that("catalog version check detects the matching version", {
  catalog <- load_catalog()
  expect_true(check_catalog_version(catalog))
})

test_that("catalog version check warns on mismatch", {
  catalog <- load_catalog()
  catalog$meta$rpact_version <- "0.0.1"
  expect_warning(
    result <- check_catalog_version(catalog),
    "differs from the version"
  )
  expect_false(result)
})
