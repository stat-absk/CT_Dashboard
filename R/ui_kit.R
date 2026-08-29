# Shared page furniture.
#
# Every tab opens the same way: an eyebrow naming the phase of work the
# tab belongs to, the tab's own title, and one line saying what it is for.
# That is the same three-part opening the Start page gives each part of
# the course, so the vocabulary carries across the whole app instead of
# stopping at the landing page.
#
# Two page shapes, because the tabs come in two kinds:
#   wb_page()      - document tabs (Saved Work, Environment). Content is
#                    read top to bottom, so the page scrolls as one thing.
#   wb_tool_page() - tool tabs (the runners, Compare). A sidebar layout
#                    fills the height and does its own scrolling, so the
#                    header sits above it and the layout takes the rest.

#' A tab's opening: eyebrow, title, and one framing line
#'
#' @param eyebrow The phase of work this tab belongs to - Plan, Check,
#'   Monitor, Compare. Names something true about where the tab sits in
#'   the work, rather than decorating it.
#' @keywords internal
wb_page_header <- function(eyebrow, title, lede) {
  shiny::div(
    class = "wb-page-head",
    shiny::p(class = "wb-eyebrow", eyebrow),
    shiny::h1(title),
    shiny::p(class = "wb-page-lede", lede)
  )
}

#' A document tab: a header and content that scroll together
#' @keywords internal
wb_page <- function(...) {
  shiny::div(class = "wb-page", ...)
}

#' A quiet placeholder for a panel that has nothing in it yet
#'
#' An empty panel should say why it is empty and what would fill it,
#' rather than leaving a blank rectangle the reader has to interpret.
#' @keywords internal
wb_empty <- function(...) {
  shiny::div(class = "wb-empty", shiny::p(...))
}

#' A tool tab: a header above a layout that fills the remaining height
#'
#' The header is deliberately not a fill item, so the sidebar layout
#' below it keeps the whole height it had before the header existed.
#' @keywords internal
wb_tool_page <- function(header, ...) {
  shiny::tagList(shiny::div(class = "wb-tool-head", header), ...)
}
