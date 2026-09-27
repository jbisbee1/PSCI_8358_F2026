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
require(tidyverse)

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
    kappa = 1 - D * (1 - Z) / (1 - p_z) - (1 - D) * Z / p_z,
    kappa_2 = 1 - D * (1 - Z) / (1 - mean(Z)) - (1 - D) * Z / mean(Z)
  )

dat_kappa %>%
  select(id,type,D,Z,kappa_2)

complier_mean_X_hat <- with(dat_kappa, sum(kappa * X) / sum(kappa))
complier_mean_X_true <- dat_kappa %>%
  filter(type == "complier") %>%
  summarize(mean(X)) %>%
  pull()

c(kappa_estimate = complier_mean_X_hat, truth = complier_mean_X_true)

dat_kappa %>%
  ggplot(aes(x = X)) + 
  geom_histogram()

dat_kappa %>%
  ggplot(aes(x = X,weights = kappa)) + 
  geom_histogram()

ggplot(dat_kappa, aes(x = X, weight = kappa, fill = interaction(D, Z))) +
  geom_histogram(
    bins = 30,
    position = "identity",
    alpha = 0.4
  )


# Same idea, any g(Y,D,X): e.g. the complier share itself
pi_c_hat <- mean(dat_kappa$kappa)
pi_c_true <- mean(dat_kappa$type == "complier")
c(pi_c_hat = pi_c_hat, pi_c_true = pi_c_true)


# How about some real data?
require(tidyverse)
dat <- haven::read_dta('./ipums-1pct-working-clean.dta')
dat %>%
  select(samesex,morekids,empstatm)

dat %>%
  mutate(kappa = 1 - morekids * (1 - samesex) / (1 - mean(samesex) - (1 - morekids) * samesex / mean(samesex))) %>%
  select(kappa,agem) %>%
  mutate(type = 'compliers') %>%
  bind_rows(dat %>%
              select(agem) %>%
              mutate(kappa = 1) %>%
              mutate(type = 'full')) %>%
  ggplot(aes(x = agem,weights = kappa,fill = type)) + 
  geom_histogram(aes(y = after_stat(density)),
                 position = 'dodge',binwidth = 1)




require(fixest)
feols(morekids ~ samesex,dat)
feols(empstatm ~ marital | year + cntry | morekids ~ samesex + marital,
      dat %>%
        mutate(empstatm = ifelse(empstatm == 1,1,
                                 ifelse(empstatm %in% c(2,3),0,NA))))



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

# ------------------------------------------------------------
# The same table, built from real data: IPUMS samesex / morekids
# with mother's employment (binary) as Y.
#   Z = samesex, D = morekids, Y = employed (1) vs. unemployed or
#   inactive (0); NIU / unknown dropped.
# With a binary Y the "density" is just two cells, y = 0 and y = 1,
# so the dominance conditions are four inequalities.
# ------------------------------------------------------------

dat_bin <- dat %>%
  mutate(across(c(empstatm, samesex, morekids), ~ as.numeric(haven::zap_labels(.x)))) %>%
  mutate(Y = case_when(empstatm == 1 ~ 1,
                       empstatm %in% c(2, 3) ~ 0,
                       TRUE ~ NA_real_)) %>%
  filter(!is.na(Y), !is.na(samesex), !is.na(morekids))

# P(Y = y, D = d | Z = z), one column per (d, z) cell, plus the
# cell sizes for standard errors.
n_z <- dat_bin %>% count(samesex) %>% deframe()   # names "0", "1"

kit_real <- dat_bin %>%
  group_by(y = Y, D = morekids, Z = samesex) %>%
  summarize(n = n(), .groups = "drop") %>%
  mutate(p = n / n_z[as.character(Z)]) %>%
  select(-n) %>%
  pivot_wider(names_from = c(D, Z), values_from = p,
              names_glue = "p_y_d{D}_z{Z}") %>%
  transmute(y = if_else(y == 1, "employed", "not employed"),
            p_y_d1_z1, p_y_d1_z0, p_y_d0_z1, p_y_d0_z0)

