# ============================================================
# Instrumental Variables: worked synthetic examples
#
# Four self-contained exercises, in order:
#   1. constant effects vs. heterogeneity: monotonicity as the
#      price of dropping constant effects (the defier example)
#   2. Abadie's kappa weights: recovering the complier
#      covariate mean without observing type
#   3. a Kitagawa-style testable implication check
#   4. Conley, Hansen & Rossi plausibly exogenous bounds
#
# Nothing here is fit on real data. Each section simulates a
# population with known types/effects so the recovered
# quantities can be checked against ground truth.
# ============================================================

library(tidyverse)

set.seed(8358)


# ============================================================
# 1. CONSTANT EFFECTS VS. HETEROGENEITY
# ============================================================

# Simulate a population of compliers and defiers only (drop
# always-/never-takers for clarity -- they contribute zero to
# both ITT_Y and ITT_D regardless).
#
# Compliers: D(1)=1, D(0)=0, true effect tau_c
# Defiers:   D(1)=0, D(0)=1, true effect tau_d

N <- 100000
pi_c <- 0.4
pi_d <- 0.1
# remaining 0.5 are always-/never-takers, split evenly
pi_a <- 0.25
pi_n <- 0.25

tau_c <- 2
tau_d <- -8

type <- sample(
  c("complier", "defier", "always", "never"),
  size = N, replace = TRUE,
  prob = c(pi_c, pi_d, pi_a, pi_n)
)

dat_mono <- tibble(id = 1:N, type = type) %>%
  mutate(
    D1 = case_when(
      type %in% c("complier", "always") ~ 1,
      TRUE ~ 0
    ),
    D0 = case_when(
      type %in% c("defier", "always") ~ 1,
      TRUE ~ 0
    ),
    tau_i = case_when(
      type == "complier" ~ tau_c,
      type == "defier" ~ tau_d,
      TRUE ~ 0  # irrelevant: potential outcomes don't move for these types
    ),
    Y0 = rnorm(N, 0, 1),
    Y1 = Y0 + tau_i,
    Z = rbinom(N, 1, 0.5),
    D = if_else(Z == 1, D1, D0),
    Y = if_else(D == 1, Y1, Y0)
  )

itt_y <- with(dat_mono, mean(Y[Z == 1]) - mean(Y[Z == 0]))
itt_d <- with(dat_mono, mean(D[Z == 1]) - mean(D[Z == 0]))
wald <- itt_y / itt_d

tibble(
  quantity = c("ITT_Y", "ITT_D", "Wald = ITT_Y/ITT_D",
               "true complier effect", "true defier effect"),
  value = c(itt_y, itt_d, wald, tau_c, tau_d)
)

# The Wald estimate falls outside [tau_d, tau_c] -- it is not a
# weighted average of any real subgroup effect once defiers are
# present and effects are heterogeneous.

# Now re-run with pi_d = 0 (monotonicity holds) and confirm the
# Wald estimator recovers the complier effect exactly.

dat_late <- dat_mono %>% filter(type != "defier")

itt_y_late <- with(dat_late, mean(Y[Z == 1]) - mean(Y[Z == 0]))
itt_d_late <- with(dat_late, mean(D[Z == 1]) - mean(D[Z == 0]))
wald_late <- itt_y_late / itt_d_late

c(wald_late = wald_late, true_complier_effect = tau_c)


# ============================================================
# 2. ABADIE'S KAPPA WEIGHTS
# ============================================================

# Simulate compliers, always-takers, never-takers with a
# covariate X whose distribution differs by type. Random
# assignment of Z guarantees the always-/never-taker X
# distributions do not depend on Z -- kappa exploits exactly
# this to recover the complier mean of X without ever observing
# type.

N2 <- 20000
p_z <- 0.5

