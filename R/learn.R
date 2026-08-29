# The guided learning path on the Start tab.
#
# Ordered the way statisticians actually learn trial design: fixed-design
# sample size first, then power, then survival's events-not-people logic,
# and only then the step up to group sequential designs. Each chapter
# teaches one idea in plain language and drops the reader into the live
# tool with the matching worked example loaded and running. Chapters that
# need a saved design seed it automatically (audited like any other
# computation) so no chapter can dead-end.

#' @keywords internal
learn_ui <- function() {
  chapter <- function(n, title, ..., button_id, button_label) {
    bslib::accordion_panel(
      title = paste0(n, " · ", title),
      value = paste0("ch", n),
      ...,
      shiny::actionButton(button_id, button_label, class = "btn-primary")
    )
  }
  shiny::tagList(
    bslib::card(
      bslib::card_header("Learn clinical trial design by doing"),
      shiny::p(
        "A free, open-source practice environment for the rpact R package. ",
        "It is built for statisticians who are new to trial design, and it ",
        "teaches the way people actually learn: start with the question ",
        "every trial begins with - how many patients? - then power, then ",
        "the step up to designs with interim looks."
      ),
      shiny::p(
        "Every screen mirrors the real rpact API, and every result shows ",
        "the exact R code that produced it, so what you learn here ",
        "transfers directly to your own scripts. Follow the chapters below ",
        "in order, or jump straight into any tab if you already know your ",
        "way around."
      )
    ),
    bslib::accordion(
      open = "ch1",
      chapter(
        1, "How many patients? Your first sample size calculation",
        shiny::p(
          "Every trial starts here. Four quantities fix the answer: the ",
          "effect you want to detect, how noisy the endpoint is, the ",
          "false-positive rate you can tolerate (alpha), and the chance ",
          "of finding a real effect (power). We'll compare the means of ",
          "two groups - the simplest case - with a medium effect."
        ),
        shiny::p(
          "Once the result is up, try it: halve the effect from 0.5 to ",
          "0.25 and watch the sample size quadruple. That inverse-square ",
          "law is the single most important intuition in trial design."
        ),
        button_id = "learn_go_1",
        button_label = "Calculate your first sample size"
      ),
      chapter(
        2, "Power: what your budget can actually detect",
        shiny::p(
          "In practice the sample size is often fixed by budget or ",
          "feasibility, and the honest question becomes: with this many ",
          "patients, what can we detect? This chapter turns the ",
          "calculation around for a binary endpoint: 200 patients, ",
          "a 30% control response rate, and a range of treatment effects."
        ),
        shiny::p(
          "The sobering lesson in the power curve: with 200 patients, a ",
          "real 10-point improvement is more likely missed than found. ",
          "Running a study that cannot answer its own question is the ",
          "failure mode power calculations exist to prevent."
        ),
        button_id = "learn_go_2",
        button_label = "Explore a power curve"
      ),
      chapter(
        3, "Survival trials count events, not people",
        shiny::p(
          "Time-to-event endpoints change the accounting: information ",
          "comes from events (deaths, progressions), not from enrollment. ",
          "The required number of events depends only on the hazard ",
          "ratio, alpha, and power - patients, accrual, and follow-up ",
          "are then the levers you pull to collect those events on an ",
          "acceptable calendar."
        ),
        button_id = "learn_go_3",
        button_label = "Size a survival trial"
      ),
      chapter(
        4, "The case for looking early: group sequential designs",
        shiny::p(
          "A fixed trial locks you in until the end - even if the ",
          "treatment effect is dramatic, or clearly absent, halfway ",
          "through. Group sequential designs add planned interim looks ",
          "with adjusted significance thresholds (boundaries), so you ",
          "can stop early for efficacy or futility without inflating ",
          "the false-positive rate."
        ),
        shiny::p(
          "You'll create the workhorse of confirmatory practice: three ",
          "looks with O'Brien-Fleming-type alpha spending. When the ",
          "boundaries appear, press ", shiny::strong("Save for later use"),
          " - a name is suggested for you - because the next chapter ",
          "builds on this design."
        ),
        button_id = "learn_go_4",
        button_label = "Create a group sequential design"
      ),
      chapter(
        5, "Sizing the sequential trial: what do the looks cost?",
        shiny::p(
          "Now combine the two ideas: the same means comparison from ",
          "chapter 1, run under the chapter 4 design. Compare the ",
          "numbers with the fixed trial: the maximum sample size barely ",
          "moves (about 128 to 129), but the expected sample size drops ",
          "to about 110, because the trial can stop at the interims. ",
          "Small worst-case premium, large average saving - that is the ",
          "entire sales pitch for interim looks."
        ),
        button_id = "learn_go_5",
        button_label = "Size the sequential trial"
      ),
      chapter(
        6, "O'Brien-Fleming vs Pocock: the classic trade-off",
        shiny::p(
          "Not all interim looks are priced the same. O'Brien-Fleming ",
          "boundaries make early stopping hard and cost almost nothing; ",
          "Pocock boundaries make early stopping easy and inflate the ",
          "sample size noticeably. Both designs are waiting for you on ",
          "the Compare tab: tick them, press Compare, and you will see ",
          "the trade-off every protocol team argues about on one plot."
        ),
        button_id = "learn_go_6",
        button_label = "Compare the two designs"
      )
    )
  )
}

#' Server logic for the learning path
#'
#' @param pending `reactiveVal` consumed by the runner modules: a list
#'   of `module`, `fn`, `example` selects that tab's function and loads
#'   the worked example.
#' @keywords internal
learn_server <- function(input, session, store, store_version, pending, catalog) {
  go <- function(tab, module = NULL, fn = NULL, example = NULL) {
    if (!is.null(module)) {
      pending(list(module = module, fn = fn, example = example))
    }
    bslib::nav_select("nav", tab, session = session)
  }

  ensure_design <- function(label, type_of_design) {
    if (!is.null(store_get(store, label))) return(invisible())
    outcome <- run_catalog_function(
      "getDesignGroupSequential",
      list(kMax = "3", alpha = "0.025", beta = "0.2", sided = "1",
           typeOfDesign = paste0('"', type_of_design, '"')),
      catalog
    )
    audit_append(audit_record(outcome, user = session$user))
    store_put(store, label, outcome$result,
              fn_name = "getDesignGroupSequential",
              call_text = outcome$call_text)
    store_version(store_version() + 1)
    shiny::showNotification(
      sprintf("'%s' was created and added to your saved work for this chapter.",
              label),
      type = "message"
    )
  }

  shiny::observeEvent(input$learn_go_1,
    go("Sample Size & Power", "samplesize", "getSampleSizeMeans", 1))
  shiny::observeEvent(input$learn_go_2,
    go("Sample Size & Power", "samplesize", "getPowerRates", 1))
  shiny::observeEvent(input$learn_go_3,
    go("Sample Size & Power", "samplesize", "getSampleSizeSurvival", 1))
  shiny::observeEvent(input$learn_go_4,
    go("Design", "design", "getDesignGroupSequential", 1))
  shiny::observeEvent(input$learn_go_5, {
    ensure_design("O'Brien-Fleming (3 looks)", "asOF")
    go("Sample Size & Power", "samplesize", "getSampleSizeMeans", 2)
  })
  shiny::observeEvent(input$learn_go_6, {
    ensure_design("O'Brien-Fleming (3 looks)", "asOF")
    ensure_design("Pocock (3 looks)", "asP")
    go("Compare Designs")
  })
}