kit_real

se_diff <- function(p1, p0) sqrt(p1 * (1 - p1) / n_z[["1"]] + p0 * (1 - p0) / n_z[["0"]])

kit_real_check <- kit_real %>%
  mutate(
    # pi_c * P(Y(1) = y | complier)  and  pi_c * P(Y(0) = y | complier)
    treated_diff   = p_y_d1_z1 - p_y_d1_z0,
    untreated_diff = p_y_d0_z0 - p_y_d0_z1,
    treated_z      = treated_diff   / se_diff(p_y_d1_z1, p_y_d1_z0),
    untreated_z    = untreated_diff / se_diff(p_y_d0_z1, p_y_d0_z0),
    d1_dominance_holds = treated_diff   >= 0,
    d0_dominance_holds = untreated_diff >= 0
  )

kit_real_check

# Complier share (first stage) and the implied complier means.
pi_c_bin <- sum(kit_real_check$treated_diff)   # = P(D=1|Z=1) - P(D=1|Z=0)
c(pi_c_from_treated   = sum(kit_real_check$treated_diff),
  pi_c_from_untreated = sum(kit_real_check$untreated_diff),
  pi_c_first_stage    = mean(dat_bin$morekids[dat_bin$samesex == 1]) -
                        mean(dat_bin$morekids[dat_bin$samesex == 0]))

kit_real_check %>%
  filter(y == "employed") %>%
  transmute(
    complier_mean_Y1 = treated_diff   / pi_c_bin,   # P(employed | complier, 3+ kids)
    complier_mean_Y0 = untreated_diff / pi_c_bin,   # P(employed | complier, 2 kids)
    LATE             = complier_mean_Y1 - complier_mean_Y0
  )

colnames(dat)

dat %>%
  select(schoolm,yrschlm)


# ------------------------------------------------------------
# 3b. KITAGAWA DENSITY PLOTS ON REAL DATA: CARD (1995)
# ------------------------------------------------------------

# Z = grew up near a 4-year college (nearc4)
# D = attended college (educ >= 13)
# Y = log hourly wage (lwage), continuous
#
# Under the LATE assumptions, the sub-densities
#   f(y, D=1 | Z=z) = P(D=1|Z=z) * f(y | D=1, Z=z)
# satisfy
#   f(y, D=1 | Z=1) - f(y, D=1 | Z=0) = pi_c * f_{Y1|complier}(y) >= 0
#   f(y, D=0 | Z=0) - f(y, D=0 | Z=1) = pi_c * f_{Y0|complier}(y) >= 0
# so the differences (a) must be non-negative everywhere (the
# testable implication) and (b) rescaled by the complier share
# give the complier potential-outcome densities.

if (!requireNamespace("wooldridge", quietly = TRUE)) install.packages("wooldridge")

card <- wooldridge::card %>%
  transmute(Z = nearc4, D = as.numeric(educ >= 13), Y = lwage) %>%
  drop_na()

# Sub-density of Y for the cell (D = d, Z = z): P(D=d|Z=z) * f(y|D=d,Z=z)
# Evaluated on a common grid so the cells can be subtracted.
y_grid <- seq(min(card$Y) - 0.25, max(card$Y) + 0.25, length.out = 512)

subdens <- function(data = card,d, z) {
  cell <- data %>% filter(Z == z)
  p_d  <- mean(cell$D == d)
  y    <- cell$Y[cell$D == d]
  f    <- density(y, from = min(y_grid), to = max(y_grid),
                  n = length(y_grid), bw = "SJ")$y
  p_d * f
}

