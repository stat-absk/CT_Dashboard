# The guided learning path on the Start tab.
#
# Ordered the way statisticians actually learn trial design: fixed-design
# sample size first, then power, then survival's events-not-people logic,
# and only then the step up to group sequential designs. Each chapter
# teaches one idea in plain language and drops the reader into the live
# tool with the matching worked example loaded and running. Chapters that
# need a saved design seed it automatically (audited like any other
# computation) so no chapter can dead-end.
#
# The page is laid out as a course: one obvious way in, a contents list so
# the whole course is visible at a glance, then the chapters grouped into
# the three parts they genuinely form. The grouping carries information -
# part two only makes sense once part one is understood - so it is
# structure, not ornament.
#
# The parts are declared once, as data, and the contents list and the
# chapter cards are both generated from that declaration. Writing the
# chapter titles twice would let the two drift apart.

#' The course, as data
#'
#' Each chapter's `id` is its `actionButton` input id; `learn_server()`
#' matches on the same ids. `dest` names the tab its button lands on.
#' @keywords internal
learn_parts <- function() {
  list(
    list(
      eyebrow = "Part one",
      title = "Sizing a fixed trial",
      note = paste(
        "Where every trial starts: how big it has to be, what a fixed",
        "budget can actually detect, and why survival trials count events",
        "instead of people."
      ),
      chapters = list(
        list(
          n = 1,
          title = "How many patients?",
          lead = paste(
            "Four quantities fix the answer: the effect you want to detect,",
            "how noisy the endpoint is, the false-positive rate you can",
            "tolerate, and the power you want. We compare two group means -",
            "the simplest case there is."
          ),
          takeaway = paste(
            "Halve the effect from 0.5 to 0.25 and the sample size",
            "quadruples. That inverse-square law is the single most",
            "important intuition in trial design."
          ),
          id = "learn_go_1",
          label = "Calculate a sample size",
          dest = "Sample Size & Power"
        ),
        list(
          n = 2,
          title = "What your budget can detect",
          lead = paste(
            "In practice the sample size is fixed by money or feasibility,",
            "so the honest question flips: with these patients, what can we",
            "detect? 200 patients, a 30% control response rate, and a range",
            "of treatment effects."
          ),
          takeaway = paste(
            "With 200 patients a real 10-point improvement is more likely",
            "missed than found. A study that cannot answer its own question",
            "is the failure power calculations exist to prevent."
          ),
          id = "learn_go_2",
          label = "Explore a power curve",
          dest = "Sample Size & Power"
        ),
        list(
          n = 3,
          title = "Survival counts events, not people",
          lead = paste(
            "Time-to-event endpoints change the accounting: information",
            "arrives with events - deaths, progressions - not with",
            "enrollment. The events you need depend only on the hazard",
            "ratio, alpha, and power."
          ),
          takeaway = paste(
            "Patients, accrual, and follow-up are then the three levers you",
            "pull to collect those events on a calendar anyone will agree to."
          ),
          id = "learn_go_3",
          label = "Size a survival trial",
          dest = "Sample Size & Power"
        )
      )
    ),
    list(
      eyebrow = "Part two",
      title = "Designs that can stop early",
      note = paste(
        "Interim looks let a trial end as soon as the answer is in - but",
        "they have a price, and the boundary family you choose decides",
        "how much."
      ),
      chapters = list(
        list(
          n = 4,
          title = "The case for looking early",
          lead = paste(
            "A fixed trial locks you in until the end, even when the effect",
            "is dramatic, or clearly absent, halfway through. Group",
            "sequential designs add planned looks with adjusted boundaries,",
            "so you can stop without inflating the false-positive rate."
          ),
          takeaway = paste(
            "You will build the workhorse of confirmatory practice: three",
            "looks, O'Brien-Fleming spending. Save it when it appears - the",
            "next chapter builds on it."
          ),
          id = "learn_go_4",
          label = "Create a sequential design",
          dest = "Design"
        ),
        list(
          n = 5,
          title = "What do the looks cost?",
          lead = paste(
            "Now put the two ideas together: chapter one's means comparison,",
            "run under chapter four's design. Then compare the numbers with",
            "the fixed trial."
          ),
          takeaway = paste(
            "The maximum sample size barely moves - about 128 to 129 - but",
            "the expected size falls to roughly 110. Small worst-case",
            "premium, large average saving: the entire sales pitch for",
            "interim looks."
          ),
          id = "learn_go_5",
          label = "Size the sequential trial",
          dest = "Sample Size & Power"
        ),
        list(
          n = 6,
          title = "O'Brien-Fleming vs Pocock",
          lead = paste(
            "Not all interim looks are priced the same. O'Brien-Fleming",
            "boundaries make stopping early hard and cost almost nothing;",
            "Pocock boundaries make it easy and inflate the sample size",
            "noticeably."
          ),
          takeaway = paste(
            "Both designs are waiting on the Compare tab. Tick them, press",
            "Compare, and the trade-off every protocol team argues about",
            "lands on a single plot."
          ),
          id = "learn_go_6",
          label = "Compare the two designs",
          dest = "Compare Designs"
        )
      )
    ),
    list(
      eyebrow = "Part three",
      title = "Beyond the formula",
      note = paste(
        "Check the assumptions the formulas rest on, then stop planning",
        "and read a trial that is already running."
      ),
      chapters = list(
        list(
          n = 7,
          title = "Trust, but simulate",
          lead = paste(
            "Chapters one to six rest on assumptions: normality, known",
            "variances, proportional hazards. Simulation is how trialists",
            "check them - generate a thousand trials and count what actually",
            "happens."
          ),
          takeaway = paste(
            "Once the round trip checks out, simulation becomes the design",
            "tool for what formulas cannot do at all: multi-arm trials with",
            "interim selection, and biomarker enrichment."
          ),
          id = "learn_go_7",
          label = "Simulate your first trial",
          dest = "Simulation"
        ),
        list(
          n = 8,
          title = "Your first interim analysis",
          lead = paste(
            "Everything so far was planning. Now the trial is underway, two",
            "of three stages are complete, and you are the statistician",
            "reporting to the data monitoring committee."
          ),
          takeaway = paste(
            "Has the efficacy boundary been crossed - stop for success - or",
            "does the trial continue? You will read the observed effect, the",
            "statistic against the boundary, conditional power, and repeated",
            "confidence intervals."
          ),
          id = "learn_go_8",
          label = "Run the interim analysis",
          dest = "Analysis"
        )
      )
    )
  )
}

