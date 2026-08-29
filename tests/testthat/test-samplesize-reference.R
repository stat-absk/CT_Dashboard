# Phase 3 acceptance: sample size, power, and survival planning functions
# driven through the engine produce results identical to direct rpact
# calls - including the piecewise accrual + piecewise hazard scenario.

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

test_that("getSampleSizeMeans matches direct call (fixed and sequential)", {
  outcome <- run_catalog_function("getSampleSizeMeans",
                                  list(alternative = "0.5", stDev = "1"))
  expect_same_output(outcome, rpact::getSampleSizeMeans(alternative = 0.5, stDev = 1))

  outcome <- run_catalog_function(
    "getSampleSizeMeans",
    list(design = "@design_1", alternative = "0.5", stDev = "1"),
    resolve = make_resolver()
  )
  expect_same_output(
    outcome,
    rpact::getSampleSizeMeans(reference_design(), alternative = 0.5, stDev = 1)
  )
})

test_that("getSampleSizeRates matches direct call", {
  outcome <- run_catalog_function("getSampleSizeRates",
                                  list(pi1 = "0.45", pi2 = "0.3"))
  expect_same_output(outcome, rpact::getSampleSizeRates(pi1 = 0.45, pi2 = 0.3))
})

test_that("getSampleSizeSurvival matches direct call", {
  outcome <- run_catalog_function("getSampleSizeSurvival", list(
    hazardRatio = "0.7", median2 = "12", accrualTime = "12", followUpTime = "12"
  ))
  expect_same_output(
    outcome,
    rpact::getSampleSizeSurvival(hazardRatio = 0.7, median2 = 12,
                                 accrualTime = 12, followUpTime = 12)
  )
})

test_that("getSampleSizeSurvival piecewise accrual + hazards matches direct call", {
  outcome <- run_catalog_function("getSampleSizeSurvival", list(
    piecewiseSurvivalTime = "c(0, 6, 12)",
    lambda2 = "c(0.025, 0.04, 0.015)",
    hazardRatio = "0.7",
    accrualTime = "c(0, 12, 24)",
    accrualIntensity = "c(15, 30)"
  ))
  direct <- rpact::getSampleSizeSurvival(
    piecewiseSurvivalTime = c(0, 6, 12), lambda2 = c(0.025, 0.04, 0.015),
    hazardRatio = 0.7, accrualTime = c(0, 12, 24), accrualIntensity = c(15, 30)
  )
  expect_same_output(outcome, direct)
  expect_equal(outcome$result$maxNumberOfSubjects, 540)
})

test_that("getSampleSizeCounts matches direct call", {
  outcome <- run_catalog_function("getSampleSizeCounts", list(
    lambda2 = "0.8", theta = "0.75", overdispersion = "0.5",
    fixedExposureTime = "1"
  ))
  expect_same_output(
    outcome,
    rpact::getSampleSizeCounts(lambda2 = 0.8, theta = 0.75,
                               overdispersion = 0.5, fixedExposureTime = 1)
  )
})

test_that("getPowerMeans matches direct call via @reference design", {
  outcome <- run_catalog_function(
    "getPowerMeans",
    list(design = "@design_1", alternative = "seq(0.2, 0.8, 0.2)",
         stDev = "1", maxNumberOfSubjects = "128", directionUpper = "TRUE"),
    resolve = make_resolver()
  )
  expect_same_output(
    outcome,
    rpact::getPowerMeans(reference_design(), alternative = seq(0.2, 0.8, 0.2),
                         stDev = 1, maxNumberOfSubjects = 128,
                         directionUpper = TRUE)
  )
})

test_that("getPowerRates matches direct call", {
  outcome <- run_catalog_function("getPowerRates", list(
    pi1 = "seq(0.4, 0.6, 0.05)", pi2 = "0.3",
    maxNumberOfSubjects = "200", directionUpper = "TRUE"
  ))
  expect_same_output(
    outcome,
    rpact::getPowerRates(pi1 = seq(0.4, 0.6, 0.05), pi2 = 0.3,
                         maxNumberOfSubjects = 200, directionUpper = TRUE)
  )
})

