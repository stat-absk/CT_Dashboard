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
    bslib::nav_panel(
      "Start",
      start_page_ui()
    ),
    bslib::nav_panel(
      "Design",
      mod_runner_ui("design")
    ),
    bslib::nav_panel(
      "Sample Size & Power",
      mod_runner_ui("samplesize")
    ),
    bslib::nav_panel(
      "Compare Designs",
      mod_compare_ui("compare")
    ),
    bslib::nav_panel(
      "Session Objects",
      bslib::card(
        bslib::card_header("Saved results"),
        shiny::p(
          "Everything you save with 'Save for later use' appears here, ",
          "and becomes selectable as an input in the other tabs - the ",
          "same way rpact objects are passed between functions in R code."
        ),
        shiny::tableOutput("store_table")
      )
    ),
    bslib::nav_spacer(),
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

#' The Start tab: orientation and a three-step learning path
#' @keywords internal
start_page_ui <- function() {
  step_card <- function(step, title, body, button_id, button_label) {
    bslib::card(
      bslib::card_header(paste0(step, " · ", title)),
      shiny::p(body),
      shiny::actionButton(button_id, button_label, class = "btn-primary mt-auto")
    )
  }
  shiny::tagList(
    bslib::card(
      bslib::card_header("Learn adaptive trial design by doing"),
      shiny::p(
        "This is a free, open-source practice environment for the rpact ",
        "R package, built for statisticians who are new to group ",
        "sequential and adaptive designs. Every screen mirrors the real ",
        "rpact API: what you learn here transfers directly to your own ",
        "R scripts, because every result shows the exact code that ",
        "produced it."
      ),
      shiny::p(
        shiny::strong("How to use it: "),
        "each computation offers worked examples - realistic scenarios ",
        "with notes on what to look for in the output. Load one, read ",
        "the result, then change an input and watch the result update. ",
        "Hover any argument name for its official documentation."
      )
    ),
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      step_card(
        "1", "Design a trial",
        paste0(
          "Create a group sequential design: how many looks, how the ",
          "significance level is spent across them, and what the efficacy ",
          "boundaries look like. Start with the O'Brien-Fleming worked ",
          "example, then save your design for step 2."
        ),
        "go_design", "Open Design"
      ),
      step_card(
        "2", "Size it",
        paste0(
          "Compute the sample size or power for your saved design across ",
          "the four endpoint types - means, rates, survival, counts - ",
          "plus the survival planning helpers and unit converters every ",
          "trialist uses."
        ),
        "go_samplesize", "Open Sample Size & Power"
      ),
      step_card(
        "3", "Compare & explore",
        paste0(
          "Put two designs side by side - O'Brien-Fleming against Pocock ",
          "is the classic first comparison - and see the trade-off ",
          "between early stopping and sample size in one plot."
        ),
        "go_compare", "Open Compare Designs"
      )
    )
  )
}
