# The session report: one self-contained HTML file with every saved
# result, its creating call, summary, an embedded plot, and a runnable
# R script.

test_that("the report includes saved work, plots, and a runnable script", {
  store <- store_new()
  design <- rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")
  store_put(store, "O'Brien-Fleming (3 looks)", design,
            fn_name = "getDesignGroupSequential",
            call_text = 'rpact::getDesignGroupSequential(kMax = 3, typeOfDesign = "asOF")')
  ss <- rpact::getSampleSizeMeans(design, alternative = 0.5, stDev = 1)
  store_put(store, "Sample Size Means", ss,
            fn_name = "getSampleSizeMeans",
            call_text = "rpact::getSampleSizeMeans(design = obf, alternative = 0.5, stDev = 1)")

  html <- render_report(store)

  expect_match(html, "<!DOCTYPE html>", fixed = TRUE)
  expect_match(html, "O'Brien-Fleming (3 looks)", fixed = TRUE)
  expect_match(html, "Sample Size Means", fixed = TRUE)
  expect_match(html, "getDesignGroupSequential", fixed = TRUE)
  expect_match(html, "Sequential analysis", fixed = TRUE)
  # at least one embedded plot
  expect_match(html, "data:image/png;base64,", fixed = TRUE)
  # the reproducible script section with readable variable names
  expect_match(html, "Reproducible R script", fixed = TRUE)
  expect_match(html, "o_brien_fleming_3_looks &lt;- rpact::getDesignGroupSequential",
               fixed = TRUE)
  # environment versions in the footer
  expect_match(html, as.character(utils::packageVersion("rpact")), fixed = TRUE)

  # writes as a well-formed standalone file
  path <- withr::local_tempfile(fileext = ".html")
  writeLines(html, path, useBytes = TRUE)
  expect_gt(file.size(path), 10000)
})

test_that("an empty session still renders a friendly report", {
  html <- render_report(store_new())
  expect_match(html, "Nothing saved yet", fixed = TRUE)
  expect_false(grepl("Reproducible R script", html, fixed = TRUE))
})
