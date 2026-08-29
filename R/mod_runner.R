# Generic function-runner Shiny module. One instance serves a whole
# catalog family: the user picks a function (shown under a plain-language
# title), gets smart inputs - dropdowns for enumerated choices, pickers
# for stored objects, text fields for numerics and vectors - split into
# essential arguments (the ones the worked examples use) and a collapsed
# "more arguments" section. Results, plot, and the reproducing R code are
# all visible at once, and update automatically after the first run.

#' @keywords internal
mod_runner_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      width = 380, open = "always",
      shiny::uiOutput(ns("fn_select")),
      shiny::uiOutput(ns("fn_about")),
      shiny::uiOutput(ns("example_picker")),
      shiny::uiOutput(ns("args_form")),
      shiny::div(
        class = "d-flex gap-3 align-items-center",
        shiny::actionButton(ns("run"), "Run", class = "btn-primary"),
        shiny::checkboxInput(ns("auto"), "Auto-update", value = TRUE,
                             width = "auto")
      ),
      shiny::helpText(
        "Blank fields use the rpact default (shown greyed). Numeric ",
        "fields accept R expressions like c(0.5, 1) or seq(0, 1, 0.25)."
      )
    ),
    shiny::uiOutput(ns("example_notes")),
    bslib::layout_columns(
      col_widths = c(6, 6),
      bslib::card(
        bslib::card_header("Result"),
        shiny::verbatimTextOutput(ns("summary"), placeholder = TRUE),
        bslib::card_footer(
          shiny::div(
            class = "d-flex gap-2 align-items-center",
            shiny::textInput(ns("store_label"), NULL, placeholder = "label",
                             width = "160px"),
            shiny::actionButton(ns("store_save"), "Save for later use",
                                class = "btn-outline-primary btn-sm"),
            shiny::span(class = "text-muted small",
                        "Saved results can be picked as inputs elsewhere.")
          )
        )
      ),
      bslib::card(
        bslib::card_header("Plot"),
        shiny::uiOutput(ns("plot_type_select")),
        shiny::plotOutput(ns("plot"), height = "400px")
      )
    ),
    bslib::card(
      bslib::card_header("R code - run this yourself in R"),
      shiny::verbatimTextOutput(ns("rcode"), placeholder = TRUE)
    ),
    bslib::navset_card_tab(
      bslib::nav_panel("Table", shiny::div(
        style = "overflow-x: auto;", shiny::tableOutput(ns("table"))
      )),
      bslib::nav_panel("Audit record", shiny::verbatimTextOutput(ns("audit")))
    )
  )
}

