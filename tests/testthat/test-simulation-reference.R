# Phase 4 acceptance: seeded simulations driven through the engine are
# identical to direct rpact calls, including multi-arm and enrichment.

obf3 <- function() {
  rpact::getDesignGroupSequential(kMax = 3, alpha = 0.025, beta = 0.2,
                                  sided = 1, typeOfDesign = "asOF")
}
inm2 <- function() {
  rpact::getDesignInverseNormal(kMax = 2, alpha = 0.025, beta = 0.2,
                                typeOfDesign = "asOF")
}

make_resolver <- function() {
  store <- store_new()
  store_put(store, "O'Brien-Fleming (3 looks)", obf3())
  store_put(store, "O'Brien-Fleming (2 looks, inverse normal)", inm2())
  function(label) store_get(store, label)
}

expect_same_output <- function(outcome, direct) {
  expect_true(outcome$ok, info = outcome$error)
  expect_identical(
    utils::capture.output(print(outcome$result)),
    utils::capture.output(print(direct))
  )
}

test_that("getSimulationMeans (seeded) matches direct call", {
  outcome <- run_catalog_function(
    "getSimulationMeans",
    list(design = "@O'Brien-Fleming (3 looks)", alternative = "c(0, 0.5)",
         stDev = "1", plannedSubjects = "c(44, 88, 132)",
         maxNumberOfIterations = "1000", seed = "123"),
    resolve = make_resolver()
  )
  direct <- rpact::getSimulationMeans(
    obf3(), alternative = c(0, 0.5), stDev = 1,
    plannedSubjects = c(44, 88, 132),
    maxNumberOfIterations = 1000, seed = 123
  )
  expect_same_output(outcome, direct)
  # simulation recovers the designed operating characteristics
  expect_lt(outcome$result$overallReject[1], 0.04)
  expect_gt(outcome$result$overallReject[2], 0.75)
})

test_that("getSimulationRates (seeded) matches direct call", {
  outcome <- run_catalog_function(
    "getSimulationRates",
    list(pi1 = "c(0.3, 0.45)", pi2 = "0.3", plannedSubjects = "325",
         maxNumberOfIterations = "1000", seed = "456")
  )
  direct <- rpact::getSimulationRates(
    pi1 = c(0.3, 0.45), pi2 = 0.3, plannedSubjects = 325,
    maxNumberOfIterations = 1000, seed = 456
  )
  expect_same_output(outcome, direct)
})

test_that("getSimulationSurvival (seeded) matches direct call", {
  outcome <- run_catalog_function(
    "getSimulationSurvival",
    list(plannedEvents = "247", maxNumberOfSubjects = "429",
         accrualTime = "12", median2 = "12", hazardRatio = "c(0.7, 1)",
         directionUpper = "FALSE",
         maxNumberOfIterations = "1000", seed = "789")
  )
  direct <- rpact::getSimulationSurvival(
    plannedEvents = 247, maxNumberOfSubjects = 429, accrualTime = 12,
    median2 = 12, hazardRatio = c(0.7, 1), directionUpper = FALSE,
    maxNumberOfIterations = 1000, seed = 789
  )
  expect_same_output(outcome, direct)
  expect_gt(outcome$result$overallReject[1], 0.7)
})

test_that("getSimulationMultiArmMeans (seeded) matches direct call", {
  outcome <- run_catalog_function(
    "getSimulationMultiArmMeans",
    list(design = "@O'Brien-Fleming (2 looks, inverse normal)",
         activeArms = "3", muMaxVector = "c(0, 0.5)", stDev = "1",
         typeOfSelection = '"best"', plannedSubjects = "c(30, 60)",
         maxNumberOfIterations = "1000", seed = "321"),
    resolve = make_resolver()
  )
  direct <- rpact::getSimulationMultiArmMeans(
    inm2(), activeArms = 3, muMaxVector = c(0, 0.5), stDev = 1,
    typeOfSelection = "best", plannedSubjects = c(30, 60),
    maxNumberOfIterations = 1000, seed = 321
  )
  expect_same_output(outcome, direct)
})

test_that("getSimulationEnrichmentMeans (seeded) matches direct call", {
  effect_list_text <- paste0(
    'list(subGroups = c("S", "R"), prevalences = c(0.4, 0.6), ',
    "stDevs = 1, effects = matrix(c(0.5, 0.1), nrow = 1))"
  )
  outcome <- run_catalog_function(
    "getSimulationEnrichmentMeans",
    list(design = "@O'Brien-Fleming (2 looks, inverse normal)",
         effectList = effect_list_text,
         plannedSubjects = "c(150, 300)",
         typeOfSelection = '"epsilon"', epsilonValue = "0.1",
         maxNumberOfIterations = "500", seed = "654"),
    resolve = make_resolver()
  )
  direct <- rpact::getSimulationEnrichmentMeans(
    inm2(),
    effectList = list(subGroups = c("S", "R"), prevalences = c(0.4, 0.6),
                      stDevs = 1, effects = matrix(c(0.5, 0.1), nrow = 1)),
    plannedSubjects = c(150, 300),
    typeOfSelection = "epsilon", epsilonValue = 0.1,
    maxNumberOfIterations = 500, seed = 654
  )
  expect_same_output(outcome, direct)
})

test_that("getData extracts per-iteration results through the engine", {
  store <- store_new()
  sim <- rpact::getSimulationMeans(
    obf3(), alternative = c(0, 0.5), stDev = 1,
    plannedSubjects = c(44, 88, 132),
    maxNumberOfIterations = 1000, seed = 123
  )
  store_put(store, "Simulation Means", sim)
  outcome <- run_catalog_function(
    "getData", list(x = "@Simulation Means"),
    resolve = function(label) store_get(store, label)
  )
  expect_true(outcome$ok, info = outcome$error)
  expect_s3_class(outcome$result, "data.frame")
  expect_identical(outcome$result, rpact::getData(sim))
})

test_that("simulation results describe themselves and plot", {
  skip_if_not_installed("ggplot2")
  sim <- rpact::getSimulationMeans(
    obf3(), alternative = c(0, 0.5), stDev = 1,
    plannedSubjects = c(44, 88, 132),
    maxNumberOfIterations = 500, seed = 1
  )
  d <- describe_result(sim)
  expect_true(length(d$plot_types) > 0)
  expect_match(d$r_code, "getSimulationMeans")
  # the inverse normal design gets a distinct human name
  expect_identical(describe_object(inm2()),
                   "O'Brien-Fleming (2 looks, inverse normal)")
})
