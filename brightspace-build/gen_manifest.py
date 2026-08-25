# -*- coding: utf-8 -*-
"""
Generates:
  - brightspace-build/pages/syllabus.html
  - brightspace-build/pages/week-XX-overview.html   (one per week)
  - brightspace-build/course.json

Run from the brightspace-build/ directory: python gen_manifest.py
"""
import json
import re
import html
from pathlib import Path

import markdown as md

ROOT = Path(__file__).resolve().parent.parent  # PSCI_8358_F2026/
BUILD = Path(__file__).resolve().parent        # brightspace-build/
PAGES = BUILD / "pages"
PAGES.mkdir(exist_ok=True)
READINGS = ROOT / "Readings"

PAGE_CSS = """
<style>
  body { font-family: -apple-system, Segoe UI, Helvetica, Arial, sans-serif;
         line-height: 1.5; color: #1a1a1a; max-width: 900px; margin: 0 auto; padding: 1rem; }
  h1, h2, h3 { line-height: 1.25; }
  h1 { font-size: 1.6rem; border-bottom: 2px solid #333; padding-bottom: .3rem; }
  h2 { font-size: 1.3rem; margin-top: 1.6rem; }
  h3 { font-size: 1.1rem; }
  table { border-collapse: collapse; margin: 1rem 0; }
  th, td { border: 1px solid #ccc; padding: .4rem .7rem; text-align: left; }
  code { background: #f2f2f2; padding: .1rem .3rem; border-radius: 3px; }
  .central-q { background: #f5f7fa; border-left: 4px solid #4a6fa5; padding: .6rem 1rem; margin: 1rem 0; }
  .readings { background: #fbf8f0; border-left: 4px solid #b58a2f; padding: .5rem 1rem; margin: .5rem 0 1rem; }
  .readings ul { margin: .2rem 0 0; }
  ul { margin-top: .3rem; }
</style>
""".strip()