dat_kappa <- tibble(
  id = 1:N2,
  type = sample(c("complier", "always", "never"),
                 N2, replace = TRUE, prob = c(0.5, 0.25, 0.25)),
  X = case_when(
    type == "complier" ~ rnorm(N2, 40, 8),
    type == "always"   ~ rnorm(N2, 60, 8),
    type == "never"    ~ rnorm(N2, 20, 8)
  ),
  Z = rbinom(N2, 1, p_z)
) %>%
  mutate(
    D = case_when(
      type == "always" ~ 1,
      type == "never" ~ 0,
      type == "complier" ~ Z
    )
  )

dat_kappa <- dat_kappa %>%
  mutate(
    kappa = 1 - D * (1 - Z) / (1 - p_z) - (1 - D) * Z / p_z
  )

complier_mean_X_hat <- with(dat_kappa, sum(kappa * X) / sum(kappa))
complier_mean_X_true <- dat_kappa %>%
  filter(type == "complier") %>%
  summarize(mean(X)) %>%
  pull()

c(kappa_estimate = complier_mean_X_hat, truth = complier_mean_X_true)

# Same idea, any g(Y,D,X): e.g. the complier share itself
pi_c_hat <- mean(dat_kappa$kappa)
pi_c_true <- mean(dat_kappa$type == "complier")
c(pi_c_hat = pi_c_hat, pi_c_true = pi_c_true)


# ============================================================
# 3. TESTABLE IMPLICATIONS: A KITAGAWA-STYLE CHECK
# ============================================================

# Ordinal Y in {low, mid, high}. Build the joint P(Y=y, D=1|Z)
# and P(Y=y, D=0|Z) tables and check the pointwise dominance
# conditions implied by the LATE assumptions.

kit_tab <- tribble(
  ~y,     ~p_y_d1_z1, ~p_y_d1_z0, ~p_y_d0_z1, ~p_y_d0_z0,
  "low",   0.10,       0.05,       0.25,       0.30,
  "mid",   0.20,       0.15,       0.10,       0.20,
  "high",  0.30,       0.20,       0.05,       0.10
)

kit_tab %>%
  mutate(
    d1_dominance_holds = p_y_d1_z1 >= p_y_d1_z0,   # f(y,D=1|Z=1) >= f(y,D=1|Z=0)
    d0_dominance_holds = p_y_d0_z0 >= p_y_d0_z1    # f(y,D=0|Z=0) >= f(y,D=0|Z=1)
  )

# Flip one cell to see a rejection: suppose P(high, D=1|Z=1) had
# been observed at 0.15 instead of 0.30.
kit_tab_violation <- kit_tab %>%
  mutate(p_y_d1_z1 = if_else(y == "high", 0.15, p_y_d1_z1)) %>%
  mutate(d1_dominance_holds = p_y_d1_z1 >= p_y_d1_z0)

kit_tab_violation


# ============================================================
# 4. SENSITIVITY ANALYSIS: PLAUSIBLY EXOGENOUS (CONLEY ET AL. 2012)
# ============================================================

# theta(gamma) = theta_hat_2SLS - gamma / pi_first_stage
# Trace the identified set for theta over a grid of gamma,
# under two different beliefs about how large the direct
# effect of Z on Y (net of D) plausibly is.

theta_hat_2sls <- 2.0
pi_first_stage <- 0.5

conley_bounds <- function(gamma_max, theta_hat, pi_fs) {
  tibble(
    gamma_max = gamma_max,
    lower = theta_hat - gamma_max / pi_fs,
    upper = theta_hat + gamma_max / pi_fs
  )
}

sensitivity_grid <- map_dfr(c(0, 0.1, 0.25, 0.5, 1.0), conley_bounds,
                             theta_hat = theta_hat_2sls, pi_fs = pi_first_stage)

sensitivity_grid

ggplot(sensitivity_grid, aes(x = gamma_max)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(aes(y = lower)) +
  geom_point(aes(y = upper)) +
  labs(
    x = expression("Assumed bound on direct effect, " * group("|", gamma, "|") <= gamma[max]),
    y = expression("Identified set for " * theta),
    title = "How much does the estimate depend on exclusion holding exactly?"
  ) +
  theme_minimal(base_size = 14)

# At gamma_max = 1.0 the identified set includes zero: the
# conclusion does not survive a direct effect of that size.
