# Phase 1 acceptance: the generic engine must produce results identical
# to direct rpact calls, reject unsafe input, and leave a complete audit
# record for every computation.

test_that("parse_arg_value handles the value types statisticians type", {
  expect_identical(parse_arg_value("0.025"), 0.025)
  expect_identical(parse_arg_value("3"), 3)
  expect_identical(parse_arg_value("c(0.5, 1)"), c(0.5, 1))
  expect_identical(parse_arg_value('"asOF"'), "asOF")
  expect_identical(parse_arg_value("TRUE"), TRUE)
  expect_identical(parse_arg_value("NA"), NA)
  expect_identical(parse_arg_value("NULL"), NULL)
  expect_identical(parse_arg_value("1:3"), 1:3)
  expect_identical(parse_arg_value("seq(0.1, 0.3, 0.1)"), seq(0.1, 0.3, 0.1))
  expect_identical(parse_arg_value("-0.5"), -0.5)
  expect_identical(parse_arg_value("c(1/3, 2/3, 1)"), c(1 / 3, 2 / 3, 1))
})

test_that("parse_arg_value rejects anything outside the whitelist", {
  expect_error(parse_arg_value("system('ls')"), "not allowed")
  expect_error(parse_arg_value("readLines('/etc/passwd')"), "not allowed")
  expect_error(parse_arg_value("x"), "not allowed")
  expect_error(parse_arg_value("rnorm(10)"), "not allowed")
  expect_error(parse_arg_value("q()"), "not allowed")
  expect_error(parse_arg_value("a <- 1"), "not allowed")
  expect_error(parse_arg_value("c(1, system('ls'))"), "not allowed")
  expect_error(parse_arg_value(""), "Empty")
  expect_error(parse_arg_value("not valid r ("), "Not valid R syntax")
})

test_that("parse_arg_value resolves @label object references", {
  store <- store_new()
  store_put(store, "d1", "the-object")
  resolve <- function(label) store_get(store, label)
  expect_identical(parse_arg_value("@d1", resolve = resolve), "the-object")
  expect_error(parse_arg_value("@missing", resolve = resolve), "No stored object")
  expect_error(parse_arg_value("@d1"), "not available")
})

test_that("run_catalog_function reproduces a direct rpact call exactly", {
  outcome <- run_catalog_function(
    "getDesignGroupSequential",
    list(kMax = "3", alpha = "0.025", typeOfDesign = '"asOF"', sided = "1")
  )
  expect_true(outcome$ok)

  direct <- rpact::getDesignGroupSequential(
    kMax = 3, alpha = 0.025, typeOfDesign = "asOF", sided = 1
  )
  expect_identical(outcome$result$criticalValues, direct$criticalValues)
  expect_identical(outcome$result$stageLevels, direct$stageLevels)
  expect_identical(
    utils::capture.output(summary(outcome$result)),
    utils::capture.output(summary(direct))
  )
  expect_identical(result_hash(outcome$result), result_hash(direct))
})

test_that("blank inputs fall back to rpact defaults", {
  outcome <- run_catalog_function(
    "getDesignGroupSequential",
    list(kMax = "", alpha = NULL, typeOfDesign = '"asOF"')
  )
  expect_true(outcome$ok)
  direct <- rpact::getDesignGroupSequential(typeOfDesign = "asOF")
  expect_identical(outcome$result$criticalValues, direct$criticalValues)
  expect_match(outcome$call_text, "^rpact::getDesignGroupSequential\\(typeOfDesign")
})

test_that("rpact errors are captured, not thrown", {
  outcome <- run_catalog_function(
    "getDesignGroupSequential",
    list(alpha = "1.5")
  )
  expect_false(outcome$ok)
  expect_null(outcome$result)
  expect_match(outcome$error, "alpha")
})