#' The anchor a chapter card is reachable at
#' @keywords internal
learn_anchor <- function(n) paste0("chapter-", n)

#' Contents: the whole course at a glance, in three columns of links
#'
#' The page is roughly 2500px tall, so without this the reader cannot see
#' what the eight chapters are without scrolling the length of the course.
#' The columns are the three parts, so the contents also states the shape
#' of the course rather than just listing it.
#' @keywords internal
learn_toc <- function(parts) {
  column <- function(part) {
    shiny::div(
      class = "wb-toc-col",
      shiny::p(class = "wb-toc-part",
               paste0(part$eyebrow, " · ", part$title)),
      shiny::tags$ul(
        class = "wb-toc-list",
        lapply(part$chapters, function(ch) {
          shiny::tags$li(
            shiny::tags$a(
              href = paste0("#", learn_anchor(ch$n)),
              shiny::span(class = "wb-toc-n", `aria-hidden` = "true", ch$n),
              shiny::span(
                class = "wb-toc-text",
                # Numbered for screen readers, which skip the visual numeral.
                shiny::span(class = "visually-hidden",
                            paste0("Chapter ", ch$n, ": ")),
                ch$title
              )
            )
          )
        })
      )
    )
  }
  shiny::tags$nav(
    class = "wb-toc",
    `aria-label` = "Course contents",
    shiny::p(class = "wb-eyebrow", "Contents"),
    shiny::div(class = "wb-toc-cols", lapply(parts, column))
  )
}

#' One chapter, as a card in the path
#'
#' The numeral is shown large and faint and hidden from screen readers -
#' the sequence is already carried by the heading text and DOM order.
#' `dest` is named because a control that moves you somewhere should say
#' where it is taking you.
#' @keywords internal
learn_chapter_card <- function(ch) {
  shiny::div(
    class = "wb-chapter",
    id = learn_anchor(ch$n),
    # Focusable only programmatically, so a contents link can move focus
    # here and keyboard users continue from the chapter they jumped to.
    tabindex = "-1",
    shiny::span(class = "wb-chapter-n", `aria-hidden` = "true", ch$n),
    shiny::h3(
      class = "wb-chapter-title",
      shiny::span(class = "visually-hidden", paste0("Chapter ", ch$n, ": ")),
      ch$title
    ),
    shiny::p(class = "wb-chapter-lead", ch$lead),
    shiny::p(class = "wb-takeaway", ch$takeaway),
    shiny::div(
      class = "wb-chapter-foot",
      shiny::actionButton(ch$id, ch$label, class = "btn-primary"),
      shiny::span(class = "wb-dest", ch$dest)
    )
  )
}

#' One part: an eyebrow, a framing line, and the chapters it contains
#' @keywords internal
learn_part_section <- function(part) {
  shiny::tagList(
    shiny::div(
      class = "wb-act",
      shiny::p(class = "wb-eyebrow", part$eyebrow),
      shiny::h2(part$title),
      shiny::p(part$note)
    ),
    shiny::div(
      class = "wb-chapters",
      lapply(part$chapters, learn_chapter_card)
    )
  )
}

