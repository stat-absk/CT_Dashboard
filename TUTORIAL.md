# Trial Design Workbench — Hands-On Tutorial

A complete, follow-along practice course for the
[RPACT Trial Design Workbench](https://stat-absk-learn-trial-design.share.connect.posit.cloud/).
Every feature of the app gets at least one exercise with exact inputs to
type, the result you should see, and a variation to try on your own.
Work through it in order and you will have practiced every part of
designing, simulating, and monitoring a clinical trial — and collected
the runnable R code for all of it.

New to the app? Read the short [user guide](USER_GUIDE.md) first — it
explains the interface in five points. This tutorial assumes you know
that blank fields mean "use the default", that results auto-update
after the first run, and that **Save for later use** puts a result in
your saved work under a suggested name.

**Conventions used below**

- *Load:* pick this entry from the "Start from a worked example"
  dropdown and press **Load & run example**. Every exercise here has a
  matching worked example in the app, so you never type from scratch
  unless the exercise says so.
- *Expect:* the numbers you should see. All of them were computed with
  rpact 4.4.0 — if you see something different, check your inputs
  against the exercise.
- *Try:* a variation to run before moving on. This is where the
  learning happens; the worked example is just the starting position.

---

## Module 0 — The guided chapters (Start tab)

**Exercise 0.1 — Walk the eight chapters.** On the **Start** tab, work
through chapters 1–8 in order, pressing each chapter's button and
reading the "What to look for" notes that load with each example. This
is the fastest tour of the whole app, and chapters 4 and 8 quietly
save the two objects many later exercises build on:

- **O'Brien-Fleming (3 looks)** — the reusable group sequential design
  (chapter 4; press **Save for later use** when the chapter asks).
- **Interim data (continuous)** — the two-stages-in dataset
  (chapter 8 creates it for you).

Check the **Saved Work** tab afterwards: both should be listed. If they
are not, chapters 4 and 8 will seed them again when revisited.

---

## Module 1 — Sample size (Sample Size & Power tab)

Use the calculation picker at the top of the sidebar; these four live
under **Sample size**.

**Exercise 1.1 — Continuous endpoint.** Pick *Sample Size Means*.
*Load:* "Continuous endpoint, fixed design".
*Expect:* about **128 subjects** (64 per group) for standardized effect
0.5, one-sided alpha 2.5%, power 80%.
*Try:* set `alternative` to 0.25 and watch the requirement become about
**505** — halving the effect quadruples the trial, because sample size
scales with (stDev ÷ effect)².

**Exercise 1.2 — Binary endpoint.** Pick *Sample Size Rates*.
*Load:* "Binary endpoint, 45% vs 30% response".
*Expect:* about **325 subjects** for a 15-point improvement.
*Try:* keep the 15-point difference but move it up the scale —
`pi1` = 0.65, `pi2` = 0.5. The requirement *rises* to about **339**,
because the variance of a proportion peaks at 50%. Same difference,
harder neighborhood.

**Exercise 1.3 — Survival endpoint.** Pick *Sample Size Survival*.
*Load:* "Survival endpoint, HR 0.7, median control survival 12 months".
*Expect:* about **247 events**, achieved with **429 subjects** over a
24-month trial (12 accrual + 12 follow-up).
*Try:* set `followUpTime` to 24. The event target stays 247 — events
depend only on the hazard ratio, alpha, and power — but now only about
**325 subjects** are needed, at the price of a 36-month trial. That
subjects-versus-calendar trade is the central budget decision of every
survival trial.

**Exercise 1.4 — Recurrent events.** Pick *Sample Size Counts*.
*Load:* "Recurrent events, negative binomial".
*Expect:* about **744 subjects** at rate ratio 0.75 with
overdispersion 0.5.
*Try:* set `overdispersion` to 0 — the requirement falls to about
**554**. Under-guessing overdispersion at the design stage is a classic
way recurrent-event trials end up underpowered.

**Exercise 1.5 — The realistic survival trial.** Still on *Sample Size
Survival*, *Load:* "Piecewise accrual and piecewise hazards".
*Expect:* the same ~247 events, but 540 subjects, ~25 months of
follow-up, analysis near month 49 — realistic ramp-up and a hazard
that falls over time stretch the calendar dramatically.
*Try:* open **More arguments** to see everything else the function
accepts; this pattern (essentials up front, the full rpact signature
one click away) is the same on every calculation in the app.

---

## Module 2 — Power (same tab, group "Power")

**Exercise 2.1 — The power curve.** Pick *Power Means*.
*Load:* "Power curve under a saved sequential design" (needs the saved
3-look design from Module 0).
*Expect:* cumulative power **20% / 61% / 92% / 99%** at effects 0.2 /
0.4 / 0.6 / 0.8 with 128 subjects — and at effect 0.8 the expected
sample size is only ~85, because strong effects stop the trial early.
*Try:* the Plot tab — "Overall Power and Early Stopping" draws the
curve you just read as numbers.

**Exercise 2.2 — What your budget can detect.** Pick *Power Rates*.
*Load:* "Power for a range of response rates, n = 200".
*Expect:* power **32%** at pi1 = 0.40 rising to **99%** at 0.60. With
200 subjects, a real 10-point improvement is more likely missed than
found.

**Exercise 2.3 — The direction pitfall.** Pick *Power Survival*.
*Load:* "Power for a range of hazard ratios, 200 events".
*Expect:* power **95% / 71% / 35%** at hazard ratios 0.6 / 0.7 / 0.8.
*Try:* flip `directionUpper` to TRUE and watch the powers collapse to
almost nothing — you just computed power for the wrong tail. Benefit
below 1 needs `directionUpper = FALSE`; this is among the most common
rpact mistakes, and the app makes it cheap to see what it looks like.

**Exercise 2.4 — Counts.** Pick *Power Counts*, *Load:* "Power for
recurrent events, n = 400". *Expect:* **71%** at rate ratio 0.7,
**37%** at 0.8.

---

## Module 3 — Survival planning (group "Survival planning")

**Exercise 3.1 — When do the events arrive?** Pick *Event
Probabilities*. *Load:* "How fast do events accumulate?"
*Expect:* the cumulative event probability grows 6% → 23% → 65%
between months 6 and 30; multiply by n = 400 for expected event
counts. Note the treatment arm lags the control arm — an effective
treatment slows your own trial down.

**Exercise 3.2 — The recruitment curve.** Pick *Number Of Subjects*.
*Load:* "Recruitment curve with a ramp-up". *Expect:* 45, 90, 180, 270
and flat after month 12. This exercise also teaches the piecewise
accrual notation (`c(0, 6, 12)` + intensities `c(15, 30)`) used by
every survival function.

**Exercise 3.3 — Anchoring relative accrual.** Pick *Accrual Time*.
*Load:* "From relative site capacity to absolute intensities".
*Expect:* relative rates 0.22 / 0.33 scale to about 23.8 / 35.7
subjects per month to reach exactly 1000 subjects by month 30.

**Exercise 3.4 — Proportional hazards, concretely.** Pick *Piecewise
Survival Time*. *Load:* "Piecewise hazards under a proportional
effect". *Expect:* every treatment hazard is exactly 0.8 × its control
counterpart — that is what "proportional hazards" means.

---

## Module 4 — Conversion calculators (group "Conversion calculators")

Clinicians speak in medians and event rates; design functions want
hazard rates and hazard ratios. These one-line converters are the
bridge, and each has a worked example. Run this chain to see them
cooperate:

**Exercise 4.1 — The conversion chain.**

1. *Lambda By Median*, example "Median survival to hazard rate":
   median 12 months → hazard **0.0578**/month.
2. *Median By Lambda*, example "Hazard rate to median survival": feed
   0.0578 back → **12 months**. Round trip closed.
3. *Lambda By Pi*, example "Event probability to hazard rate": "30%
   had an event by month 12" → hazard **0.0297**/month.
4. *Hazard Ratio By Median*, example "Medians to hazard ratio":
   medians 18 vs 12 → HR **0.667**.
5. *Pi1 By Pi2 And Hazard Ratio*, example "Implied treatment event
   rate": control 45% events at month 12, HR 0.7 → treatment
   **34%**. This is how "hazard ratio 0.7" becomes a statement a
   clinical team can react to.

*Try:* the remaining converters (*Pi By Median*, *Median By Pi*,
*Hazard Ratio By Lambda*, *Hazard Ratio By Pi*, *Pi2 By Pi1...*,
*Lambda1 By Lambda2...*, *Lambda2 By Lambda1...*) each have an example;
any two of {lambda1, lambda2, HR} determine the third, in every
direction.

**Exercise 4.2 — Piecewise distributions.** Run the three *Piecewise
Exponential...* examples: the distribution function (event probability
14% → 43% between months 6 and 24 under the planning hazard), the
quantile (median ≈ **32 months** — see how a low late hazard stretches
the tail), and the random-number generator (ten simulated event times —
the raw material of survival simulation).

---

## Module 5 — Designs (Design tab)

**Exercise 5.1 — The workhorse.** Pick *Design Group Sequential*.
*Load:* "O'Brien-Fleming-type alpha spending, 3 looks".
*Expect:* efficacy boundaries **3.71 / 2.51 / 1.99** on the z-scale.
If Module 0 didn't already, press **Save for later use** and accept
the suggested name "O'Brien-Fleming (3 looks)".
*Try:* the Plot tab, "Boundaries" — the falling staircase is the
design's signature.

**Exercise 5.2 — The rival.** *Load:* "Pocock-type alpha spending, 3
looks". *Expect:* nearly flat boundaries around **2.28**. Save this
one too — Module 6 compares them head to head.

**Exercise 5.3 — Stopping for futility.** *Load:* "Adding a
non-binding futility bound". *Expect:* a futility boundary at z = 0
alongside the efficacy boundary, and a futility-probabilities row
showing the chance of stopping a truly ineffective trial early.

**Exercise 5.4 — The adaptive design.** Pick *Design Inverse Normal*.
*Load:* "Inverse normal combination, unequal information".
*Expect:* boundaries identical to the group sequential design with the
same inputs — the flexibility to adapt mid-trial is invisible in the
boundary table, and that is the point.
*Now create the second canonical design yourself:* set `kMax` to 2,
clear `informationRates` (blank = default), run, and save it — the
suggested name is **"O'Brien-Fleming (2 looks, inverse normal)"**. The
multi-arm and enrichment simulations in Module 7 need it.

**Exercise 5.5 — Two more design families.** Run the *Design Fisher*
example (critical values live on the p-value-product scale, not the
z-scale) and the *Design Conditional Dunnett* example (no boundary
table at all — its interim is for selecting arms, not stopping).

**Exercise 5.6 — Interrogating a design.** Three functions turn a
saved design into planning numbers, and each has an example that uses
your saved 3-look design:

- *Design Characteristics* — inflation factor ≈ **1.013**: the 3-look
  O'Brien-Fleming design costs 1.3% extra maximum sample size. Rerun
  it on the saved Pocock design: **1.17**. That single comparison is
  the O'Brien-Fleming-vs-Pocock argument in two numbers.
- *Power And Average Sample Number* — power and expected sample size
  across effect sizes; at theta = 0 the "power" row reads 0.025, the
  type I error, as it must.
- *Group Sequential Probabilities* — the low-level engine: check that
  the boundary-crossing probabilities under the null sum to alpha.
  This demystifies where boundaries come from.

**Exercise 5.7 — Restating a futility rule.** Pick *Futility Bounds*,
*Load:* "Converting a futility bound between scales" — z = 0.5 reads
as a one-sided p-value of about 0.31. *Try:* every `targetScale` in
the dropdown; being able to restate a rule on the scale your team
thinks in is a routine communication task.

---

## Module 6 — Compare Designs tab

**Exercise 6.1 — The classic face-off.** With both Module 5 designs
saved, open **Compare Designs**, tick "O'Brien-Fleming (3 looks)" and
the Pocock design, press **Compare**.
*Expect:* one plot, two boundary staircases — O'Brien-Fleming starting
high (3.71) and falling steeply, Pocock nearly flat at ~2.28. Pocock
stops early more easily and pays for it at the end (final boundary
2.30 vs 1.99) and in sample size (inflation 1.17 vs 1.013).
*Try:* add a third design to the comparison — for instance the
futility-bound design from Exercise 5.3.

---

## Module 7 — Simulation (Simulation tab)

**Two-arm trials**

**Exercise 7.1 — Validate the formulas.** Pick *Simulation Means*.
*Load:* "Does the design deliver what the formulas promised?"
*Expect:* rejection ≈ **1.9%** at effect 0 (the 2.5% type I error,
within noise) and ≈ **81%** at 0.5 (the designed 80%); expected sample
size ≈ 112 against the analytic 110.
*Try:* `maxNumberOfIterations` = 10000 — watch the estimates tighten
around the theory.

**Exercise 7.2 — Stress the assumptions.** Pick *Simulation Rates*.
*Load:* "Checking the binary-endpoint calculation" (**79%** power at
pi1 = 0.45, as designed). *Try:* set `pi2` to 0.35 — the control arm
responds better than planned, the treatment difference shrinks to 10
points, and power collapses to about **47%** with the sample size
unchanged. Formulas answer the question you asked; simulation lets you
ask what happens when the world disagrees with your assumptions.

**Exercise 7.3 — The trial calendar.** Pick *Simulation Survival*.
*Load:* "A survival trial in silico". *Expect:* ≈ **79%** power at
HR 0.7 — and the analysis-time row shows effective-treatment trials
finishing around month 21, not 24. *Try:* `directionUpper` = TRUE to
see the wrong-tail pitfall from Exercise 2.3 reproduced by brute force.

**Exercise 7.4 — Counts.** Pick *Simulation Counts*.
*Load:* "Checking the recurrent-events calculation".
*Expect:* ≈ **82%** rejection at rate ratio 0.75, ≈ 3% at 1 — the
744-subject calculation from Exercise 1.4 confirmed. rpact labels
count-data simulation experimental, which is exactly why the
formula-versus-simulation round trip is worth running.

**Multi-arm** (all three need the saved 2-stage inverse normal design
from Exercise 5.4)

**Exercise 7.5 — Pick the best arm.** Pick *Simulation Multi-Arm
Means*, *Load:* "Pick the best of three arms at an interim".
*Expect:* familywise error ≈ **2.7%**, power ≈ **66%** when the best
arm has effect 0.5. The selected-arms table shows how often each arm
survives the interim.
*Try:* `typeOfSelection` = "epsilon" with `epsilonValue` = 0.1 — keep
every arm within 0.1 of the best, not just the single winner.

**Exercise 7.6 — Rates and survival versions.** Run the *Simulation
Multi-Arm Rates* example (power ≈ **47%** for a 30%→50% response
lift — binary endpoints again) and the *Simulation Multi-Arm Survival*
example (power only ≈ **37%** at HR 0.7 with 150 events split across
three comparisons; a two-arm trial needed 247 events for 80% — that
gap is the honest price of a selection design).

**Enrichment**

**Exercise 7.7 — Trials that zoom in.** Run all three *Simulation
Enrichment...* examples (means, rates, survival). In each, a
biomarker-positive subgroup carries the effect, and the interim can
restrict stage 2 to it. *Expect:* ≈ **83%** (means), ≈ **71%**
(rates), ≈ **79%** (survival) probability of rejecting at least one
hypothesis — despite full-population effects too diluted to power a
conventional trial. Note the `effectList` structure in each: it is a
table of subgroups, prevalences, and per-subgroup effects, and it is
the whole scenario in one argument.

*The "Extract from results" group* (*Simulation Data*, *Raw Data*,
*Performance Score*) pulls per-iteration data out of saved simulation
objects — useful in R scripts; the R code panel of any simulation
shows the object to call them on.

---

## Module 8 — Analysis (Analysis tab)

**Enter data first**

**Exercise 8.1 — Three endpoints, one form.** On **1 · Enter data**,
create all three pre-filled datasets, switching the endpoint dropdown
between Continuous, Binary, and Survival and pressing **Create
dataset** each time. You now have "Interim data (continuous)",
"Interim data (binary)", and "Interim data (survival)" in your saved
work. Note what the survival form asked for — cumulative events and
log-rank statistics, not patient-level times: that is literally what a
statistician receives at an interim.

**The monitoring committee's view**

**Exercise 8.2 — Continuous.** On **2 · Analyze**, pick *Analysis
Results*, *Load:* "The interim decision: continue or stop?"
*Expect:* test statistic **2.26** vs boundary **2.51** → *continue*;
conditional power **90%**; repeated CI **[-0.06, 1.01]**.

**Exercise 8.3 — Binary and survival.** Load the other two *Analysis
Results* examples. Binary: z climbs 1.61 → **2.05**, still short of
2.51, RCI [-0.03, 0.33]. Survival: log-rank 2.11 vs 2.51, RCI for the
hazard ratio [0.91, 2.85] — still includes 1. Same design, three
endpoints, one discipline.

**The stage-results chain**

**Exercise 8.4 — Build the chain.** Pick *Stage Results*, *Load:* "The
machinery under the analysis", and save the result under the suggested
name **"Stage Results"**. Then run, in order, each one's worked
example:

1. *Test Actions* — "continue, continue": the one-word verdicts.
2. *Conditional Power* — **90%** with 44 subjects still to come.
   *Try:* `nPlanned` = 20 → **78%**; a thinner final stage erodes the
   chance of success.
3. *Conditional Rejection Probabilities* — 0.14 → **0.38**: the alpha
   budget an adaptive redesign would inherit mid-trial.
4. *Repeated P Values* — 0.22 → **0.043**: still above 0.025, and
   deliberately larger than the naive p ≈ 0.012, because it accounts
   for every look.
5. *Repeated Confidence Intervals* — [-0.66, 1.78] → [-0.06, 1.01]:
   what you may honestly quote mid-trial.
6. *Observed Information Rates* — 0.333, 0.667: reality matched the
   plan (in real trials it never quite does, and this function feeds
   the true rates back into the spending function).

**Final inference — and a refusal worth understanding**

**Exercise 8.5 — Ask too early.** Run the *Final P Value* and *Final
Confidence Interval* examples. *Expect:* empty results — with two of
three stages done and no boundary crossed, the trial has not stopped,
and rpact declines to invent final inference for an unfinished trial.

**Exercise 8.6 — Cross the boundary.** Now make the trial stop. On
**1 · Enter data** (Continuous), change group 1's means to
`0.64, 1.05`, name it "Interim data (crossed)", create it, and rerun
*Analysis Results* with it. *Expect:* the stage-2 statistic is now
**3.51**, past the boundary 2.51 → *reject and stop*. Rerun *Final P
Value* (via new *Stage Results* for the new dataset) and *Final
Confidence Interval* with the new dataset: final p ≈ **0.0004**,
design-adjusted CI ≈ **[0.30, 1.13]**, median-unbiased estimate ≈
**0.72** — note it is pulled below the naive estimate, correcting the
optimism of stopping early.

**Data utilities**

**Exercise 8.7 — See what rpact derived.** Run the *Wide Format* and
*Long Format* examples. Check one derived number: the overall group-1
mean after stage 2 is **0.575**, the weighted average of 0.64 and
0.51. Group sequential analysis runs on these cumulative statistics.

*The "Multi-arm closed tests" group* (*Closed Combination Test
Results*, *Closed Conditional Dunnett Test Results*) needs multi-arm
datasets, which the data-entry form does not build — they are best
explored in R directly; their ⓘ tooltips and the rpact vignettes show
the way.

---

## Module 9 — Saved Work, reports, and taking it with you

**Exercise 9.1 — The report.** By now your saved work holds designs,
datasets, and results. On **Saved Work**, press **Download report**:
one self-contained HTML file with every saved item's creating call,
summary, first plot — and a complete runnable R script at the end. It
prints cleanly to PDF.

**Exercise 9.2 — Save and restore a session.** Press **Save session to
file**, then (in a fresh browser session, or right away) restore the
`.rds` file with **Restore from file**. Everything returns by name.

**Exercise 9.3 — Leave the app.** Open any result's "R code — run this
yourself in R" panel, copy it into R (`install.packages("rpact")`
first), and confirm you get the identical numbers. The **Environment**
tab records the exact R and rpact versions behind every result. This
is the graduation step: the workbench is scaffolding, and the code
panel is how you climb off it.

