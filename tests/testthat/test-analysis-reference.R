# Phase 5 acceptance: dataset creation and the interim-monitoring
# functions driven through the engine are identical to direct rpact
# calls.

obf3 <- function() {
  rpact::getDesignGroupSequential(kMax = 3, alpha = 0.025, beta = 0.2,
                                  sided = 1, typeOfDesign = "asOF")
}
interim_data <- function() {
  rpact::getDataset(
    n1 = c(22, 22), n2 = c(22, 22),
    means1 = c(0.64, 0.51), means2 = c(0.08, 0.12),
    stDevs1 = c(1.02, 0.98), stDevs2 = c(0.97, 1.01)
  )
}

make_resolver <- function() {
  store <- store_new()
  store_put(store, "O'Brien-Fleming (3 looks)", obf3())
  store_put(store, "Interim data (continuous)", interim_data())
  store_put(store, "Stage results",
            rpact::getStageResults(obf3(), dataInput = interim_data()))
  function(label) store_get(store, label)
}

expect_same_output <- function(outcome, direct) {
  expect_true(outcome$ok, info = outcome$error)
  expect_identical(
    utils::capture.output(print(outcome$result)),
    utils::capture.output(print(direct))
  )
}

test_that("getDataset builds all three endpoint types through the engine", {
  outcome <- run_catalog_function("getDataset", list(
    n1 = "c(22, 22)", n2 = "c(22, 22)",
    means1 = "c(0.64, 0.51)", means2 = "c(0.08, 0.12)",
    stDevs1 = "c(1.02, 0.98)", stDevs2 = "c(0.97, 1.01)"
  ))
  expect_same_output(outcome, interim_data())
  expect_s3_class(outcome$result, "DatasetMeans")

  outcome <- run_catalog_function("getDataset", list(
    n1 = "c(40, 40)", n2 = "c(40, 40)",
    events1 = "c(12, 19)", events2 = "c(6, 13)"
  ))
  expect_true(outcome$ok, info = outcome$error)
  expect_s3_class(outcome$result, "DatasetRates")

  outcome <- run_catalog_function("getDataset", list(
    overallEvents = "c(38, 78)", overallLogRanks = "c(1.66, 2.11)",
    overallAllocationRatios = "c(1, 1)"
  ))
  expect_true(outcome$ok, info = outcome$error)
  expect_s3_class(outcome$result, "DatasetSurvival")
})

test_that("getAnalysisResults matches the direct interim analysis", {
  outcome <- run_catalog_function(
    "getAnalysisResults",
    list(design = "@O'Brien-Fleming (3 looks)",
         dataInput = "@Interim data (continuous)", nPlanned = "44"),
    resolve = make_resolver()
  )
  direct <- rpact::getAnalysisResults(obf3(), dataInput = interim_data(),
                                      nPlanned = 44)
  expect_same_output(outcome, direct)
  # the interim picture the chapter teaches: continue, high conditional power
  expect_identical(outcome$result$testActions[2], "continue")
  expect_gt(outcome$result$conditionalPower[3], 0.85)
})

test_that("getStageResults and its consumers match direct calls", {
  resolver <- make_resolver()

  outcome <- run_catalog_function(
    "getStageResults",
    list(design = "@O'Brien-Fleming (3 looks)",
         dataInput = "@Interim data (continuous)"),
    resolve = resolver
  )
  direct_sr <- rpact::getStageResults(obf3(), dataInput = interim_data())
  expect_same_output(outcome, direct_sr)

  outcome <- run_catalog_function(
    "getConditionalRejectionProbabilities",
    list(stageResults = "@Stage results"),
    resolve = resolver
  )
  expect_true(outcome$ok, info = outcome$error)
  expect_equal(outcome$result,
               rpact::getConditionalRejectionProbabilities(direct_sr))

  outcome <- run_catalog_function(
    "getTestActions", list(stageResults = "@Stage results"),
    resolve = resolver
  )
  expect_true(outcome$ok, info = outcome$error)
  expect_identical(outcome$result[1:2], c("continue", "continue"))
})

test_that("repeated confidence intervals match the direct call", {
  outcome <- run_catalog_function(
    "getRepeatedConfidenceIntervals",
    list(design = "@O'Brien-Fleming (3 looks)",
         dataInput = "@Interim data (continuous)"),
    resolve = make_resolver()
  )
  expect_true(outcome$ok, info = outcome$error)
  direct <- rpact::getRepeatedConfidenceIntervals(obf3(),
                                                  dataInput = interim_data())
  expect_equal(outcome$result, direct)
  # the stage-2 interval has tightened but still includes zero
  expect_lt(outcome$result[1, 2], 0)
  expect_gt(outcome$result[2, 2], 0)
})

test_that("observed information rates match the direct call", {
  outcome <- run_catalog_function(
    "getObservedInformationRates",
    list(dataInput = "@Interim data (continuous)", maxInformation = "132"),
    resolve = make_resolver()
  )
  expect_true(outcome$ok, info = outcome$error)
  direct <- rpact::getObservedInformationRates(interim_data(),
                                               maxInformation = 132)
  expect_equal(outcome$result$informationRates, direct$informationRates)
})

test_that("vector input normalization wraps bare comma lists only", {
  expect_identical(normalize_vector_input("0.64, 0.51"), "c(0.64, 0.51)")
  expect_identical(normalize_vector_input("c(0.64, 0.51)"), "c(0.64, 0.51)")
  expect_identical(normalize_vector_input("132"), "132")
  expect_identical(normalize_vector_input(" 22, 22 "), "c(22, 22)")
})

test_that("the dataset entry module creates and stores a named dataset", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())
  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)

  shiny::testServer(
    mod_dataset_server,
    args = list(catalog = catalog, store = store,
                store_version = store_version),
    {
      session$setInputs(
        type = "means",
        field_n1 = "22, 22", field_n2 = "22, 22",
        field_means1 = "0.64, 0.51", field_means2 = "0.08, 0.12",
        field_stDevs1 = "1.02, 0.98", field_stDevs2 = "0.97, 1.01",
        name = "Interim data (continuous)",
        create = 1
      )
      expect_s3_class(store_get(store, "Interim data (continuous)"),
                      "DatasetMeans")
      expect_identical(store_version(), 1)
      # creating again under the same name uniquifies instead of failing
      session$setInputs(create = 2)
      expect_s3_class(store_get(store, "Interim data (continuous) 2"),
                      "DatasetMeans")
    }
  )
})
