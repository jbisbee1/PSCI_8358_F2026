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

<!-- MATERIALS:1 -->
<div class="readings"><strong>Materials:</strong><ul><li><a href="Lectures/lecture1/lecture01_identification.html">Lecture 1 slides: From Causal Questions to Identification</a></li><li><a href="Psets/PS0/PS0_naming_the_estimand.html">Assignment 0: Naming the Estimand (due Sep 2)</a></li></ul></div>
<!-- /MATERIALS:1 -->

<!-- READINGS:1 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/ding_2023_first_course_causal_inference.pdf">Ding 2023 First Course Causal Inference</a></li><li><a href="Readings/elwert_graphical_causal_models_2013.pdf">Elwert Graphical Causal Models 2013</a></li><li><a href="Readings/greenland_pearl_causal_diagrams_2014.pdf">Greenland Pearl Causal Diagrams 2014</a></li><li><a href="Readings/imbens_2020_potential_outcome_dag.pdf">Imbens 2020 Potential Outcome Dag</a></li><li><a href="Readings/lundberg_et_al_2021_what_is_your_estimand.pdf">Lundberg Et Al 2021 What Is Your Estimand</a></li><li><a href="Readings/morgan_winship.pdf">Morgan Winship</a></li><li><a href="Readings/pearl_1995_causal_diagrams.pdf">Pearl 1995 Causal Diagrams</a></li><li><a href="Readings/pearl_causality_ch3.pdf">Pearl Causality Ch3</a></li><li><a href="Readings/samii_2016_causal_empiricism_quantitative_research.pdf">Samii 2016 Causal Empiricism Quantitative Research</a></li></ul></div>
<!-- /READINGS:1 -->

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

<!-- MATERIALS:2 -->
<div class="readings"><strong>Materials:</strong><ul><li><a href="Lectures/lecture2/lecture02_conditioning.html">Lecture 2 slides: Conditioning, DAGs, and Good and Bad Controls</a></li><li><a href="Psets/PS1/PS1_conditioning_matching_AGG2010.html">Problem Set 1: Conditioning and Matching (due Sep 16)</a></li></ul></div>
<!-- /MATERIALS:2 -->

<!-- READINGS:2 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/acharya_blackwell_sen_2016_direct_effects.pdf">Acharya Blackwell Sen 2016 Direct Effects</a></li><li><a href="Readings/angrist_hahn_2004_when_to_control_covariates.pdf">Angrist Hahn 2004 When To Control Covariates</a></li><li><a href="Readings/blackwell_ma_opacic_2024_assumption_smuggling.pdf">Blackwell Ma Opacic 2024 Assumption Smuggling</a></li><li><a href="Readings/cinelli_forney_pearl_2022.pdf">Cinelli Forney Pearl 2022</a></li><li><a href="Readings/cinelli_hazlett_sensitivity_2020.pdf">Cinelli Hazlett Sensitivity 2020</a></li><li><a href="Readings/clarke_2009_phantom_menace.pdf">Clarke 2009 Phantom Menace</a></li><li><a href="Readings/imai_keele_tingley_yamamoto_2011_unpacking_black_box.pdf">Imai Keele Tingley Yamamoto 2011 Unpacking Black Box</a></li><li><a href="Readings/imai_keele_yamamoto_2010_causal_mediation_sensitivity.pdf">Imai Keele Yamamoto 2010 Causal Mediation Sensitivity</a></li><li><a href="Readings/mohan_pearl_2021_graphical_models_missing_data.pdf">Mohan Pearl 2021 Graphical Models Missing Data</a></li></ul></div>
<!-- /READINGS:2 -->

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

**Student presentation:** Cinelli, Forney & Pearl (2022)

---

## September 9 — Matching, Weighting, and Overlap

<!-- MATERIALS:3 -->
<div class="readings"><strong>Materials:</strong><ul><li><a href="Lectures/lecture3/lecture03_matching_weighting_overlap.html">Lecture 3 slides: Matching, Weighting, and Overlap</a></li></ul></div>
<!-- /MATERIALS:3 -->

