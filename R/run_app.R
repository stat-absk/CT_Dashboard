#' Launch the RPACT Trial Design Workbench
#'
#' @param ... Passed to [shiny::shinyApp()].
#' @export
run_app <- function(...) {
  shiny::shinyApp(ui = app_ui(), server = app_server, ...)
}
