# Advanced Observational Causal Inference

## Course Description

This course provides advanced training in the design, implementation, and evaluation of observational causal inference in the social sciences. The course assumes prior familiarity with the potential-outcomes framework, linear regression, robust and clustered inference, propensity scores, and basic instrumental variables.

The central premise of the course is that causal inference is fundamentally a problem of **research design and identification**, rather than the mechanical application of statistical estimators. For each design, we will ask four recurring questions:

1. **What is the causal quantity we want to learn?**
2. **What variation in the data is supposed to identify it?**
3. **Under what assumptions does that variation identify the causal quantity?**
4. **What evidence can we use to assess the credibility of those assumptions?**

Students will answer these questions both conceptually and empirically through repeated replication and reanalysis of published observational research.

All empirical work will be conducted in **R** using reproducible workflows.

## Course Structure

A typical class will combine conceptual instruction, discussion of one or more published applications, and hands-on analysis. Formal derivations and proofs will be provided as optional extensions where useful, but mastery of proofs is not required. Students are expected instead to understand the logic of identification results well enough to explain, apply, and critically evaluate them.

Approximately every two to three weeks, students will complete a **replication problem set** based on a published social-science article and its replication data. Each problem set will require students to:

- reproduce a central published result;
- identify the causal estimand;
- reconstruct the paper's identification argument;
- implement the relevant estimator in R;
- conduct design-specific diagnostics;
- implement at least one meaningful reanalysis or alternative specification; and
- write a short assessment of what causal conclusion is justified by the evidence.

The final project is an **independent causal audit** of a published observational study.

# Semester Schedule

## August 26 — From Potential Outcomes to Identification

**Core concepts**

- Brief review of potential outcomes and causal estimands
- Identification versus estimation
- Identification versus statistical uncertainty
- Directed acyclic graphs
- d-separation and causal paths
- Confounders, mediators, and colliders
- Translating substantive theories into DAGs
- Identification strategies as arguments about the data-generating process

**Central question:** What would have to be true for an observed comparison to have a causal interpretation?

**Optional technical extension:** Nonparametric structural equation models and the formal relationship between DAGs and potential outcomes.

**Assignment 0 assigned: Naming the Estimand (reading only; no data or code)**

---

## September 2 — Conditioning, DAGs, and Good and Bad Controls

**Core concepts**

- Backdoor criterion
- Conditioning as a graph operation
- Covariate selection
- Collider bias
- Sample-selection bias
- Post-treatment bias
- Bias amplification
- Regression adjustment revisited as an identification strategy
- Sensitivity to unobserved confounding

**Application emphasis:** Reconstruct the implicit DAG behind a published regression-control strategy and determine whether the authors' controls help or harm identification.

**Assignment 0 due**

**Replication Problem Set 1 assigned: Conditioning and selection on observables**

---

## September 9 — Matching, Weighting, and Overlap

**Core concepts**

- Strong ignorability
- Exact and coarsened exact matching
- Nearest-neighbor matching
- Propensity-score weighting
- Covariate-balancing approaches
- Balance diagnostics
- Common support and overlap
- Estimand changes induced by trimming or matching
- Effective samples and treatment-effect heterogeneity

**Central question:** When does making treated and control observations "look alike" create a credible causal comparison?

**Application emphasis:** Compare regression adjustment, matching, and weighting for the same published causal claim and examine which observations actually identify the reported effect.

---

## September 16 — Doubly Robust Estimation and Double Machine Learning

**Core concepts**

- Outcome regression and propensity-score models
- Augmented inverse probability weighting
- Doubly robust estimation
- High-dimensional confounding
- Problems with naïve machine-learning plug-in estimators
- Cross-fitting
- Neyman orthogonality
- Double/debiased machine learning

**Central question:** What can flexible machine learning improve, and what identification problems can it not solve?

**Application emphasis:** Re-estimate a published selection-on-observables design using AIPW/DML and compare results with conventional specifications.

**Replication Problem Set 1 due**

**Optional technical extension:** Orthogonal scores and the intuition behind root-N inference with estimated nuisance functions.

