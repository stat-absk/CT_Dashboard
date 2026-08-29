# Clinical Trial Design Workbench

**Try it live: https://stat-absk-learn-trial-design.share.connect.posit.cloud/** — no installation needed.
New here? Follow the **[step-by-step user guide](USER_GUIDE.md)**,
then work through the **[hands-on tutorial](TUTORIAL.md)** — a
follow-along practice course with an exercise for every feature.

An open-source [Shiny](https://shiny.posit.co/) dashboard for learning
confirmatory adaptive clinical trial design with the
[rpact](https://www.rpact.org/) R package — built as a **tutorial and
hands-on practice environment for new and junior statisticians**.

Every user-facing rpact function gets a catalog-driven interface that
mirrors the package API exactly, so what you learn in the app transfers
directly to your own R scripts: every result shows the reproducible
rpact code that produced it.

## Why this instead of rpact cloud?

[rpact cloud](https://www.rpact.com/products/rpact-cloud/) is a
commercial product aimed at expert users in production settings. This
workbench is different on purpose:

- **Free and open source** — run it locally, read the code, fork it.
- **Learning-first** — the interface teaches the package: rpact's own
  argument names and defaults, the documentation title for every
  function, and the exact R code for every result you generate.
- **Practice-safe** — experiment freely; an audit log and session
  object store demonstrate good statistical practice habits (traceable
  computations, reproducible calls) without production ceremony.

This is a learning tool, not a validated production system. For
regulatory work, use rpact directly with your organization's qualified
processes.

## Getting started

Open `CT_Dashboard.Rproj` in RStudio (renv activates automatically),
then:

```r
renv::restore()        # first time only: install pinned dependencies
pkgload::load_all()
run_app()
```

## Status

| Phase | Scope | Status |
|---|---|---|
| 0 | Scaffold, function catalog, coverage tests, CI | **Done** |
| 1 | Core engine: generic runner, result renderer, object store, audit log | **Done** |
| 2 | Design module with tutorial content and worked examples | **Done** |
| 3 | Sample size & power module (28 functions, grouped) | **Done** |
| 4 | Simulation module (two-arm, multi-arm, enrichment) | **Done** |
| 5 | Analysis module (data entry + interim monitoring) | **Done** |
| 6 | Guided learning path, report export, session save/restore, deployment | **Done** |

## How the interface works

- **Start tab: a six-chapter guided path** ordered the way people
  actually learn - (1) your first sample size, (2) power, (3) survival
  trials count events, (4) the case for interim looks, (5) sizing a
  sequential trial, (6) O'Brien-Fleming vs Pocock. Each chapter teaches
  one idea and drops you into the live tool with the matching worked
  example loaded and running; chapters that need a saved design seed it
  automatically.
- **Smart inputs**: arguments with enumerated choices (rpact's
  `match.arg` defaults) render as dropdowns, saved objects as pickers,
  logicals as selects - no quoting or R syntax needed for the common
  cases. Free-text fields (numerics, vectors) show the rpact default as
  a placeholder; blank always means "use the default".
- **Essential vs advanced**: the arguments used by a function's worked
  examples appear up front; everything else collapses behind "More
  arguments".
- **Everything visible at once**: result summary, plot, and the
  reproducing R code share the screen, and results auto-update as
  inputs change after the first run.
- **Worked examples** load and run with one click, with narrative
  "what to look for" notes above the result.

## Architecture

- **Catalog-driven forms.** `data-raw/build_catalog.R` introspects the
  installed rpact namespace into `inst/catalog/functions.json` — every
  exported `get*` function, its arguments, defaults, and documentation
  title. UI forms are rendered from this catalog.
- **Completeness guarantee.** `tests/testthat/test-catalog-coverage.R`
  fails if the installed rpact exports a function the catalog does not
  cover, if any catalogued signature has drifted, or if the catalog was
  generated against a different rpact version. CI regenerates the
  catalog and fails on drift.
- **Composition via the session store.** A design saved as `design_1`
  can be referenced as `@design_1` in any argument field — the same way
  rpact objects compose in code.

## Development

```r
# regenerate the function catalog after an rpact upgrade
source("data-raw/build_catalog.R")

# run tests
testthat::test_local()
```

Environment pinned via `renv.lock` (R 4.6, rpact 4.4.0).

## Reports and sessions

The **Saved Work** tab exports a self-contained HTML report - every
saved result with its creating call, rpact summary, first plot, and a
complete runnable R script - which prints cleanly to PDF. Sessions can
be saved to a `.rds` file and restored later.

## Hosting it

`app.R` at the repo root makes the app deployable as-is. For free
hosting on [shinyapps.io](https://www.shinyapps.io):

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "<account>", token = "<token>", secret = "<secret>")
rsconnect::deployApp(appName = "rpact-workbench")
```

Any Shiny host (Posit Connect, Shiny Server) works the same way - the
dependencies come from `DESCRIPTION`.

## License & attribution

Licensed under **LGPL-3** ([LICENSE.md](LICENSE.md)) — the same license as
the [rpact package](https://github.com/rpact-com/rpact) this workbench
builds on. All statistical computations are performed by rpact itself;
this project provides only the learning interface on top of it.

This is an independent open-source project, not affiliated with or
endorsed by RPACT GbR. If you use rpact in your own work, cite the
package as its authors request (see `citation("rpact")`).