<!-- READINGS:3 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/Chattopadhyay_hase_zubizareeta_2020_balancing_vs_modeling.pdf">Chattopadhyay Hase Zubizareeta 2020 Balancing Vs Modeling</a></li><li><a href="Readings/WangZubizarreta2020_minimal_dispersion.pdf">WangZubizarreta2020 Minimal Dispersion</a></li><li><a href="Readings/abadie_imbens_bias_corrected.pdf">Abadie Imbens Bias Corrected</a></li><li><a href="Readings/arbour_dimmery_sondhi_2021_permutation_weighting.pdf">Arbour Dimmery Sondhi 2021 Permutation Weighting</a></li><li><a href="Readings/bruhn_mckenzie_2009_pursuit_of_balance.pdf">Bruhn Mckenzie 2009 Pursuit Of Balance</a></li><li><a href="Readings/busso_dinardo_mccracy_2014_new_evidence.pdf">Busso Dinardo Mccracy 2014 New Evidence</a></li><li><a href="Readings/diamon_sekhon_2013_genetic_matching.pdf">Diamon Sekhon 2013 Genetic Matching</a></li><li><a href="Readings/hainmueller_2012_entropy_balancing.pdf">Hainmueller 2012 Entropy Balancing</a></li><li><a href="Readings/hartman_hidalgo_2018_equivalence_balance_placebo.pdf">Hartman Hidalgo 2018 Equivalence Balance Placebo</a></li><li><a href="Readings/hirano_imbens_ridder_2003_efficient_estimation_propensity_score.pdf">Hirano Imbens Ridder 2003 Efficient Estimation Propensity Score</a></li><li><a href="Readings/iacus_king_porro_2012_cem.pdf">Iacus King Porro 2012 Cem</a></li><li><a href="Readings/imai_king_stuart_2008_misunderstandings.pdf">Imai King Stuart 2008 Misunderstandings</a></li><li><a href="Readings/king_nielsen_2019_propensity_scores.pdf">King Nielsen 2019 Propensity Scores</a></li><li><a href="Readings/lin_ding_han_2023_nearest_neighbor_matching.pdf">Lin Ding Han 2023 Nearest Neighbor Matching</a></li><li><a href="Readings/marbach_hangartner_2020_profiling.pdf">Marbach Hangartner 2020 Profiling</a></li><li><a href="Readings/otsu_rai_2017_bootstrap_matching_estimators.pdf">Otsu Rai 2017 Bootstrap Matching Estimators</a></li><li><a href="Readings/rosenbaum_rubin_1983_propensity_score.pdf">Rosenbaum Rubin 1983 Propensity Score</a></li><li><a href="Readings/sekhon_2009_opiates.pdf">Sekhon 2009 Opiates</a></li></ul></div>
<!-- /READINGS:3 -->

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

**Student presentation:** King & Nielsen (2019)

---

## September 16 — Doubly Robust Estimation and Double Machine Learning

<!-- MATERIALS:4 --><!-- /MATERIALS:4 -->

<!-- READINGS:4 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/ahrens_et_al_2026_dml.pdf">Ahrens Et Al 2026 Dml</a></li><li><a href="Readings/athey_imbens_wager_2018_approximate_residual.pdf">Athey Imbens Wager 2018 Approximate Residual</a></li><li><a href="Readings/chern_et_al_2018_dml_structural.pdf">Chern Et Al 2018 Dml Structural</a></li><li><a href="Readings/glynn_quinn_2010_augmented_inverse_propensity.pdf">Glynn Quinn 2010 Augmented Inverse Propensity</a></li><li><a href="Readings/kennedy_2024_semiparametric_doubly_robust.pdf">Kennedy 2024 Semiparametric Doubly Robust</a></li></ul></div>
<!-- /READINGS:4 -->

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

**Student presentation:** Glynn & Quinn (2010)

---

## September 23 — Instrumental Variables: Identification Beyond the Textbook Model

<!-- MATERIALS:5 --><!-- /MATERIALS:5 -->

<!-- READINGS:5 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/abadie_2003_semiparametric.pdf">Abadie 2003 Semiparametric</a></li><li><a href="Readings/angrist_imbens_rubin_1996_iv.pdf">Angrist Imbens Rubin 1996 Iv</a></li><li><a href="Readings/huber_mellace_2015_testing_instrument_validity.pdf">Huber Mellace 2015 Testing Instrument Validity</a></li><li><a href="Readings/mercatanti_li_2014_debit_cards_household_spending.pdf">Mercatanti Li 2014 Debit Cards Household Spending</a></li><li><a href="Readings/mogstad_santos_torgovitsky_2018_policy_relevant_treatment_params.pdf">Mogstad Santos Torgovitsky 2018 Policy Relevant Treatment Params</a></li></ul></div>
<!-- /READINGS:5 -->

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