def wrap(title, body_html):
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>{html.escape(title)}</title>
{PAGE_CSS}
</head><body>
{body_html}
</body></html>
"""


MONTHS = ("January|February|March|April|May|June|July|August|September|"
          "October|November|December")


def inject_readings(body_html, week_readings, titleize_fn):
    """Insert a Readings block right after each weekly <h2> heading in the
    syllabus body, matched positionally among *weekly-schedule* headings
    only (those starting with a month name -- "Course Description" and
    "Course Structure" are also <h2> but aren't weeks and must be excluded,
    or the count drifts): the Nth such <h2> corresponds to
    WEEKS[N-1] / week_readings[N]."""
    h2_pattern = re.compile(rf"(<h2>(?:{MONTHS})\b.*?</h2>)", re.S)
    counter = {"n": 0}

    def repl(m):
        counter["n"] += 1
        n = counter["n"]
        block = m.group(1)
        readings = week_readings.get(n)
        if readings:
            items = "".join(
                f"<li>{html.escape(titleize_fn(p.stem))}</li>" for p in readings
            )
            block += f'<div class="readings"><strong>Readings:</strong><ul>{items}</ul></div>'
        return block

    return h2_pattern.sub(repl, body_html)


# ---------------------------------------------------------------------------
# 1. Syllabus page — rendered from README.md, everything up to "# AI Policy"
#    inclusive (course description, schedule, assessments, AI policy).
# Reading lists are injected per week further below, once week_readings is
# resolved; the file is written there, not here.
# ---------------------------------------------------------------------------
readme_text = (ROOT / "README.md").read_text(encoding="utf-8")
syllabus_html_body = md.markdown(readme_text, extensions=["tables", "fenced_code"])

# ---------------------------------------------------------------------------
# 2. Weekly schedule (mirrors README.md's "# Semester Schedule")
# ---------------------------------------------------------------------------
WEEKS = [
    dict(n=1, date="2026-08-26", title="From Potential Outcomes to Identification",
         central="What would have to be true for an observed comparison to have a causal interpretation?",
         concepts=["Brief review of potential outcomes and causal estimands", "Identification versus estimation",
                    "Identification versus statistical uncertainty", "Directed acyclic graphs",
                    "d-separation and causal paths", "Confounders, mediators, and colliders",
                    "Translating substantive theories into DAGs",
                    "Identification strategies as arguments about the data-generating process"],
         app=None, note="Assignment 0 assigned: Naming the Estimand (reading only; no data or code). Optional technical extension: nonparametric structural equation models and the formal relationship between DAGs and potential outcomes."),
    dict(n=2, date="2026-09-02", title="Conditioning, DAGs, and Good and Bad Controls",
         central="",
         concepts=["Backdoor criterion", "Conditioning as a graph operation", "Covariate selection", "Collider bias",
                    "Sample-selection bias", "Post-treatment bias", "Bias amplification",
                    "Regression adjustment revisited as an identification strategy",
                    "Sensitivity to unobserved confounding"],
         app="Reconstruct the implicit DAG behind a published regression-control strategy and determine whether the authors' controls help or harm identification.",
         note="Assignment 0 due. Replication Problem Set 1 assigned: Conditioning and selection on observables."),
    dict(n=3, date="2026-09-09", title="Matching, Weighting, and Overlap",
         central="When does making treated and control observations “look alike” create a credible causal comparison?",
         concepts=["Strong ignorability", "Exact and coarsened exact matching", "Nearest-neighbor matching",
                    "Propensity-score weighting", "Covariate-balancing approaches", "Balance diagnostics",
                    "Common support and overlap", "Estimand changes induced by trimming or matching",
                    "Effective samples and treatment-effect heterogeneity"],
         app="Compare regression adjustment, matching, and weighting for the same published causal claim and examine which observations actually identify the reported effect.",
         note=None),
    dict(n=4, date="2026-09-16", title="Doubly Robust Estimation and Double Machine Learning",
         central="What can flexible machine learning improve, and what identification problems can it not solve?",
         concepts=["Outcome regression and propensity-score models", "Augmented inverse probability weighting",
                    "Doubly robust estimation", "High-dimensional confounding",
                    "Problems with naïve machine-learning plug-in estimators", "Cross-fitting",
                    "Neyman orthogonality", "Double/debiased machine learning"],
         app="Re-estimate a published selection-on-observables design using AIPW/DML and compare results with conventional specifications.",
         note="Replication Problem Set 1 due. Optional technical extension: orthogonal scores and the intuition behind root-N inference with estimated nuisance functions."),
    dict(n=5, date="2026-09-23", title="Instrumental Variables: Identification Beyond the Textbook Model",
         central="Whose causal effect does an instrument identify, and why?",
         concepts=["Review of conventional IV", "Potential-outcomes formulation",
                    "Independence, exclusion, relevance, and monotonicity", "LATE and complier populations",
                    "Characterizing compliers", "Weak instruments", "What exactly does 2SLS estimate?"],
         app=None, note="Replication Problem Set 2 assigned: Instrumental variables."),
    dict(n=6, date="2026-09-30", title="Modern Instrumental-Variables Designs",
         central="",
         concepts=["Empirical checks on IV assumptions", "Placebo outcomes and balance",
                    "Testable implications of IV validity", "Judge/leniency instruments",
                    "Leave-one-out construction and JIVE", "Shift-share/Bartik instruments",
                    "Decomposing identifying variation in shift-share designs",
                    "Distinguishing credible instruments from convenient instruments"],
         app="Reconstruct the identifying variation in a published IV design and determine which observations or shocks drive the estimate.",
         note="Optional technical extension: instrumental inequalities and formal tests of IV validity."),
    dict(n=7, date="2026-10-07", title="Partial Identification: What Can We Learn When Point Identification Fails?",
         central="When assumptions required for point identification are not credible, what can the data still tell us?",
         concepts=["Point versus set identification", "Manski worst-case bounds",
                    "Strengthening assumptions and tightening bounds",
                    "Monotone treatment response and monotone treatment selection", "Balke–Pearl IV bounds",
                    "Lee bounds", "Sensitivity of conclusions to identifying assumptions"],
         app="Replace a strong point-identifying assumption in an empirical study with weaker assumptions and examine the resulting identified set.",
         note="Replication Problem Set 2 due. Replication Problem Set 2B assigned: Partial identification."),
    dict(n=8, date="2026-10-14", title="Difference-in-Differences and Event Studies",
         central="What counterfactual trend is a DiD design constructing?",
         concepts=["Two-period DiD", "Potential-outcomes formulation of parallel trends", "Conditional parallel trends",
                    "Pre-treatment trends", "Event studies", "Placebo tests", "Anticipation", "Triple differences",
                    "Sensitivity to violations of parallel trends"],
         app=None, note=None),
    dict(n=9, date="2026-10-21", title="Staggered Adoption and Modern DiD",
         central="",
         concepts=["Multiple treatment events", "Why conventional two-way fixed effects can fail",
                    "Treatment-effect heterogeneity", "Goodman-Bacon decomposition",
                    "Cohort/event-specific treatment effects", "Sun–Abraham and Callaway–Sant'Anna approaches",
                    "Covariate adjustment", "Modern event-study estimation"],
         app="Reproduce a published TWFE result, diagnose the comparisons underlying it, and re-estimate the effect using a modern staggered-adoption estimator.",
         note="Replication Problem Set 2B due. Replication Problem Set 3 assigned: Difference-in-differences. Optional technical extension: weighting representations of TWFE estimators."),
    dict(n=10, date="2026-10-28", title="Synthetic Control",
         central="When can a weighted combination of untreated units provide a credible counterfactual?",
         concepts=["Comparative case-study logic", "Identification in synthetic-control designs",
                    "Donor-pool construction", "Predictor and outcome balance", "Pre-treatment fit",
                    "Placebo and permutation inference", "Sensitivity to donor-pool choices",
                    "One treated unit versus multiple treated units", "Augmented synthetic control",
                    "Interactive fixed effects and matrix completion"],
         app=None, note=None),
    dict(n=11, date="2026-11-04", title="Regression Discontinuity I: Identification and Estimation",
         central="Why does being just above versus just below a threshold approximate an experiment?",
         concepts=["Sharp regression discontinuity", "Potential-outcomes interpretation", "Continuity assumptions",
                    "Local causal estimands", "Parametric versus local-polynomial estimation", "Bandwidth selection",
                    "Robust bias-corrected inference", "Graphical presentation of RD evidence"],
         app=None, note="Replication Problem Set 3 due. Replication Problem Set 4 assigned: Synthetic control and panel counterfactuals."),
    dict(n=12, date="2026-11-11", title="Regression Discontinuity II: Diagnostics and Extensions",
         central="",
         concepts=["Manipulation and sorting", "Covariate continuity", "Placebo cutoffs and placebo outcomes",
                    "Bandwidth sensitivity", "Fuzzy RD", "Regression kink designs", "Geographic RD", "Donut RD",
                    "External validity and extrapolation"],
         app="Replicate a published RD result, conduct contemporary diagnostics, and assess whether the design supports the published causal interpretation.",
         note=None),
    dict(n=13, date="2026-11-18", title="Comparing Designs and Triangulating Evidence",
         central="What makes an observational design persuasive?",
         concepts=["Comparing identifying assumptions across designs", "Selection on observables versus natural experiments",
                    "Internal versus external validity", "Design diagnostics versus robustness checks",
                    "Specification robustness versus identification robustness",
                    "Sensitivity analysis across canonical designs", "Combining evidence from different identification strategies"],
         app=None,
         note="Replication Problem Set 4 due. Replication Problem Set 5 assigned: Regression discontinuity. Workshop: students receive several short empirical research scenarios and must select and defend an identification strategy—or explain why none of the canonical designs supports a credible causal claim. Independent Causal Audit assigned."),
    dict(n=14, date="2026-11-25", title="No Class / Thanksgiving Break",
         central="", concepts=[], app=None, note=None),
    dict(n=15, date="2026-12-02", title="Causal Audit Workshop",
         central="",
         concepts=[],
         app=None,
         note="Replication Problem Set 5 due. Students workshop their independent causal audits (peer review structured as a mock journal-review process)."),
    dict(n=16, date="2026-12-09", title="Causal Audit Defenses",
         central="",
         concepts=[],
         app=None,
         note="Students present and orally defend their independent causal audits. The defense emphasizes methodological judgment: why the original design does or does not identify its claimed effect, defense of reanalysis choices, and how strongly the evidence supports the original causal claim."),
]

# ---------------------------------------------------------------------------
# 3. Reading -> week map. Keys are filename substrings (unique enough to
#    match exactly one file each); value is a list of week numbers (usually
#    one). Anything in Readings/ not claimed here falls into the
#    "Supplementary / Reference Readings" module at the end for the
#    instructor to sort by hand.
# ---------------------------------------------------------------------------
READING_WEEK = {
    # Week 1 -- potential outcomes / identification / DAGs
    "pearl_1995_causal_diagrams": 1,
    "lundberg_et_al_2021_what_is_your_estimand": 1,
    "pearl_causality_ch3": 1,
    "greenland_pearl_causal_diagrams_2014": 1,
    "elwert_graphical_causal_models_2013": 1,
    "imbens_2020_potential_outcome_dag": 1,
    "samii_2016_causal_empiricism_quantitative_research": 1,
    "morgan_winship": 1,
    "ding_2023_first_course_causal_inference": 1,
    # Week 2 -- conditioning / good-bad controls / mediation / sensitivity
    "cinelli_forney_pearl_2022": 2,
    "cinelli_hazlett_sensitivity_2020": 2,
    "clarke_2009_phantom_menace": 2,
    "angrist_hahn_2004_when_to_control_covariates": 2,
    "acharya_blackwell_sen_2016_direct_effects": 2,
    "blackwell_ma_opacic_2024_assumption_smuggling": 2,
    "imai_keele_tingley_yamamoto_2011_unpacking_black_box": 2,
    "imai_keele_yamamoto_2010_causal_mediation_sensitivity": 2,
    "mohan_pearl_2021_graphical_models_missing_data": 2,
    # Week 3 -- matching / weighting / overlap
    "rosenbaum_rubin_1983_propensity_score": 3,
    "hirano_imbens_ridder_2003_efficient_estimation_propensity_score": 3,
    "hainmueller_2012_entropy_balancing": 3,
    "iacus_king_porro_2012_cem": 3,
    "diamon_sekhon_2013_genetic_matching": 3,
    "sekhon_2009_opiates": 3,
    "king_nielsen_2019_propensity_scores": 3,
    "imai_king_stuart_2008_misunderstandings": 3,
    "abadie_imbens_bias_corrected": 3,
    "chattopadhyay_hase_zubizareeta_2020_balancing_vs_modeling": 3,
    "wangzubizarreta2020_minimal_dispersion": 3,
    "arbour_dimmery_sondhi_2021_permutation_weighting": 3,
    "busso_dinardo_mccracy_2014_new_evidence": 3,
    "hartman_hidalgo_2018_equivalence_balance_placebo": 3,
    "otsu_rai_2017_bootstrap_matching_estimators": 3,
    "lin_ding_han_2023_nearest_neighbor_matching": 3,
    "bruhn_mckenzie_2009_pursuit_of_balance": 3,
    "marbach_hangartner_2020_profiling": 3,
    # Week 4 -- DR / DML
    "glynn_quinn_2010_augmented_inverse_propensity": 4,
    "chern_et_al_2018_dml_structural": 4,
    "athey_imbens_wager_2018_approximate_residual": 4,
    "ahrens_et_al_2026_dml": 4,
    "kennedy_2024_semiparametric_doubly_robust": 4,
    # Week 5 -- IV core
    "angrist_imbens_rubin_1996_iv": 5,
    "abadie_2003_semiparametric": 5,
    "huber_mellace_2015_testing_instrument_validity": 5,
    "mogstad_santos_torgovitsky_2018_policy_relevant_treatment_params": 5,
    "mercatanti_li_2014_debit_cards_household_spending": 5,
    # Week 6 -- modern IV
    "andrew_stock_sun_2019_weak_instruments": 6,
    "angrist_imbens_krueger_1999_jackknife_iv": 6,
    "goldsmithpinkham_sorkin_swift_2020_bartik_instruments": 6,
    "borusyak_hull_jaravel_2022_shift_share": 6,
    "borusyak_hull_jaravel_2025_formula_instruments": 6,
    "lee_et_al_2022_valid_t_ratio": 6,
    "kitagawa_2015_a_test": 6,
    # Week 7 -- partial identification / bounds
    "manski_1990_nonparametric_bounds": 7,
    "manski_1997_bounds": 7,
    "manski_2003_partial_identification_excerpt": 7,
    "manski_pepper_2000_monotone_iv_returns_schooling": 7,
    "balke_pearl_1997_bounds_imperfect": 7,
    "lee_2009_training_wages_sample_selection": 7,
    "molinari_2020_partial_identification": 7,
    "chernozhukov_lee_rosen_2013_intersection_bounds": 7,
    "coppock_gerber_green_kern_2017_double_sampling_bounds": 7,
    "swanson_et_al_2018_partial": 7,
    "samii_wang_zhou_2026_trimming_bounds_random_forests": 7,
    # Week 8 -- 2-period DiD / event studies
    "fernan_pinto_2019_inference_did": 8,
    "roth_santanna_bilinski_poe_2023_did_trending": 8,
    # Week 9 -- staggered adoption / modern DiD
    "goodmanbacon_2021_did_variation_treatment_timing": 9,
    "callaway_santanna_2021_multiple_time_periods_did": 9,
    "callaway_goodmanbacon_santanna_2024_continuous_treatment_did": 9,
    "sun_abraham_2021_dynamic_treatment_effects_event_studies": 9,
    "roth_rambachan_2022_credible_approach_parallel_trends": 9,
    "borusyak_jaravel_spiess_2024_event_study": 9,
    "chiu_lan_liu_xu_2023_causal_panel_parallel_trends": 9,
    "dechaisemartin_dhaultfoeuille_2026_did_book": 9,
    "dechaisemartin_dhaultfoeuille_vazquezbare_2024_continuous_treatments_no_stayers": 9,
    "dube_girardi_jorda_taylor_2023_local_projections_did": 9,
    "mackinnon_webb_2016_did_few_treated_clusters": 9,
    "liu_wang_xu_2024_counterfactual_estimators": 9,
    "cengiz_dube_lindner_zipperer_2019_minimum_wages": 9,
    "xu_zhao_ding_2024_factorial_did": 9,
    "xu_hazlett_trajectory_balancing": 9,
    # Week 10 -- synthetic control
    "abadie_diamond_hainmueller_2010_synthetic_control": 10,
    "abadie_gardeazabal_2003_basque_country": 10,
    "benmichael_feller_rothstein_2021_augmented_synthetic_control": 10,
    "chernozhukov_wuthrich_zhu_2021_conformal_inference_synthetic_control": 10,
    "firpo_possebom_2018_synthetic_control_inference": 10,
    "hahn_shi_2017_synthetic_control_inference": 10,
    "kuosmanen_zhou_eskelinen_malo_2021_synthetic_control_design_flaw": 10,
    # Week 11 -- RD I
    "cattaneo_idrobo_titiunik_2019_rd_foundations": 11,
    "cattaneo_titiunik_2022_rd_designs": 11,
    "kling_2006_incarceration_length_employment": 11,
    # Week 12 -- RD II
    "card_lee_pei_weber_2017_regression_kink_design": 12,
    "cattaneo_titiunik_yu_2025_boundary_discontinuity": 12,
    "dowd_2021_donuts_distant_cates": 12,
    "stommes_aronow_savje_2023_rd_reliability_political_science": 12,
    # Week 13 -- comparing designs / triangulating
    "rambachan_roth_2025_design_based_uncertainty_quasi_experiments": 13,
}

# supplementary/general-methods readings not tied to one specific week
SUPPLEMENTARY = [
    "MHE",
    "abadie_athens_imbens_woolridge_2020_sampling_design",
    "abadie_athey_imbens_wooldridge_2023_clustering_se",
    "anderson_2008_multiple_inference_gender",
    "aronow_eckles_samii_zonszein_2021_spillover_effects",
    "aronow_samii_2017_general_interference",
    "aronow_samii_representative_2016",
    "bloom_1995_minimum_detectable_effects",
    "cameron_gelbach_miller_2008_bootstrap_clustered_errors",
    "fogarty_2018_finely_stratified_experiments",
    "gomila_clark_2022_missing_data_experiments",
    "hainmueller_mummolo_xu_2019_multiplicative_interaction",
    "hudgens_halloran_2008_toward",
    "imai_jiang_2020_contagion_effects",
    "muralidharan_romero_wuthrich_2025_factorial_designs",
    "pustejovsky_tipton_2018_cluster_robust_variance_small_sample",
    "samii_paler_daly_2016_retrospective_causal_inference_ml",
    "staub_2014_causal_interp",
]


def titleize(stem):
    """abadie_diamond_hainmueller_2010_synthetic_control -> Abadie Diamond Hainmueller 2010 Synthetic Control"""
    words = stem.replace("-", "_").split("_")
    out = []
    for w in words:
        if re.fullmatch(r"\d{4}[a-z]?", w):
            out.append(w)
        else:
            out.append(w[:1].upper() + w[1:])
    return " ".join(out)


all_pdfs = sorted(READINGS.glob("*.pdf"))
claimed = {}
for stem_key, wk in READING_WEEK.items():
    claimed.setdefault(wk, []).append(stem_key)

# resolve stem_key -> actual filename (case-insensitive substring match)
def resolve(stem_key):
    for p in all_pdfs:
        if p.stem.lower() == stem_key.lower():
            return p
    raise KeyError(f"no reading file matches key: {stem_key}")

week_readings = {}
used_files = set()
for wk in range(1, 14):
    files = []
    for key in claimed.get(wk, []):
        p = resolve(key)
        files.append(p)
        used_files.add(p.name)
    files.sort(key=lambda p: p.name)
    week_readings[wk] = files

supp_files = []
for key in SUPPLEMENTARY:
    p = resolve(key)
    supp_files.append(p)
    used_files.add(p.name)

# Now that week_readings is resolved, finish and write the syllabus page.
syllabus_html_body = inject_readings(syllabus_html_body, week_readings, titleize)
(PAGES / "syllabus.html").write_text(
    wrap("PSCI 8358 — Syllabus: Advanced Observational Causal Inference", syllabus_html_body),
    encoding="utf-8",
)

unclaimed = [p for p in all_pdfs if p.name not in used_files]

# ---------------------------------------------------------------------------
# 4. Build course.json
# ---------------------------------------------------------------------------
manifest = {
    "course": {
        "name": "PSCI 8358-01: Topics in Political Methodology (Advanced Observational Causal Inference)",
        "term": "Fall 2026",
        "template": "none",
        "ou": 648878,
        "keep_inactive": True,
        "no_class_dates": ["2026-11-25"],
    },
    "modules": [],
    "assignments": [],
    "announcements": [],
}

# Syllabus module (first)
manifest["modules"].append({
    "title": "Syllabus",
    "pages": [
        {"title": "Syllabus", "file": "pages/syllabus.html", "kit": "raw"}
    ],
})

for w in WEEKS:
    n = w["n"]
    date_human = w["date"]
    mod_title = f"Week {n:02d} ({date_human}): {w['title']}"

    body = [f"<h1>Week {n}: {html.escape(w['title'])}</h1>", f"<p><strong>{date_human}</strong></p>"]
    if w["central"]:
        body.append(f'<div class="central-q"><strong>Central question:</strong> {html.escape(w["central"])}</div>')
    if w["concepts"]:
        body.append("<h2>Core concepts</h2><ul>")
        body += [f"<li>{html.escape(c)}</li>" for c in w["concepts"]]
        body.append("</ul>")
    if w["app"]:
        body.append(f'<h2>Application emphasis</h2><p>{html.escape(w["app"])}</p>')
    if w["note"]:
        body.append(f'<h2>Notes</h2><p>{html.escape(w["note"])}</p>')

    readings = week_readings.get(n, [])
    if readings:
        body.append("<h2>Readings</h2><ul>")
        for p in readings:
            body.append(f"<li>{html.escape(titleize(p.stem))}</li>")
        body.append("</ul>")

    page_file = f"pages/week-{n:02d}-overview.html"
    (PAGES / f"week-{n:02d}-overview.html").write_text(
        wrap(mod_title, "\n".join(body)), encoding="utf-8"
    )

    module = {
        "title": mod_title,
        "pages": [{"title": f"Week {n} Overview", "file": page_file, "kit": "raw"}],
        "files": [
            {"title": titleize(p.stem), "file": f"../Readings/{p.name}"} for p in readings
        ],
    }
    manifest["modules"].append(module)

# Supplementary readings module
supp_body = ["<h1>Supplementary / Reference Readings</h1>",
             "<p>General-methods references not tied to a single week: sampling design, "
             "clustering/inference, interference/spillovers, multiple testing, missing data, "
             "and standard texts.</p>", "<ul>"]
for p in sorted(supp_files, key=lambda p: p.name):
    supp_body.append(f"<li>{html.escape(titleize(p.stem))}</li>")
supp_body.append("</ul>")
(PAGES / "supplementary-overview.html").write_text(
    wrap("Supplementary / Reference Readings", "\n".join(supp_body)), encoding="utf-8"
)
manifest["modules"].append({
    "title": "Supplementary / Reference Readings",
    "pages": [{"title": "Supplementary Readings Overview", "file": "pages/supplementary-overview.html", "kit": "raw"}],
    "files": [{"title": titleize(p.stem), "file": f"../Readings/{p.name}"} for p in sorted(supp_files, key=lambda p: p.name)],
})

# Lectures -- flagged separately, not auto-added (see note printed below)

# PS1 assignment, filed under Week 2 (assigned) with a due date at Week 4 (due per README).
# The full write-up is 640KB of knitted RMarkdown HTML -- too much for an assignment
# description; posted instead as a file in the Week 2 module (below), alongside the
# source article and replication package, with the answer key excluded.
ps1_dir = ROOT / "Psets" / "PS1"
ps1_instructions = """
<h2>Replication Problem Set 1: Conditioning and Selection on Observables</h2>
<p>Replicate and reanalyze <strong>Arceneaux, Gerber &amp; Green (2010)</strong>,
"A Cautionary Note on the Use of Matching to Estimate Causal Effects."</p>
<p>Materials (article, full problem-set write-up, and replication package) are posted in the
<strong>Week 02 (Conditioning, DAGs, and Good and Bad Controls)</strong> module.</p>
<p>Submit your reproduction, identification-argument writeup, and reanalysis as described in the
posted problem-set document.</p>
""".strip()
manifest["assignments"].append({
    "title": "Replication Problem Set 1: Conditioning and Selection on Observables (AGG 2010)",
    "due": "2026-09-16T04:59:00.000Z",  # Tue Sep 15 11:59pm CT -> due morning of Week 4 class
    "out_of": 100,
    "hidden": False,
    "instructions": ps1_instructions,
})

PS1_FILES = [
    ("PS1: Conditioning & Matching — Assignment (AGG 2010)", "PS1_conditioning_matching_AGG2010.html"),
    ("Arceneaux, Gerber & Green (2010) — Cautionary Note (source article)", "arceneux_gerber_green_2010_cautionary.pdf"),
    ("AGG 2010 Replication Package (data + code)", "arceneux_gerber_green_2010_replication.zip"),
]
# find the Week 2 module dict (already appended above) and add these files
for m in manifest["modules"]:
    if m["title"].startswith("Week 02"):
        m.setdefault("files", [])
        m["files"] += [
            {"title": title, "file": f"../Psets/PS1/{fname}"} for title, fname in PS1_FILES
        ]
        break


# --- Assignment 0 (Week 1, due Week 2): reading-only estimand exercise -----
a0_instructions = """
<h2>Assignment 0: Naming the Estimand</h2>
<p>Read Lundberg, Johnson &amp; Stewart (2021), "What Is Your Estimand?", and apply its
framework to <strong>Arceneaux, Gerber &amp; Green (2010)</strong>, the article you will
replicate in Problem Set 1.</p>
<p>This assignment involves <strong>no data and no code</strong>. Two pages maximum.</p>
<p>Materials are posted in the <strong>Week 01 (From Potential Outcomes to Identification)</strong> module.</p>
""".strip()
manifest["assignments"].append({
    "title": "Assignment 0: Naming the Estimand",
    "due": "2026-09-02T04:59:00.000Z",  # Tue Sep 1 11:59pm CT -> due morning of Week 2 class
    "out_of": 50,
    "hidden": False,
    "instructions": a0_instructions,
})

PS0_FILES = [
    ("Assignment 0: Naming the Estimand", "PS0_naming_the_estimand.html"),
]
for m in manifest["modules"]:
    if m["title"].startswith("Week 01"):
        m.setdefault("files", [])
        m["files"] += [
            {"title": title, "file": f"../Psets/PS0/{fname}"} for title, fname in PS0_FILES
        ]
        break

# --- Problem Set 2B (Week 7, due Week 9): partial identification ----------
ps2b_instructions = """
<h2>Replication Problem Set 2B: Partial Identification</h2>
<p>Return to <strong>Arceneaux, Gerber &amp; Green (2010)</strong> and ask what the data
still rule out once the assumptions required for a point estimate are set aside.</p>
<p>Reuses the Problem Set 1 data and variables; no new data preparation is required.</p>
<p>Materials are posted in the <strong>Week 07 (Partial Identification)</strong> module.</p>
""".strip()
manifest["assignments"].append({
    "title": "Replication Problem Set 2B: Partial Identification (AGG 2010)",
    "due": "2026-10-21T04:59:00.000Z",  # Tue Oct 20 11:59pm CT -> due morning of Week 9 class
    "out_of": 100,
    "hidden": False,
    "instructions": ps2b_instructions,
})

PS2B_FILES = [
    ("PS2B: Partial Identification Assignment (AGG 2010)", "PS2B_partial_identification_AGG2010.html"),
]
for m in manifest["modules"]:
    if m["title"].startswith("Week 07"):
        m.setdefault("files", [])
        m["files"] += [
            {"title": title, "file": f"../Psets/PS2B/{fname}"} for title, fname in PS2B_FILES
        ]
        break

BUILD.joinpath("course.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

# ---------------------------------------------------------------------------
# 5. Report
# ---------------------------------------------------------------------------
print(f"Total PDFs in Readings/: {len(all_pdfs)}")
print(f"Assigned to weeks 1-13:   {sum(len(v) for v in week_readings.values())}")
print(f"Supplementary module:     {len(supp_files)}")
print(f"Unclaimed (not placed):   {len(unclaimed)}")
if unclaimed:
    print("\n-- UNCLAIMED FILES (need manual placement) --")
    for p in unclaimed:
        print(" ", p.name)
print("\nPer-week reading counts:")
for n in range(1, 14):
    print(f"  Week {n:2d}: {len(week_readings.get(n, []))} readings")
print("\nWrote:", BUILD / "course.json")
