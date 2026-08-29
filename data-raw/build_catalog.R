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

# Map every documented alias to its Rd title, description, and
# per-argument help text, so catalog entries carry the official package
# documentation into the UI (tooltips and "about" panels).
rd_flatten <- function(x) {
  txt <- paste(unlist(x), collapse = "")
  trimws(gsub("\\s+", " ", txt))
}

rd_docs <- local({
  db <- tools::Rd_db("rpact")
  docs <- list()
  for (rd in db) {
    tags <- vapply(rd, function(x) attr(x, "Rd_tag"), character(1))
    title <- rd_flatten(rd[tags == "\\title"])
    description <- rd_flatten(rd[tags == "\\description"])

    arg_help <- list()
    args_secs <- rd[tags == "\\arguments"]
    if (length(args_secs) > 0) {
      items <- Filter(
        function(x) identical(attr(x, "Rd_tag"), "\\item"),
        args_secs[[1]]
      )
      for (it in items) {
        # one \item may document several arguments ("alpha, beta")
        arg_names <- trimws(strsplit(rd_flatten(it[[1]]), ",")[[1]])
        text <- rd_flatten(it[[2]])
        for (an in arg_names) {
          arg_help[[an]] <- text
        }
      }
    }

    for (alias in unlist(rd[tags == "\\alias"])) {
      docs[[trimws(alias)]] <- list(
        title = title, description = description, arg_help = arg_help
      )
    }
  }
  docs
})

describe_args <- function(fn, arg_help = list()) {
  fmls <- formals(fn)
  if (is.null(fmls)) return(list())
  unname(Map(function(arg_name, default) {
    required <- identical(default, quote(expr = ))
    list(
      name = arg_name,
      required = required,
      default = if (required) NULL else paste(deparse(default), collapse = " "),
      description = arg_help[[arg_name]]
    )
  }, names(fmls), fmls))
}

exports <- sort(getNamespaceExports("rpact"))
target <- exports[grepl("^get", exports)]
target <- Filter(function(n) is.function(getExportedValue("rpact", n)), target)

functions <- lapply(target, function(name) {
  fn <- getExportedValue("rpact", name)
  doc <- rd_docs[[name]]
  list(
    name = name,
    family = classify_family(name),
    title = if (!is.null(doc)) doc$title else NA,
    description = if (!is.null(doc)) doc$description else NA,
    args = describe_args(fn, if (!is.null(doc)) doc$arg_help else list())
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
