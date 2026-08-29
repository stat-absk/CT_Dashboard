# Uniform extraction of displayable content from any rpact result object.
# Everything is guarded: rpact result classes vary, so each accessor falls
# back to NULL rather than erroring, and the UI shows what is available.

#' Summarise an rpact result for display
#'
#' @param x An rpact result object.
#' @return List with `summary_text`, `print_text`, `table` (data.frame or
#'   NULL), `plot_types` (integer vector, possibly empty), `r_code`
#'   (character from [rpact::getObjectRCode()] or NULL).
#' @keywords internal
describe_result <- function(x) {
  list(
    summary_text = safe_output(function() summary(x)),
    print_text = safe_output(function() print(x)),
    table = tryCatch(as.data.frame(x), error = function(e) NULL),
    plot_types = tryCatch(rpact::getAvailablePlotTypes(x), error = function(e) integer(0)),
    r_code = tryCatch(
      paste(rpact::getObjectRCode(x), collapse = "\n"),
      error = function(e) NULL
    )
  )
}

#' Capture printed output of a thunk, NULL on error
#' @keywords internal
safe_output <- function(thunk) {
  tryCatch(
    paste(utils::capture.output(thunk()), collapse = "\n"),
    error = function(e) NULL
  )
}

#' A deterministic content hash of a result object
#'
#' Hashes the printed representation rather than the in-memory object, so
#' the hash is stable across sessions for identical results (R6 objects
#' embed environments whose serialization is not content-stable).
#' @keywords internal
result_hash <- function(x) {
  txt <- safe_output(function() print(x))
  if (is.null(txt)) txt <- paste(class(x), collapse = "/")
  rlang::hash(txt)
}
