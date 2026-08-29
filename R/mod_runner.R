# Generic function-runner Shiny module. One instance serves a whole
# catalog family: the user picks a function, gets one input per argument
# (rpact names and defaults, exactly as documented), runs it, and reads
# the result as summary / table / plot / reproducible R code / audit
# record. Successful results can be registered in the session object
# store and referenced from other inputs as @label.

#' @keywords internal
mod_runner_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 380,
      shiny::uiOutput(ns("fn_select")),
      shiny::uiOutput(ns("fn_about")),
      shiny::uiOutput(ns("example_picker")),
      shiny::uiOutput(ns("args_form")),
      shiny::actionButton(ns("run"), "Run", class = "btn-primary"),
      shiny::helpText(
        "Argument values are R expressions (e.g. 0.025, c(0.5, 1), \"asOF\").",
        "Leave blank to use the rpact default.",
        "Reference a stored session object with @label.",
        "Hover an argument name for its official documentation."
      )
    ),
    shiny::uiOutput(ns("example_notes")),
    bslib::navset_card_tab(
      bslib::nav_panel("Summary", shiny::verbatimTextOutput(ns("summary"))),
      bslib::nav_panel("Table", shiny::div(
        style = "overflow-x: auto;", shiny::tableOutput(ns("table"))
      )),
      bslib::nav_panel(
        "Plot",
        shiny::uiOutput(ns("plot_type_select")),
        shiny::plotOutput(ns("plot"), height = "480px")
      ),
      bslib::nav_panel("R Code", shiny::verbatimTextOutput(ns("rcode"))),
      bslib::nav_panel("Audit", shiny::verbatimTextOutput(ns("audit")))
    ),
    bslib::card(
      bslib::card_header("Store result"),
      shiny::div(
        style = "display: flex; gap: 0.5rem; align-items: center;",
        shiny::textInput(ns("store_label"), NULL, placeholder = "label"),
        shiny::actionButton(ns("store_save"), "Save to session objects")
      )
    )
  )
}