kit_dens <- tibble(
  y      = y_grid,
  d1_z1  = subdens(data = card,1, 1),
  d1_z0  = subdens(data = card,1, 0),
  d0_z1  = subdens(data = card,0, 1),
  d0_z0  = subdens(data = card,0, 0)
) %>%
  mutate(
    treated_diff   = d1_z1 - d1_z0,   # pi_c * f_{Y1|c}
    untreated_diff = d0_z0 - d0_z1    # pi_c * f_{Y0|c}
  )

# Complier share = first stage
pi_c_card <- mean(card$D[card$Z == 1]) - mean(card$D[card$Z == 0])
pi_c_card

# Plot 1: the raw sub-densities. The testable implication is that
# the Z = 1 curve sits weakly above Z = 0 for D = 1 (and the
# reverse for D = 0).
kit_dens %>%
  select(y, d1_z1, d1_z0, d0_z1, d0_z0) %>%
  pivot_longer(-y) %>%
  separate(name, c("D", "Z"), sep = "_") %>%
  mutate(D = if_else(D == "d1", "D = 1 (college)", "D = 0 (no college)"),
         Z = if_else(Z == "z1", "Z = 1 (near college)", "Z = 0 (far)")) %>%
  ggplot(aes(x = y, y = value, colour = Z)) +
  geom_line(linewidth = 1) +
  facet_wrap(~D) +
  labs(x = "Log wage", y = expression(f(y, D == d ~ "|" ~ Z == z)),
       colour = NULL,
       title = "Kitagawa sub-densities, Card (1995)") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")


# ------------------------------------------------------------
# 3c. KITAGAWA PLOTS ON ANGRIST & EVANS (1998), 1980 CENSUS
# ------------------------------------------------------------

# Z = first two children have the same sex (samesex)
# D = 3+ children (morekids)
# Y = mother's weeks worked in 1980 (0-52, integer)
#
# Sample follows Angrist & Evans: married mothers aged 21-35 with
# 2+ kids, second child at least 1 year old, first child not a twin.
# Source: AngEv98.zip (m_d_806.sas7bdat, ~190MB, so it is unzipped
# to a temp directory rather than into the repo).

ae_zip <- "./AngEv98.zip"
ae_sas <- file.path(tempdir(), "AngEv98", "m_d_806.sas7bdat")
if (!file.exists(ae_sas)) {
  unzip(ae_zip, files = "AngEv98/m_d_806.sas7bdat", exdir = tempdir())
}

raw <- haven::read_sas(ae_sas) 
colnames(raw)

raw %>%
  ggplot(aes(x = as.numeric(HOURSM))) + 
  geom_histogram()

ae <- raw %>%
  mutate(across(c(SEXK, SEX2ND, MARITAL, AGEM, WEEKSM,INCOME1M),
                ~ suppressWarnings(as.numeric(.x)))) %>%
  filter(MARITAL == 0, AGEM >= 21, AGEM <= 35, KIDCOUNT >= 2,
         AGEQ2ND > 4, TWIN1ST == 0, !is.na(SEXK), !is.na(SEX2ND)) %>%
  transmute(Z = as.numeric(SEXK == SEX2ND),
            D = as.numeric(KIDCOUNT > 2),
            Y = WEEKSM,
            inc = INCOME1M)

# Sanity checks against the published paper: first stage ~0.06,
# Wald effect on weeks worked ~ -6.
pi_c_ae <- mean(ae$D[ae$Z == 1]) - mean(ae$D[ae$Z == 0])
c(n = nrow(ae), first_stage = pi_c_ae,
  wald = (mean(ae$Y[ae$Z == 1]) - mean(ae$Y[ae$Z == 0])) / pi_c_ae)

c(n = nrow(ae), first_stage = pi_c_ae,
  wald = (mean(ae$inc[ae$Z == 1]) - mean(ae$inc[ae$Z == 0])) / pi_c_ae)

