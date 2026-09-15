# ============================================================
# Matching, Weighting, and Overlap:
# A worked synthetic example
# ============================================================

# Packages
library(tidyverse)
library(MatchIt)
library(WeightIt)
library(cobalt)

set.seed(1234)


# ============================================================
# 1. CREATE A SYNTHETIC DATASET
# ============================================================

# We create:
#   age        = continuous pre-treatment covariate
#   income     = continuous pre-treatment covariate
#   college    = binary pre-treatment covariate
#   D          = treatment
#   Y0, Y1     = potential outcomes
#   Y          = observed outcome
#
# Treatment assignment depends on the covariates, so there is
# confounding. The treatment effect also varies across units.

N <- 100

dat <- tibble(
  id = 1:N,
  age = pmin(pmax(rnorm(N, 40, 10), 20), 65),
  income = pmax(rnorm(N, 50 + 0.8 * age, 20), 5),
  college = rbinom(N, 1, plogis(-2 + 0.04 * age))
)

# Propensity score used to generate treatment
dat <- dat %>%
  mutate(
    true_ps =
      plogis(
        -5.5 +
          0.055 * age +
          0.012 * income +
          0.9 * college
      ),
    D = rbinom(N, 1, true_ps)
  )

# Potential outcomes
#
# Baseline outcome depends nonlinearly on covariates.
# Treatment effect is heterogeneous: treatment is somewhat
# more effective for people with higher income.

dat <- dat %>%
  mutate(
    Y0 =
      20 +
      0.35 * age +
      0.08 * income +
      5 * college +
      0.002 * income^2 +
      rnorm(N, 0, 5),
    
    tau =
      8 +
      0.05 * (income - mean(income)),
    
    Y1 = Y0 + tau,
    
    # Observed outcome
    Y = D * Y1 + (1 - D) * Y0
  )

# True causal quantities -- available only because this is simulated
true_ate <- mean(dat$Y1 - dat$Y0)
true_att <- mean((dat$Y1 - dat$Y0)[dat$D == 1])
true_atc <- mean((dat$Y1 - dat$Y0)[dat$D == 0])

c(
  ATE = true_ate,
  ATT = true_att,
  ATC = true_atc
)


# ============================================================
# 2. LOOK AT THE RAW DATA
# ============================================================

# The first visual:
# treatment groups occupy somewhat different regions of
# covariate space.

ggplot(dat, aes(x = income, y = age, shape = factor(D))) +
  geom_point(size = 3, alpha = 0.7) +
  scale_shape_manual(values = c(19,21)) + 
  labs(
    x = "Income",
    y = "Age",
    shape = "Treatment",
    title = "Before adjustment"
  ) +
  theme_minimal(base_size = 14)


