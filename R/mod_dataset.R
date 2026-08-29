# Trial data entry for the Analysis tab.
#
# rpact's getDataset() takes its stage-wise data through `...`, so it
# cannot be rendered from the catalog like other functions. This module
# is its human interface: pick the endpoint type, type one value per
# completed stage into plainly-labelled fields, and the dataset is
# created through the same audited engine and saved under a name the
# analysis functions can pick up.

DATASET_FIELDS <- list(
  means = list(
    n1 = "Group 1: subjects per stage",
    n2 = "Group 2: subjects per stage",
    means1 = "Group 1: mean per stage",
    means2 = "Group 2: mean per stage",
    stDevs1 = "Group 1: standard deviation per stage",
    stDevs2 = "Group 2: standard deviation per stage"
  ),
  rates = list(
    n1 = "Group 1: subjects per stage",
    n2 = "Group 2: subjects per stage",
    events1 = "Group 1: responders per stage",
    events2 = "Group 2: responders per stage"
  ),
  survival = list(
    overallEvents = "Cumulative events at each stage",
    overallLogRanks = "Cumulative log-rank statistic at each stage",
    overallAllocationRatios = "Allocation ratio at each stage"
  )
)

# The chapter-8 interim scenario: the chapter-1 trial, two of three
# stages observed, effect trending as designed.
DATASET_PREFILL <- list(
  means = list(n1 = "22, 22", n2 = "22, 22",
               means1 = "0.64, 0.51", means2 = "0.08, 0.12",
               stDevs1 = "1.02, 0.98", stDevs2 = "0.97, 1.01"),
  rates = list(n1 = "40, 40", n2 = "40, 40",
               events1 = "12, 19", events2 = "6, 13"),
  survival = list(overallEvents = "38, 78",
                  overallLogRanks = "1.66, 2.11",
                  overallAllocationRatios = "1, 1")
)

DATASET_NAMES <- c(means = "Interim data (continuous)",
                   rates = "Interim data (binary)",
                   survival = "Interim data (survival)")

#' @keywords internal
mod_dataset_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::card(
    bslib::card_header("Enter the trial data observed so far"),
    shiny::p(
      "One value per completed stage, separated by commas - stage 1 ",
      "first. The form starts pre-filled with a worked interim: the ",
      "chapter-1 trial after two of its three stages."
    ),
    shiny::selectInput(
      ns("type"), "Endpoint",
      choices = c("Continuous (means)" = "means",
                  "Binary (response rates)" = "rates",
                  "Survival (log-rank)" = "survival")
    ),
    shiny::uiOutput(ns("fields")),
    shiny::textInput(ns("name"), "Name for this dataset",
                     value = DATASET_NAMES[["means"]]),
    shiny::actionButton(ns("create"), "Create dataset", class = "btn-primary"),
    shiny::p(class = "text-muted small mt-2",
             "The dataset is saved to your saved work and appears in the ",
             "data dropdowns of the analysis functions on the Analyze tab.")
  )
}

#' Wrap a comma list in c(...) unless it is already an expression
#' @keywords internal
normalize_vector_input <- function(text) {
  text <- trimws(text)
  if (grepl(",", text) && !grepl("^c\\(", text)) {
    paste0("c(", text, ")")
  } else {
    text
  }
}

#' @keywords internal
mod_dataset_server <- function(id, catalog, store, store_version) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$fields <- shiny::renderUI({
      type <- input$type
      shiny::req(type)
      fields <- DATASET_FIELDS[[type]]
      prefill <- DATASET_PREFILL[[type]]
      do.call(shiny::tagList, lapply(names(fields), function(nm) {
        shiny::textInput(ns(paste0("field_", nm)), fields[[nm]],
                         value = prefill[[nm]])
      }))
    })

    shiny::observeEvent(input$type, {
      shiny::updateTextInput(session, "name",
                             value = DATASET_NAMES[[input$type]])
    })

    shiny::observeEvent(input$create, {
      fields <- DATASET_FIELDS[[input$type]]
      args <- stats::setNames(
        lapply(names(fields), function(nm) {
          normalize_vector_input(input[[paste0("field_", nm)]] %||% "")
        }),
        names(fields)
      )
      outcome <- tryCatch(
        run_catalog_function("getDataset", args, catalog),
        error = function(e) list(ok = FALSE, error = conditionMessage(e),
                                 result = NULL, call_text = NA_character_,
                                 args_text = args, fn_name = "getDataset")
      )
      audit_append(audit_record(outcome, user = session$user))
      if (!outcome$ok) {
        shiny::showNotification(outcome$error, type = "error", duration = 10)
        return()
      }
      label <- trimws(input$name)
      if (!nzchar(label)) label <- DATASET_NAMES[[input$type]]
      base <- label
      i <- 2
      while (label %in% names(store$objects)) {
        label <- paste0(base, " ", i)
        i <- i + 1
      }
      store_put(store, label, outcome$result,
                fn_name = "getDataset", call_text = outcome$call_text)
      store_version(store_version() + 1)
      shiny::showNotification(
        sprintf("'%s' saved - now open the Analyze tab and pick it as the data input.",
                label),
        type = "message"
      )
    })
  })
}
