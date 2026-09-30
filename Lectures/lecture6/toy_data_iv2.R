# ============================================================
# IV designs beyond the canonical case: worked synthetic examples
#
# Three self-contained exercises, in order, matching the three
# "Worked in R" slides in lecture06_iv_designs.qmd:
#   1. Judge leniency: own-observation bias, and why the
#      leave-one-out instrument fixes it
#   2. Many instruments: 2SLS vs. jackknife IV (JIVE)
#   3. Bartik instruments: the Goldsmith-Pinkham-Sorkin-Swift
#      decomposition and Rotemberg weights
#
# Nothing here is fit on real data. Each section simulates a
# population with a known true effect (or a known null) so the
# recovered quantities can be checked against ground truth.
# ============================================================

library(tidyverse)
library(fixest)

set.seed(8358)


# ============================================================
# 1. JUDGE LENIENCY: OWN-OBSERVATION BIAS
# ============================================================

# ------------------------------------------------------------
# 1a. Placebo check: judges have NO true leniency variation, D
# is pure noise. The naive (own-included) instrument still shows
# a nontrivial correlation with D -- purely mechanical, because
# each case's own D is one of the terms in its own judge's mean.
# The leave-one-out instrument does not.
# ------------------------------------------------------------

n_judges <- 50
n_per_judge <- 20

dat_placebo <- tibble(judge = rep(1:n_judges, each = n_per_judge)) %>%
  mutate(D = rbinom(n(), 1, 0.4))   # D unrelated to any real leniency

naive_Z_placebo <- ave(dat_placebo$D, dat_placebo$judge)
loo_Z_placebo <- (ave(dat_placebo$D, dat_placebo$judge, FUN = sum) - dat_placebo$D) /
  (n_per_judge - 1)

c(naive_cor = cor(naive_Z_placebo, dat_placebo$D),
  loo_cor   = cor(loo_Z_placebo, dat_placebo$D))

# ------------------------------------------------------------
# 1b. Full IV comparison: judges DO vary genuinely in leniency
# (so the leave-one-out instrument is legitimately relevant),
# but D also depends on an unobserved case-level confound that
# separately drives Y -- the endogeneity a judge design is meant
# to get around. Compare OLS, 2SLS on the naive instrument, and
# 2SLS on the leave-one-out instrument, against the true effect.
# ------------------------------------------------------------

n_judges2 <- 60
n_per_judge2 <- 30
N2 <- n_judges2 * n_per_judge2
theta_true <- 1

judge_leniency <- rnorm(n_judges2)   # true judge heterogeneity

dat_judge <- tibble(
  judge = rep(1:n_judges2, each = n_per_judge2),
  leniency = judge_leniency[judge],
  confound = rnorm(N2)                                  # unobserved: drives both D and Y
) %>%
  mutate(
    D = rbinom(N2, 1, plogis(leniency + 0.8 * confound)),
    Y = theta_true * D + 1.2 * confound + rnorm(N2)
  )

dat_judge <- dat_judge %>%
  mutate(
    naive_Z = ave(D, judge),
    loo_Z   = (ave(D, judge, FUN = sum) - D) / (n_per_judge2 - 1)
  )

m_ols   <- feols(Y ~ D, dat_judge)
m_naive <- feols(Y ~ 1 | D ~ naive_Z, dat_judge)
m_loo   <- feols(Y ~ 1 | D ~ loo_Z, dat_judge)

tibble(
  estimator = c("OLS", "2SLS, naive Z", "2SLS, leave-one-out Z", "truth"),
  theta_hat = c(coef(m_ols)[["D"]], coef(m_naive)[["fit_D"]],
                coef(m_loo)[["fit_D"]], theta_true)
)

# The naive-instrument 2SLS estimate sits close to OLS -- both
# contaminated by the confound. The leave-one-out estimate is the
# one that should land near the true effect of 1.


# ============================================================
# 2. MANY INSTRUMENTS: 2SLS VS. JACKKNIFE IV (JIVE)
# ============================================================

# One instrument, weakly relevant, is fine. A first stage built
# from K = 100 such instruments (e.g. many judge or zip-code
# dummies) in a sample of only n = 500 is not: 2SLS over-fits the
# first stage using each unit's own noise, biasing the estimate
# toward OLS. JIVE removes a unit's own observation from its own
# fitted first-stage value.