---

## September 23 — Instrumental Variables: Identification Beyond the Textbook Model

**Core concepts**

- Review of conventional IV
- Potential-outcomes formulation
- Independence, exclusion, relevance, and monotonicity
- LATE and complier populations
- Characterizing compliers
- Weak instruments
- What exactly does 2SLS estimate?

**Central question:** Whose causal effect does an instrument identify, and why?

**Replication Problem Set 2 assigned: Instrumental variables**

---

## September 30 — Modern Instrumental-Variables Designs

**Core concepts**

- Empirical checks on IV assumptions
- Placebo outcomes and balance
- Testable implications of IV validity
- Judge/leniency instruments
- Leave-one-out construction and JIVE
- Shift-share/Bartik instruments
- Decomposing identifying variation in shift-share designs
- Distinguishing credible instruments from convenient instruments

**Application emphasis:** Reconstruct the identifying variation in a published IV design and determine which observations or shocks drive the estimate.

**Optional technical extension:** Instrumental inequalities and formal tests of IV validity.

---

## October 7 — Partial Identification: What Can We Learn When Point Identification Fails?

**Core concepts**

- Point versus set identification
- Manski worst-case bounds
- Strengthening assumptions and tightening bounds
- Monotone treatment response and monotone treatment selection
- Balke–Pearl IV bounds
- Lee bounds
- Sensitivity of conclusions to identifying assumptions

**Central question:** When assumptions required for point identification are not credible, what can the data still tell us?

**Replication Problem Set 2 due**

**Replication Problem Set 2B assigned: Partial identification**

**Application emphasis:** Replace a strong point-identifying assumption in an empirical study with weaker assumptions and examine the resulting identified set.

---

## October 14 — Difference-in-Differences and Event Studies

**Core concepts**

- Two-period DiD
- Potential-outcomes formulation of parallel trends
- Conditional parallel trends
- Pre-treatment trends
- Event studies
- Placebo tests
- Anticipation
- Triple differences
- Sensitivity to violations of parallel trends

**Central question:** What counterfactual trend is a DiD design constructing?

---

## October 21 — Staggered Adoption and Modern DiD

**Core concepts**

- Multiple treatment events
- Why conventional two-way fixed effects can fail
- Treatment-effect heterogeneity
- Goodman-Bacon decomposition
- Cohort/event-specific treatment effects
- Sun–Abraham and Callaway–Sant'Anna approaches
- Covariate adjustment
- Modern event-study estimation

**Application emphasis:** Reproduce a published TWFE result, diagnose the comparisons underlying it, and re-estimate the effect using a modern staggered-adoption estimator.

**Optional technical extension:** Weighting representations of TWFE estimators.

**Replication Problem Set 2B due**

**Replication Problem Set 3 assigned: Difference-in-differences**

---

## October 28 — Synthetic Control

**Core concepts**

- Comparative case-study logic
- Identification in synthetic-control designs
- Donor-pool construction
- Predictor and outcome balance
- Pre-treatment fit
- Placebo and permutation inference
- Sensitivity to donor-pool choices
- One treated unit versus multiple treated units
- Augmented synthetic control
- Interactive fixed effects and matrix completion

**Central question:** When can a weighted combination of untreated units provide a credible counterfactual?

---

## November 4 — Regression Discontinuity I: Identification and Estimation

**Core concepts**

- Sharp regression discontinuity
- Potential-outcomes interpretation
- Continuity assumptions
- Local causal estimands
- Parametric versus local-polynomial estimation
- Bandwidth selection
- Robust bias-corrected inference
- Graphical presentation of RD evidence

**Central question:** Why does being just above versus just below a threshold approximate an experiment?

**Replication Problem Set 3 due**

**Replication Problem Set 4 assigned: Synthetic control and panel counterfactuals**

---

## November 11 — Regression Discontinuity II: Diagnostics and Extensions

**Core concepts**

