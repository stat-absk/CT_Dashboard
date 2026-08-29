# Trial Design Workbench — User Guide

A step-by-step walkthrough of the RPACT Trial Design Workbench: a free,
hands-on environment for learning clinical trial design, from your first
sample size calculation to running an interim analysis.

**Open the app:** https://stat-absk-learn-trial-design.share.connect.posit.cloud/ —
nothing to install. All statistics are computed by the
[rpact](https://www.rpact.org) R package; this app is an independent
open-source learning interface on top of it.

## Five things to know before you start

1. **Follow the chapters.** The **Start** tab holds an eight-chapter
   path ordered the way people actually learn. Each chapter is a
   two-minute read with one button that opens the right tool with a
   worked example already computed.
2. **Worked examples are the fastest way in.** Every calculation offers
   a "Start from a worked example" dropdown. Press **Load & run
   example** and read the "What to look for" notes above the result —
   then change an input and watch the result update by itself.
3. **Blank means sensible.** Greyed values in empty fields are the
   defaults; "automatic" means rpact picks a sensible value. Hover the
   small ⓘ next to any field name for its official documentation.
4. **Save what you build.** Press **Save for later use** under any
   result (a name is suggested, e.g. "O'Brien-Fleming (3 looks)").
   Saved items appear by name in the dropdowns of other calculations —
   a saved design feeds a sample size calculation, exactly as objects
   are passed between functions in R.
5. **Every result shows its R code.** The "R code — run this yourself
   in R" panel contains a complete, copy-paste-runnable script for
   what's on screen. What you learn here transfers directly to your own
   R work.

## The walkthrough

Each step matches a chapter on the **Start** tab. Do them in order the
first time; every step takes a few minutes.

### Step 1 — Your first sample size calculation

Click **Calculate your first sample size**. You land on **Sample Size &
Power** with a computed example: comparing the means of two groups,
effect 0.5, standard deviation 1. Read "Number of subjects ≈ 128" —
about 64 per group. Then change `alternative` from 0.5 to 0.25 and
watch the requirement roughly quadruple.

> **Concept — sample size.** Four quantities fix the answer: the
> *effect* to detect, the endpoint's *variability*, the tolerated
> false-positive rate (*alpha*, typically one-sided 2.5%), and the
> chance of detecting a real effect (*power*, typically 80–90%). Sample
> size scales with (variability ÷ effect)² — halving the effect
> quadruples the trial.

### Step 2 — Power: what your budget can detect

Chapter 2 reverses the question: with 200 patients and a 30% control
response rate, power climbs from 32% (treatment rate 40%) to 99% (60%).
A real 10-point improvement is more likely missed than found with this
budget.

> **Concept — power.** Power is the probability of a significant result
> when the treatment truly works. An underpowered trial wastes patients
> on a question it cannot answer. When budget fixes n, the honest
> deliverable is a power curve across plausible effects.

### Step 3 — Survival trials count events, not people

Chapter 3 sizes a time-to-event trial: control median survival 12
months, hazard ratio 0.7, 12 months accrual + 12 follow-up → about 247
*events*, 429 subjects, a 24-month trial.

> **Concept — survival endpoints.** Information comes from events, not
> enrollment. The required event count depends only on the hazard
> ratio, alpha, and power; subjects, accrual, and follow-up are the
> levers that collect those events on an acceptable calendar.

### Step 4 — Add interim looks: a group sequential design

Chapter 4 opens the **Design** tab with three looks of
O'Brien-Fleming-type alpha spending computed. Look at the boundary plot
(first boundary z ≈ 3.71, final ≈ 1.99), then press **Save for later
use** — the next steps build on this design.

> **Concept — group sequential designs & alpha spending.** Repeatedly
> testing accumulating data at the naive threshold inflates the
> false-positive rate — three looks roughly doubles it. Group
> sequential designs adjust the per-look thresholds (boundaries) so the
> overall alpha stays protected while allowing early stopping. An
> *alpha spending function* decides how much alpha each look may use:
> O'Brien-Fleming-type spending is stingy early and generous late
> (almost no sample size premium); Pocock-type spends evenly (easy
> early stopping, larger trial). Looks are scheduled by *information
> rate* — the fraction of total statistical information accrued.

### Step 5 — What do the interim looks cost?

Chapter 5 reruns the step-1 calculation under the saved design: the
maximum sample size rises only 128 → 129, but the *expected* sample
size falls to about 110 thanks to early stopping. Small worst-case
premium, large average saving.

### Step 6 — O'Brien-Fleming vs Pocock, side by side

Chapter 6 opens **Compare Designs** with both classics waiting. Tick
both, press **Compare**: O'Brien-Fleming starts high and falls steeply;
Pocock is nearly flat around z ≈ 2.28. Pocock stops early more often
but pays a sample-size premium — the trade-off protocol teams argue
about.

### Step 7 — Trust, but simulate

Chapter 7 replays the step-1 trial in silico on the **Simulation** tab:
1000 simulated trials recover the promised 2.5% type I error and 80%
power (within noise), with a fixed `seed` so the run reproduces
exactly. Then explore the Multi-arm and Enrichment pickers — treatment
selection and biomarker enrichment have no formulas at all; simulation
*is* the design tool there.

> **Concept — operating characteristics.** Type I error, power,
> expected sample size, and stopping probabilities are what a design
> actually delivers across many hypothetical trials. Formulas compute
> them under assumptions; simulation checks those assumptions and
> covers designs too complex for formulas.

### Step 8 — The trial is running: your first interim analysis

Chapter 8 opens the **Analysis** tab with two of three stages of data
entered (see *Enter data* for the editable form). Read it like a
monitoring committee: the test statistic (2.26) has not crossed the
boundary (2.51) → *continue*; conditional power for the final stage is
90%; the repeated confidence interval has narrowed to [−0.06, 1.01].
Nudge the stage-2 means and watch the decision flip.

> **Concept — interim monitoring.** Conditional power is the chance of
> eventual success given the data so far. Repeated confidence intervals
> are widened so they stay valid despite multiple looks — naive
> intervals quoted mid-trial overstate precision.

## Ready for more? The hands-on tutorial

The [hands-on tutorial](TUTORIAL.md) continues where the chapters end:
a follow-along practice course with exercises for every feature of the
app — every calculator, every design family, every simulation type,
the full interim-analysis chain, and a capstone where you design a
trial end to end. Every exercise starts from a worked example built
into the app and quotes the exact numbers you should see.

## Beyond the chapters

- **The full toolbox** — the pickers cover every rpact sample size,
  power, simulation, and analysis function, grouped by task, including
  the survival planning helpers and unit converters.
- **Saved Work tab** — download a self-contained HTML **report** (every
  result, plot, and a runnable R script; prints to PDF), and save or
  restore your session as a file.
- **Take the code with you** — `install.packages("rpact")`, paste any
  R-code panel into R, get the identical result.

## Glossary

| Term | Meaning |
|---|---|
| Alpha | Accepted false-positive rate (typically one-sided 2.5%) |
| Power / beta | Probability of detecting a true effect; beta = 1 − power |
| Effect size | The treatment difference the trial is designed to detect |
| Information rate | Fraction of total statistical information at a look |
| Efficacy boundary | Per-look threshold for claiming success early |
| Alpha spending function | Rule allocating alpha across looks (OF, Pocock, …) |
| Futility bound | Threshold for stopping a hopeless trial early |
| Hazard ratio | Treatment ÷ control instantaneous event rates; < 1 favors treatment |
| Expected sample size | Average n of a sequential trial, counting early stops |
| Conditional power | Probability of final success given interim data |
| Repeated confidence interval | Interval valid despite multiple looks |

## Learn more

- [rpact.org](https://www.rpact.org) — vignettes and case studies by
  the package authors.
- [Workbench source](https://github.com/stat-absk/CT_Dashboard) — open
  an issue for bugs or ideas. LGPL-3, same license as rpact.
- In R: `citation("rpact")` for how to cite the package.