#' @keywords internal
learn_ui <- function() {
  parts <- learn_parts()
  n_chapters <- sum(vapply(parts, function(p) length(p$chapters), integer(1)))

  stat <- function(n, label) {
    shiny::div(
      shiny::span(class = "wb-stat-n", n),
      shiny::span(class = "wb-stat-l", label)
    )
  }

  shiny::div(
    class = "wb-start",

    # The page scrolls inside this panel rather than the document, and a
    # bare "#chapter-n" jump does not reliably drive a nested scroller, so
    # contents links are handled explicitly. Focus follows the jump so
    # keyboard users carry on from the chapter they landed on.
    shiny::tags$script(shiny::HTML("
      document.addEventListener('click', function (e) {
        var link = e.target.closest('a[href^=\"#chapter-\"]');
        if (!link) return;
        var target = document.getElementById(link.hash.slice(1));
        if (!target) return;
        e.preventDefault();
        var still = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
        target.scrollIntoView({ behavior: still ? 'auto' : 'smooth',
                                block: 'start' });
        target.focus({ preventScroll: true });
      });
    ")),

    # ---- Hero: the offer, and one obvious way in --------------------------
    shiny::div(
      class = "wb-hero",
      shiny::div(
        class = "wb-hero-flags",
        shiny::p(class = "wb-eyebrow", "A hands-on course"),
        shiny::span(
          class = "wb-flag",
          title = paste("Under active development - chapters and examples",
                        "are still being added."),
          "Work in progress"
        )
      ),
      shiny::h1("Learn clinical trial design by designing trials."),
      shiny::p(
        class = "wb-hero-lead",
        "Eight chapters that start with the question every trial begins ",
        "with - how many patients? - and end with you in the data ",
        "monitoring committee's seat, reading an interim analysis. Every ",
        "screen mirrors the real rpact API, and every result shows the R ",
        "code that produced it."
      ),
      shiny::div(
        class = "wb-hero-actions",
        shiny::actionButton(
          "learn_start", "Start with chapter 1",
          class = "btn-primary btn-lg"
        ),
        shiny::tags$a(
          class = "btn wb-btn-ghost",
          href = paste0("https://github.com/stat-absk/CT_Dashboard",
                        "/blob/main/TUTORIAL.md"),
          target = "_blank", rel = "noopener",
          "Read the full tutorial"
        )
      ),
      shiny::div(
        class = "wb-stats",
        stat(n_chapters, "guided chapters"),
        stat("64", "worked examples"),
        stat("58", "rpact functions covered")
      )
    ),

    # ---- Contents ---------------------------------------------------------
    learn_toc(parts),

    # ---- The three parts --------------------------------------------------
    lapply(parts, learn_part_section),

    # ---- Outro ------------------------------------------------------------
    shiny::div(
      class = "wb-outro",
      shiny::h2("Already know your way around?"),
      shiny::p(
        "Every tab works on its own, and each function carries worked ",
        "examples you can load with a click, run, and then bend. Anything ",
        "you compute can be saved, carried into the next calculation, ",
        "exported as a report, or written to a session file and restored ",
        "later."
      ),
      shiny::p(
        shiny::tags$em(
          "The workbench is a teaching tool and a work in progress, not a ",
          "validated system. A design headed for a protocol should be ",
          "reproduced in rpact itself - which is what the R code under ",
          "every result is for."
        )
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

  ensure_dataset <- function() {
    label <- "Interim data (continuous)"
    if (!is.null(store_get(store, label))) return(invisible())
    outcome <- run_catalog_function(
      "getDataset",
      list(n1 = "c(22, 22)", n2 = "c(22, 22)",
           means1 = "c(0.64, 0.51)", means2 = "c(0.08, 0.12)",
           stDevs1 = "c(1.02, 0.98)", stDevs2 = "c(0.97, 1.01)"),
      catalog
    )
    audit_append(audit_record(outcome, user = session$user))
    store_put(store, label, outcome$result,
              fn_name = "getDataset", call_text = outcome$call_text)
    store_version(store_version() + 1)
    shiny::showNotification(
      sprintf("'%s' was created and added to your saved work for this chapter.",
              label),
      type = "message"
    )
  }

  # The hero button and chapter 1's own button are the same journey; the
  # hero one exists so the page has a single obvious way in.
  start_chapter_1 <- function() {
    go("Sample Size & Power", "samplesize", "getSampleSizeMeans", 1)
  }
  shiny::observeEvent(input$learn_start, start_chapter_1())
  shiny::observeEvent(input$learn_go_1, start_chapter_1())
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
  shiny::observeEvent(input$learn_go_7, {
    ensure_design("O'Brien-Fleming (3 looks)", "asOF")
    go("Simulation", "simulation", "getSimulationMeans", 1)
  })
  shiny::observeEvent(input$learn_go_8, {
    ensure_design("O'Brien-Fleming (3 looks)", "asOF")
    ensure_dataset()
    go("Analysis", "analysis", "getAnalysisResults", 1)
    bslib::nav_select("analysis_tabs", "2 · Analyze", session = session)
  })
}
