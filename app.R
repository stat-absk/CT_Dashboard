# Entry point for hosted deployments (shinyapps.io, Posit Connect,
# Shiny Server). rsconnect bundles this directory and installs the
# package dependencies declared in DESCRIPTION.
pkgload::load_all(export_all = FALSE, helpers = FALSE,
                  attach_testthat = FALSE, quiet = TRUE)
run_app()
