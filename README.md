# RPACT Trial Design Workbench

A full-capability [Shiny](https://shiny.posit.co/) dashboard for confirmatory
adaptive clinical trial design with the [rpact](https://www.rpact.org/)
R package. Every user-facing rpact function gets a catalog-driven interface
with reproducible R code output and an audit trail, targeting regulated
(GxP) environments.

## Status

| Phase | Scope | Status |
|---|---|---|
| 0 | Scaffold, function catalog, coverage tests, CI | **Done** |
| 1 | Core engine: generic runner, result renderer, object store, audit log | **Done** |
| 2 | Design module (9 functions) | Next |
| 3 | Sample size & power module (12 functions) | Planned |
| 4 | Simulation module | Deferred |
| 5 | Analysis module | Deferred |
| 6 | Reports, validation package, deployment | Planned |

## Architecture

- **Catalog-driven forms.** `data-raw/build_catalog.R` introspects the
  installed rpact namespace into `inst/catalog/functions.json` — every
  exported `get*` function, its arguments, defaults, and documentation
  title. UI forms are rendered from this catalog.
- **Completeness guarantee.** `tests/testthat/test-catalog-coverage.R`
  fails if the installed rpact exports a function the catalog does not
  cover, if any catalogued signature has drifted, or if the catalog was
  generated against a different rpact version. CI regenerates the catalog
  and fails on drift.
- **GxP posture.** The app displays and verifies its computational
  environment at startup; the environment is pinned with `renv`.

## Development

```r
# install dependencies
renv::restore()

# regenerate the function catalog after an rpact upgrade
source("data-raw/build_catalog.R")

# run tests
testthat::test_local()

# launch the app
pkgload::load_all(); run_app()
```

## Environment

Pinned via `renv.lock`: R 4.x, rpact 4.4.0. Version identity is a GxP
control — the app warns at startup if the installed rpact differs from
the version the catalog was generated against.