- Manipulation and sorting
- Covariate continuity
- Placebo cutoffs and placebo outcomes
- Bandwidth sensitivity
- Fuzzy RD
- Regression kink designs
- Geographic RD
- Donut RD
- External validity and extrapolation

**Application emphasis:** Replicate a published RD result, conduct contemporary diagnostics, and assess whether the design supports the published causal interpretation.

---

## November 18 — Comparing Designs and Triangulating Evidence

**Core concepts**

- Comparing identifying assumptions across designs
- Selection on observables versus natural experiments
- Internal versus external validity
- Design diagnostics versus robustness checks
- Specification robustness versus identification robustness
- Sensitivity analysis across canonical designs
- What makes an observational design persuasive?
- Combining evidence from different identification strategies

**Workshop:** Students receive several short empirical research scenarios and must select and defend an identification strategy—or explain why none of the canonical designs supports a credible causal claim.

**Replication Problem Set 4 due**

**Replication Problem Set 5 assigned: Regression discontinuity**

**Independent Causal Audit assigned**

---

## November 25 — No Class / Thanksgiving Break

---

## December 2 — Causal Audit Workshop

**Replication Problem Set 5 due**

Students workshop their independent causal audits.

Each student must be able to explain, without relying on code or AI output:

- the substantive causal question;
- the estimand;
- the source of identifying variation;
- the identifying assumptions;
- the estimator;
- the most consequential threat to identification;
- which diagnostic evidence bears on that threat;
- what alternative analysis would be most informative; and
- the strongest causal conclusion they believe the evidence supports.

Peer review will be structured as a mock journal-review process.

---

## December 9 — Causal Audit Defenses

Students present and orally defend their independent causal audits.

The defense emphasizes methodological judgment rather than presentation polish. Students should be prepared to explain why the original design does or does not identify its claimed effect, defend their reanalysis choices, distinguish identification problems from estimation or inference problems, and state precisely how strongly they believe the evidence supports the original causal claim.

# Major Assessments

### Replication Problem Sets — 60%

Six replication-based assignments, approximately 10% each. Assignment 0, a short reading-based exercise due in Week 2, is graded within the participation component rather than as a sixth problem set.

Each assignment combines implementation and critical evaluation. A typical assignment begins with a published article and replication dataset and asks students to reproduce a central table or figure before interrogating the design with tools developed in class.

Grading should place approximately equal weight on:

- **implementation and reproducibility**, and
- **identification analysis and methodological judgment**.

Correct code with an incorrect causal interpretation is not a successful analysis. Conversely, a persuasive conceptual critique without the ability to demonstrate the issue empirically is incomplete.

### Independent Causal Audit — 30%

Students select a published observational causal study outside the papers used for the replication problem sets. The final submission includes:

1. a concise reconstruction of the paper's causal argument;
2. an explicit statement of the estimand;
3. a DAG or other appropriate representation of the identification argument;
4. reproduction of at least one central result;
5. analysis of the identifying assumptions;
6. appropriate design-specific diagnostics;
7. at least one substantively motivated reanalysis;
8. a comparison of the original and revised evidence; and
9. a final judgment stating the strongest causal conclusion supported by the evidence.

Students also complete a short oral defense.

### Participation and In-Class Causal Reasoning — 10%

Short in-class exercises require students to diagnose designs, interpret estimands, critique empirical claims, or explain the logic of an estimator without relying on software.

# AI Policy

Generative AI tools may be used for coding assistance, debugging, exploration of unfamiliar R packages, and clarification of course material. Students may also use AI as a critical interlocutor when working through an analysis.

AI use does not alter the competencies assessed in the course. Students remain responsible for every analytical choice, line of code, statistical result, and causal claim they submit. They must be able to explain and defend their work independently.

For replication problem sets and the causal audit, students should disclose substantive AI use. Assessment will emphasize whether students can explain:

- what the code is doing;
- why a particular estimator is appropriate;
- what assumptions are required;
- what the diagnostics establish and do not establish;
- what the reported estimand means; and
- how the evidence supports or fails to support the causal conclusion.

AI can assist with implementation. It cannot substitute for methodological judgment.