# Human naming: saved work is described in the user's language, and the
# R code panel emits runnable code with real variable names.

test_that("designs are described by type and number of looks", {
  asOF <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  expect_identical(describe_object(asOF), "O'Brien-Fleming (3 looks)")
  asP <- rpact::getDesignGroupSequential(kMax = 4, typeOfDesign = "asP")
  expect_identical(describe_object(asP), "Pocock (4 looks)")
  fisher <- rpact::getDesignFisher(kMax = 2)
  expect_identical(describe_object(fisher), "Fisher combination (2 looks)")
})

test_that("non-design results fall back to the catalog title", {
  ss <- rpact::getSampleSizeMeans(alternative = 0.5, stDev = 1)
  expect_identical(
    describe_object(ss, title = "Get Sample Size Means"),
    "Sample Size Means"
  )
})

test_that("suggested labels are unique", {
  store <- store_new()
  d <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  first <- suggest_store_label(store, d)
  expect_identical(first, "O'Brien-Fleming (3 looks)")
  store_put(store, first, d)
  expect_identical(suggest_store_label(store, d), "O'Brien-Fleming (3 looks) 2")
})

test_that("labels become valid readable variable names", {
  expect_identical(label_to_var("O'Brien-Fleming (3 looks)"),
                   "o_brien_fleming_3_looks")
  expect_identical(label_to_var("Pocock (3 looks)"), "pocock_3_looks")
  expect_identical(label_to_var("123"), "x123")
})

test_that("the code panel emits runnable code for saved-object calls", {
  store <- store_new()
  design <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  store_put(store, "O'Brien-Fleming (3 looks)", design,
            fn_name = "getDesignGroupSequential",
            call_text = 'rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")')

  outcome <- run_catalog_function(
    "getSampleSizeMeans",
    list(design = "@O'Brien-Fleming (3 looks)", alternative = "0.5", stDev = "1"),
    resolve = function(label) store_get(store, label)
  )
  expect_true(outcome$ok)

  code <- build_repro_code(outcome, store)
  expect_match(code, "o_brien_fleming_3_looks <- rpact::getDesignGroupSequential",
               fixed = TRUE)
  expect_match(code, "design = o_brien_fleming_3_looks", fixed = TRUE)
  expect_false(grepl("@", code, fixed = TRUE))

  # and the emitted code actually runs and reproduces the result
  env <- new.env()
  result <- eval(parse(text = paste0("{", code, "}")), env)
  expect_identical(
    result$maxNumberOfSubjects,
    outcome$result$maxNumberOfSubjects
  )
})

test_that("calls without saved objects pass through unchanged", {
  store <- store_new()
  outcome <- run_catalog_function(
    "getSampleSizeMeans", list(alternative = "0.5", stDev = "1")
  )
  expect_identical(build_repro_code(outcome, store), outcome$call_text)
})
