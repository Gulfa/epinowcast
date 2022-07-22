functions {
#include functions/regression.stan
#include functions/discretised_reporting_prob.stan
#include functions/hazard.stan
#include functions/zero_truncated_normal.stan
#include functions/expected_obs.stan
#include functions/expected_obs_from_index.stan
#include functions/obs_lpmf.stan
}

data {
  // Indexes and lookups
  int n; // total observations
  int t; // time range over which data is available 
  int s; // number of snapshots there are
  int g; // number of data groups
  array[s] int st; // when in this time snapshots are from
  array[t, g] int ts; // snapshot related to time and group
  array[s] int sl; // how many days of reported data does each snapshot have
  array[s] int csl; // cumulative version of the above
  array[s] int sg; // how snapshots are related
  int dmax; // maximum possible report date
  // Reference day model
  int refp_fnrow; // how many unique pmfs there are
  array[s] int refp_findex; // how each date links to a pmf
  int refp_fncol; // number of effects to apply
  matrix[refp_fnrow, refp_fncol + 1] refp_fdesign; // design matrix for pmfs
  int refp_rncol; // number of standard deviations to use for pooling
  matrix[refp_fncol, refp_rncol + 1] refp_rdesign; // Pooling pmf design matrix 
  int model_refp; // parametric distribution (0 = none, 1 = exp, 2 = lognormal, 3 = gamma, 4 = loglogistic)
  // Reporting day model
<<<<<<< HEAD
  int rd; // how many reporting days are there (t + dmax - 1)
  int urds; // how many unique reporting days are there
  array[rd, g] int rdlurd; // how each report date links to a sparse report effect
  int nrd_effs; // number of report day effects to apply
  matrix[urds, nrd_effs + 1] rd_fixed; // design matrix for report dates
  int nrd_eff_sds; // number of standard deviations to use for pooling for rds
  matrix[nrd_effs, nrd_eff_sds + 1] rd_random; // Pooling pmf design matrix 
  // Observations
  array[s, dmax] int obs; // obs for each primary date (row) and report date (column)
  array[n] int flat_obs; // obs stored as a flat vector
  array[g, t] int obs_miss; // obs with missing primary date (group first)
  array[t, g] int latest_obs; // latest obs for each snapshot group
=======
  int model_rep; // Reporting day model in use
  int rep_t; // how many reporting days are there (t + dmax - 1)
  int rep_fnrow; // how many unique reporting days are there
  array[g, rep_t] int rep_findex; // how each report date links to a sparse report effect
  int rep_fncol; // number of report day effects to apply
  matrix[rep_fnrow, rep_fncol + 1] rep_fdesign; // design matrix for report dates
  int rep_rncol; // number of standard deviations to use for pooling for rds
  matrix[rep_fncol, rep_rncol + 1] rep_rdesign; // Pooling pmf design matrix 
  // Observation model
  int model_obs; // Control parameter for the observation model (0 = Poisson, 1 = Negbin)
>>>>>>> develop
  // Control parameters
  int debug; // should debug information be shown
  int likelihood; // should the likelihood be included
  int pp; // should posterior predictions be produced
  int cast; // should a nowcast be produced
  int ologlik; // Should the pointwise log likelihood be calculated
  // Priors (1st index = mean, 2nd index = standard deviation)
  array[2] real eobs_lsd_p; // Standard deviation for expected final observations
<<<<<<< HEAD
  array[2] real alpha_start_p; // starting value for alpha random walk (logit scale)
  array[2] real alpha_sd_p; // standard deviation for alpha random walk increments
  array[2] real logmean_int_p; // log mean intercept for reference date delay
  array[2] real logsd_int_p; // log standard deviation for the reference date delay
  array[2] real logmean_sd_p; // standard deviation of scaled pooled logmean effects
  array[2] real logsd_sd_p; // standard deviation of scaled pooled logsd effects
  array[2] real rd_eff_sd_p; //standard deviation of scaled pooled report date effects
=======
  array[2] real refp_mean_int_p; // log mean intercept for reference date delay
  array[2] real refp_sd_int_p; // log standard deviation for the reference date delay
  array[2] real refp_mean_beta_sd_p; // standard deviation of scaled pooled logmean effects
  array[2] real refp_sd_beta_sd_p; // standard deviation of scaled pooled logsd effects
  array[2] real rep_beta_sd_p; //standard deviation of scaled pooled report date effects
>>>>>>> develop
  array[2] real sqrt_phi_p; // 1/sqrt(overdispersion)
}

transformed data{
  real logdmax = 5*log(dmax); // scaled maxmimum delay to log for crude bounds
  // prior mean of cases based on thoose observed
  vector[g] eobs_init = log(to_vector(latest_obs[1, 1:g]) + 1);
  // if no reporting day effects use native probability for reference day
  // effects
  int ref_as_p = (model_rep > 0 || model_refp > 0) ? 0 : 1; 
}

