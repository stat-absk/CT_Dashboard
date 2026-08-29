# Self-contained HTML report of the user's saved work.
#
# One file, no external toolchain (no pandoc/quarto): for every saved
# result it includes what it is, the call that made it, the rpact
# summary, and the first available plot embedded as an image - plus a
# complete reproducible R script and the environment versions. Opens in
# any browser and prints cleanly to PDF.

#' Render the session report as an HTML string
#'
#' @param store Session object store.
#' @param catalog Function catalog (for friendly titles).
#' @return Character scalar of complete HTML.
#' @keywords internal
render_report <- function(store, catalog = load_catalog()) {
  esc <- htmltools::htmlEscape
  titles <- stats::setNames(
    vapply(catalog$functions, function(f)
      sub("^Get ", "", if (is.null(f$title) || is.na(f$title)) f$name else f$title),
      character(1)),
    vapply(catalog$functions, function(f) f$name, character(1))
  )

  sections <- character(0)
  script_lines <- character(0)

  for (label in names(store$objects)) {
    entry <- store$objects[[label]]
    x <- entry$object
    made_with <- if (!is.na(entry$fn_name) && entry$fn_name %in% names(titles)) {
      titles[[entry$fn_name]]
    } else {
      entry$class
    }

    call_html <- if (!is.null(entry$call_text) && !is.na(entry$call_text)) {
      script_lines <- c(script_lines,
                        paste0(label_to_var(label), " <- ", entry$call_text))
      sprintf("<pre>%s</pre>", esc(entry$call_text))
    } else {
      ""
    }

    described <- describe_result(x)
    summary_html <- {
      txt <- described$summary_text %||% described$print_text
      if (is.null(txt)) "" else sprintf("<pre>%s</pre>", esc(txt))
    }

    plot_html <- tryCatch({
      types <- described$plot_types
      if (length(types) == 0) "" else {
        png_file <- tempfile(fileext = ".png")
        grDevices::png(png_file, width = 880, height = 520, res = 108)
        print(plot(x, type = as.integer(types[1])))
        grDevices::dev.off()
        data <- jsonlite::base64_enc(readBin(png_file, "raw",
                                             file.size(png_file)))
        unlink(png_file)
        sprintf('<img alt="Plot of %s" src="data:image/png;base64,%s">',
                esc(label), gsub("\n", "", data))
      }
    }, error = function(e) "")

    sections <- c(sections, sprintf(
      '<section><h2>%s</h2><p class="meta">%s &middot; saved %s</p>%s%s%s</section>',
      esc(label), esc(made_with), esc(entry$created),
      call_html, summary_html, plot_html
    ))
  }

  body <- if (length(sections) == 0) {
    "<p>Nothing saved yet. Save results in the app with 'Save for later use', then export again.</p>"
  } else {
    paste(sections, collapse = "\n")
  }

  script_html <- if (length(script_lines) == 0) "" else sprintf(
    '<section><h2>Reproducible R script</h2><p class="meta">Runs as-is with the rpact package installed.</p><pre>library(rpact)\n\n%s</pre></section>',
    esc(paste(script_lines, collapse = "\n"))
  )

  versions <- sprintf(
    "Generated %s &middot; R %s &middot; rpact %s &middot; RPACT Trial Design Workbench %s",
    format(Sys.time(), "%Y-%m-%d %H:%M"),
    paste(R.version$major, R.version$minor, sep = "."),
    utils::packageVersion("rpact"),
    utils::packageVersion("rpactdash")
  )

  sprintf(
    '<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Trial Design Report</title>
<style>
body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
       max-width: 60rem; margin: 0 auto; padding: 2.5rem 1.25rem 4rem;
       color: #1B2A33; line-height: 1.55; }
h1 { letter-spacing: -0.02em; margin-bottom: 0.25rem; }
h2 { letter-spacing: -0.01em; border-top: 1px solid #DDE4E8;
     padding-top: 1.5rem; margin-top: 2.5rem; }
.meta { color: #5B6B75; font-size: 0.9rem; margin-top: 0; }
pre { background: #F4F7F8; border: 1px solid #DDE4E8; border-radius: 8px;
      padding: 1rem 1.2rem; overflow-x: auto; font-size: 0.85rem;
      line-height: 1.5; }
img { max-width: 100%%; border: 1px solid #DDE4E8; border-radius: 8px; }
footer { margin-top: 3rem; padding-top: 1.25rem; border-top: 1px solid #DDE4E8;
         color: #5B6B75; font-size: 0.85rem; }
@media print { body { padding: 0; } }
</style></head><body>
<h1>Trial Design Report</h1>
<p class="meta">Saved work from the RPACT Trial Design Workbench</p>
%s
%s
<footer>%s</footer>
</body></html>',
    body, script_html, versions
  )
}