**Student presentation:** Angrist, Imbens & Rubin (1996)

---

## September 30 — Modern Instrumental-Variables Designs

<!-- MATERIALS:6 --><!-- /MATERIALS:6 -->

<!-- READINGS:6 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/andrew_stock_sun_2019_weak_instruments.pdf">Andrew Stock Sun 2019 Weak Instruments</a></li><li><a href="Readings/angrist_imbens_krueger_1999_jackknife_iv.pdf">Angrist Imbens Krueger 1999 Jackknife Iv</a></li><li><a href="Readings/borusyak_hull_jaravel_2022_shift_share.pdf">Borusyak Hull Jaravel 2022 Shift Share</a></li><li><a href="Readings/borusyak_hull_jaravel_2025_formula_instruments.pdf">Borusyak Hull Jaravel 2025 Formula Instruments</a></li><li><a href="Readings/goldsmithpinkham_sorkin_swift_2020_bartik_instruments.pdf">Goldsmithpinkham Sorkin Swift 2020 Bartik Instruments</a></li><li><a href="Readings/kitagawa_2015_a_test.pdf">Kitagawa 2015 A Test</a></li><li><a href="Readings/lee_et_al_2022_valid_t_ratio.pdf">Lee Et Al 2022 Valid T Ratio</a></li></ul></div>
<!-- /READINGS:6 -->

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

**Student presentation:** Goldsmith-Pinkham, Sorkin & Swift (2020)

---

## October 7 — Partial Identification: What Can We Learn When Point Identification Fails?

<!-- MATERIALS:7 -->
<div class="readings"><strong>Materials:</strong><ul><li><a href="Psets/PS2B/PS2B_partial_identification_AGG2010.html">Problem Set 2B: Partial Identification (due Oct 21)</a></li></ul></div>
<!-- /MATERIALS:7 -->

<!-- READINGS:7 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/balke_pearl_1997_bounds_imperfect.pdf">Balke Pearl 1997 Bounds Imperfect</a></li><li><a href="Readings/chernozhukov_lee_rosen_2013_intersection_bounds.pdf">Chernozhukov Lee Rosen 2013 Intersection Bounds</a></li><li><a href="Readings/coppock_gerber_green_kern_2017_double_sampling_bounds.pdf">Coppock Gerber Green Kern 2017 Double Sampling Bounds</a></li><li><a href="Readings/lee_2009_training_wages_sample_selection.pdf">Lee 2009 Training Wages Sample Selection</a></li><li><a href="Readings/manski_1990_nonparametric_bounds.pdf">Manski 1990 Nonparametric Bounds</a></li><li><a href="Readings/manski_1997_bounds.pdf">Manski 1997 Bounds</a></li><li><a href="Readings/manski_2003_partial_identification_excerpt.pdf">Manski 2003 Partial Identification Excerpt</a></li><li><a href="Readings/manski_pepper_2000_monotone_iv_returns_schooling.pdf">Manski Pepper 2000 Monotone Iv Returns Schooling</a></li><li><a href="Readings/molinari_2020_partial_identification.pdf">Molinari 2020 Partial Identification</a></li><li><a href="Readings/samii_wang_zhou_2026_trimming_bounds_random_forests.pdf">Samii Wang Zhou 2026 Trimming Bounds Random Forests</a></li><li><a href="Readings/swanson_et_al_2018_partial.pdf">Swanson Et Al 2018 Partial</a></li></ul></div>
<!-- /READINGS:7 -->

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

**Student presentation:** Manski (1990)

---

## October 14 — Difference-in-Differences and Event Studies

<!-- MATERIALS:8 --><!-- /MATERIALS:8 -->

<!-- READINGS:8 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/fernan_pinto_2019_inference_did.pdf">Fernan Pinto 2019 Inference Did</a></li><li><a href="Readings/roth_santanna_bilinski_poe_2023_did_trending.pdf">Roth Santanna Bilinski Poe 2023 Did Trending</a></li></ul></div>
<!-- /READINGS:8 -->

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

**Student presentation:** Roth, Sant'Anna, Bilinski & Poe (2023)

---

## October 21 — Staggered Adoption and Modern DiD

<!-- MATERIALS:9 --><!-- /MATERIALS:9 -->

