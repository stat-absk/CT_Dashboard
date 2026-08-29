# Design comparison module: pick two or more stored designs, build an
# rpact TrialDesignSet, and read boundaries side by side as a table and
# overlaid plots. This is the interface to getDesignSet(), whose
# signature (only `...`) cannot be rendered as a catalog form.

#' @keywords internal
mod_compare_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 380,
      shiny::uiOutput(ns("design_select")),
      shiny::actionButton(ns("compare"), "Compare", class = "btn-primary"),
      shiny::helpText(
        "Save two or more designs from the Design tab, then select them ",
        "here to compare boundaries and characteristics side by side. ",
        "Try comparing the O'Brien-Fleming and Pocock worked examples."
      )
    ),
    bslib::navset_card_tab(
      bslib::nav_panel(
        "Plot",
        shiny::uiOutput(ns("plot_type_select")),
        shiny::plotOutput(ns("plot"), height = "480px")
      ),
      bslib::nav_panel("Table", shiny::div(
        style = "overflow-x: auto;", shiny::tableOutput(ns("table"))
      )),
      bslib::nav_panel("Summary", shiny::verbatimTextOutput(ns("summary"))),
      bslib::nav_panel("R Code", shiny::verbatimTextOutput(ns("rcode")))
    )
  )
}

#' @keywords internal
mod_compare_server <- function(id, store, store_version) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    design_labels <- shiny::reactive({
      store_version()
      listing <- store_list(store)
      keep <- vapply(
        listing$label,
        function(l) inherits(store_get(store, l), "TrialDesign"),
        logical(1)
      )
      listing$label[keep]
    })

    output$design_select <- shiny::renderUI({
      labels <- design_labels()
      if (length(labels) < 2) {
        return(shiny::helpText(
          "At least two stored designs are needed. ",
          "Currently stored: ", length(labels), "."
        ))
      }
      shiny::checkboxGroupInput(ns("designs"), "Designs to compare",
                                choices = labels)
    })

    comparison <- shiny::eventReactive(input$compare, {
      labels <- input$designs
      if (length(labels) < 2) {
        shiny::showNotification("Select at least two designs.", type = "warning")
        return(NULL)
      }
      designs <- lapply(labels, function(l) store_get(store, l))
      call_text <- sprintf(
        "rpact::getDesignSet(designs = list(%s))",
        paste(labels, collapse = ", ")
      )
      outcome <- tryCatch(
        list(ok = TRUE, error = NULL,
             result = rpact::getDesignSet(designs = designs)),
        error = function(e) list(ok = FALSE, error = conditionMessage(e),
                                 result = NULL)
      )
      outcome <- c(outcome, list(
        call_text = call_text,
        args_text = list(designs = paste0("@", labels)),
        fn_name = "getDesignSet"
      ))
      audit_append(audit_record(outcome, user = session$user))
      if (!outcome$ok) {
        shiny::showNotification(outcome$error, type = "error", duration = 10)
        return(NULL)
      }
      list(res = outcome, described = describe_result(outcome$result))
    })

    output$plot_type_select <- shiny::renderUI({
      o <- comparison()
      shiny::req(o)
      types <- o$described$plot_types
      if (length(types) == 0) return(shiny::helpText("No plots available."))
      shiny::selectInput(ns("plot_type"), "Plot type", choices = types)
    })

    output$plot <- shiny::renderPlot({
      o <- comparison()
      shiny::req(o, input$plot_type)
      print(plot(o$res$result, type = as.integer(input$plot_type)))
    })

    output$table <- shiny::renderTable({
      o <- comparison()
      shiny::req(o, !is.null(o$described$table))
      o$described$table
    })

    output$summary <- shiny::renderPrint({
      o <- comparison()
      shiny::req(o)
      cat(o$described$summary_text %||% o$described$print_text %||% "No summary available")
    })

    output$rcode <- shiny::renderPrint({
      o <- comparison()
      shiny::req(o)
      cat(o$described$r_code %||% o$res$call_text)
    })
  })
}
