# Server-level test of the generic runner module: drive the design
# module end-to-end (select function, fill arguments, run, store) the
# way the browser would.

test_that("mod_runner_server runs a design and stores it", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())

  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)

  shiny::testServer(
    mod_runner_server,
    args = list(
      family = "design", catalog = catalog,
      store = store, store_version = store_version,
      label_prefix = "design"
    ),
    {
      session$setInputs(
        fn = "getDesignGroupSequential",
        arg_kMax = "3", arg_alpha = "0.025", arg_typeOfDesign = '"asOF"',
        run = 1
      )
      o <- outcome()
      expect_true(o$res$ok)
      expect_identical(o$res$fn_name, "getDesignGroupSequential")
      expect_match(o$described$r_code, "getDesignGroupSequential")
      # session$user is NULL outside a deployed context; audit falls back
      # to the OS-level user identity
      expect_identical(o$record$user, Sys.info()[["user"]])

      # audit line was appended
      expect_length(audit_read(), 1)

      # suggested label was set; store the result
      session$setInputs(store_label = "design_1", store_save = 1)
      expect_identical(store_list(store)$label, "design_1")
      expect_identical(store_version(), 1)

      # a second save under the same label is refused, store unchanged
      session$setInputs(store_save = 2)
      expect_identical(nrow(store_list(store)), 1L)
    }
  )
})

test_that("mod_runner_server surfaces rpact errors without crashing", {
  withr::local_options(rpactdash.audit_dir = withr::local_tempdir())

  catalog <- load_catalog()
  store <- store_new()
  store_version <- shiny::reactiveVal(0)

  shiny::testServer(
    mod_runner_server,
    args = list(
      family = "design", catalog = catalog,
      store = store, store_version = store_version
    ),
    {
      session$setInputs(fn = "getDesignGroupSequential", arg_alpha = "1.5", run = 1)
      o <- outcome()
      expect_false(o$res$ok)
      expect_match(o$res$error, "alpha")
      records <- audit_read()
      expect_length(records, 1)
      expect_false(records[[1]]$ok)
    }
  )
})