one_rep <- function(n = 500, K = 100, pi_strength = 0.02, endog = 0.8) {
  Z <- matrix(rnorm(n * K), n, K)
  v <- rnorm(n)
  D <- Z %*% rep(pi_strength, K) + v            # weak first stage, spread over K instruments
  eps <- endog * v + rnorm(n)                    # D endogenous: shares v with the outcome
  Y <- 0 * D + eps                               # true theta = 0

  Dhat_2sls <- fitted(lm(D ~ Z))
  theta_2sls <- coef(lm(Y ~ Dhat_2sls))[["Dhat_2sls"]]

  H <- Z %*% solve(crossprod(Z)) %*% t(Z)        # hat matrix from the first stage
  h <- diag(H)
  Dhat_jive <- (H %*% D - h * D) / (1 - h)        # leave-one-out fitted values (JIVE1, schematic)
  theta_jive <- coef(lm(Y ~ Dhat_jive))[["Dhat_jive"]]

  c(theta_2sls = theta_2sls, theta_jive = theta_jive)
}

# A single draw, matching the deck's slide exactly.
set.seed(2)
one_rep()

# Monte Carlo: average bias over many draws, true theta = 0.
set.seed(8358)
mc_reps <- map_dfr(1:200, ~ as_tibble_row(one_rep()))

mc_reps %>%
  summarize(across(everything(), list(mean = mean, sd = sd)))

# 2SLS averages well above 0, biased toward the OLS-like
# endogenous term; JIVE averages close to the true 0.


# ============================================================
# 3. BARTIK INSTRUMENTS: GPSS DECOMPOSITION AND ROTEMBERG WEIGHTS
# ============================================================

# Setup: L locations, K industries. Location l's Bartik
# instrument is Z_l = sum_k share_lk * g_k. The GPSS identity
# (no controls, for clarity):
#
#   theta_hat_Bartik = Cov(Z,Y) / Cov(Z,D)
#                     = sum_k [ Cov(z_k,D)/Cov(Z,D) ] * [ Cov(z_k,Y)/Cov(z_k,D) ]
#                     = sum_k alpha_hat_k * theta_hat_k
#
# where z_k = share_{.,k} * g_k is industry k's own piece of the
# instrument, theta_hat_k is the just-identified IV estimate using
# z_k alone, and alpha_hat_k (the Rotemberg weight) is z_k's share
# of the total first-stage covariance. This holds as an exact
# algebraic identity -- verified numerically below.
#
# To make the identity worth inspecting, industry 1's national
# shock is built to share an unobserved factor U with the local
# confound in the locations most exposed to it -- a stand-in for
# "this industry's national shock is not really exogenous." The
# other industries' shocks are clean.

L <- 300   # locations
K <- 5     # industries

conc <- c(3, 6, 6, 6, 6)                          # industry 1: more concentrated exposure
raw_shares <- matrix(rgamma(L * K, shape = rep(conc, each = L)), L, K)
share <- raw_shares / rowSums(raw_shares)
colnames(share) <- paste0("industry", 1:K)

U <- rnorm(1)                                      # unobserved common national factor
g <- numeric(K)
g[1] <- 0.05 * U + rnorm(1, 0, 0.01)                # industry 1's shock: partly driven by U
g[2:K] <- rnorm(K - 1, 0, 0.03)                     # clean national shocks

confound <- 0.6 * share[, 1] * U + rnorm(L, 0, 0.5) # confound loads on U only where exposed to industry 1

pi_first_stage <- 20
theta_true_bartik <- 2

Z <- as.numeric(share %*% g)                        # the Bartik instrument
D <- pi_first_stage * Z + confound + rnorm(L)
Y <- theta_true_bartik * D + 1.5 * confound + rnorm(L)

# Naive Bartik 2SLS
theta_bartik_direct <- cov(Z, Y) / cov(Z, D)

# Per-industry just-identified estimates and Rotemberg weights
z_k <- sweep(share, 2, g, `*`)                       # L x K matrix, column k = share_{.,k} * g_k
cov_zk_D <- apply(z_k, 2, cov, y = D)
cov_zk_Y <- apply(z_k, 2, cov, y = Y)

alpha_hat <- cov_zk_D / sum(cov_zk_D)                # Rotemberg weights, sum to 1
theta_hat_k <- cov_zk_Y / cov_zk_D                   # just-identified estimate per industry

tibble(
  industry   = colnames(share),
  alpha_hat  = alpha_hat,
  theta_hat  = theta_hat_k,
  avg_share  = colMeans(share)
)

# The identity: weighted sum of the per-industry estimates should
# reproduce the direct Bartik 2SLS estimate exactly.
c(theta_bartik_direct = theta_bartik_direct,
  theta_bartik_reconstructed = sum(alpha_hat * theta_hat_k),
  theta_true = theta_true_bartik)

# Industry 1 should carry a disproportionate Rotemberg weight and
# the largest gap between theta_hat_k and the true effect -- the
# Rotemberg-weight diagnostic pointing straight at the one
# national shock that is not actually exogenous, exactly as the
# "Rotemberg weights in practice" slide describes.
