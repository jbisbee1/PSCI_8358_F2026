# ============================================================
# Doubly Robust Estimation and Double Machine Learning:
# A worked synthetic example
#
# This script picks up the same synthetic setting as
# Lecture 3 (age, income, college) and asks: what happens
# when the outcome and propensity models are nonlinear and
# we need flexible (ML) nuisance estimators?
#
# We build up, in order:
#   1. a richer, more nonlinear DGP than Lecture 3;
#   2. parametric AIPW (the Lecture 3 baseline, done properly);
#   3. naive ML plug-in AIPW, fit and evaluated on the SAME data
#      (this is the estimator you should not use -- it shows
#      overfitting bias directly);
#   4. cross-fitted, orthogonal DML AIPW (the estimator you
#      should use).
#
# Everything is benchmarked against the known true ATE/ATT.
# ============================================================

# Packages
library(tidyverse)
library(ranger)   # random forest nuisance models

set.seed(8358)


# ============================================================
# 1. CREATE A SYNTHETIC DATASET WITH NONLINEAR NUISANCE FUNCTIONS
# ============================================================

# Same covariates as Lecture 3 (age, income, college), but now:
#   - the propensity score is a sharply nonlinear function of X;
#   - the baseline outcome is a sharply nonlinear function of X;
#   - we add several noise covariates, so a kitchen-sink linear
#     model is not obviously "the" correct specification.
#
# A linear/logistic model of D and Y on X will be misspecified
# by construction -- this is the setting DML is built for.

N <- 1000

dat <- tibble(
  id = 1:N,
  age = pmin(pmax(rnorm(N, 40, 10), 20), 65),
  income = pmax(rnorm(N, 50 + 0.8 * age, 20), 5),
  college = rbinom(N, 1, plogis(-2 + 0.04 * age)),
  noise1 = rnorm(N),
  noise2 = rnorm(N),
  noise3 = rnorm(N)
)

# Nonlinear true propensity score: a threshold-like function of
# age and income, plus an interaction with college. A logistic
# model in levels will not recover this well.

dat <- dat %>%
  mutate(
    age_c = age - 40,
    inc_c = (income - 75) / 20,
    true_ps = plogis(
      -0.3 +
        1.6 * sin(age_c / 8) +
        1.1 * tanh(inc_c) +
        1.4 * college * tanh(inc_c) -
        0.02 * age_c^2 / 10
    ),
    D = rbinom(N, 1, true_ps)
  )

# Nonlinear potential outcomes. Baseline outcome has a strong
# nonlinear income effect (a "kink") and an age/college
# interaction. Treatment effect is heterogeneous in age.

dat <- dat %>%
  mutate(
    Y0 =
      20 +
      0.4 * age +
      0.15 * income +
      6 * college * (age > 45) +
      8 * sin(inc_c) +
      0.05 * income * (income > 90) +
      rnorm(N, 0, 5),

    tau =
      6 +
      0.15 * age_c -
      0.002 * age_c^2,

    Y1 = Y0 + tau,

    Y = D * Y1 + (1 - D) * Y0
  )

true_ate <- mean(dat$Y1 - dat$Y0)
true_att <- mean((dat$Y1 - dat$Y0)[dat$D == 1])

c(ATE = true_ate, ATT = true_att)


