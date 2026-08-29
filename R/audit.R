# Append-only audit trail: one JSON line per computation with the actor,
# the exact call, the environment versions, and a content hash of the
# result. This is the GxP record of what was computed, by whom, and with
# what software.

#' Directory holding the audit log
#'
#' Configurable via option `rpactdash.audit_dir` (or env var
#' `RPACTDASH_AUDIT_DIR`); defaults to the platform user-data directory.
#' @keywords internal
audit_dir <- function() {
  dir <- getOption(
    "rpactdash.audit_dir",
    Sys.getenv("RPACTDASH_AUDIT_DIR", tools::R_user_dir("rpactdash", "data"))
  )
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  dir
}

#' @keywords internal
audit_file <- function() {
  file.path(audit_dir(), "audit-log.jsonl")
}

#' Build an audit record for one computation
#'
#' @param outcome A result list from [run_catalog_function()].
#' @param user Identity of the actor (authenticated username in deployed
#'   settings; the OS user otherwise).
#' @keywords internal
audit_record <- function(outcome, user = NULL) {
  if (is.null(user)) {
    user <- Sys.info()[["user"]]
  }
  list(
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3%z"),
    user = user,
    fn = outcome$fn_name,
    call = outcome$call_text,
    args = outcome$args_text,
    ok = outcome$ok,
    error = outcome$error,
    result_class = if (outcome$ok) class(outcome$result)[1] else NULL,
    result_hash = if (outcome$ok) result_hash(outcome$result) else NULL,
    versions = list(
      r = paste(R.version$major, R.version$minor, sep = "."),
      rpact = as.character(utils::packageVersion("rpact")),
      rpactdash = as.character(utils::packageVersion("rpactdash"))
    )
  )
}

#' Append a record to the audit log (one JSON line)
#' @keywords internal
audit_append <- function(record, path = audit_file()) {
  line <- jsonlite::toJSON(record, auto_unbox = TRUE, null = "null")
  con <- file(path, open = "a", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(line, con)
  invisible(path)
}

#' Read the audit log back as a list of records
#' @keywords internal
audit_read <- function(path = audit_file()) {
  if (!file.exists(path)) return(list())
  lapply(readLines(path, encoding = "UTF-8"), jsonlite::fromJSON)
}
