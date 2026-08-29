#' Application UI
#' @keywords internal
app_ui <- function() {
  bslib::page_navbar(
    title = "RPACT Trial Design Workbench",
    theme = bslib::bs_theme(
      version = 5,
      preset = "shiny",
      primary = "#0F6B66"
    ),
    bslib::nav_panel(
      "Design",
      mod_runner_ui("design")
    ),
    bslib::nav_panel(
      "Session Objects",
      bslib::card(
        bslib::card_header("Stored session objects"),
        shiny::p(
          "Results saved from any module. Reference one in an argument ",
          "field as @label (e.g. design = @design_1)."
        ),
        shiny::tableOutput("store_table")
      )
    ),
    bslib::nav_panel(
      "Sample Size & Power",
      bslib::card(
        bslib::card_header("Sample size & power module"),
        shiny::p("Sample size, power, and survival planning helpers. Arrives in Phase 3.")
      )
    ),
    bslib::nav_panel(
      "Catalog",
      bslib::card(
        bslib::card_header("Function catalog coverage"),
        shiny::tableOutput("catalog_summary")
      )
    ),
    bslib::nav_spacer(),
    bslib::nav_panel(
      "Environment",
      bslib::card(
        bslib::card_header("Computational environment"),
        shiny::p(
          "All results in this application are produced by the rpact package ",
          "in the pinned environment below. Version identity is a GxP control: ",
          "the catalog records the rpact version it was generated against, and ",
          "the app verifies it at startup."
        ),
        shiny::tableOutput("env_info")
      )
    )
  )
}