#' @param id Module id.
#' @param family Catalog family served by this instance.
#' @param catalog Catalog list.
#' @param store Session object store ([store_new()]).
#' @param store_version A `reactiveVal` bumped whenever the store changes.
#' @param label_prefix Prefix for suggested store labels.
#' @param examples Worked-example library ([load_examples()]).
#' @param group_fn Optional function(name) -> subgroup label for the picker.
#' @param group_order Optional display order for subgroup labels.
#' @keywords internal
mod_runner_server <- function(id, family, catalog, store, store_version,
                              label_prefix = family, examples = load_examples(),
                              group_fn = NULL, group_order = NULL,
                              default_fn = NULL, pending = NULL) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    entries <- catalog_family(catalog, family)
    fn_names <- vapply(entries, function(f) f$name, character(1))
    entry_by_name <- stats::setNames(entries, fn_names)

    friendly <- vapply(entries, function(f) {
      title <- if (!is.null(f$title) && !is.na(f$title)) f$title else f$name
      sub("^Get ", "", title)
    }, character(1))
    labelled <- stats::setNames(fn_names, friendly)

    choices <- if (is.null(group_fn)) {
      labelled
    } else {
      groups <- vapply(fn_names, group_fn, character(1))
      order <- group_order %||% unique(groups)
      stats::setNames(lapply(order, function(g) labelled[groups == g]), order)
    }

    output$fn_select <- shiny::renderUI({
      shiny::selectInput(ns("fn"), "What do you want to compute?",
                         choices = choices, selected = default_fn)
    })

    current_entry <- shiny::reactive({
      shiny::req(input$fn)
      entry_by_name[[input$fn]]
    })

    arg_specs <- shiny::reactive({
      entry <- current_entry()
      specs <- lapply(entry$args, arg_widget_spec)
      stats::setNames(specs, vapply(entry$args, function(a) a$name, character(1)))
    })

    output$fn_about <- shiny::renderUI({
      entry <- current_entry()
      shiny::div(
        shiny::code(paste0(entry$name, "()")),
        if (!is.null(entry$description) && !is.na(entry$description)) {
          shiny::p(class = "text-muted small mb-1", entry$description)
        }
      )
    })

    output$example_picker <- shiny::renderUI({
      entry <- current_entry()
      fn_examples <- examples[[entry$name]]
      if (is.null(fn_examples) || length(fn_examples) == 0) return(NULL)
      labels <- vapply(fn_examples, function(e) e$label, character(1))
      shiny::div(
        shiny::selectInput(ns("example"), "Start from a worked example",
                           choices = stats::setNames(seq_along(labels), labels)),
        shiny::actionButton(ns("load_example"), "Load & run example",
                            class = "btn-outline-primary btn-sm")
      )
    })

    make_widget <- function(a, spec) {
      input_id <- ns(paste0("arg_", a$name))
      label_txt <- if (isTRUE(a$required)) paste0(a$name, " *") else a$name
      label <- if (!is.null(a$description) && !is.na(a$description)) {
        bslib::tooltip(
          shiny::span(label_txt, shiny::HTML("&nbsp;&#9432;")),
          a$description, placement = "right"
        )
      } else {
        label_txt
      }
      switch(spec$type,
        object = {
          stored <- store_list(store)$label
          usable <- stored[vapply(stored, function(l)
            inherits(store_get(store, l), spec$class), logical(1))]
          shiny::selectInput(input_id, label,
                             choices = c("(use default)" = "", usable))
        },
        choice = shiny::selectInput(
          input_id, label,
          choices = c(stats::setNames("", paste0("(default: ", spec$choices[1], ")")),
                      spec$choices)
        ),
        logical = shiny::selectInput(
          input_id, label,
          choices = c(stats::setNames("", paste0("(default: ", a$default, ")")),
                      "TRUE", "FALSE")
        ),
        shiny::textInput(input_id, label, value = "",
                         placeholder = if (isTRUE(a$required)) "(required)" else a$default)
      )
    }

    output$args_form <- shiny::renderUI({
      entry <- current_entry()
      specs <- arg_specs()
      essential <- essential_args(entry, examples)
      widgets <- list(essential = list(), advanced = list())
      for (a in entry$args) {
        if (identical(a$name, "...")) next
        w <- make_widget(a, specs[[a$name]])
        slot <- if (a$name %in% essential) "essential" else "advanced"
        widgets[[slot]] <- c(widgets[[slot]], list(w))
      }
      shiny::tagList(
        do.call(shiny::tagList, widgets$essential),
        if (length(widgets$advanced) > 0) {
          bslib::accordion(
            open = FALSE,
            bslib::accordion_panel(
              sprintf("More arguments (%d)", length(widgets$advanced)),
              do.call(shiny::tagList, widgets$advanced)
            )
          )
        }
      )
    })

    # keep object pickers in sync with the store without resetting the form
    shiny::observeEvent(store_version(), {
      specs <- arg_specs()
      for (nm in names(specs)) {
        if (!identical(specs[[nm]]$type, "object")) next
        stored <- store_list(store)$label
        usable <- stored[vapply(stored, function(l)
          inherits(store_get(store, l), specs[[nm]]$class), logical(1))]
        shiny::updateSelectInput(
          session, paste0("arg_", nm),
          choices = c("(use default)" = "", usable),
          selected = input[[paste0("arg_", nm)]]
        )
      }
    }, ignoreInit = TRUE)

    collect_inputs <- function() {
      entry <- current_entry()
      specs <- arg_specs()
      arg_names <- setdiff(names(specs), "...")
      values <- lapply(arg_names, function(nm) {
        widget_value_to_expr(specs[[nm]], input[[paste0("arg_", nm)]])
      })
      stats::setNames(values, arg_names)
    }

    last_outcome <- shiny::reactiveVal(NULL)

    do_run <- function() {
      entry <- current_entry()
      res <- tryCatch(
        run_catalog_function(
          entry$name, collect_inputs(), catalog,
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
      last_outcome(list(
        res = res, record = record,
        described = if (res$ok) describe_result(res$result) else NULL
      ))
    }

    shiny::observeEvent(input$run, do_run())

    # auto-update: rerun when inputs change, but only after a first
    # successful run of the same function (or a just-loaded example)
    pending_run <- shiny::reactiveVal(FALSE)
    arg_values <- shiny::debounce(shiny::reactive({
      specs <- arg_specs()
      lapply(setdiff(names(specs), "..."),
             function(nm) input[[paste0("arg_", nm)]])
    }), 1000)
    shiny::observeEvent(arg_values(), {
      if (isTRUE(pending_run())) {
        pending_run(FALSE)
        do_run()
        return()
      }
      o <- last_outcome()
      if (is.null(o) || !isTRUE(input$auto)) return()
      if (!identical(o$res$fn_name, input$fn)) return()
      do_run()
    }, ignoreInit = TRUE)

    loaded_example <- shiny::reactiveVal(NULL)
    shiny::observeEvent(input$fn, loaded_example(NULL))

    apply_example <- function(idx) {
      entry <- current_entry()
      ex <- examples[[entry$name]][[idx]]
      if (is.null(ex)) return()
      specs <- arg_specs()
      for (a in entry$args) {
        if (identical(a$name, "...")) next
        raw <- ex$args[[a$name]] %||% ""
        spec <- specs[[a$name]]
        input_id <- paste0("arg_", a$name)
        # examples store engine-level expression strings; translate back
        # to the widget's own value space
        if (spec$type %in% c("choice", "logical")) {
          shiny::updateSelectInput(session, input_id,
                                   selected = gsub('"', "", raw))
        } else if (spec$type == "object") {
          shiny::updateSelectInput(session, input_id,
                                   selected = sub("^@", "", raw))
        } else {
          shiny::updateTextInput(session, input_id, value = raw)
        }
      }
      shiny::updateSelectInput(session, "example", selected = idx)
      loaded_example(ex)
      pending_run(TRUE)
    }

    shiny::observeEvent(input$load_example,
                        apply_example(as.integer(input$example)))

    # a Learn-path chapter can hand this module a function + example to
    # open: switch the function first, then apply the example once the
    # re-rendered form has reported its inputs back (arg_values fires)
    staged_example <- shiny::reactiveVal(NULL)
    if (!is.null(pending)) {
      shiny::observeEvent(pending(), {
        p <- pending()
        if (is.null(p) || !identical(p$module, id)) return()
        pending(NULL)
        if (identical(input$fn, p$fn)) {
          apply_example(p$example)
        } else {
          staged_example(p)
          shiny::updateSelectInput(session, "fn", selected = p$fn)
        }
      })
      shiny::observeEvent(arg_values(), {
        s <- staged_example()
        if (!is.null(s) && identical(input$fn, s$fn)) {
          staged_example(NULL)
          apply_example(s$example)
        }
      })
    }

    output$example_notes <- shiny::renderUI({
      ex <- loaded_example()
      if (is.null(ex)) return(NULL)
      bslib::card(
        bslib::card_header(paste("Worked example:", ex$label)),
        shiny::p(ex$description),
        shiny::p(shiny::strong("What to look for: "), ex$interpretation)
      )
    })

    output$summary <- shiny::renderPrint({
      o <- last_outcome()
      if (is.null(o)) {
        cat("Nothing computed yet.\n\n",
            "Pick a computation on the left - or, better, load a worked\n",
            "example and read its 'what to look for' notes.", sep = "")
      } else if (!o$res$ok) {
        cat("Error:", o$res$error)
      } else {
        cat(o$described$summary_text %||% o$described$print_text %||%
              "No summary available")
      }
    })

    output$table <- shiny::renderTable({
      o <- last_outcome()
      shiny::req(o, o$res$ok, !is.null(o$described$table))
      o$described$table
    })

    output$plot_type_select <- shiny::renderUI({
      o <- last_outcome()
      shiny::req(o, o$res$ok)
      types <- o$described$plot_types
      if (length(types) == 0) {
        return(shiny::helpText("This result has no plots."))
      }
      shiny::selectInput(ns("plot_type"), NULL, choices = types, width = "120px")
    })

    output$plot <- shiny::renderPlot({
      o <- last_outcome()
      shiny::req(o, o$res$ok, input$plot_type,
                 length(o$described$plot_types) > 0)
      print(plot(o$res$result, type = as.integer(input$plot_type)))
    })

    output$rcode <- shiny::renderPrint({
      o <- last_outcome()
      if (is.null(o)) {
        cat("# The exact rpact code for your result will appear here.")
      } else {
        shiny::req(o$res$ok)
        cat("# As entered:\n", o$res$call_text, "\n", sep = "")
        if (!is.null(o$described$r_code) &&
            !identical(o$described$r_code, o$res$call_text)) {
          cat("\n# Minimal form (rpact defaults omitted):\n",
              o$described$r_code, "\n", sep = "")
        }
      }
    })

    output$audit <- shiny::renderPrint({
      o <- last_outcome()
      shiny::req(o)
      cat(jsonlite::toJSON(o$record, auto_unbox = TRUE, pretty = TRUE,
                           null = "null"))
    })

    shiny::observeEvent(last_outcome(), {
      shiny::updateTextInput(session, "store_label",
                             value = store_next_label(store, label_prefix))
    })

    shiny::observeEvent(input$store_save, {
      o <- last_outcome()
      if (is.null(o) || !o$res$ok) {
        shiny::showNotification(
          "Nothing to store: run a computation successfully first.",
          type = "warning"
        )
        return()
      }
      label <- trimws(input$store_label)
      tryCatch({
        store_put(store, label, o$res$result,
                  fn_name = o$res$fn_name, call_text = o$res$call_text)
        store_version(store_version() + 1)
        shiny::showNotification(
          sprintf("Saved as '%s' - now selectable as an input elsewhere.", label),
          type = "message"
        )
      }, error = function(e) {
        shiny::showNotification(conditionMessage(e), type = "error")
      })
    })

    # expose for testing
    outcome <- shiny::reactive(last_outcome())
  })
}

`%||%` <- function(x, y) if (is.null(x)) y else x
