# Restricted parsing of user-entered argument values.
#
# Forms mirror the rpact API, so users type R expressions ("c(0.5, 1)",
# "0.025", '"asOF"', "TRUE"). For auditability the evaluator is a strict
# whitelist: literals plus a small set of vector-building functions. Any
# other call (file access, system, assignment, ...) is rejected.

PARSE_ALLOWED_CALLS <- c("c", ":", "seq", "seq_len", "rep", "+", "-", "*", "/", "(", "list")

#' Parse one user-entered argument value under the whitelist
#'
#' @param text Character scalar as typed by the user. A leading `@` denotes
#'   a reference to a stored session object, resolved via `resolve`.
#' @param resolve Optional function(label) returning a stored object;
#'   required to use `@label` references.
#' @return The evaluated R value.
#' @keywords internal
parse_arg_value <- function(text, resolve = NULL) {
  stopifnot(is.character(text), length(text) == 1)
  text <- trimws(text)
  if (identical(text, "")) {
    stop("Empty argument value", call. = FALSE)
  }

  if (startsWith(text, "@")) {
    label <- sub("^@", "", text)
    if (is.null(resolve)) {
      stop("Object references (@...) are not available here", call. = FALSE)
    }
    obj <- resolve(label)
    if (is.null(obj)) {
      stop(sprintf("No stored object named '%s'", label), call. = FALSE)
    }
    return(obj)
  }

  exprs <- tryCatch(
    parse(text = text, keep.source = FALSE),
    error = function(e) stop(sprintf("Not valid R syntax: %s", text), call. = FALSE)
  )
  if (length(exprs) != 1) {
    stop("Exactly one expression expected", call. = FALSE)
  }
  expr <- exprs[[1]]
  check_expr_allowed(expr)

  env <- new.env(parent = emptyenv())
  for (fn in PARSE_ALLOWED_CALLS) {
    assign(fn, get(fn, baseenv()), envir = env)
  }
  for (const in c("TRUE", "FALSE", "NA", "NULL", "Inf", "NaN",
                  "NA_integer_", "NA_real_", "NA_character_", "T", "F", "pi")) {
    assign(const, eval(parse(text = const), baseenv()), envir = env)
  }
  eval(expr, env)
}

#' Recursively verify an expression only uses whitelisted syntax
#' @keywords internal
check_expr_allowed <- function(expr) {
  if (is.atomic(expr) || is.null(expr)) {
    return(invisible(TRUE))
  }
  if (is.symbol(expr)) {
    name <- as.character(expr)
    allowed <- c("TRUE", "FALSE", "NA", "NULL", "Inf", "NaN",
                 "NA_integer_", "NA_real_", "NA_character_", "T", "F", "pi")
    if (!name %in% allowed) {
      stop(sprintf("Symbol '%s' is not allowed in argument values", name), call. = FALSE)
    }
    return(invisible(TRUE))
  }
  if (is.call(expr)) {
    head <- expr[[1]]
    if (!is.symbol(head) || !as.character(head) %in% PARSE_ALLOWED_CALLS) {
      stop(sprintf(
        "Function '%s' is not allowed in argument values; permitted: %s",
        paste(deparse(head), collapse = ""), paste(PARSE_ALLOWED_CALLS, collapse = ", ")
      ), call. = FALSE)
    }
    for (i in seq_along(expr)[-1]) {
      check_expr_allowed(expr[[i]])
    }
    return(invisible(TRUE))
  }
  stop("Unsupported expression type in argument value", call. = FALSE)
}
