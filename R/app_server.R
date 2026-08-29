#' Application server
#' @keywords internal
app_server <- function(input, output, session) {
  catalog <- load_catalog()

  check_catalog_version(catalog, session)

  store <- store_new()
  store_version <- shiny::reactiveVal(0)
  pending <- shiny::reactiveVal(NULL)

  mod_runner_server("design", "design", catalog, store, store_version,
                    default_fn = "getDesignGroupSequential",
                    pending = pending)
  mod_runner_server(
    "samplesize", "samplesize_power", catalog, store, store_version,
    label_prefix = "result",
    group_fn = samplesize_group,
    group_order = c("Sample size", "Power", "Survival planning",
                    "Conversion calculators"),
    default_fn = "getSampleSizeMeans",
    pending = pending
  )
  mod_compare_server("compare", store, store_version)
  learn_server(input, session, store, store_version, pending, catalog)

  output$store_table <- shiny::renderTable({
    store_version()
    store_list(store)
  })

  output$env_info <- shiny::renderTable({
    data.frame(
      Component = c("R", "rpact", "rpactdash", "Catalog generated against rpact"),
      Version = c(
        paste(R.version$major, R.version$minor, sep = "."),
        as.character(utils::packageVersion("rpact")),
        as.character(utils::packageVersion("rpactdash")),
        catalog$meta$rpact_version
      )
    )
  })

  output$catalog_summary <- shiny::renderTable({
    families <- vapply(catalog$functions, function(f) f$family, character(1))
    counts <- table(families)
    data.frame(
      Family = names(counts),
      Functions = as.integer(counts)
    )
  })
}

#' Subgroup labels for the sample size & power function picker
#' @keywords internal
samplesize_group <- function(name) {
  if (startsWith(name, "getSampleSize")) return("Sample size")
  if (startsWith(name, "getPower")) return("Power")
  if (name %in% c("getEventProbabilities", "getNumberOfSubjects",
                  "getAccrualTime", "getPiecewiseSurvivalTime")) {
    return("Survival planning")
  }
  "Conversion calculators"
}

#' Warn if the installed rpact differs from the catalog's generation version
#' @keywords internal
check_catalog_version <- function(catalog, session = NULL) {
  installed <- as.character(utils::packageVersion("rpact"))
  generated <- catalog$meta$rpact_version
  if (!identical(installed, generated)) {
    msg <- sprintf(
      paste0(
        "Installed rpact (%s) differs from the version the function catalog ",
        "was generated against (%s). Regenerate the catalog with ",
        "data-raw/build_catalog.R and re-run the validation suite."
      ),
      installed, generated
    )
    warning(msg, call. = FALSE)
    if (!is.null(session)) {
      shiny::showNotification(msg, type = "warning", duration = NULL)
    }
  }
  invisible(identical(installed, generated))
}