# Add college status
ggplot(dat, aes(
  x = income,
  y = age,
  shape = factor(D),
  color = factor(college)
)) +
  scale_shape_manual(values = c(19,21)) + 
  geom_point(size = 3, alpha = 0.7) +
  labs(
    x = "Income",
    y = "Age",
    shape = "Treatment",
    color = "College",
    title = "Covariate space before adjustment"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 3. NAIVE DIFFERENCE IN MEANS
# ============================================================

naive_ate <- with(
  dat,
  mean(Y[D == 1]) - mean(Y[D == 0])
)

naive_ate


# Compare to truth
tibble(
  estimator = c("True ATE", "Naive difference in means"),
  estimate = c(true_ate, naive_ate)
)


# ============================================================
# 4. EXACT MATCHING
# ============================================================

# Exact matching is very difficult in most settings
# Use MatchIt to perform exact matching
m_exact <- matchit(
  D ~ age + income + college,
  data = dat,
  method = "exact",
  estimand = "ATT"
)

# So let's PRETEND that we have coarser categorical variables initially (although in practice this is just CEM)
# Create relatively coarse categorical versions of age and income.

dat <- dat %>%
  mutate(
    age_band = cut(
      age,
      breaks = c(19, 29, 39, 49, 59, 69),
      labels = FALSE
    ),
    income_band = cut(
      income,
      breaks = c(0, 50, 75, 100, 125, Inf),
      labels = FALSE
    )
  )

# Inspect the exact-match strata
dat %>%
  count(age_band, income_band, college, D) %>%
  arrange(age_band, income_band, college)


# Use MatchIt to perform exact matching
m_exact <- matchit(
  D ~ age_band + income_band + college,
  data = dat,
  method = "exact",
  estimand = "ATT"
)

summary(m_exact)


# Matched data
exact_dat <- match.data(m_exact)


# Visualize which observations remain
ggplot(
  exact_dat,
  aes(x = income, y = age, shape = factor(D))
) +
  geom_point(size = 3, alpha = 0.75) +
  scale_shape_manual(values = c(19,21)) + 
  labs(
    x = "Income",
    y = "Age",
    shape = "Treatment",
    title = "Exact matching: observations in matched strata"
  ) +
  theme_minimal(base_size = 14)

ggplot(
  exact_dat,
  aes(x = income, y = age, shape = factor(D))
) +
  geom_vline(
    xintercept = c(50, 75, 100, 125),
    linetype = "dashed",
    alpha = 0.5
  ) +
  geom_hline(
    yintercept = c(19, 29, 39, 49, 59),
    linetype = "dashed",
    alpha = 0.5
  ) +
  geom_point(size = 3, alpha = 0.75) +
  scale_shape_manual(
    values = c(19, 21),
    labels = c("Control", "Treated")
  ) +
  facet_wrap(
    ~ college,
    labeller = as_labeller(
      c(`0` = "No college", `1` = "College")
    )
  ) +
  labs(
    x = "Income",
    y = "Age",
    shape = "",
    title = "Coarsened exact matching",
    subtitle = "Each rectangle within a panel defines a matching stratum"
  ) +
  theme_minimal(base_size = 14)

# ------------------------------------------------------------
# Calculate ATT directly using the stratification formula
# ------------------------------------------------------------

exact_att <- exact_dat %>%
  group_by(age_band, income_band, college) %>%
  summarise(
    treated_mean = mean(Y[D == 1]),
    control_mean = mean(Y[D == 0]),
    n_treated = sum(D == 1),
    .groups = "drop"
  ) %>%
  mutate(
    stratum_effect = treated_mean - control_mean,
    treated_weight = n_treated / sum(n_treated)
  ) %>%
  summarise(
    ATT = sum(stratum_effect * treated_weight)
  ) %>%
  pull(ATT)

exact_att


# Compare to truth
tibble(
  estimator = c("True ATT", "Naive", "Exact matching"),
  estimate = c(true_att, naive_ate, exact_att)
)


# ============================================================
# 5. WHAT EXACT MATCHING IS DOING
# ============================================================

# This is a useful teaching table.
#
# Each matched stratum gets:
#   - a treated mean
#   - a control mean
#   - a within-stratum difference
#   - a weight equal to its share of the treated sample

exact_table <- exact_dat %>%
  group_by(age_band, income_band, college) %>%
  summarise(
    n_treated = sum(D == 1),
    n_control = sum(D == 0),
    mean_treated = mean(Y[D == 1]),
    mean_control = mean(Y[D == 0]),
    difference = mean_treated - mean_control,
    .groups = "drop"
  ) %>%
  filter(n_treated > 0, n_control > 0) %>%
  mutate(
    weight = n_treated / sum(n_treated)
  )

exact_table


# ============================================================
# 6. COARSENED EXACT MATCHING
# ============================================================

# CEM takes continuous covariates and creates bins.
#
# The bins here are intentionally wider than the exact match.
# That means more observations can be retained.

dat <- dat %>%
  mutate(
    age_cem = cut(
      age,
      breaks = c(19, 34, 44, 54, 69),
      labels = FALSE
    ),
    income_cem = cut(
      income,
      breaks = c(0, 60, 90, 120, Inf),
      labels = FALSE
    )
  )

m_cem <- matchit(
  D ~ age + income + college,
  data = dat,
  method = "cem",
  estimand = "ATT",
  # cutpoints = list(
  #   age = c(34, 44, 54),
  #   income = c(60, 90, 120)
  # )
)

summary(m_cem)

cem_dat <- match.data(m_cem)


# Visualize
ggplot(
  cem_dat,
  aes(x = income, y = age, shape = factor(D))
) +
  geom_point(size = 3, alpha = 0.75) +
  labs(
    x = "Income",
    y = "Age",
    shape = "Treatment",
    title = "Coarsened exact matching"
  ) +
  theme_minimal(base_size = 14)


# Estimate ATT
cem_fit <- lm(
  Y ~ D,
  data = cem_dat,
  weights = weights
)

coef(cem_fit)["D"]


# ============================================================
# 7. NEAREST-NEIGHBOR MATCHING
# ============================================================

# With continuous covariates, exact matching is often impossible.
# Instead, we define a distance between observations.
#
# Here we use Mahalanobis distance.

m_nn <- matchit(
  D ~ age + income + college,
  data = dat,
  method = "nearest",
  distance = "mahalanobis",
  replace = TRUE,
  ratio = 1,
  estimand = "ATT"
)

summary(m_nn)


nn_dat <- match.data(m_nn)


# Estimate ATT
nn_fit <- lm(
  Y ~ D,
  data = nn_dat,
  weights = weights
)

nn_att <- coef(nn_fit)["D"]

nn_att


# ============================================================
# 8. VISUALIZE THE NEAREST-NEIGHBOR MATCHES
# ============================================================

# MatchIt stores the actual pairings in match.matrix.

m_nn$match.matrix


# Create a plotting dataset showing one-to-one matches.

matched_pairs <- tibble(
  treated_id = as.numeric(rownames(m_nn$match.matrix)),
  control_id = as.numeric(m_nn$match.matrix[, 1])
) %>%
  left_join(
    dat %>%
      select(id, income, age, D),
    by = c("treated_id" = "id")
  ) %>%
  rename(
    treated_income = income,
    treated_age = age
  ) %>%
  left_join(
    dat %>%
      select(id, income, age),
    by = c("control_id" = "id")
  ) %>%
  rename(
    control_income = income,
    control_age = age
  )

matched_pairs


# Plot all observations
base_plot <- ggplot(dat, aes(x = income, y = age)) +
  geom_point(
    aes(shape = factor(D)),
    size = 2.5,
    alpha = 0.4
  ) +
  labs(
    x = "Income",
    y = "Age",
    shape = "Treatment",
    title = "Nearest-neighbor matching"
  ) +
  theme_minimal(base_size = 14)


# Add matching lines
base_plot +
  geom_segment(
    data = matched_pairs,
    aes(
      x = control_income,
      y = control_age,
      xend = treated_income,
      yend = treated_age
    ),
    inherit.aes = FALSE,
    alpha = 0.5
  )


# ============================================================
# 9. COMPARE THE MATCHING ESTIMATORS
# ============================================================

results_matching <- tibble(
  estimator = c(
    "True ATT",
    "Naive difference",
    "Exact matching",
    "CEM",
    "Nearest neighbor"
  ),
  estimate = c(
    true_att,
    naive_ate,
    exact_att,
    coef(cem_fit)["D"],
    nn_att
  )
)

results_matching


# ============================================================
# 10. PROPENSITY SCORES
# ============================================================

# Estimate the propensity score from observable covariates.

ps_model <- glm(
  D ~ age + income + college,
  data = dat,
  family = binomial()
)

dat <- dat %>%
  mutate(
    ps = predict(ps_model, type = "response")
  )


# Plot estimated propensity scores by treatment status

ggplot(dat, aes(x = ps, fill = factor(D))) +
  geom_density(alpha = 0.4) +
  labs(
    x = "Estimated propensity score",
    fill = "Treatment",
    title = "Propensity-score overlap"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 11. ATT INVERSE-PROPENSITY WEIGHTING
# ============================================================

# For the ATT:
#
#   treated: weight = 1
#   control: weight = e(X) / [1 - e(X)]
#
# This constructs a weighted control population whose covariate
# distribution resembles the treated population.

dat <- dat %>%
  mutate(
    att_weight = if_else(
      D == 1,
      1,
      ps / (1 - ps)
    )
  )


# Estimate ATT with weighted least squares

att_ipw_fit <- lm(
  Y ~ D,
  data = dat,
  weights = att_weight
)

att_ipw <- coef(att_ipw_fit)["D"]

att_ipw


# ------------------------------------------------------------
# A more transparent calculation of the counterfactual mean
# ------------------------------------------------------------

control_counterfactual_att <-
  with(
    dat[dat$D == 0, ],
    weighted.mean(Y, att_weight)
  )

treated_mean <-
  with(
    dat[dat$D == 1, ],
    mean(Y)
  )

att_ipw_manual <-
  treated_mean - control_counterfactual_att

c(
  ATT = att_ipw_manual
)


# ============================================================
# 12. VISUALIZE ATT WEIGHTS
# ============================================================

ggplot(
  dat,
  aes(x = ps, y = att_weight, shape = factor(D))
) +
  geom_point(size = 2.5, alpha = 0.7) +
  labs(
    x = "Estimated propensity score",
    y = "ATT weight",
    shape = "Treatment",
    title = "ATT inverse-propensity weights"
  ) +
  theme_minimal(base_size = 14)


# Show how the weights transform the sample

ggplot(
  dat,
  aes(x = income, y = age, size = att_weight, shape = factor(D))
) +
  geom_point(alpha = 0.5) +
  labs(
    x = "Income",
    y = "Age",
    size = "ATT weight",
    shape = "Treatment",
    title = "Weighted sample for the ATT"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 13. ATE IPW
# ============================================================

# For the ATE:
#
#   treated: weight = 1 / e(X)
#   control: weight = 1 / [1-e(X)]

dat <- dat %>%
  mutate(
    ate_weight = if_else(
      D == 1,
      1 / ps,
      1 / (1 - ps)
    )
  )

ate_ipw_fit <- lm(
  Y ~ D,
  data = dat,
  weights = ate_weight
)

ate_ipw <- coef(ate_ipw_fit)["D"]

ate_ipw


# ============================================================
# 14. OVERLAP WEIGHTS
# ============================================================

# Overlap weights use:
#
#   treated: 1 - e(X)
#   control: e(X)
#
# Equivalently, the overall unit weight is proportional to
# e(X) [1-e(X)].

dat <- dat %>%
  mutate(
    overlap_weight = if_else(
      D == 1,
      1 - ps,
      ps
    )
  )

overlap_fit <- lm(
  Y ~ D,
  data = dat,
  weights = overlap_weight
)

overlap_ate <- coef(overlap_fit)["D"]

overlap_ate


# ============================================================
# 15. COMPARE THE WEIGHTING ESTIMATORS
# ============================================================

results_weighting <- tibble(
  estimator = c(
    "True ATT",
    "True ATE",
    "Naive difference",
    "ATT IPW",
    "ATE IPW",
    "Overlap weights"
  ),
  estimate = c(
    true_att,
    true_ate,
    naive_ate,
    att_ipw,
    ate_ipw,
    overlap_ate
  )
)

results_weighting


# ============================================================
# 16. SEE WHAT OVERLAP WEIGHTS DO
# ============================================================

# Compare IPW and overlap weights.

ggplot(
  dat,
  aes(x = ps, y = ate_weight, shape = factor(D))
) +
  geom_point(size = 2.5, alpha = 0.7) +
  labs(
    x = "Estimated propensity score",
    y = "ATE IPW weight",
    shape = "Treatment",
    title = "Inverse-propensity weights"
  ) +
  theme_minimal(base_size = 14)


ggplot(
  dat,
  aes(x = ps, y = overlap_weight, shape = factor(D))
) +
  geom_point(size = 2.5, alpha = 0.7) +
  labs(
    x = "Estimated propensity score",
    y = "Overlap weight",
    shape = "Treatment",
    title = "Overlap weights"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 17. BALANCE CHECKING
# ============================================================

# The central diagnostic:
# Did the procedure actually create balance?

# Unadjusted balance
bal_unadjusted <- bal.tab(
  D ~ age + income + college,
  data = dat,
  estimand = "ATT",
  un = TRUE
)

bal_unadjusted


# Balance after exact matching
bal_exact <- bal.tab(
  m_exact,
  un = TRUE,
  m.threshold = 0.1
)

bal_exact


# Balance after nearest-neighbor matching
bal_nn <- bal.tab(
  m_nn,
  un = TRUE,
  m.threshold = 0.1
)

bal_nn


# Balance after ATT weighting
bal_att_ipw <- bal.tab(
  D ~ age + income + college,
  data = dat,
  weights = dat$att_weight,
  estimand = "ATT",
  un = TRUE,
  m.threshold = 0.1
)

bal_att_ipw


# ============================================================
# 18. LOVE PLOTS
# ============================================================

# This is probably the most useful visual aid for class.

love.plot(
  bal_exact,
  stat = "mean.diffs",
  abs = TRUE,
  thresholds = c(m = 0.1),
  var.order = "unadjusted"
) +
  labs(
    title = "Covariate balance: exact matching"
  )


love.plot(
  bal_nn,
  stat = "mean.diffs",
  abs = TRUE,
  thresholds = c(m = 0.1),
  var.order = "unadjusted"
) +
  labs(
    title = "Covariate balance: nearest-neighbor matching"
  )


love.plot(
  bal_att_ipw,
  stat = "mean.diffs",
  abs = TRUE,
  thresholds = c(m = 0.1),
  var.order = "unadjusted"
) +
  labs(
    title = "Covariate balance: ATT weighting"
  )


# ============================================================
# 19. DIRECTLY COMPARE THE COVARIATE DISTRIBUTIONS
# ============================================================

# Age before / after ATT weighting

ggplot(dat, aes(x = age, weight = att_weight, fill = factor(D))) +
  geom_density(alpha = 0.35) +
  labs(
    x = "Age",
    fill = "Treatment",
    title = "Age distribution after ATT weighting"
  ) +
  theme_minimal(base_size = 14)


# Income before / after ATT weighting

ggplot(dat, aes(x = income, weight = att_weight, fill = factor(D))) +
  geom_density(alpha = 0.35) +
  labs(
    x = "Income",
    fill = "Treatment",
    title = "Income distribution after ATT weighting"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 20. ONE TABLE SUMMARIZING EVERYTHING
# ============================================================

final_results <- tibble(
  estimand = c(
    "ATT",
    "ATT",
    "ATT",
    "ATT",
    "ATT",
    "ATE",
    "ATE",
    "ATE"
  ),
  method = c(
    "Truth",
    "Naive difference",
    "Exact matching",
    "CEM",
    "Nearest neighbor",
    "Truth",
    "ATE IPW",
    "Overlap weights"
  ),
  estimate = c(
    true_att,
    naive_ate,
    exact_att,
    coef(cem_fit)["D"],
    nn_att,
    true_ate,
    ate_ipw,
    overlap_ate
  )
)

final_results


exact_table
