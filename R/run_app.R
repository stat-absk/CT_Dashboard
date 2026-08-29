#' Launch the Clinical Trial Design Workbench
#'
#' @param ... Passed to [shiny::shinyApp()].
#' @export
run_app <- function(...) {
  thematic::thematic_shiny()
  shiny::shinyApp(ui = app_ui(), server = app_server, ...)
}
