# Generate inst/catalog/functions.json from the installed rpact namespace.
#
# The catalog is the single source of truth for the dashboard's function
# coverage: every exported rpact `get*` function, its formal arguments,
# their defaults, and its documentation title. UI forms are rendered from
# this file, and tests/testthat/test-catalog-coverage.R fails if the
# installed package exposes a function the catalog does not know about.
#
# Run from the package root:  Rscript data-raw/build_catalog.R

suppressPackageStartupMessages(library(rpact))

ANALYSIS_FUNCTIONS <- c(
  "getDataset", "getDataSet", "getAnalysisResults", "getStageResults",
  "getConditionalPower", "getRepeatedConfidenceIntervals",
  "getRepeatedPValues", "getFinalConfidenceInterval", "getFinalPValue",
  "getConditionalRejectionProbabilities", "getObservedInformationRates",
  "getWideFormat", "getLongFormat",
  "getClosedCombinationTestResults", "getClosedConditionalDunnettTestResults",
  "getTestActions"
)

DESIGN_FUNCTIONS <- c(
  "getPowerAndAverageSampleNumber", "getGroupSequentialProbabilities",
  "getFutilityBounds"
)

# Survival planning helpers and the parameter conversion calculators
# (hazard ratio <-> lambda <-> median <-> pi) used when planning
# time-to-event trials.
SURVIVAL_HELPERS <- c(
  "getEventProbabilities", "getNumberOfSubjects", "getAccrualTime",
  "getPiecewiseSurvivalTime",
  "getHazardRatioByLambda", "getHazardRatioByMedian", "getHazardRatioByPi",
  "getLambda1ByLambda2AndHazardRatio", "getLambda2ByLambda1AndHazardRatio",
  "getLambdaByMedian", "getLambdaByPi", "getMedianByLambda", "getMedianByPi",
  "getPi1ByPi2AndHazardRatio", "getPi2ByPi1AndHazardRatio",
  "getPiByLambda", "getPiByMedian",
  "getPiecewiseExponentialDistribution", "getPiecewiseExponentialQuantile",
  "getPiecewiseExponentialRandomNumbers"
)

SIMULATION_FUNCTIONS <- c(
  "getData", "getData.SimulationResults", "getRawData", "getPerformanceScore"
)

classify_family <- function(name) {
  if (name %in% DESIGN_FUNCTIONS || grepl("^getDesign", name)) {
    return("design")
  }
  if (grepl("^getSampleSize|^getPower", name) || name %in% SURVIVAL_HELPERS) {
    return("samplesize_power")
  }
  if (grepl("^getSimulation", name) || name %in% SIMULATION_FUNCTIONS) {
    return("simulation")
  }
  if (name %in% ANALYSIS_FUNCTIONS) {
    return("analysis")
  }
  "utility"
}

# Map every documented alias to its Rd title so each catalog entry carries
# the official one-line description from the package documentation.
rd_titles <- local({
  db <- tools::Rd_db("rpact")
  titles <- list()
  for (rd in db) {
    tags <- vapply(rd, function(x) attr(x, "Rd_tag"), character(1))
    title <- trimws(paste(unlist(rd[tags == "\\title"]), collapse = " "))
    title <- gsub("\\s+", " ", title)
    for (alias in unlist(rd[tags == "\\alias"])) {
      titles[[trimws(alias)]] <- title
    }
  }
  titles
})

describe_args <- function(fn) {
  fmls <- formals(fn)
  if (is.null(fmls)) return(list())
  unname(Map(function(arg_name, default) {
    required <- identical(default, quote(expr = ))
    list(
      name = arg_name,
      required = required,
      default = if (required) NULL else paste(deparse(default), collapse = " ")
    )
  }, names(fmls), fmls))
}

exports <- sort(getNamespaceExports("rpact"))
target <- exports[grepl("^get", exports)]
target <- Filter(function(n) is.function(getExportedValue("rpact", n)), target)

functions <- lapply(target, function(name) {
  fn <- getExportedValue("rpact", name)
  list(
    name = name,
    family = classify_family(name),
    title = if (!is.null(rd_titles[[name]])) rd_titles[[name]] else NA,
    args = describe_args(fn)
  )
})

catalog <- list(
  meta = list(
    rpact_version = as.character(packageVersion("rpact")),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    generated = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    n_functions = length(functions)
  ),
  functions = functions
)

dir.create(file.path("inst", "catalog"), recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(
  catalog,
  file.path("inst", "catalog", "functions.json"),
  pretty = TRUE, auto_unbox = TRUE, null = "null"
)

cat(sprintf(
  "Catalog written: %d functions (rpact %s)\n",
  length(functions), catalog$meta$rpact_version
))
print(table(vapply(functions, function(f) f$family, character(1))))
