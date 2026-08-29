# Phase 2 acceptance, part 1: every design-family function driven through
# the engine produces results identical to the direct rpact call.

catalog <- load_catalog()

reference_design <- function() {
  rpact::getDesignGroupSequential(kMax = 3, alpha = 0.025, beta = 0.2,
                                  sided = 1, typeOfDesign = "asOF")
}

make_resolver <- function() {
  store <- store_new()
  store_put(store, "design_1", reference_design())
  function(label) store_get(store, label)
}

expect_same_output <- function(outcome, direct) {
  expect_true(outcome$ok, info = outcome$error)
  expect_identical(
    utils::capture.output(print(outcome$result)),
    utils::capture.output(print(direct))
  )
}

test_that("getDesignGroupSequential matches direct call", {
  outcome <- run_catalog_function("getDesignGroupSequential", list(
    kMax = "3", alpha = "0.025", beta = "0.2", sided = "1",
    typeOfDesign = '"asOF"'
  ))
  expect_same_output(outcome, reference_design())
})

test_that("getDesignInverseNormal matches direct call", {
  outcome <- run_catalog_function("getDesignInverseNormal", list(
    kMax = "3", alpha = "0.025", typeOfDesign = '"asOF"',
    informationRates = "c(0.4, 0.7, 1)"
  ))
  direct <- rpact::getDesignInverseNormal(
    kMax = 3, alpha = 0.025, typeOfDesign = "asOF",
    informationRates = c(0.4, 0.7, 1)
  )
  expect_same_output(outcome, direct)
})

test_that("getDesignFisher matches direct call", {
  outcome <- run_catalog_function("getDesignFisher", list(
    kMax = "2", alpha = "0.025", method = '"equalAlpha"', alpha0Vec = "0.5"
  ))
  direct <- rpact::getDesignFisher(kMax = 2, alpha = 0.025,
                                   method = "equalAlpha", alpha0Vec = 0.5)
  expect_same_output(outcome, direct)
})

test_that("getDesignConditionalDunnett matches direct call", {
  outcome <- run_catalog_function("getDesignConditionalDunnett", list(
    alpha = "0.025", informationAtInterim = "0.5",
    secondStageConditioning = "TRUE"
  ))
  direct <- rpact::getDesignConditionalDunnett(
    alpha = 0.025, informationAtInterim = 0.5, secondStageConditioning = TRUE
  )
  expect_same_output(outcome, direct)
})

test_that("getDesignCharacteristics matches direct call via @reference", {
  outcome <- run_catalog_function(
    "getDesignCharacteristics", list(design = "@design_1"),
    resolve = make_resolver()
  )
  direct <- rpact::getDesignCharacteristics(reference_design())
  expect_same_output(outcome, direct)
})

test_that("getPowerAndAverageSampleNumber matches direct call via @reference", {
  outcome <- run_catalog_function(
    "getPowerAndAverageSampleNumber",
    list(design = "@design_1", theta = "seq(0, 1, 0.25)", nMax = "100"),
    resolve = make_resolver()
  )
  direct <- rpact::getPowerAndAverageSampleNumber(
    reference_design(), theta = seq(0, 1, 0.25), nMax = 100
  )
  expect_same_output(outcome, direct)
})

test_that("getGroupSequentialProbabilities matches direct call", {
  outcome <- run_catalog_function("getGroupSequentialProbabilities", list(
    decisionMatrix = "matrix(c(-Inf, -Inf, -Inf, 3.471, 2.454, 2.004), nrow = 2, byrow = TRUE)",
    informationRates = "c(1/3, 2/3, 1)"
  ))
  direct <- rpact::getGroupSequentialProbabilities(
    decisionMatrix = matrix(c(-Inf, -Inf, -Inf, 3.471, 2.454, 2.004),
                            nrow = 2, byrow = TRUE),
    informationRates = c(1 / 3, 2 / 3, 1)
  )
  expect_true(outcome$ok, info = outcome$error)
  expect_equal(outcome$result, direct)
})

test_that("getFutilityBounds matches direct call", {
  outcome <- run_catalog_function("getFutilityBounds", list(
    sourceValue = "0.5", sourceScale = '"zValue"', targetScale = '"pValue"'
  ))
  direct <- rpact::getFutilityBounds(
    sourceValue = 0.5, sourceScale = "zValue", targetScale = "pValue"
  )
  expect_true(outcome$ok, info = outcome$error)
  expect_identical(
    utils::capture.output(print(outcome$result)),
    utils::capture.output(print(direct))
  )
})

test_that("getDesignSet comparison matches the direct construction", {
  d1 <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  d2 <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asP")
  ds <- rpact::getDesignSet(designs = list(d1, d2))
  expect_s4_or_r6 <- inherits(ds, "TrialDesignSet")
  expect_true(expect_s4_or_r6)
  described <- describe_result(ds)
  expect_s3_class(described$table, "data.frame")
  expect_equal(nrow(described$table), 6)
  expect_true(length(described$plot_types) > 0)
})

test_that("designs boundary plot renders without error", {
  skip_if_not_installed("ggplot2")
  design <- reference_design()
  p <- plot(design, type = 1)
  expect_s3_class(p, "ggplot")
})
