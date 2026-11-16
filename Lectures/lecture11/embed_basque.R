# Embed Basque Country series into lecture11_synthetic_control_interactive.html.
# Fills the <script id="deck-data"> block with {"basque": {...}}, which slides
# s7, s19, s24, and s37 read. Specification mirrors lecture11_synthetic_control_artifact.qmd.
# Run from this folder:  Rscript embed_basque.R

library(Synth)
library(jsonlite)
data(basque)

fit_b <- function(tr, ctl) {
  dp <- dataprep(
    foo = basque,
    predictors = c("school.illit", "school.prim", "school.med", "school.high", "school.post.high", "invest"),
    predictors.op = "mean", time.predictors.prior = 1964:1969,
    special.predictors = list(
      list("gdpcap", 1960:1969, "mean"),
      list("sec.agriculture", seq(1961, 1969, 2), "mean"),
      list("sec.energy", seq(1961, 1969, 2), "mean"),
      list("sec.industry", seq(1961, 1969, 2), "mean"),
      list("sec.construction", seq(1961, 1969, 2), "mean"),
      list("sec.services.venta", seq(1961, 1969, 2), "mean"),
      list("sec.services.nonventa", seq(1961, 1969, 2), "mean"),
      list("popdens", 1969, "mean")),
    dependent = "gdpcap", unit.variable = "regionno", unit.names.variable = "regionname",
    time.variable = "year", treatment.identifier = tr, controls.identifier = ctl,
    time.optimize.ssr = 1960:1969, time.plot = 1955:1997)
  invisible(capture.output(so <- synth(data.prep.obj = dp, method = "BFGS")))
  list(dp = dp, so = so)
}
gap_of <- function(f) drop(f$dp$Y1plot - f$dp$Y0plot %*% f$so$solution.w)
yr <- 1955:1997
rmspe_ratio <- function(g) sqrt(mean(g[yr > 1969]^2)) / sqrt(mean(g[yr <= 1969]^2))

donors <- c(2:16, 18)
bq <- fit_b(17, donors)
bq_gap <- gap_of(bq)
pl_gap <- sapply(donors, function(d) gap_of(fit_b(d, setdiff(c(17, donors), d))))
loo_cat <- gap_of(fit_b(17, setdiff(donors, 10)))
loo_mad <- gap_of(fit_b(17, setdiff(donors, 14)))

short <- function(x) sub(" \\(.*", "", x)
reg_names <- short(basque$regionname[match(donors, basque$regionno)])
ratios <- c(Basque = rmspe_ratio(bq_gap), setNames(apply(pl_gap, 2, rmspe_ratio), reg_names))

payload <- list(basque = list(
  year = yr,
  basque = drop(bq$dp$Y1plot),
  spain = basque$gdpcap[basque$regionno == 1 & basque$year %in% yr],
  synthetic = drop(bq$dp$Y0plot %*% bq$so$solution.w),
  gap = bq_gap,
  placebo_gaps = unname(pl_gap),          # rows = years, columns = donor placebos
  ratios = as.list(ratios),               # Basque first; dotRanks highlights it
  loo_catalonia = loo_cat,
  loo_madrid = loo_mad
))
json <- toJSON(payload, digits = 5, auto_unbox = TRUE)

f <- "lecture11_synthetic_control_interactive.html"
html <- readLines(f, encoding = "UTF-8", warn = FALSE)
open <- grep('<script id="deck-data" type="application/json">', html, fixed = TRUE)
close <- open + which(html[(open + 1):length(html)] == "</script>")[1]
html <- c(html[1:open], json, html[close:length(html)])
writeLines(html, f, useBytes = TRUE)
cat("Embedded", nchar(json), "characters of Basque data into", f, "\n")
