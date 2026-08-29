# Smart widgets: catalog metadata decides the input control, and each
# control's raw value translates back into the engine's expression form.

catalog <- load_catalog()
examples <- load_examples()
entry_by_name <- stats::setNames(
  catalog$functions,
  vapply(catalog$functions, function(f) f$name, character(1))
)
find_arg <- function(fn, arg) {
  Filter(function(a) a$name == arg, entry_by_name[[fn]]$args)[[1]]
}

test_that("match.arg defaults become choice widgets", {
  spec <- arg_widget_spec(find_arg("getDesignGroupSequential", "typeOfDesign"))
  expect_identical(spec$type, "choice")
  expect_true(all(c("OF", "P", "asOF", "asP") %in% spec$choices))
})

test_that("design arguments become object pickers", {
  spec <- arg_widget_spec(find_arg("getSampleSizeMeans", "design"))
  expect_identical(spec$type, "object")
  expect_identical(spec$class, "TrialDesign")
})

test_that("scalar logical defaults become logical widgets", {
  spec <- arg_widget_spec(find_arg("getDesignGroupSequential", "bindingFutility"))
  expect_identical(spec$type, "logical")
})

test_that("numeric and vector arguments stay text", {
  expect_identical(arg_widget_spec(find_arg("getDesignGroupSequential", "alpha"))$type,
                   "text")
  expect_identical(
    arg_widget_spec(find_arg("getDesignGroupSequential", "informationRates"))$type,
    "text"
  )
})

test_that("widget values translate to engine expression strings", {
  expect_identical(widget_value_to_expr(list(type = "choice"), "asOF"), '"asOF"')
  expect_identical(widget_value_to_expr(list(type = "object"), "design_1"),
                   "@design_1")
  expect_identical(widget_value_to_expr(list(type = "logical"), "TRUE"), "TRUE")
  expect_identical(widget_value_to_expr(list(type = "text"), "c(0.5, 1)"),
                   "c(0.5, 1)")
  # blank always means "use the rpact default"
  for (type in c("choice", "object", "logical", "text")) {
    expect_identical(widget_value_to_expr(list(type = type), ""), "")
    expect_identical(widget_value_to_expr(list(type = type), NULL), "")
  }
})

test_that("essential arguments follow the worked examples", {
  entry <- entry_by_name[["getDesignGroupSequential"]]
  essential <- essential_args(entry, examples)
  # everything the examples touch is essential
  expect_true(all(c("kMax", "alpha", "beta", "sided", "typeOfDesign",
                    "futilityBounds", "bindingFutility") %in% essential))
  # untouched exotica are not
  expect_false("betaAdjustment" %in% essential)
  expect_false("constantBoundsHP" %in% essential)

  # a function without examples shows everything
  no_ex <- entry_by_name[["getLambdaStepFunction"]]
  expect_setequal(
    essential_args(no_ex, examples),
    setdiff(vapply(no_ex$args, function(a) a$name, character(1)), "...")
  )
})

test_that("choice translation round-trips through the engine", {
  spec <- arg_widget_spec(find_arg("getDesignGroupSequential", "typeOfDesign"))
  expr <- widget_value_to_expr(spec, "asOF")
  outcome <- run_catalog_function(
    "getDesignGroupSequential",
    list(kMax = "3", typeOfDesign = expr)
  )
  expect_true(outcome$ok)
  direct <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  expect_identical(outcome$result$criticalValues, direct$criticalValues)
})