test_that("unknown functions and arguments are rejected", {
  expect_error(
    run_catalog_function("notAFunction", list()),
    "not in the catalog"
  )
  # getLambdaByMedian has no `...`: the engine rejects unknown args itself
  expect_error(
    run_catalog_function("getLambdaByMedian", list(median = "12", bogusArg = "1")),
    "Unknown argument"
  )
  # getDesignGroupSequential has `...`: unknown args pass through and
  # rpact's own guardrail warns that they are ignored
  expect_warning(
    run_catalog_function("getDesignGroupSequential", list(bogusArg = "1")),
    "unknown"
  )
})

test_that("describe_result extracts summary, table, plots, and R code", {
  design <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  d <- describe_result(design)
  expect_match(d$summary_text, "group sequential design", ignore.case = TRUE)
  expect_s3_class(d$table, "data.frame")
  expect_equal(nrow(d$table), 3)
  expect_true(length(d$plot_types) > 0)
  expect_match(d$r_code, "getDesignGroupSequential")
})

test_that("object store enforces unique labels and lists contents", {
  store <- store_new()
  design <- rpact::getDesignGroupSequential(typeOfDesign = "asOF")
  store_put(store, "design_1", design,
            fn_name = "getDesignGroupSequential", call_text = "rpact::getDesignGroupSequential()")
  expect_error(store_put(store, "design_1", design), "already exists")
  expect_identical(store_get(store, "design_1"), design)
  expect_null(store_get(store, "nope"))

  listing <- store_list(store)
  expect_identical(listing$label, "design_1")
  expect_identical(listing$created_by, "getDesignGroupSequential")
  expect_identical(store_next_label(store, "design"), "design_2")
})

test_that("store round-trips through an .rds scenario file", {
  store <- store_new()
  store_put(store, "d", rpact::getDesignGroupSequential(typeOfDesign = "asOF"))
  path <- withr::local_tempfile(fileext = ".rds")
  store_save(store, path)
  restored <- store_load(store_new(), path)
  expect_identical(
    store_get(restored, "d")$criticalValues,
    store_get(store, "d")$criticalValues
  )
})

test_that("a stored design composes into a downstream call via @label", {
  store <- store_new()
  design <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  store_put(store, "design_1", design)

  outcome <- run_catalog_function(
    "getSampleSizeMeans",
    list(design = "@design_1", alternative = "0.8", stDev = "2"),
    resolve = function(label) store_get(store, label)
  )
  expect_true(outcome$ok)
  direct <- rpact::getSampleSizeMeans(design, alternative = 0.8, stDev = 2)
  expect_identical(
    outcome$result$maxNumberOfSubjects,
    direct$maxNumberOfSubjects
  )
})

test_that("audit records capture the full computation context", {
  audit_path <- withr::local_tempfile(fileext = ".jsonl")

  outcome <- run_catalog_function(
    "getDesignGroupSequential",
    list(kMax = "3", typeOfDesign = '"asOF"')
  )
  record <- audit_record(outcome, user = "test-user")
  expect_identical(record$user, "test-user")
  expect_identical(record$fn, "getDesignGroupSequential")
  expect_match(record$call, "rpact::getDesignGroupSequential\\(kMax = 3")
  expect_true(record$ok)
  expect_identical(record$result_class, "TrialDesignGroupSequential")
  expect_match(record$result_hash, "^[0-9a-f]+$")
  expect_identical(record$versions$rpact, as.character(packageVersion("rpact")))

  audit_append(record, audit_path)
  audit_append(record, audit_path)
  records <- audit_read(audit_path)
  expect_length(records, 2)
  expect_identical(records[[1]]$fn, "getDesignGroupSequential")
})

test_that("failed runs are auditable too", {
  outcome <- run_catalog_function("getDesignGroupSequential", list(alpha = "1.5"))
  record <- audit_record(outcome, user = "test-user")
  expect_false(record$ok)
  expect_type(record$error, "character")
  expect_null(record$result_hash)
})

test_that("identical results hash identically, different ones differ", {
  a <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  b <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  c <- rpact::getDesignGroupSequential(kMax = 4, typeOfDesign = "asOF")
  expect_identical(result_hash(a), result_hash(b))
  expect_false(identical(result_hash(a), result_hash(c)))
})
