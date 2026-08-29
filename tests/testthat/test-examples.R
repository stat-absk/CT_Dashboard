# Phase 2 acceptance, part 2: the worked-example library is complete and
# every example actually runs through the engine.

catalog <- load_catalog()
examples <- load_examples()

catalogued_names <- vapply(catalog$functions, function(f) f$name, character(1))
entry_by_name <- stats::setNames(catalog$functions, catalogued_names)

test_that("every design function with a form has at least one worked example", {
  design_fns <- vapply(catalog_family(catalog, "design"),
                       function(f) f$name, character(1))
  # getDesignSet's signature is only `...`; its interface is the
  # Compare Designs panel, not a catalog form
  needs_example <- setdiff(design_fns, "getDesignSet")
  missing <- setdiff(needs_example, names(examples))
  expect_true(length(missing) == 0,
              info = paste("Design functions without examples:",
                           paste(missing, collapse = ", ")))
})

test_that("the core sample size & power functions all have worked examples", {
  core <- c(
    paste0("getSampleSize", c("Means", "Rates", "Survival", "Counts")),
    paste0("getPower", c("Means", "Rates", "Survival", "Counts")),
    "getEventProbabilities", "getNumberOfSubjects",
    "getAccrualTime", "getPiecewiseSurvivalTime"
  )
  missing <- setdiff(core, names(examples))
  expect_true(length(missing) == 0,
              info = paste("Core functions without examples:",
                           paste(missing, collapse = ", ")))
})

test_that("examples reference catalogued functions and valid arguments", {
  for (fn in names(examples)) {
    expect_true(fn %in% catalogued_names, info = paste("Unknown function:", fn))
    known_args <- vapply(entry_by_name[[fn]]$args,
                         function(a) a$name, character(1))
    for (ex in examples[[fn]]) {
      expect_true(nzchar(ex$label))
      expect_true(nzchar(ex$description))
      expect_true(nzchar(ex$interpretation))
      bad <- setdiff(names(ex$args), known_args)
      expect_true(length(bad) == 0,
                  info = sprintf("%s / %s: unknown args %s",
                                 fn, ex$label, paste(bad, collapse = ", ")))
    }
  }
})

test_that("every worked example runs successfully through the engine", {
  # examples referencing @design_1 assume the user saved the classic
  # O'Brien-Fleming design first, as their descriptions instruct
  store <- store_new()
  store_put(store, "O'Brien-Fleming (3 looks)",
            rpact::getDesignGroupSequential(kMax = 3, alpha = 0.025,
                                            beta = 0.2, sided = 1,
                                            typeOfDesign = "asOF"))
  store_put(store, "O'Brien-Fleming (2 looks, inverse normal)",
            rpact::getDesignInverseNormal(kMax = 2, alpha = 0.025,
                                          beta = 0.2, typeOfDesign = "asOF"))
  store_put(store, "Interim data (continuous)",
            rpact::getDataset(n1 = c(22, 22), n2 = c(22, 22),
                              means1 = c(0.64, 0.51), means2 = c(0.08, 0.12),
                              stDevs1 = c(1.02, 0.98), stDevs2 = c(0.97, 1.01)))
  # the other two pre-filled datasets from the Enter data tab
  store_put(store, "Interim data (binary)",
            rpact::getDataset(n1 = c(40, 40), n2 = c(40, 40),
                              events1 = c(12, 19), events2 = c(6, 13)))
  store_put(store, "Interim data (survival)",
            rpact::getDataset(overallEvents = c(38, 78),
                              overallLogRanks = c(1.66, 2.11),
                              overallAllocationRatios = c(1, 1)))
  # stage results saved under the label the app suggests for them
  store_put(store, "Stage Results",
            rpact::getStageResults(store_get(store, "O'Brien-Fleming (3 looks)"),
                                   store_get(store, "Interim data (continuous)")))
  resolve <- function(label) store_get(store, label)

  for (fn in names(examples)) {
    for (ex in examples[[fn]]) {
      args <- lapply(ex$args, as.character)
      outcome <- run_catalog_function(fn, args, catalog, resolve = resolve)
      expect_true(outcome$ok,
                  info = sprintf("%s / %s failed: %s", fn, ex$label,
                                 outcome$error))
    }
  }
})

test_that("catalog carries documentation for the tutorial UI", {
  for (f in catalog_family(catalog, "design")) {
    expect_true(!is.null(f$description) && !is.na(f$description),
                info = paste("No description:", f$name))
  }
  # spot-check an argument tooltip
  gsd <- entry_by_name[["getDesignGroupSequential"]]
  alpha <- Filter(function(a) a$name == "alpha", gsd$args)[[1]]
  expect_match(alpha$description, "significance level")
})