<!-- READINGS:9 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/borusyak_jaravel_spiess_2024_event_study.pdf">Borusyak Jaravel Spiess 2024 Event Study</a></li><li><a href="Readings/callaway_goodmanbacon_santanna_2024_continuous_treatment_did.pdf">Callaway Goodmanbacon Santanna 2024 Continuous Treatment Did</a></li><li><a href="Readings/callaway_santanna_2021_multiple_time_periods_did.pdf">Callaway Santanna 2021 Multiple Time Periods Did</a></li><li><a href="Readings/cengiz_dube_lindner_zipperer_2019_minimum_wages.pdf">Cengiz Dube Lindner Zipperer 2019 Minimum Wages</a></li><li><a href="Readings/chiu_lan_liu_xu_2023_causal_panel_parallel_trends.pdf">Chiu Lan Liu Xu 2023 Causal Panel Parallel Trends</a></li><li><a href="Readings/dechaisemartin_dhaultfoeuille_2026_did_book.pdf">Dechaisemartin Dhaultfoeuille 2026 Did Book</a></li><li><a href="Readings/dechaisemartin_dhaultfoeuille_vazquezbare_2024_continuous_treatments_no_stayers.pdf">Dechaisemartin Dhaultfoeuille Vazquezbare 2024 Continuous Treatments No Stayers</a></li><li><a href="Readings/dube_girardi_jorda_taylor_2023_local_projections_did.pdf">Dube Girardi Jorda Taylor 2023 Local Projections Did</a></li><li><a href="Readings/goodmanbacon_2021_did_variation_treatment_timing.pdf">Goodmanbacon 2021 Did Variation Treatment Timing</a></li><li><a href="Readings/liu_wang_xu_2024_counterfactual_estimators.pdf">Liu Wang Xu 2024 Counterfactual Estimators</a></li><li><a href="Readings/mackinnon_webb_2016_did_few_treated_clusters.pdf">Mackinnon Webb 2016 Did Few Treated Clusters</a></li><li><a href="Readings/roth_rambachan_2022_credible_approach_parallel_trends.pdf">Roth Rambachan 2022 Credible Approach Parallel Trends</a></li><li><a href="Readings/sun_abraham_2021_dynamic_treatment_effects_event_studies.pdf">Sun Abraham 2021 Dynamic Treatment Effects Event Studies</a></li><li><a href="Readings/xu_hazlett_trajectory_balancing.pdf">Xu Hazlett Trajectory Balancing</a></li><li><a href="Readings/xu_zhao_ding_2024_factorial_did.pdf">Xu Zhao Ding 2024 Factorial Did</a></li></ul></div>
<!-- /READINGS:9 -->

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

**Student presentation:** Goodman-Bacon (2021)

---

## October 28 — Synthetic Control

<!-- MATERIALS:10 --><!-- /MATERIALS:10 -->

<!-- READINGS:10 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/abadie_diamond_hainmueller_2010_synthetic_control.pdf">Abadie Diamond Hainmueller 2010 Synthetic Control</a></li><li><a href="Readings/abadie_gardeazabal_2003_basque_country.pdf">Abadie Gardeazabal 2003 Basque Country</a></li><li><a href="Readings/benmichael_feller_rothstein_2021_augmented_synthetic_control.pdf">Benmichael Feller Rothstein 2021 Augmented Synthetic Control</a></li><li><a href="Readings/chernozhukov_wuthrich_zhu_2021_conformal_inference_synthetic_control.pdf">Chernozhukov Wuthrich Zhu 2021 Conformal Inference Synthetic Control</a></li><li><a href="Readings/firpo_possebom_2018_synthetic_control_inference.pdf">Firpo Possebom 2018 Synthetic Control Inference</a></li><li><a href="Readings/hahn_shi_2017_synthetic_control_inference.pdf">Hahn Shi 2017 Synthetic Control Inference</a></li><li><a href="Readings/kuosmanen_zhou_eskelinen_malo_2021_synthetic_control_design_flaw.pdf">Kuosmanen Zhou Eskelinen Malo 2021 Synthetic Control Design Flaw</a></li></ul></div>
<!-- /READINGS:10 -->

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

**Student presentation:** Abadie, Diamond & Hainmueller (2010)

---

## November 4 — Regression Discontinuity I: Identification and Estimation

<!-- MATERIALS:11 --><!-- /MATERIALS:11 -->