#' @param id Module id.
#' @param family Catalog family served by this instance.
#' @param catalog Catalog list.
#' @param store Session object store ([store_new()]).
#' @param store_version A `reactiveVal` bumped whenever the store changes.
#' @param label_prefix Prefix for suggested store labels.
#' @keywords internal
mod_runner_server <- function(id, family, catalog, store, store_version,
                              label_prefix = family, examples = load_examples(),
                              group_fn = NULL, group_order = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    entries <- catalog_family(catalog, family)
    fn_names <- vapply(entries, function(f) f$name, character(1))
    entry_by_name <- stats::setNames(entries, fn_names)

    choices <- if (is.null(group_fn)) {
      fn_names
    } else {
      labels <- vapply(fn_names, group_fn, character(1))
      order <- group_order %||% unique(labels)
      grouped <- lapply(order, function(g) fn_names[labels == g])
      stats::setNames(grouped, order)
    }

    output$fn_select <- shiny::renderUI({
      shiny::selectInput(ns("fn"), "Function", choices = choices)
    })

    current_entry <- shiny::reactive({
      shiny::req(input$fn)
      entry_by_name[[input$fn]]
    })

    output$fn_about <- shiny::renderUI({
      entry <- current_entry()
      parts <- list()
      if (!is.null(entry$title) && !is.na(entry$title)) {
        parts <- c(parts, list(shiny::strong(entry$title)))
      }
      if (!is.null(entry$description) && !is.na(entry$description)) {
        parts <- c(parts, list(shiny::p(class = "text-muted small mb-1",
                                        entry$description)))
      }
      if (length(parts) == 0) return(NULL)
      do.call(shiny::div, parts)
    })

    output$example_picker <- shiny::renderUI({
      entry <- current_entry()
      fn_examples <- examples[[entry$name]]
      if (is.null(fn_examples) || length(fn_examples) == 0) return(NULL)
      labels <- vapply(fn_examples, function(e) e$label, character(1))
      shiny::div(
        shiny::selectInput(ns("example"), "Worked example",
                           choices = stats::setNames(seq_along(labels), labels)),
        shiny::actionButton(ns("load_example"), "Load example",
                            class = "btn-outline-primary btn-sm")
      )
    })

    loaded_example <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$fn, loaded_example(NULL))

    shiny::observeEvent(input$load_example, {
      entry <- current_entry()
      ex <- examples[[entry$name]][[as.integer(input$example)]]
      # clear every field, then prefill the example's values
      for (a in entry$args) {
        if (identical(a$name, "...")) next
        shiny::updateTextInput(session, paste0("arg_", a$name),
                               value = ex$args[[a$name]] %||% "")
      }
      loaded_example(ex)
    })

    output$example_notes <- shiny::renderUI({
      ex <- loaded_example()
      if (is.null(ex)) return(NULL)
      bslib::card(
        bslib::card_header(paste("Worked example:", ex$label)),
        shiny::p(ex$description),
        shiny::p(shiny::strong("What to look for: "), ex$interpretation)
      )
    })

    output$args_form <- shiny::renderUI({
      entry <- current_entry()
      inputs <- lapply(entry$args, function(a) {
        if (identical(a$name, "...")) return(NULL)
        placeholder <- if (isTRUE(a$required)) "(required)" else a$default
        label_txt <- if (isTRUE(a$required)) paste0(a$name, " *") else a$name
        label <- if (!is.null(a$description) && !is.na(a$description)) {
          bslib::tooltip(
            shiny::span(label_txt, shiny::HTML("&nbsp;&#9432;")),
            a$description,
            placement = "right"
          )
        } else {
          label_txt
        }
        shiny::textInput(ns(paste0("arg_", a$name)), label, value = "",
                         placeholder = placeholder)
      })
      do.call(shiny::tagList, Filter(Negate(is.null), inputs))
    })

    outcome <- shiny::eventReactive(input$run, {
      entry <- current_entry()
      arg_names <- setdiff(
        vapply(entry$args, function(a) a$name, character(1)), "..."
      )
      inputs <- stats::setNames(
        lapply(arg_names, function(a) input[[paste0("arg_", a)]]),
        arg_names
      )
      res <- tryCatch(
        run_catalog_function(
          entry$name, inputs, catalog,
          resolve = function(label) store_get(store, label)
        ),
        error = function(e) list(
          ok = FALSE, result = NULL, error = conditionMessage(e),
          call_text = NA_character_, args_text = list(), fn_name = entry$name
        )
      )
      record <- audit_record(res, user = session$user)
      audit_append(record)
      if (!res$ok) {
        shiny::showNotification(res$error, type = "error", duration = 10)
      }
      list(res = res, record = record,
           described = if (res$ok) describe_result(res$result) else NULL)
    })

    output$summary <- shiny::renderPrint({
      o <- outcome()
      if (!o$res$ok) cat("Error:", o$res$error)
      else cat(o$described$summary_text %||% o$described$print_text %||% "No summary available")
    })

    output$table <- shiny::renderTable({
      o <- outcome()
      shiny::req(o$res$ok, !is.null(o$described$table))
      o$described$table
    })

    output$plot_type_select <- shiny::renderUI({
      o <- outcome()
      shiny::req(o$res$ok)
      types <- o$described$plot_types
      if (length(types) == 0) return(shiny::helpText("No plots available for this result."))
      shiny::selectInput(ns("plot_type"), "Plot type", choices = types)
    })

    output$plot <- shiny::renderPlot({
      o <- outcome()
      shiny::req(o$res$ok, input$plot_type)
      print(plot(o$res$result, type = as.integer(input$plot_type)))
    })

    output$rcode <- shiny::renderPrint({
      o <- outcome()
      shiny::req(o$res$ok)
      cat(o$described$r_code %||% o$res$call_text)
    })

    output$audit <- shiny::renderPrint({
      o <- outcome()
      cat(jsonlite::toJSON(o$record, auto_unbox = TRUE, pretty = TRUE, null = "null"))
    })

    shiny::observeEvent(outcome(), {
      shiny::updateTextInput(session, "store_label",
                             value = store_next_label(store, label_prefix))
    })

    shiny::observeEvent(input$store_save, {
      o <- outcome()
      if (is.null(o) || !o$res$ok) {
        shiny::showNotification("Nothing to store: run a function successfully first.",
                                type = "warning")
        return()
      }
      label <- trimws(input$store_label)
      tryCatch({
        store_put(store, label, o$res$result,
                  fn_name = o$res$fn_name, call_text = o$res$call_text)
        store_version(store_version() + 1)
        shiny::showNotification(
          sprintf("Stored as @%s - reference it in any argument field.", label),
          type = "message"
        )
      }, error = function(e) {
        shiny::showNotification(conditionMessage(e), type = "error")
      })
    })
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
