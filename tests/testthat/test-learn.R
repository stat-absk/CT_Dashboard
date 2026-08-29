# The guided learning path: chapters hand a function + worked example to
# the runner modules via `pending`, and later chapters seed the designs
# they depend on.

test_that("learn_ui builds with eight ordered chapters", {
  html <- as.character(shiny::tagList(learn_ui()))
  for (n in 1:8) {
    # each chapter is a card with an anchor, a contents link, and a button
    expect_match(html, paste0('id="chapter-', n, '"'), fixed = TRUE)
    expect_match(html, paste0('href="#chapter-', n, '"'), fixed = TRUE)
    expect_match(html, paste0('id="learn_go_', n, '"'), fixed = TRUE)
  }
  # the hero's way in
  expect_match(html, 'id="learn_start"', fixed = TRUE)
  # the arc starts by sizing a fixed trial, not with sequential designs
  expect_lt(
    regexpr("Sizing a fixed trial", html)[1],
    regexpr("Designs that can stop early", html)[1]
  )
})

test_that("the contents lists exactly the chapters that exist", {
  # The contents and the cards are generated from one declaration; this is
  # the guard that keeps them from drifting apart if that ever changes.
  parts <- learn_parts()
  chapters <- unlist(lapply(parts, `[[`, "chapters"), recursive = FALSE)

  expect_identical(vapply(chapters, `[[`, numeric(1), "n"), as.numeric(1:8))
  expect_identical(
    vapply(chapters, `[[`, character(1), "id"),
    paste0("learn_go_", 1:8)
  )

  toc <- as.character(shiny::tagList(learn_toc(parts)))
  for (ch in chapters) {
    expect_match(toc, ch$title, fixed = TRUE)
    expect_match(toc, paste0('href="#chapter-', ch$n, '"'), fixed = TRUE)
  }
})

test_that("a pending example switches the runner's function and runs it", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())
  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)
  pending <- shiny::reactiveVal(NULL)

  shiny::testServer(
    mod_runner_server,
    args = list(
      family = "samplesize_power", catalog = catalog,
      store = store, store_version = store_version,
      pending = pending
    ),
    {
      session$setInputs(fn = "getSampleSizeMeans")
      pending(list(module = "proxy1", fn = "getPowerRates", example = 1))
      session$flushReact()
      # the module consumed the pending request and staged the example
      expect_null(pending())
      # the client would now re-render the form; simulate its report-back
      # (elapse advances mock time past the 1s input debounce)
      session$setInputs(fn = "getPowerRates", arg_pi2 = "0.3",
                        arg_maxNumberOfSubjects = "200")
      session$elapse(1100)
      # the staged example is applied; its updates echo back as another
      # input tick, which executes the queued run
      session$setInputs(arg_pi1 = "seq(0.4, 0.6, 0.05)")
      session$elapse(1100)
      o <- outcome()
      expect_identical(o$res$fn_name, "getPowerRates")
    }
  )
})

test_that("a pending example for the already-selected function applies directly", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())
  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)
  pending <- shiny::reactiveVal(NULL)

  shiny::testServer(
    mod_runner_server,
    args = list(
      family = "samplesize_power", catalog = catalog,
      store = store, store_version = store_version,
      pending = pending
    ),
    {
      session$setInputs(fn = "getSampleSizeMeans")
      pending(list(module = "proxy1", fn = "getSampleSizeMeans", example = 1))
      session$flushReact()
      expect_null(pending())
      # apply_example marked a run as pending; any input tick executes it
      session$setInputs(arg_alternative = "0.5", arg_stDev = "1")
      session$elapse(1100)
      o <- outcome()
      expect_true(o$res$ok)
      expect_identical(o$res$fn_name, "getSampleSizeMeans")
    }
  )
})

test_that("pending requests addressed to another module are ignored", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())
  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)
  pending <- shiny::reactiveVal(NULL)

  shiny::testServer(
    mod_runner_server,
    args = list(
      family = "design", catalog = catalog,
      store = store, store_version = store_version,
      pending = pending
    ),
    {
      session$setInputs(fn = "getDesignGroupSequential")
      pending(list(module = "not-this-module", fn = "getDesignFisher", example = 1))
      session$flushReact()
      # not consumed, not applied
      expect_false(is.null(pending()))
    }
  )
})

test_that("learn chapters seed the designs they depend on", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())
  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)
  pending <- shiny::reactiveVal(NULL)

  server <- function(input, output, session) {
    learn_server(input, session, store, store_version, pending, catalog)
  }
  shiny::testServer(server, {
    session$setInputs(learn_go_6 = 1)
    d1 <- store_get(store, "O'Brien-Fleming (3 looks)")
    d2 <- store_get(store, "Pocock (3 looks)")
    expect_s4_or_r6 <- inherits(d1, "TrialDesign") && inherits(d2, "TrialDesign")
    expect_true(expect_s4_or_r6)
    # the seeds are the canonical chapter designs
    direct <- rpact::getDesignGroupSequential(kMax = 3, alpha = 0.025,
                                              beta = 0.2, sided = 1,
                                              typeOfDesign = "asP")
    expect_identical(d2$criticalValues, direct$criticalValues)
    expect_identical(store_version(), 2)
    # seeding is idempotent
    session$setInputs(learn_go_5 = 1)
    expect_identical(store_version(), 2)
    # and chapter 5 queued its example for the samplesize module
    expect_identical(pending()$fn, "getSampleSizeMeans")
    expect_identical(pending()$example, 2)
  })
})
