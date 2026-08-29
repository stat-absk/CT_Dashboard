#' Application UI
#' @keywords internal
app_ui <- function() {
  bslib::page_navbar(
    id = "nav",
    title = "RPACT Trial Design Workbench",
    theme = bslib::bs_theme(
      version = 5,
      preset = "shiny",
      primary = "#0F6B66"
    ),
    header = shiny::tagList(
      shiny::tags$head(shiny::tags$style(shiny::HTML(workbench_css()))),
      shiny::useBusyIndicators(spinners = FALSE, pulse = TRUE)
    ),
    bslib::nav_panel(
      "Start",
      learn_ui()
    ),
    bslib::nav_panel(
      "Sample Size & Power",
      mod_runner_ui("samplesize")
    ),
    bslib::nav_panel(
      "Design",
      mod_runner_ui("design")
    ),
    bslib::nav_panel(
      "Compare Designs",
      mod_compare_ui("compare")
    ),
    bslib::nav_panel(
      "Saved Work",
      bslib::card(
        bslib::card_header("Your saved work"),
        shiny::p(
          "Everything you save with 'Save for later use' lands here, ",
          "and shows up by name wherever a computation can build on it - ",
          "for example, a saved design appears in the 'design' dropdown ",
          "of the sample size calculators."
        ),
        shiny::tableOutput("store_table"),
        bslib::card_footer(
          shiny::div(
            class = "d-flex gap-2 align-items-center flex-wrap",
            shiny::downloadButton("download_report", "Download report",
                                  class = "btn-primary btn-sm"),
            shiny::downloadButton("download_scenario", "Save session to file",
                                  class = "btn-outline-primary btn-sm"),
            shiny::span(class = "text-muted small",
              "The report is a single HTML file with every result, plot, ",
              "and a runnable R script - it prints cleanly to PDF."
            )
          )
        )
      ),
      bslib::card(
        bslib::card_header("Continue where you left off"),
        shiny::p(
          "A session file (.rds) holds everything in your saved work. ",
          "Restore one here to pick up a previous session."
        ),
        shiny::fileInput("restore_scenario", NULL, accept = ".rds",
                         buttonLabel = "Restore from file",
                         placeholder = "No session file chosen")
      )
    ),
    bslib::nav_spacer(),
    bslib::nav_item(bslib::input_dark_mode(id = "dark_mode", mode = NULL)),
    bslib::nav_panel(
      "Environment",
      bslib::card(
        bslib::card_header("Computational environment"),
        shiny::p(
          "All results are computed by the rpact package in the pinned ",
          "environment below. The app warns if the installed rpact ",
          "differs from the version the function catalog was built against."
        ),
        shiny::tableOutput("env_info")
      )
    )
  )
}

#' Read the design-system stylesheet shipped with the package
#' @keywords internal
workbench_css <- function() {
  path <- system.file("www", "workbench.css", package = "rpactdash")
  if (path == "") {
    path <- file.path("inst", "www", "workbench.css")
  }
  paste(readLines(path, encoding = "UTF-8"), collapse = "\n")
}