# ------------------------------------------------------------
# Outcome = mother's labor income (INCOME1M, dollars).
# ~48% of mothers report exactly $0, so Y is semi-continuous: a
# point mass at 0 plus a continuous part. A kernel density on
# log(income + 1) fails here (the mass at 0 drives the bandwidth
# to ~0.001 and the fit is a spike plus noise). Instead, treat
# the two pieces separately:
#   (a) point mass:  P(Y = 0,  D=d | Z=z)
#   (b) density:     P(Y > 0,  D=d | Z=z) * f(log Y | Y > 0, D=d, Z=z)
# using ONE bandwidth for all four (d, z) cells -- the cells are
# differenced, so they must be smoothed identically.
# ------------------------------------------------------------

ae_pos <- ae %>% filter(inc > 0)
# 2x the rule-of-thumb bandwidth: smooths over the heaping at round dollar amounts
bw_inc <- 3 * bw.nrd0(log(ae_pos$inc))
ly_grid <- seq(min(log(ae_pos$inc)) - 0.5, max(log(ae_pos$inc)) + 0.5,
               length.out = 400)

subdens_inc <- function(data, d, z) {
  cell <- data %>% filter(Z == z)
  n    <- nrow(cell)
  y    <- log(cell$inc[cell$D == d & cell$inc > 0])
  list(
    p0 = sum(cell$D == d & cell$inc == 0) / n,
    f  = (length(y) / n) *
      density(y, bw = bw_inc, from = min(ly_grid), to = max(ly_grid),
              n = length(ly_grid))$y
  )
}

cells <- list(d1_z1 = subdens_inc(ae, 1, 1), d1_z0 = subdens_inc(ae, 1, 0),
              d0_z1 = subdens_inc(ae, 0, 1), d0_z0 = subdens_inc(ae, 0, 0))

# Raw sub-densities, before differencing. The testable implication
# is visible here: in the D = 1 panel the Z = 1 (same-sex) curve
# should sit weakly above the Z = 0 curve, and in the D = 0 panel
# the Z = 0 curve should sit weakly above the Z = 1 curve. The gap
# between the two curves in each panel is the complier part.
cell_labs <- c(d1_z1 = "D = 1 (3+ kids)|Z = 1 (same sex)",
               d1_z0 = "D = 1 (3+ kids)|Z = 0 (mixed sex)",
               d0_z1 = "D = 0 (2 kids)|Z = 1 (same sex)",
               d0_z0 = "D = 0 (2 kids)|Z = 0 (mixed sex)")

sub_long <- imap_dfr(cells, function(cell, nm) {
  lab <- strsplit(cell_labs[[nm]], "|", fixed = TRUE)[[1]]
  tibble(D = lab[1], Z = lab[2], ly = ly_grid, dens = cell$f, p0 = cell$p0)
})

# Positive incomes: density of log income
p_sub_pos <- ggplot(sub_long, aes(x = ly, y = dens, colour = Z)) +
  geom_line(linewidth = 1) +
  facet_wrap(~D) +
  labs(x = "Log labor income (income > 0)",
       y = expression(f(y ~ "," ~ D == d ~ "|" ~ Z == z)),
       colour = NULL,
       title = "Sub-densities by instrument, income > 0") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")