---

## Capstone — design a trial end to end

No worked example this time. Invent a trial — say, a new anti-hypertensive
expected to lower systolic blood pressure by 5 mmHg (SD 12) — and:

1. **Size it** as a fixed design (*Sample Size Means*; expect a big
   number — the standardized effect is only 0.42).
2. **Design** a 2-look O'Brien-Fleming group sequential version and
   save it.
3. **Re-size** under the design and note the maximum and expected
   sample sizes.
4. **Check** the design's inflation factor (*Design Characteristics*)
   and power curve (*Power And Average Sample Number*).
5. **Simulate** it (*Simulation Means*) at the null and at effects
   3, 5, and 7 mmHg — does it hold its promises? What if the SD is
   really 15?
6. **Run a fake interim**: enter plausible stage-1 data, get the
   analysis, the test action, and the conditional power.
7. **Export the report** — design rationale, operating
   characteristics, and reproducible code in one file.

If you can do this unaided, you are no longer a beginner — and every
step of it transfers directly to rpact in R.

## Where to go next

- [rpact.org vignettes](https://www.rpact.org) — the package authors'
  case studies, including the adaptive and multi-arm methodology this
  app only samples.
- [The user guide](USER_GUIDE.md) — the short orientation version of
  this tutorial.
- [The workbench source](https://github.com/stat-absk/CT_Dashboard) —
  issues and ideas welcome. LGPL-3, like rpact itself.
