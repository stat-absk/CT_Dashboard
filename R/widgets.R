# Smart input widgets derived from catalog metadata.
#
# The catalog stores each argument's deparsed default. rpact uses the
# match.arg idiom - a character-vector default enumerates the valid
# choices - so those arguments become dropdowns instead of free-text
# fields where users must remember quoting. Object-valued arguments
# (design, dataset) become pickers over the session store. Everything
# else stays a text field accepting an R expression, with the default
# as placeholder.

OBJECT_ARG_CLASSES <- list(
  design = "TrialDesign",
  dataSet = "Dataset",
  dataInput = "Dataset",
  x = "SimulationResults",
  simulationResult = "SimulationResults",
  stageResults = "StageResults"
)

#' Decide the widget for one catalogued argument
#'
#' @param arg One `args` entry from a catalog function.
#' @return List with `type` ("object", "choice", "logical", "text") and,
#'   for choices, the `choices` vector; for objects, the required `class`.
#' @keywords internal
arg_widget_spec <- function(arg) {
  if (arg$name %in% names(OBJECT_ARG_CLASSES)) {
    return(list(type = "object", class = OBJECT_ARG_CLASSES[[arg$name]]))
  }
  default <- arg$default
  if (!is.null(default) && !is.na(default)) {
    value <- tryCatch(eval(parse(text = default), baseenv()),
                      error = function(e) NULL)
    if (is.character(value) && length(value) > 1) {
      return(list(type = "choice", choices = value))
    }
    if (is.logical(value) && length(value) == 1) {
      return(list(type = "logical"))
    }
  }
  list(type = "text")
}

#' Translate a widget's raw input value into an R expression string
#'
#' The engine consumes argument values as R expression strings; blank
#' means "use the rpact default". Each widget type has its own encoding:
#' dropdown selections need quoting, object picks become @label
#' references, text passes through verbatim.
#' @keywords internal
widget_value_to_expr <- function(spec, value) {
  if (is.null(value) || identical(trimws(as.character(value)[1]), "")) {
    return("")
  }
  value <- as.character(value)[1]
  switch(spec$type,
    object = paste0("@", value),
    choice = paste0('"', value, '"'),
    logical = value,
    value
  )
}

#' Human placeholder text for an argument's default value
#'
#' Machine spellings never reach the interface: NA variants, NULL, and
#' computed defaults read "automatic" (rpact picks a sensible value);
#' integer literals lose their L suffix; anything long or expression-like
#' also collapses to "automatic".
#' @keywords internal
default_placeholder <- function(arg) {
  if (isTRUE(arg$required)) return("(required)")
  d <- arg$default
  automatic <- function() doc_default(arg) %||% "automatic"
  if (is.null(d) || is.na(d)) return(automatic())
  d <- trimws(d)
  if (d %in% c("NA", "NA_real_", "NA_integer_", "NA_character_", "NULL", "")) {
    return(automatic())
  }
  # computed defaults (ifelse(...), function calls) are rpact's business
  if (grepl("[A-Za-z_.][A-Za-z0-9_.]*\\(", d) && !grepl("^(c|seq|rep)\\(", d)) {
    return(automatic())
  }
  d <- gsub("([0-9])L\\b", "\\1", d)
  d <- gsub("NA_real_|NA_integer_|NA_character_", "NA", d)
  if (nchar(d) > 40) return(automatic())
  d
}

#' Pull the documented default out of an argument's help text
#'
#' rpact's docs state real defaults in prose ("default is 0.025",
#' "default value is 3") even when the formal default is NA because the
#' package resolves it internally. Surfacing the documented value beats
#' a generic "automatic".
#' @keywords internal
doc_default <- function(arg) {
  desc <- arg$description
  if (is.null(desc) || is.na(desc)) return(NULL)
  m <- regmatches(
    desc,
    regexec("[Dd]efault (?:value )?is (-?[0-9]+(?:\\.[0-9]+)?|TRUE|FALSE)", desc)
  )[[1]]
  if (length(m) == 2) m[2] else NULL
}

#' Label for the empty option of a logical dropdown
#' @keywords internal
logical_default_label <- function(arg) {
  d <- arg$default
  if (is.null(d) || is.na(d) || trimws(d) %in% c("NA", "NULL")) {
    return("(automatic)")
  }
  paste0("(default: ", trimws(d), ")")
}

#' Label for the empty option of an object picker
#' @keywords internal
object_empty_label <- function(arg) {
  if (identical(arg$name, "design")) return("(none - fixed sample design)")
  if (isTRUE(arg$required)) return("(choose from your saved work)")
  "(none)"
}

#' Essential arguments for a function: those its worked examples use
#'
#' The examples are the curriculum; arguments no example touches are
#' "advanced" and collapse behind an accordion. Required arguments are
#' always essential. Functions without examples show everything.
#' @keywords internal
essential_args <- function(entry, examples) {
  arg_names <- vapply(entry$args, function(a) a$name, character(1))
  required <- arg_names[vapply(entry$args, function(a) isTRUE(a$required), logical(1))]
  arg_names <- setdiff(arg_names, "...")
  fn_examples <- examples[[entry$name]]
  if (is.null(fn_examples) || length(fn_examples) == 0) {
    return(arg_names)
  }
  used <- unique(unlist(lapply(fn_examples, function(e) names(e$args))))
  intersect(arg_names, union(used, required))
}