# $0 income: the point mass in each cell
p_sub_zero <- sub_long %>%
  distinct(D, Z, p0) %>%
  ggplot(aes(x = Z, y = p0, fill = Z)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  facet_wrap(~D) +
  labs(x = NULL, y = expression(P(Y == 0 ~ "," ~ D == d ~ "|" ~ Z == z)),
       title = "Sub-densities by instrument, income = $0") +
  theme_minimal(base_size = 14)

p_sub_zero
p_sub_pos

# pi_c * P(Y(1) | complier) and pi_c * P(Y(0) | complier)
kit_inc <- tibble(
  ly             = ly_grid,
  treated_diff   = cells$d1_z1$f - cells$d1_z0$f,
  untreated_diff = cells$d0_z0$f - cells$d0_z1$f
)
zero_diff <- c(treated   = cells$d1_z1$p0 - cells$d1_z0$p0,
               untreated = cells$d0_z0$p0 - cells$d0_z1$p0)

# Testable implication: all of these should be >= 0. Also, the
# zero mass plus the density mass should sum to the complier share.
dx <- diff(ly_grid)[1]
tibble(
  arm            = c("treated", "untreated"),
  zero_mass      = zero_diff,
  density_mass   = c(sum(kit_inc$treated_diff), sum(kit_inc$untreated_diff)) * dx,
  neg_share      = c(sum(pmin(kit_inc$treated_diff, 0))   / sum(abs(kit_inc$treated_diff)),
                     sum(pmin(kit_inc$untreated_diff, 0)) / sum(abs(kit_inc$untreated_diff)))
) %>%
  mutate(total = zero_mass + density_mass)   # each should be ~ pi_c_ae

# Complier distributions, renormalised: each arm's zero mass and
# density (clipped at 0 to drop sampling noise) sum to 1.
arm_tot <- c(
  treated   = max(zero_diff["treated"], 0)   + sum(pmax(kit_inc$treated_diff, 0))   * dx,
  untreated = max(zero_diff["untreated"], 0) + sum(pmax(kit_inc$untreated_diff, 0)) * dx
)
arm_lab <- c(treated = "Compliers, Y(1): 3+ kids", untreated = "Compliers, Y(0): 2 kids")

comp_dens <- bind_rows(
  tibble(ly = ly_grid, arm = arm_lab[["treated"]],
         dens = pmax(kit_inc$treated_diff, 0) / arm_tot[["treated"]]),
  tibble(ly = ly_grid, arm = arm_lab[["untreated"]],
         dens = pmax(kit_inc$untreated_diff, 0) / arm_tot[["untreated"]])
)

comp_zero <- tibble(
  arm   = unname(arm_lab),
  share = c(max(zero_diff[["treated"]], 0)   / arm_tot[["treated"]],
            max(zero_diff[["untreated"]], 0) / arm_tot[["untreated"]])
)

# Left panel: share of compliers with $0 income (point mass).
# Right panel: density of log(income) among the rest.
p_zero <- ggplot(comp_zero, aes(x = arm, y = share, fill = arm)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  labs(x = NULL, y = "Share of compliers", title = "P(income = $0)") +
  theme_minimal(base_size = 14)

p_pos <- ggplot(comp_dens, aes(x = ly, y = dens, colour = arm)) +
  geom_line(linewidth = 1) +
  labs(x = "Log labor income (income > 0)", y = "Density (share of all compliers)",
       colour = NULL, title = "Density of log income, income > 0") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")

p_zero
p_pos

comp_dens %>%
  ggplot(aes(x = ly, y = dens, colour = arm)) +
  geom_line(linewidth = 1) +
  labs(x = "Log labor income (income > 0)", y = "Density (share of all compliers)",
       colour = NULL, title = "Density of log income, income > 0") +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom")


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


# ------------------------------------------------------------
# 4b. CONLEY ET AL. ON REAL DATA: samesex -> morekids -> employed
# ------------------------------------------------------------

# Structural model:  Y = beta * D + gamma * Z + e
# gamma is the direct effect of same-sex first children on
# employment, i.e. an exclusion-restriction violation. Under an
# assumed gamma, beta is identified by 2SLS on the adjusted outcome
# Y - gamma * Z, so  beta(gamma) = beta_2sls - gamma / pi.
#
# "Union of confidence intervals" (UCI): if we only believe
# |gamma| <= delta, report the union of the 95% CIs for beta(gamma)
# over every gamma in [-delta, delta].
#
# Uses dat_bin (employed = 1) from the Kitagawa table above.

require(fixest)

fs_bin  <- mean(dat_bin$morekids[dat_bin$samesex == 1]) -
           mean(dat_bin$morekids[dat_bin$samesex == 0])
itt_bin <- mean(dat_bin$Y[dat_bin$samesex == 1]) -
           mean(dat_bin$Y[dat_bin$samesex == 0])
c(first_stage = fs_bin, itt = itt_bin, wald = itt_bin / fs_bin)

# 2SLS of the gamma-adjusted outcome, at a given gamma
iv_at_gamma <- function(gamma) {
  m <- feols((Y - gamma * samesex) ~ 1 | morekids ~ samesex,
             data = dat_bin, vcov = "hetero")
  tibble(gamma = gamma,
         beta  = coef(m)[["fit_morekids"]],
         lo    = confint(m)["fit_morekids", 1],
         hi    = confint(m)["fit_morekids", 2])
}

# gamma grid: the first stage is small (~0.04), so even a direct
# effect of a few tenths of a percentage point matters a lot.
gamma_grid <- seq(-0.02, 0.02, by = 0.002)
conley_real <- map_dfr(gamma_grid, iv_at_gamma)

# UCI for a few beliefs about |gamma|
uci <- function(delta) {
  conley_real %>%
    filter(abs(gamma) <= delta + 1e-12) %>%
    summarize(delta = delta, lower = min(lo), upper = max(hi))
}
map_dfr(c(0, 0.002, 0.005, 0.01, 0.02), uci) %>%
  mutate(includes_zero = lower <= 0 & upper >= 0)

# Breakdown point: the smallest direct effect of same-sex on
# employment that would make the 95% CI for beta reach zero.
m0 <- feols(Y ~ 1 | morekids ~ samesex, data = dat_bin, vcov = "hetero")
beta0 <- coef(m0)[["fit_morekids"]]
se0   <- se(m0)[["fit_morekids"]]
delta_star <- fs_bin * (-beta0 - 1.96 * se0)
c(beta = beta0, se = se0, breakdown_delta = delta_star)

ggplot(conley_real, aes(x = gamma)) +
  geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.3) +
  geom_line(aes(y = beta)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = c(-delta_star, delta_star), linetype = "dotted") +
  labs(
    x = expression("Assumed direct effect of same-sex on employment, " * gamma),
    y = expression("Effect of 3+ kids on employment, " * beta(gamma)),
    title = "How large an exclusion violation would overturn the result?"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 5. HUBER & MELLACE (2015): TESTING VALIDITY VIA TRIMMED MEANS
# ============================================================

# Same assumptions as Kitagawa (independence, exclusion, monotonicity),
# different testable implication -- one that only needs MEANS.
#
# Under Z = 0, the treated (D = 1) are only always-takers. Under
# Z = 1, the treated are always-takers + compliers. So the observed
# group {D=1, Z=1} is a mixture in which always-takers make up the
# share
#     q_a = P(D=1 | Z=0) / P(D=1 | Z=1).
# We don't know WHICH members of {D=1, Z=1} are always-takers, but
# whoever they are, their mean Y cannot be lower than the mean of the
# lowest q_a-fraction of {D=1, Z=1}, nor higher than the mean of the
# highest q_a-fraction. And their mean IS identified: it is
# E[Y | D=1, Z=0]. So we need
#     lower-trimmed mean  <=  E[Y | D=1, Z=0]  <=  upper-trimmed mean.
# Same logic for never-takers, using {D=0, Z=0}:
#     q_n = P(D=0 | Z=1) / P(D=0 | Z=0)
#     lower-trimmed mean  <=  E[Y | D=0, Z=1]  <=  upper-trimmed mean.
# Four inequalities in total.

# Mean of the lowest / highest q-fraction of a sample. Exact, and
# handles ties (weeks worked!) by giving the boundary observation a
# fractional weight.
trim_mean <- function(y, q, side = c("lower", "upper")) {
  side <- match.arg(side)
  y <- sort(y, decreasing = (side == "upper"))
  k <- q * length(y)
  w <- c(rep(1, floor(k)), k - floor(k))
  sum(w * y[seq_along(w)]) / k
}

# The four moment "violations": each is defined so that a value
# > 0 means the inequality FAILS.
hm_viol <- function(df) {
  p1_z1 <- mean(df$D[df$Z == 1])
  p1_z0 <- mean(df$D[df$Z == 0])
  q_a <- p1_z0 / p1_z1                 # always-takers' share of {D=1, Z=1}
  q_n <- (1 - p1_z1) / (1 - p1_z0)     # never-takers' share of {D=0, Z=0}
  y11 <- df$Y[df$D == 1 & df$Z == 1]   # always-takers + compliers
  y10 <- df$Y[df$D == 1 & df$Z == 0]   # always-takers only
  y00 <- df$Y[df$D == 0 & df$Z == 0]   # never-takers + compliers
  y01 <- df$Y[df$D == 0 & df$Z == 1]   # never-takers only
  c(always_lower = trim_mean(y11, q_a, "lower") - mean(y10),
    always_upper = mean(y10) - trim_mean(y11, q_a, "upper"),
    never_lower  = trim_mean(y00, q_n, "lower") - mean(y01),
    never_upper  = mean(y01) - trim_mean(y00, q_n, "upper"))
}

# Bootstrap standard errors for each violation, then a conservative
# Bonferroni-corrected one-sided p-value for each. (The paper uses a
# more refined critical value; this simplified version is valid but
# less powerful.) A small p_bonf for ANY row rejects the assumptions.
hm_test <- function(df, B = 300) {
  v  <- hm_viol(df)
  bs <- replicate(B, hm_viol(df[sample(nrow(df), replace = TRUE), ]))
  se <- apply(bs, 1, sd)
  tibble(moment = names(v), violation = v, se = se, z = v / se,
         p_bonf = pmin(1, 4 * (1 - pnorm(v / se))))
}

# ------------------------------------------------------------
# 5-pre. The trimming logic in a 10-person example
# ------------------------------------------------------------

# Ten treated people at Z = 1, with Y = 1, ..., 10. Six are
# always-takers and four are compliers, so q_a = 6/10. We don't
# know WHICH six are always-takers.

y_toy <- 1:10
q_toy <- 6 / 10

c(full_group_mean = mean(y_toy),
  lower_trimmed   = trim_mean(y_toy, q_toy, "lower"),   # keep the 6 lowest
  upper_trimmed   = trim_mean(y_toy, q_toy, "upper"))   # keep the 6 highest

# Every possible assignment of "who is an always-taker": all
# choose(10, 6) = 210 six-person subsets. Their means fill exactly
# [lower_trimmed, upper_trimmed] -- the trimmed means are the
# extremes, not a claim about the typical case.
subset_means <- combn(y_toy, 6, FUN = mean)
c(n_subsets = length(subset_means), min = min(subset_means), max = max(subset_means))

# Two worlds consistent with the same observed data:
#   compliers are the HIGH-Y people: always-takers = 1..6, mean 3.5
#     (= the lower bound; the full-group mean is ABOVE the AT mean)
#   compliers are the LOW-Y people:  always-takers = 5..10, mean 7.5
#     (= the upper bound; the full-group mean is BELOW the AT mean)
c(AT_mean_if_compliers_high = mean(1:6),
  AT_mean_if_compliers_low  = mean(5:10),
  full_group_mean           = mean(y_toy))

# The test: E[Y | D=1, Z=0] is the always-takers' mean, observed
# directly. It must fall in [3.5, 7.5]; anything outside is
# impossible under the assumptions.
tibble(observed_AT_mean = c(5, 3, 8)) %>%
  mutate(
    lower = trim_mean(y_toy, q_toy, "lower"),
    upper = trim_mean(y_toy, q_toy, "upper"),
    consistent_with_assumptions = observed_AT_mean >= lower & observed_AT_mean <= upper
  )

data.frame(id = 1:10,
           y = y_toy,
           type = c(rep('c',6),
                    rep('a',4))) %>%
  group_by(type) %>%
  summarise(mean(y))

data.frame(id = 1:10,
           y = y_toy,
           type = rev(c(rep('c',6),
                    rep('a',4)))) %>%
  group_by(type) %>%
  summarise(mean(y))

bs <- NULL
for(i in 1:1000) {
  bs <- bs %>%
    bind_rows(data.frame(id = 1:10,
             y = y_toy,
             type = sample(c(rep('c',6),
                      rep('a',4)),size = 10,replace = F)) %>%
    group_by(type) %>%
    summarise(meanY = mean(y)) %>%
      mutate(bsInd = i))
}


bs %>%
  filter(type == 'c') %>%
  ggplot(aes(x = meanY)) + 
  geom_histogram(bins = 20)

# ------------------------------------------------------------
# 5a. Synthetic: the test can reject, and can fail to
# ------------------------------------------------------------

# Types: always-takers (30%), never-takers (30%), compliers (40%).
# Y = type-specific mean + treatment effect (1) + direct effect of Z
# on Y (gamma) + noise. gamma = 0 satisfies exclusion; gamma > 0 does not.

sim_hm <- function(N, gamma) {
  type <- sample(c("always", "never", "complier"), N, replace = TRUE,
                 prob = c(0.3, 0.3, 0.4))
  Z <- rbinom(N, 1, 0.5)
  D <- case_when(type == "always" ~ 1, type == "never" ~ 0, TRUE ~ Z)
  mu <- c(always = 0.5, never = -0.5, complier = 0)[type]
  tibble(Z = Z, D = D, Y = mu + 1 * D + gamma * Z + rnorm(N))
}

set.seed(8358)
hm_test(sim_hm(20000, gamma = 0))     # exclusion holds: no violations
hm_test(sim_hm(20000, gamma = 1))     # violated, but NOT detected
hm_test(sim_hm(20000, gamma = 1.5))   # violated and detected (z > 9)

# A direct effect of the same size as the treatment effect (gamma = 1)
# slips through: the bounds are wide enough to absorb it. The test only
# has power against violations big enough to push a group's mean
# outside the trimmed range. Failing to reject is not confirmation.

# ------------------------------------------------------------
# 5b. Real data
# ------------------------------------------------------------

# The trimmed bounds are tightest when q is close to 1, i.e. when
# compliers are a small share of the treated: in the limit q = 1 the
# mixture contains no compliers, and E[Y | D=1, Z=0] must equal
# E[Y | D=1, Z=1] exactly. They are widest when q is small (many
# compliers). So, perversely, the test has MORE power when the
# first stage is weak -- and the synthetic example above (40%
# compliers, q_a = 0.43) is a deliberately low-power case.

hm_ae   <- ae %>% select(Z, D, Y)          # Y = weeks worked
hm_card <- card %>% select(Z, D, Y)        # Y = log wage

c(ae_q_always   = mean(hm_ae$D[hm_ae$Z == 0])     / mean(hm_ae$D[hm_ae$Z == 1]),
  card_q_always = mean(hm_card$D[hm_card$Z == 0]) / mean(hm_card$D[hm_card$Z == 1]))

set.seed(8358)
hm_test(hm_ae, B = 200)
hm_test(hm_card, B = 300)

# Neither dataset rejects (all p_bonf = 1). Compare the z-scores, not
# the raw violations (weeks vs. log wages are on different scales):
# the A&E z-scores are all below -17, comfortably inside the bounds,
# while two Card moments (always_lower, never_upper) sit at
# z ~ -1.3 and -0.3, i.e. close to binding. Card is the more
# marginal case, so it is the one to watch in a smaller sample or
# with a different definition of D.