parameters {
  array[g] real leobs_init; // First time point for expected observations
  vector<lower=0>[g] eobs_lsd; // standard deviation of rw for primary obs
  array[g] vector[t - 1] leobs_resids; // unscaled rw for primary obs
<<<<<<< HEAD
  array[dist ? 1 : 0] real<lower=-10, upper=logdmax> logmean_int; // logmean intercept
  array[dist > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> logsd_int; // logsd intercept
  vector[dist ? neffs : 0] logmean_eff; // unscaled modifiers to log mean
  vector[dist > 1 ? neffs : 0] logsd_eff; // unscaled modifiers to log sd
  vector[nrd_effs] rd_eff; // unscaled modifiers to report date hazard
  vector<lower=0>[neff_sds] logmean_sd; // pooled modifiers to logmean
  vector<lower=0>[dist ? neff_sds : 0] logsd_sd; // pooled modifiers to logsd
  vector<lower=0>[nrd_eff_sds] rd_eff_sd; // pooled modifiers to report date
  array[g] real alpha_start; // starting value for alpha
  real<lower=0> alpha_sd; // standard deviation of the random walk increments
  vector<offset=0, multiplier=alpha_sd>[t] alpha_epsilon[g]; // random walk increments, non-centered
  real<lower=0, upper=1e4> sqrt_phi; // Overall dispersion by group
=======
  array[model_refp ? 1 : 0] real<lower=-10, upper=logdmax> refp_mean_int; // logmean intercept
  array[model_refp > 1 ? 1 : 0]real<lower=1e-3, upper=2*dmax> refp_sd_int; // logsd intercept
  vector[model_refp ? refp_fncol : 0] refp_mean_beta; // unscaled modifiers to log mean
  vector[model_refp > 1 ? refp_fncol : 0] refp_sd_beta; // unscaled modifiers to log sd
  vector[rep_fncol] rep_beta; // unscaled modifiers to report date hazard
  vector<lower=0>[refp_rncol] refp_mean_beta_sd; // pooled modifiers to logmean
  vector<lower=0>[model_refp ? refp_rncol : 0] refp_sd_beta_sd; // pooled modifiers to logsd
  vector<lower=0>[rep_rncol] rep_beta_sd; // pooled modifiers to report date
  array[model_obs > 0 ? 1 : 0] real<lower=0> sqrt_phi; // Overall dispersion by group
>>>>>>> develop
}

transformed parameters{
  vector[refp_fnrow] refp_mean;
  vector[refp_fnrow] refp_sd;
  matrix[dmax, refp_fnrow] pmfs; // sparse report distributions
  matrix[dmax, refp_fnrow] ref_lh; // sparse report logit hazards
  vector[rep_fnrow] srdlh; // sparse report day logit hazards
  array[g] vector[t] imp_obs; // Expected final observations
<<<<<<< HEAD
  array[g] vector<lower=0,upper=1>[t] alpha; // share of cases with known reference date
  real phi; // Transformed overdispersion (joint across all observations)
=======
  array[model_obs > 0 ? 1 : 0] real phi; // Transformed overdispersion (joint across all observations)
>>>>>>> develop
  // calculate log mean and sd parameters for each dataset from design matrices
  profile("transformed_delay_reference_date_total") {
  if (model_refp) {
    profile("transformed_delay_reference_date_effects") {
    refp_mean = combine_effects(refp_mean_int[1], refp_mean_beta, refp_fdesign,
                                refp_mean_beta_sd, refp_rdesign, 1);
    if (model_refp > 1) {
      refp_sd = combine_effects(log(refp_sd_int[1]), refp_sd_beta, refp_fdesign,
                                refp_sd_beta_sd, refp_rdesign, 1); 
      refp_sd = exp(refp_sd);
    }
    }
    // calculate pmfs
    profile("transformed_delay_reference_date_pmfs") {
    for (i in 1:refp_fnrow) {
      pmfs[, i] =
         discretised_reporting_prob(refp_mean[i], refp_sd[i], dmax, model_refp,
         2);
    }
    if (ref_as_p == 0) {
      for (i in 1:refp_fnrow) {
        ref_lh[, i] = prob_to_hazard(pmfs[, i]);
        ref_lh[, i] = logit(ref_lh[, i]);
      }
    }else{
      ref_lh = pmfs;
    }
    }
  }
  }
  // calculate sparse report date effects with forced 0 intercept
  profile("transformed_delay_reporting_date_effects") {
  srdlh =
    combine_effects(0, rep_beta, rep_fdesign, rep_beta_sd, rep_rdesign, 1);
  }
  // estimate unobserved expected final reported cases for each group
  // this could be any forecasting model but here its a 
  // first order random walk for each group on the log scale.
  profile("transformed_expected_final_observations") {
  for (k in 1:g) {
    real llast_obs;
    imp_obs[k][1] = leobs_init[k];
    imp_obs[k][2:t] = 
      leobs_init[k] + eobs_lsd[k] * cumulative_sum(leobs_resids[k]);
  }
  }
  // estimate share of cases with eventually known reference date, modeled as
  // a first order random walk for each group on the logit scale
  for (k in 1:g) {
    alpha[k] = inv_logit(alpha_start[k] + cumulative_sum(alpha_epsilon[k]));
  }
  // transform phi to overdispersion scale
  if (model_obs) {
    phi = inv_square(sqrt_phi);
  }
  // debug issues in truncated data if/when they appear
  if (debug) {
#include /chunks/debug.stan
  }
} 
  
model {
  profile("model_priors") {
  // priors for unobserved expected reported cases
  leobs_init ~ normal(eobs_init, 1);
  eobs_lsd ~ zero_truncated_normal(eobs_lsd_p[1], eobs_lsd_p[2]);
  for (i in 1:g) {
    leobs_resids[i] ~ std_normal();
  }
  // priors for the intercept of the log mean truncation distribution
  if (model_refp) {
    refp_mean_int ~ normal(refp_mean_int_p[1], refp_mean_int_p[2]);
    if (model_refp > 1) {
      refp_sd_int ~ normal(refp_sd_int_p[1], refp_sd_int_p[2]);
    }
    // priors and scaling for date of reference effects
    if (refp_fncol) {
      refp_mean_beta ~ std_normal();
      if (refp_rncol > 1) {
        refp_sd_beta ~ std_normal();
      }
      if (refp_rncol) {
        refp_mean_beta_sd ~ 
          zero_truncated_normal(refp_mean_beta_sd_p[1], refp_mean_beta_sd_p[2]);
        if (model_refp > 1) {
          refp_sd_beta_sd ~ 
            zero_truncated_normal(refp_sd_beta_sd_p[1], refp_sd_beta_sd_p[2]);
        }
      }
    }
  }
  // priors and scaling for date of report effects
  if (rep_fncol) { 
    rep_beta ~ std_normal();
    if (rep_rncol) {
      rep_beta_sd ~ zero_truncated_normal(rep_beta_sd_p[1], rep_beta_sd_p[2]);
    } 
  }
  // share of cases with eventually known reference date
  alpha_sd ~ normal(alpha_sd_p[1], alpha_sd_p[2]) T[0, ];
  for (k in 1:g){
    alpha_start[k] ~ normal(alpha_start_p[1], alpha_start_p[2]);
    alpha_epsilon[k] ~ normal(0, alpha_sd);
  }
  // reporting overdispersion (1/sqrt)
  if (model_obs) {
    sqrt_phi[1] ~ normal(sqrt_phi_p[1], sqrt_phi_p[2]) T[0,];
  }
  }
  // log density: observed vs model
  if (likelihood) {
    profile("model_likelihood") {
<<<<<<< HEAD
    target += obs_lupmf(flat_obs | obs_miss, dmax, sl, csl, g, imp_obs, sg, st,
                         rdlurd, srdlh, ref_lh, dpmfs, ref_p, alpha, phi);
=======
    target += reduce_sum(
      obs_lupmf, st, 1, flat_obs, sl, csl, imp_obs, sg, st, rep_findex, srdlh,
      ref_lh, refp_findex, model_refp, rep_fncol, ref_as_p, phi, model_obs
    );
>>>>>>> develop
    }
  }
}

generated quantities {
<<<<<<< HEAD
  array[pp ? sum(sl) : 0] int pp_obs;
  array[pp ? sum(sl) : 0] int pp_obs_miss;
  vector[ologlik ? s : 0] log_lik;
  vector[ologlik ? (t-dmax) : 0] log_lik_miss;
  array[cast ? dmax : 0, cast ? g : 0] int pp_inf_obs;
  array[cast ? t : 0, cast ? g : 0] int pp_inf_obs_miss;
  array[cast ? (t-dmax) : 0, cast ? g : 0] int pp_inf_obs_miss_rep;
  profile("generated_total") {
  if (cast) {
    int i_group, i_time;
    real tar_obs, tar_alpha;
    vector[dmax] rdlh;
    vector[dmax] lexp_obs;
    array[ologlik ? g : 0] vector[ologlik ? t : 0] exp_obs_miss_rep;
    array[s, dmax] int pp_obs_tmp;
    array[s, dmax] int pp_obs_tmp_miss;
    exp_obs_miss_rep = rep_array(rep_vector(0, t), g);
    pp_inf_obs_miss_rep = rep_array(0, (t-dmax), g);
    // Posterior predictions for observations
    for (i in 1:s) {
      profile("generated_obs") {
      i_group = sg[i];
      i_time = st[i];
      // estimated expected cases
      tar_obs = imp_obs[i_group][i_time];
      // estimated share of known reference dates
      tar_alpha = alpha[i_group][i_time];
      // reference date delay hazard
      rdlh = srdlh[rdlurd[i_time:(i_time + dmax - 1), i_group]];
      // expected observations with delay 0:(dmax-1)
      lexp_obs = expected_obs_from_index(
        i, imp_obs, rep_findex, srdlh, ref_lh, refp_findex, model_refp,
        rep_fncol, ref_as_p, sg[i], st[i], dmax
      );
<<<<<<< HEAD
      // realized observations with known reference date
      pp_obs_tmp[i, 1:dmax] = neg_binomial_2_log_rng(lexp_obs + tar_alpha, phi);
      // realized observations with unknown reference date
      pp_obs_tmp_miss[i, 1:dmax] = neg_binomial_2_rng(exp_obs * (1 - tar_alpha), phi);
=======
      if (model_obs) {
        pp_obs_tmp[i, 1:dmax] = neg_binomial_2_log_rng(lexp_obs, phi[1]);
      } else {
        pp_obs_tmp[i, 1:dmax] = poisson_log_rng(lexp_obs);
      }
>>>>>>> develop
      }
      profile("generated_loglik") {
      if (ologlik) {
        // predicted observations with missing reference date by reporting date
        if (i_time > 1) {
          exp_obs_miss_rep[i_group][i_time:min(i_time + dmax - 1, t)]
            += (exp_obs * (1 - tar_alpha))[1:min(dmax, t - i_time + 1)];
        }
        log_lik[i] = 0;
<<<<<<< HEAD
        for (j in 1:sl[i]) {
          // log-likelihood for observations with known reference date
          log_lik[i] += neg_binomial_2_log_lpmf(obs[i, j] | lexp_obs[j] + tar_alpha, phi);
=======
        if (model_obs) {
          for (j in 1:sl[i]) {
            log_lik[i] += 
              neg_binomial_2_log_lpmf(obs[i, j] | lexp_obs[j], phi[1]);
          }
        }else{
          for (j in 1:sl[i]) {
            log_lik[i] += poisson_log_lpmf(obs[i, j] | lexp_obs[j]);
          }
>>>>>>> develop
        }
      }
      }
    }
    profile("generated_loglik") {
    if (ologlik) {
      log_lik_miss[1:(t-dmax)] = rep_vector(0, t-dmax);
      for (k in 1:g) {
        for (i in (dmax+1):t) {
          // log-likelihood for observations with missing reference date
          log_lik_miss[i - dmax] += neg_binomial_2_lpmf(
            obs_miss[k, i] | exp_obs_miss_rep[k][i], phi);
        }
      }
    }
    }
    // Posterior prediction for final reported data (i.e at t = dmax + 1)
    profile("generated_obs") {
    for (k in 1:g) {
      // cases with known reference date (by reference date)
      int start_t = t - dmax;
      for (i in 1:dmax) {
        int snap = ts[start_t + i, k];
        pp_inf_obs[i, k] = sum(obs[snap, 1:sl[snap]]);
        if (sl[snap] < dmax) {
          pp_inf_obs[i, k] += sum(pp_obs_tmp[snap, (sl[snap]+1):dmax]);
        }
      }
      // cases with missing reference date (by estimated reference date)
      for (i in 1:t) {
        int snap = ts[i, k];
        pp_inf_obs_miss[i, k] = sum(pp_obs_tmp_miss[snap, 1:dmax]);
      }
      // cases with missing reference date (by reporting date)
      for (i in 2:t) {
        int snap = ts[i, k];
        for (l in max(dmax - i + 2, 1):min(dmax, t - i + 1)){
          pp_inf_obs_miss_rep[(i - dmax) + l - 1, k] += pp_obs_tmp_miss[snap, l];
        }
      }
    }
    // If posterior predictions for all observations are needed copy
    // from a temporary object to a permanent one
    // store in a flat vector to make observation linking easier
    if (pp) {
      int start_t = 0;
      for (i in 1:s) {
        pp_obs[(start_t + 1):(start_t + sl[i])] = pp_obs_tmp[i, 1:sl[i]];
        pp_obs_miss[(start_t + 1):(start_t + sl[i])] = pp_obs_tmp_miss[i, 1:sl[i]];
        start_t += sl[i];
      }
    }
    }
  }
}
}
