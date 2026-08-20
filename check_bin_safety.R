# check_bin_safety.R
#
# Checks whether a candidate set of von Bertalanffy size-bin widths for a
# species keeps that species' growth probabilities (growthtype 3 or 4) 
# below the model's current global maximum (or at least < 1.5), 
# which determines Nstepsyr (model timesteps per year) for the WHOLE model, not just this
# species. See hydra_sim.tpl, growthtype case 3/4 and the phimax/Nstepsyr
# computation.
#
# growthprob_phi(bin) = k / log( (Linf - lo) / (Linf - hi) )
# for bins strictly below Linf; forced to 0 for the last bin and for any
# bin whose edges reach/exceed Linf.

max_phi <- function(Linf, k, binwidths) {
  # binwidths: numeric vector of 5 bin widths (cm)
  # Returns a list with per-bin phi values and the max (excluding the
  # forced-zero last bin).
  n <- length(binwidths)
  cum_lo <- c(0, head(cumsum(binwidths), -1))
  cum_hi <- cumsum(binwidths)

  phis <- numeric(n - 1)
  for (i in seq_len(n - 1)) {
    lo <- cum_lo[i]
    hi <- cum_hi[i]
    if (hi < Linf) {
      phis[i] <- k / log((Linf - lo) / (Linf - hi))
    } else {
      phis[i] <- 0
    }
  }

  list(
    edges = data.frame(bin = seq_len(n - 1), lo = cum_lo[1:(n-1)], hi = cum_hi[1:(n-1)]),
    phi = phis,
    max_phi = if (length(phis) > 0) max(phis) else 0
  )
}

# Current model-wide max growth probability across all OTHER species/years/
# bins (set by Yellowtail flounder as of the last check). Recompute this if
# other species' vonB/growth_covwt/binwidth values change.
CURRENT_GLOBAL_MAX <- 1.3629

check_bin_safety <- function(Linf, k, binwidths, global_max = CURRENT_GLOBAL_MAX) {
  result <- max_phi(Linf, k, binwidths)
  cat("per-bin phi:", round(result$phi, 3), "\n")
  cat("max phi:", round(result$max_phi, 3), "\n")
  safe <- result$max_phi < global_max
  cat("safe (keeps global Nstepsyr=1)?", safe, "\n")
  invisible(list(phi = result$phi, max_phi = result$max_phi, safe = safe))
}

check_bin_safety_covariate <- function(Linf, k, growth_covwt, growth_cov, binwidths,
                                        global_max = CURRENT_GLOBAL_MAX) {
  # For growthtype=4 (VonB with covariates), effective Linf varies by year:
  #   eff_Linf(yr) = Linf * exp(growth_covwt * growth_cov(yr))
  # There are TWO SEPARATE failure modes to check, at opposite ends of the
  # effective-Linf range:
  #   1) NaN risk (log of a non-positive ratio): triggered when effective
  #      Linf drops LOW enough to reach/fall below a bin edge.
  #      -> check the MINIMUM effective Linf across the time series.
  #   2) Phi blow-up -> inflates the model-wide phimax -> silently changes
  #      Nstepsyr for every species, not just this one.
  #      -> check the MAXIMUM effective Linf across the time series.
  eff_linf <- Linf * exp(growth_covwt * growth_cov)
  min_linf <- min(eff_linf)
  max_linf <- max(eff_linf)

  cat("Effective Linf range across covariate time series: [",
      round(min_linf, 3), ",", round(max_linf, 3), "]\n\n")

  cat("--- Worst case for NaN risk (minimum effective Linf =", round(min_linf,3), ") ---\n")
  res_min <- max_phi(min_linf, k, binwidths)
  cat("per-bin phi:", round(res_min$phi, 3), "\n")
  nan_risk <- any(is.nan(res_min$phi)) || any(res_min$phi < 0)
  # also flag bins where min_linf falls inside/below the bin edges (forced-0
  # case is handled by max_phi returning 0 there, but that 0 can mask a
  # numerator going negative right at that boundary in the actual .tpl code
  # -- check edges explicitly for a margin warning)
  cum_lo <- c(0, head(cumsum(binwidths), -1))
  cum_hi <- cumsum(binwidths)
  for (i in seq_len(length(binwidths) - 1)) {
    if (min_linf > cum_lo[i] && min_linf < cum_hi[i]) {
      cat("  WARNING: minimum effective Linf (", round(min_linf,3),
          ") falls INSIDE bin", i, "[", cum_lo[i], ",", cum_hi[i], "] -- NaN risk\n")
      nan_risk <- TRUE
    }
  }
  cat("NaN risk?", nan_risk, "\n\n")

  cat("--- Worst case for phimax/Nstepsyr risk (maximum effective Linf =", round(max_linf,3), ") ---\n")
  res_max <- max_phi(max_linf, k, binwidths)
  cat("per-bin phi:", round(res_max$phi, 3), "\n")
  cat("max phi:", round(res_max$max_phi, 3), "\n")
  nstepsyr_safe <- res_max$max_phi < global_max
  cat("safe (keeps global Nstepsyr unchanged)?", nstepsyr_safe, "\n\n")

  cat("OVERALL SAFE?", (!nan_risk) && nstepsyr_safe, "\n")

  invisible(list(min_linf = min_linf, max_linf = max_linf,
                  nan_risk = nan_risk, nstepsyr_safe = nstepsyr_safe))
}

load("HYDRA_EnvCov_Input.rdata")

# SILVER HAKE
check_bin_safety_covariate(
  Linf = 41.95007,
  k = 0.4122162,
  growth_covwt = 0.101001498,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(16,10,10,5,20)  
)

# YT FLOUNDER
check_bin_safety_covariate(
  Linf = 50.16674,
  k = 0.3566135,
  growth_covwt = 0.007733055,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(15,10,10,10,15)  
)

# HERRING
check_bin_safety_covariate(
  Linf = 30.99835,
  k = 0.3372689,
  growth_covwt = 0.029708140,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(10,5,5,5,10)  
)


# HERRING
check_bin_safety_covariate(
  Linf = 30.99835,
  k = 0.3372689,
  growth_covwt = 0.029708140,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(10,5,5,5,10) 
)

# HADDOCK
check_bin_safety_covariate(
  Linf = 58.28125,
  k = 0.4469230,
  growth_covwt = -0.101001498,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(20,12,10,10,18)  
)
 
# MACKEREL
check_bin_safety_covariate(
  Linf = 43.2563036,
  k = 0.205956533,
  growth_covwt = 0.061329889,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(20,5,5,5,20)  
)  # --> We need to keep original Linf and k values, otherwise model breaks

# GOOSEFISH
check_bin_safety_covariate(
  Linf = 157.6,
  k = 0.095,
  growth_covwt = 0,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(40,20,20,20,60) 
)  


# SPINY DOGFISH
check_bin_safety_covariate(
  Linf = 99.99,
  k = 0.1,
  growth_covwt = 0,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(30,15,15,15,25)
) 

# WINTER FLOUNDER
check_bin_safety_covariate(
  Linf = 49.84011,
  k = 0.3459697,
  growth_covwt = -0.035248041,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(20,7,7,7,15) 
) 

# WINTER SKATE
check_bin_safety_covariate(
  Linf = 114.1,
  k = 0.14405,
  growth_covwt = 0,
  growth_cov = HYDRAInput$TempCentered,
  binwidths = c(40,15,15,15,25) 
)
