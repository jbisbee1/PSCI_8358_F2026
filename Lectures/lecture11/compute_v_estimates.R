# Mean post-1969 gap for the three weight sets on the "Unstable V" slide
# (Kuosmanen, Zhou, Eskelinen, and Malo 2021, Basque application).
# Weights are copied from the slide's table; donors not listed get weight 0.
# Gap = Basque GDP per capita minus the weighted donors, averaged over 1970-1997.
# Run from this folder:  Rscript compute_v_estimates.R

library(Synth)
data(basque)

# regionno: 5 = Baleares, 10 = Cataluna, 14 = Madrid, 18 = Rioja, 17 = Pais Vasco
weights <- list(
  Synth   = c("10" = 0.851, "14" = 0.149),
  MSCMT   = c("10" = 0.633, "14" = 0.148, "5" = 0.219),
  Optimum = c("14" = 0.441, "5" = 0.370, "18" = 0.190)
)

yr <- 1955:1997
y_of <- function(r) basque$gdpcap[basque$regionno == r & basque$year %in% yr]
basque_y <- y_of(17)
post <- yr > 1969
pre  <- yr <= 1969

res <- t(sapply(names(weights), function(nm) {
  w <- weights[[nm]]; w <- w / sum(w)            # table weights sum to 1 up to rounding
  syn <- Reduce(`+`, Map(function(r, wt) wt * y_of(as.integer(r)), names(w), w))
  gap <- basque_y - syn
  c(gap_mean      = mean(gap[post]),
    gap_pct_synth = 100 * mean(gap[post] / syn[post]),
    pre_rmspe     = sqrt(mean(gap[pre]^2)))
}))
print(round(res, 3))
