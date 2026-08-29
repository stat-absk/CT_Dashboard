# The generic runner: executes any catalogued rpact function from a named
# list of user-entered argument strings. Every module in the app funnels
# through run_catalog_function(), so validation, error capture, call-text
# construction, and audit records behave identically for all functions.

#' Execute a catalogued rpact function
#'
#' @param fn_name Name of the rpact function (must exist in the catalog).
#' @param inputs Named list of character strings as typed by the user.
#'   Entries that are `NULL` or `""` are omitted so rpact defaults apply.
#' @param catalog Catalog as returned by [load_catalog()].
#' @param resolve Optional resolver for `@label` object references.
#' @return A list: `ok` (logical), `result` (rpact object or NULL),
#'   `error` (message or NULL), `call_text` (reproducible call string),
#'   `args_text` (named list of the argument strings actually used),
#'   `fn_name`.
#' @keywords internal
run_catalog_function <- function(fn_name, inputs, catalog = load_catalog(), resolve = NULL) {
  entry <- NULL
  for (f in catalog$functions) {
    if (identical(f$name, fn_name)) {
      entry <- f
      break
    }
  }
  if (is.null(entry)) {
    stop(sprintf("Function '%s' is not in the catalog", fn_name), call. = FALSE)
  }

  known_args <- vapply(entry$args, function(a) a$name, character(1))
  used <- inputs[!vapply(inputs, function(v) is.null(v) || identical(trimws(v), ""), logical(1))]
  unknown <- setdiff(names(used), known_args)
  if (length(unknown) > 0 && !"..." %in% known_args) {
    stop(sprintf("Unknown argument(s) for %s: %s", fn_name,
                 paste(unknown, collapse = ", ")), call. = FALSE)
  }

  parsed <- list()
  for (arg in names(used)) {
    value <- tryCatch(
      parse_arg_value(used[[arg]], resolve = resolve),
      error = function(e) {
        stop(sprintf("Argument '%s': %s", arg, conditionMessage(e)), call. = FALSE)
      }
    )
    parsed[[arg]] <- value
  }

  call_text <- sprintf(
    "rpact::%s(%s)", fn_name,
    paste(sprintf("%s = %s", names(used), unlist(used)), collapse = ", ")
  )

  fn <- getExportedValue("rpact", fn_name)
  outcome <- tryCatch(
    list(ok = TRUE, result = do.call(fn, parsed), error = NULL),
    error = function(e) list(ok = FALSE, result = NULL, error = conditionMessage(e))
  )

  c(outcome, list(call_text = call_text, args_text = used, fn_name = fn_name))
}
