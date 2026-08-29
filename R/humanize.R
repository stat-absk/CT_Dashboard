# Human names for the things users create and save.
#
# Saved results are labelled by what they are ("O'Brien-Fleming (3
# looks)"), not by machine counters ("design_1"). The @label encoding
# the engine uses to pass stored objects around remains internal - the
# interface shows names, and the R code panel shows real runnable code
# with real variable names.

DESIGN_TYPE_NAMES <- c(
  OF = "O'Brien-Fleming (classic)",
  P = "Pocock (classic)",
  WT = "Wang-Tsiatis",
  PT = "Pampallona-Tsiatis",
  HP = "Haybittle-Peto",
  WToptimum = "Optimal Wang-Tsiatis",
  asP = "Pocock",
  asOF = "O'Brien-Fleming",
  asKD = "Kim-DeMets",
  asHSD = "Hwang-Shih-DeCani",
  asUser = "Custom spending",
  noEarlyEfficacy = "No early efficacy"
)

#' Describe a result object in the user's language
#'
#' @param x The rpact result object.
#' @param title The catalog title of the producing function (fallback).
#' @keywords internal
describe_object <- function(x, title = NULL) {
  type <- tryCatch(x$typeOfDesign, error = function(e) NULL)
  kmax <- tryCatch(x$kMax, error = function(e) NULL)
  looks <- function(k) if (k == 1) "fixed, no looks" else paste(k, "looks")
  if (inherits(x, "TrialDesignFisher") && !is.null(kmax)) {
    return(sprintf("Fisher combination (%s)", looks(kmax)))
  }
  if (inherits(x, "TrialDesignConditionalDunnett")) {
    return("Conditional Dunnett")
  }
  if (inherits(x, "TrialDesign") && !is.null(type) && !is.null(kmax)) {
    name <- DESIGN_TYPE_NAMES[[type]] %||% type
    qualifier <- if (inherits(x, "TrialDesignInverseNormal") &&
                     !inherits(x, "TrialDesignGroupSequential")) {
      ", inverse normal"
    } else {
      ""
    }
    return(sprintf("%s (%s%s)", name, looks(kmax), qualifier))
  }
  if (!is.null(title) && !is.na(title)) {
    return(sub("^Get ", "", title))
  }
  class(x)[1]
}

#' Suggest a unique, human store label for a result
#' @keywords internal
suggest_store_label <- function(store, x, title = NULL) {
  base <- describe_object(x, title)
  label <- base
  i <- 2
  while (label %in% names(store$objects)) {
    label <- paste0(base, " ", i)
    i <- i + 1
  }
  label
}

#' Human picker labels for catalogued functions
#'
#' Documentation titles are the first choice, but rpact documents whole
#' families under one Rd title (the survival converters, the piecewise
#' exponential distribution). Identical picker entries are useless, so
#' where titles collide the function's own name - spaced into words -
#' is the label: getMedianByLambda becomes "Median By Lambda".
#' @param names Function names.
#' @param titles Their catalog titles (may contain NA).
#' @keywords internal
friendly_fn_labels <- function(names, titles) {
  labels <- ifelse(is.na(titles) | !nzchar(titles),
                   names, sub("^Get ", "", titles))
  spaced <- gsub("([a-z0-9])([A-Z])", "\\1 \\2", sub("^get", "", names))
  dup <- labels %in% labels[duplicated(labels)]
  labels[dup] <- spaced[dup]
  labels
}

#' Turn a saved-work name into a valid R variable name
#' @keywords internal
label_to_var <- function(label) {
  var <- tolower(gsub("[^A-Za-z0-9]+", "_", label))
  var <- gsub("^_+|_+$", "", var)
  if (grepl("^[0-9]", var)) var <- paste0("x", var)
  if (identical(var, "")) var <- "saved_object"
  var
}

#' Build fully runnable R code for an outcome
#'
#' Where the call used saved objects, prepend each object's own creating
#' call bound to a readable variable name, and substitute that variable
#' into the main call - so the code panel is copy-paste runnable.
#' @keywords internal
build_repro_code <- function(res, store) {
  call <- res$call_text
  defs <- character(0)
  for (arg in names(res$args_text)) {
    v <- res$args_text[[arg]]
    if (!is.character(v) || length(v) != 1 || !startsWith(v, "@")) next
    label <- sub("^@", "", v)
    var <- label_to_var(label)
    entry <- store$objects[[label]]
    creating <- if (!is.null(entry) && !is.null(entry$call_text) &&
                    !is.na(entry$call_text)) {
      entry$call_text
    } else {
      "<your saved object>"
    }
    defs <- c(defs, paste0(var, " <- ", creating))
    call <- sub(v, var, call, fixed = TRUE)
  }
  paste(c(defs, call), collapse = "\n")
}