# Look at overlap in the true propensity score
ggplot(dat, aes(x = true_ps, fill = factor(D))) +
  geom_density(alpha = 0.4) +
  labs(
    x = "True propensity score",
    fill = "Treatment",
    title = "Overlap in the (unobserved-in-practice) true propensity score"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 2. NAIVE DIFFERENCE IN MEANS
# ============================================================

naive_ate <- with(dat, mean(Y[D == 1]) - mean(Y[D == 0]))

tibble(
  estimator = c("True ATE", "Naive difference in means"),
  estimate = c(true_ate, naive_ate)
)


# ============================================================
# 3. PARAMETRIC AIPW (THE LECTURE 3 BASELINE, DONE PROPERLY)
# ============================================================

# Fit a logistic propensity model and linear outcome models
# in levels -- deliberately the "wrong" functional form, since
# the true DGP is nonlinear. This is meant to show what
# misspecification costs a parametric estimator.

ps_fit_param <- glm(
  D ~ age + income + college,
  data = dat,
  family = binomial()
)

mu1_fit_param <- lm(
  Y ~ age + income + college,
  data = dat %>% filter(D == 1)
)

mu0_fit_param <- lm(
  Y ~ age + income + college,
  data = dat %>% filter(D == 0)
)

dat <- dat %>%
  mutate(
    pi_hat_param = predict(ps_fit_param, newdata = dat, type = "response"),
    mu1_hat_param = predict(mu1_fit_param, newdata = dat),
    mu0_hat_param = predict(mu0_fit_param, newdata = dat)
  )

# AIPW score, averaged for the ATE
aipw_score <- function(Y, D, mu1, mu0, pi) {
  (mu1 - mu0) +
    D * (Y - mu1) / pi -
    (1 - D) * (Y - mu0) / (1 - pi)
}

dat <- dat %>%
  mutate(
    psi_param = aipw_score(Y, D, mu1_hat_param, mu0_hat_param, pi_hat_param)
  )

aipw_param <- mean(dat$psi_param)
aipw_param_se <- sd(dat$psi_param) / sqrt(N)

c(estimate = aipw_param, se = aipw_param_se)


# ============================================================
# 4. NAIVE ML PLUG-IN AIPW (FIT AND EVALUATED ON THE SAME DATA)
# ============================================================

# Now replace the parametric nuisance models with flexible
# random forests -- but fit and evaluate them on the SAME
# observations. This is the estimator the lecture warns about:
# it looks more "flexible" but its errors do not average out
# the way the AIPW score requires.

rf_ps_naive <- ranger(
  D ~ age + income + college + noise1 + noise2 + noise3,
  data = dat %>% mutate(D = as.numeric(D)),
  num.trees = 500
)

rf_mu1_naive <- ranger(
  Y ~ age + income + college + noise1 + noise2 + noise3,
  data = dat %>% filter(D == 1),
  num.trees = 500
)

rf_mu0_naive <- ranger(
  Y ~ age + income + college + noise1 + noise2 + noise3,
  data = dat %>% filter(D == 0),
  num.trees = 500
)

dat <- dat %>%
  mutate(
    pi_hat_naive = predict(rf_ps_naive, data = dat)$predictions,
    mu1_hat_naive = predict(rf_mu1_naive, data = dat)$predictions,
    mu0_hat_naive = predict(rf_mu0_naive, data = dat)$predictions,
    # keep predictions off the boundary so weights stay finite
    pi_hat_naive = pmin(pmax(pi_hat_naive, 0.01), 0.99)
  )

dat <- dat %>%
  mutate(
    psi_naive_ml = aipw_score(Y, D, mu1_hat_naive, mu0_hat_naive, pi_hat_naive)
  )

aipw_naive_ml <- mean(dat$psi_naive_ml)
aipw_naive_ml_se <- sd(dat$psi_naive_ml) / sqrt(N)

c(estimate = aipw_naive_ml, se = aipw_naive_ml_se)


# Show the overfitting directly: in-sample residuals from the
# outcome model used to build its own AIPW correction term.

dat <- dat %>%
  mutate(
    mu_hat_own_arm = if_else(D == 1, mu1_hat_naive, mu0_hat_naive),
    resid_naive = Y - mu_hat_own_arm
  )

ggplot(dat, aes(x = mu_hat_own_arm, y = resid_naive)) +
  geom_point(alpha = 0.4) +
  geom_smooth(se = FALSE) +
  labs(
    x = "In-sample random-forest fitted value",
    y = "Residual (Y - fitted)",
    title = "In-sample RF residuals are shrunk toward zero",
    subtitle = "This shrinkage is exactly the overfitting bias the AIPW correction term inherits"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 5. CROSS-FITTED DML AIPW
# ============================================================

# Same random-forest nuisance models, but now:
#   - split the sample into K folds;
#   - for each fold, fit mu1, mu0, pi on the OTHER K-1 folds;
#   - predict for the held-out fold using those out-of-fold fits.
#
# Every unit's AIPW score is evaluated with nuisance functions
# it did not help fit.

K <- 5

dat <- dat %>%
  mutate(fold = sample(rep(1:K, length.out = N)))

dat$pi_hat_cf  <- NA_real_
dat$mu1_hat_cf <- NA_real_
dat$mu0_hat_cf <- NA_real_

for (k in 1:K) {

  train <- dat %>% filter(fold != k)
  test  <- dat %>% filter(fold == k)

  rf_ps_k <- ranger(
    D ~ age + income + college + noise1 + noise2 + noise3,
    data = train %>% mutate(D = as.numeric(D)),
    num.trees = 500
  )

  rf_mu1_k <- ranger(
    Y ~ age + income + college + noise1 + noise2 + noise3,
    data = train %>% filter(D == 1),
    num.trees = 500
  )

  rf_mu0_k <- ranger(
    Y ~ age + income + college + noise1 + noise2 + noise3,
    data = train %>% filter(D == 0),
    num.trees = 500
  )

  dat$pi_hat_cf[dat$fold == k]  <- predict(rf_ps_k, data = test)$predictions
  dat$mu1_hat_cf[dat$fold == k] <- predict(rf_mu1_k, data = test)$predictions
  dat$mu0_hat_cf[dat$fold == k] <- predict(rf_mu0_k, data = test)$predictions
}

dat <- dat %>%
  mutate(
    pi_hat_cf = pmin(pmax(pi_hat_cf, 0.01), 0.99),
    psi_dml = aipw_score(Y, D, mu1_hat_cf, mu0_hat_cf, pi_hat_cf)
  )

dml_ate <- mean(dat$psi_dml)
dml_ate_se <- sd(dat$psi_dml) / sqrt(N)

c(estimate = dml_ate, se = dml_ate_se)


# Out-of-fold residuals should look centered, not shrunk
dat <- dat %>%
  mutate(
    mu_hat_cf_own_arm = if_else(D == 1, mu1_hat_cf, mu0_hat_cf),
    resid_cf = Y - mu_hat_cf_own_arm
  )

ggplot(dat, aes(x = mu_hat_cf_own_arm, y = resid_cf)) +
  geom_point(alpha = 0.4) +
  geom_smooth(se = FALSE) +
  labs(
    x = "Out-of-fold random-forest fitted value",
    y = "Residual (Y - fitted)",
    title = "Cross-fitted residuals are not mechanically shrunk",
    subtitle = "Compare to the in-sample plot above"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 6. COMPARE ALL FIVE ESTIMATES
# ============================================================

results_dml <- tibble(
  estimator = c(
    "True ATE",
    "Naive difference in means",
    "Parametric AIPW (misspecified)",
    "Naive ML plug-in AIPW (no cross-fitting)",
    "Cross-fitted DML AIPW"
  ),
  estimate = c(
    true_ate,
    naive_ate,
    aipw_param,
    aipw_naive_ml,
    dml_ate
  ),
  se = c(
    NA,
    NA,
    aipw_param_se,
    aipw_naive_ml_se,
    dml_ate_se
  )
)

results_dml


# ============================================================
# 7. VISUALIZE THE COMPARISON AGAINST TRUTH
# ============================================================

results_dml %>%
  filter(estimator != "True ATE") %>%
  mutate(
    lower = estimate - 1.96 * se,
    upper = estimate + 1.96 * se,
    estimator = fct_rev(fct_inorder(estimator))
  ) %>%
  ggplot(aes(x = estimate, y = estimator)) +
  geom_vline(xintercept = true_ate, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper)) +
  labs(
    x = "Estimated ATE (dashed line = truth)",
    y = NULL,
    title = "Naive vs. cross-fitted estimation of the same estimand"
  ) +
  theme_minimal(base_size = 14)


# ============================================================
# 8. OPTIONAL: THE SAME EXERCISE WITH THE DoubleML PACKAGE
# ============================================================

# The hand-rolled loop above is what cross-fitting actually
# does. In practice you will normally use a package that
# automates it. This section is optional and requires
# install.packages(c("DoubleML", "mlr3", "mlr3learners")).

# library(DoubleML)
# library(mlr3)
# library(mlr3learners)
#
# dml_data <- DoubleMLData$new(
#   as.data.frame(dat),
#   y_col = "Y",
#   d_cols = "D",
#   x_cols = c("age", "income", "college", "noise1", "noise2", "noise3")
# )
#
# ml_g <- lrn("regr.ranger", num.trees = 500)
# ml_m <- lrn("classif.ranger", num.trees = 500, predict_type = "prob")
#
# dml_irm <- DoubleMLIRM$new(
#   dml_data,
#   ml_g = ml_g,
#   ml_m = ml_m,
#   n_folds = 5,
#   score = "ATE"
# )
#
# dml_irm$fit()
# dml_irm$summary()