<!-- READINGS:11 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/cattaneo_idrobo_titiunik_2019_rd_foundations.pdf">Cattaneo Idrobo Titiunik 2019 Rd Foundations</a></li><li><a href="Readings/cattaneo_titiunik_2022_rd_designs.pdf">Cattaneo Titiunik 2022 Rd Designs</a></li><li><a href="Readings/kling_2006_incarceration_length_employment.pdf">Kling 2006 Incarceration Length Employment</a></li></ul></div>
<!-- /READINGS:11 -->

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

**Student presentation:** Cattaneo & Titiunik (2022)

---

## November 11 — Regression Discontinuity II: Diagnostics and Extensions

<!-- MATERIALS:12 --><!-- /MATERIALS:12 -->

<!-- READINGS:12 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/card_lee_pei_weber_2017_regression_kink_design.pdf">Card Lee Pei Weber 2017 Regression Kink Design</a></li><li><a href="Readings/cattaneo_titiunik_yu_2025_boundary_discontinuity.pdf">Cattaneo Titiunik Yu 2025 Boundary Discontinuity</a></li><li><a href="Readings/dowd_2021_donuts_distant_cates.pdf">Dowd 2021 Donuts Distant Cates</a></li><li><a href="Readings/stommes_aronow_savje_2023_rd_reliability_political_science.pdf">Stommes Aronow Savje 2023 Rd Reliability Political Science</a></li></ul></div>
<!-- /READINGS:12 -->

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

**Student presentation:** Stommes, Aronow & Sävje (2023)

---

## November 18 — Comparing Designs and Triangulating Evidence

<!-- MATERIALS:13 --><!-- /MATERIALS:13 -->

<!-- READINGS:13 -->
<div class="readings"><strong>Readings:</strong><ul><li><a href="Readings/rambachan_roth_2025_design_based_uncertainty_quasi_experiments.pdf">Rambachan Roth 2025 Design Based Uncertainty Quasi Experiments</a></li></ul></div>
<!-- /READINGS:13 -->

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

<!-- MATERIALS:14 --><!-- /MATERIALS:14 -->

<!-- READINGS:14 --><!-- /READINGS:14 -->

---

## December 2 — Causal Audit Workshop

<!-- MATERIALS:15 --><!-- /MATERIALS:15 -->

<!-- READINGS:15 --><!-- /READINGS:15 -->

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

<!-- MATERIALS:16 --><!-- /MATERIALS:16 -->

<!-- READINGS:16 --><!-- /READINGS:16 -->

Students present and orally defend their independent causal audits.

The defense emphasizes methodological judgment rather than presentation polish. Students should be prepared to explain why the original design does or does not identify its claimed effect, defend their reanalysis choices, distinguish identification problems from estimation or inference problems, and state precisely how strongly they believe the evidence supports the original causal claim.

# Major Assessments

### Replication Problem Sets — 55%

Six replication-based assignments, approximately 9% each. Assignment 0, a short reading-based exercise due in Week 2, is graded within the participation component rather than as a sixth problem set.

Each assignment combines implementation and critical evaluation. A typical assignment begins with a published article and replication dataset and asks students to reproduce a central table or figure before interrogating the design with tools developed in class.

Grading should place approximately equal weight on:

- **implementation and reproducibility**, and
- **identification analysis and methodological judgment**.

Correct code with an incorrect causal interpretation is not a successful analysis. Conversely, a persuasive conceptual critique without the ability to demonstrate the issue empirically is incomplete.

### Independent Causal Audit — 25%

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

### Seminar Presentation — 10%

Beginning in Week 2, one student each week presents the designated reading. Presentations run through Week 12; Weeks 13, 15, and 16 are reserved for the design workshop and the causal audit.

Each presentation is twenty minutes, followed by ten minutes of discussion that the presenter leads. It is not a summary. A presentation that walks through the paper section by section has not done the assignment.

Organize the presentation around the four questions that structure this course:

- What is the causal quantity the paper is concerned with?
- What variation is supposed to identify it?
- Under what assumptions does that variation identify it?
- What evidence bears on whether those assumptions hold?

Every presentation must also include:

- **one worked example you reconstructed independently** — a derivation, a numerical illustration, or a DAG that you produced rather than reproduced;
- **one objection** you take seriously, stated as a claim you are prepared to defend; and
- **one discussion question** for the class, circulated at least twenty-four hours in advance.

Use no more than six slides. The constraint is deliberate: a paper cannot be summarized in six slides, which forces a decision about what the paper is actually for.

The course AI policy applies in full. You may use AI tools to prepare, but you must be able to answer questions about the paper without them, and the discussion period is where that becomes apparent.

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