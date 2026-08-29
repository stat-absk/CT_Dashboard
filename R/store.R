# Session object store: results created in one module (a design, a
# dataset) are registered here and referenced from other modules with
# @label, mirroring how rpact composes objects. The core store is plain
# (testable without Shiny); the server wraps it in a reactive trigger.

#' Create an empty object store
#' @keywords internal
store_new <- function() {
  env <- new.env(parent = emptyenv())
  env$objects <- list()
  env
}

#' Register an object under a unique label
#'
#' @param store A store from [store_new()].
#' @param label Character label; must be unique within the store.
#' @param object The rpact result object.
#' @param fn_name Producing function name (for display and audit).
#' @param call_text Reproducible call string that created the object.
#' @keywords internal
store_put <- function(store, label, object, fn_name = NA_character_, call_text = NA_character_) {
  stopifnot(is.character(label), length(label) == 1, nzchar(label))
  if (label %in% names(store$objects)) {
    stop(sprintf("An object named '%s' already exists in the session store", label),
         call. = FALSE)
  }
  store$objects[[label]] <- list(
    object = object,
    fn_name = fn_name,
    call_text = call_text,
    class = class(object)[1],
    created = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
  invisible(label)
}

#' Retrieve a stored object (NULL if absent)
#' @keywords internal
store_get <- function(store, label) {
  entry <- store$objects[[label]]
  if (is.null(entry)) NULL else entry$object
}

#' List store contents as a data.frame
#' @keywords internal
store_list <- function(store) {
  if (length(store$objects) == 0) {
    return(data.frame(
      label = character(0), class = character(0),
      created_by = character(0), created = character(0)
    ))
  }
  data.frame(
    label = names(store$objects),
    class = vapply(store$objects, function(e) e$class, character(1)),
    created_by = vapply(store$objects, function(e) e$fn_name, character(1)),
    created = vapply(store$objects, function(e) e$created, character(1)),
    row.names = NULL
  )
}

#' Next free auto-label like "design_1", "design_2", ...
#' @keywords internal
store_next_label <- function(store, prefix) {
  i <- 1
  repeat {
    label <- paste0(prefix, "_", i)
    if (!label %in% names(store$objects)) return(label)
    i <- i + 1
  }
}

#' Save / load the whole store to an .rds scenario file
#' @keywords internal
store_save <- function(store, path) {
  saveRDS(store$objects, path)
  invisible(path)
}

#' @keywords internal
store_load <- function(store, path) {
  loaded <- readRDS(path)
  stopifnot(is.list(loaded))
  store$objects <- loaded
  invisible(store)
}
