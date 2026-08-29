#' Application UI
#' @keywords internal
app_ui <- function() {
  bslib::page_navbar(
    id = "nav",
    title = shiny::tagList(
      "Clinical Trial Design Workbench",
      shiny::span(
        class = "badge rounded-pill wb-wip ms-2 align-middle",
        title = "Under active development - features and examples are still being added.",
        "work in progress"
      )
    ),
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
      wb_tool_page(
        wb_page_header(
          "Plan", "Sample size and power",
          paste(
            "How many patients the trial needs - or, when the number is",
            "already fixed, what it can honestly detect. Means, rates, and",
            "time-to-event endpoints."
          )
        ),
        mod_runner_ui("samplesize")
      )
    ),
    bslib::nav_panel(
      "Design",
      wb_tool_page(
        wb_page_header(
          "Plan", "Group sequential designs",
          paste(
            "Boundaries for a trial that may stop early: the classic",
            "families, alpha spending, and the characteristics that show",
            "what each interim look costs."
          )
        ),
        mod_runner_ui("design")
      )
    ),
    bslib::nav_panel(
      "Simulation",
      wb_tool_page(
        wb_page_header(
          "Check", "Simulation",
          paste(
            "Run a design a thousand times and count what actually happens",
            "- including the multi-arm and enrichment designs no closed",
            "formula covers."
          )
        ),
        mod_runner_ui("simulation")
      )
    ),
    bslib::nav_panel(
      "Analysis",
      wb_tool_page(
        wb_page_header(
          "Monitor", "Interim analysis",
          paste(
            "Enter the data observed so far, then read the running trial:",
            "the statistic against its boundary, conditional power, and",
            "confidence intervals that stay honest despite the early looks."
          )
        ),
        bslib::navset_underline(
          id = "analysis_tabs",
          bslib::nav_panel("1 · Enter data", mod_dataset_ui("dataset")),
          bslib::nav_panel("2 · Analyze", mod_runner_ui("analysis"))
        )
      )
    ),
    bslib::nav_panel(
      "Compare Designs",
      wb_tool_page(
        wb_page_header(
          "Compare", "Designs side by side",
          paste(
            "Put two or more saved designs on the same axes and read where",
            "they differ - what the boundaries look like, and what each one",
            "costs in sample size."
          )
        ),
        mod_compare_ui("compare")
      )
    ),
    bslib::nav_panel(
      "Saved Work",
      wb_page(
        wb_page_header(
          "Session", "Your saved work",
          paste(
            "Everything you save lands here, and shows up by name wherever",
            "a computation can build on it - a saved design appears in the",
            "'design' dropdown of the sample size calculators, for instance."
          )
        ),
        bslib::card(
          bslib::card_header("Saved results"),
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
      )
    ),
    bslib::nav_spacer(),
    bslib::nav_item(bslib::input_dark_mode(id = "dark_mode", mode = NULL)),
    bslib::nav_panel(
      "Environment",
      wb_page(
        wb_page_header(
          "Provenance", "Computational environment",
          paste(
            "Every result on every tab is computed by rpact in the pinned",
            "environment below. The app warns if the installed rpact differs",
            "from the version the function catalog was built against."
          )
        ),
        bslib::card(
          bslib::card_header("Versions"),
          shiny::tableOutput("env_info")
        )
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