test_that("getPowerSurvival matches direct call", {
  outcome <- run_catalog_function("getPowerSurvival", list(
    hazardRatio = "c(0.6, 0.7, 0.8)", median2 = "12", accrualTime = "12",
    maxNumberOfSubjects = "400", maxNumberOfEvents = "200",
    directionUpper = "FALSE"
  ))
  expect_same_output(
    outcome,
    rpact::getPowerSurvival(hazardRatio = c(0.6, 0.7, 0.8), median2 = 12,
                            accrualTime = 12, maxNumberOfSubjects = 400,
                            maxNumberOfEvents = 200, directionUpper = FALSE)
  )
})

test_that("getPowerCounts matches direct call", {
  outcome <- run_catalog_function("getPowerCounts", list(
    lambda2 = "0.8", theta = "c(0.7, 0.8)", overdispersion = "0.5",
    fixedExposureTime = "1", maxNumberOfSubjects = "400",
    directionUpper = "FALSE"
  ))
  expect_same_output(
    outcome,
    rpact::getPowerCounts(lambda2 = 0.8, theta = c(0.7, 0.8),
                          overdispersion = 0.5, fixedExposureTime = 1,
                          maxNumberOfSubjects = 400, directionUpper = FALSE)
  )
})

test_that("survival planning helpers match direct calls", {
  outcome <- run_catalog_function("getEventProbabilities", list(
    time = "seq(6, 30, 6)", accrualTime = "12", lambda2 = "0.05",
    hazardRatio = "0.8", maxNumberOfSubjects = "400"
  ))
  expect_same_output(
    outcome,
    rpact::getEventProbabilities(time = seq(6, 30, 6), accrualTime = 12,
                                 lambda2 = 0.05, hazardRatio = 0.8,
                                 maxNumberOfSubjects = 400)
  )

  outcome <- run_catalog_function("getNumberOfSubjects", list(
    time = "seq(3, 24, 3)", accrualTime = "c(0, 6, 12)",
    accrualIntensity = "c(15, 30)"
  ))
  direct <- rpact::getNumberOfSubjects(time = seq(3, 24, 3),
                                       accrualTime = c(0, 6, 12),
                                       accrualIntensity = c(15, 30))
  expect_same_output(outcome, direct)
  expect_equal(outcome$result$maxNumberOfSubjects, 270)

  outcome <- run_catalog_function("getAccrualTime", list(
    accrualTime = "c(0, 6, 30)", accrualIntensity = "c(0.22, 0.33)",
    maxNumberOfSubjects = "1000"
  ))
  expect_same_output(
    outcome,
    rpact::getAccrualTime(accrualTime = c(0, 6, 30),
                          accrualIntensity = c(0.22, 0.33),
                          maxNumberOfSubjects = 1000)
  )

  outcome <- run_catalog_function("getPiecewiseSurvivalTime", list(
    piecewiseSurvivalTime = "c(0, 6, 12)", lambda2 = "c(0.025, 0.04, 0.015)",
    hazardRatio = "0.8"
  ))
  direct <- rpact::getPiecewiseSurvivalTime(
    piecewiseSurvivalTime = c(0, 6, 12), lambda2 = c(0.025, 0.04, 0.015),
    hazardRatio = 0.8
  )
  expect_same_output(outcome, direct)
  expect_equal(outcome$result$lambda1, c(0.02, 0.032, 0.012))
})

test_that("conversion calculators match direct calls", {
  outcome <- run_catalog_function("getLambdaByMedian", list(median = "12"))
  expect_true(outcome$ok)
  expect_equal(outcome$result, log(2) / 12)

  outcome <- run_catalog_function("getHazardRatioByMedian",
                                  list(median1 = "18", median2 = "12"))
  expect_true(outcome$ok)
  expect_equal(outcome$result, 12 / 18)

  outcome <- run_catalog_function("getPiByLambda",
                                  list(lambda = "0.05", eventTime = "12"))
  expect_true(outcome$ok)
  expect_equal(outcome$result, 1 - exp(-0.05 * 12))
})

test_that("sample size result composes with a stored design and plots", {
  skip_if_not_installed("ggplot2")
  ss <- rpact::getSampleSizeMeans(reference_design(), alternative = 0.5, stDev = 1)
  described <- describe_result(ss)
  expect_s3_class(described$table, "data.frame")
  expect_true(length(described$plot_types) > 0)
  expect_match(described$r_code, "getSampleSizeMeans")
})
