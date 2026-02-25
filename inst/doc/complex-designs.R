## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

## ----setup--------------------------------------------------------------------
library(metasurvey)
library(survey)
library(data.table)

data(api, package = "survey")
dt_strat <- data.table(apistrat)

## ----simple-------------------------------------------------------------------
svy_simple <- Survey$new(
  data = dt_strat,
  edition = "2000",
  type = "api",
  psu = NULL,
  engine = "data.table",
  weight = add_weight(annual = "pw")
)

cat_design(svy_simple)

## ----stratified---------------------------------------------------------------
dt_clus <- data.table(apiclus1)

svy_strat_clus <- Survey$new(
  data    = dt_strat,
  edition = "2000",
  type    = "api",
  psu     = NULL,
  strata  = "stype",
  engine  = "data.table",
  weight  = add_weight(annual = "pw")
)

cat_design(svy_strat_clus)

## ----stratified-validate------------------------------------------------------
design_strat <- svydesign(
  id = ~1, strata = ~stype, weights = ~pw,
  data = dt_strat
)
direct_strat <- svymean(~api00, design_strat)

wf_strat <- workflow(
  list(svy_strat_clus),
  survey::svymean(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

cat("Direct estimate:", round(coef(direct_strat), 2), "\n")
cat("Workflow estimate:", round(wf_strat$value, 2), "\n")
cat("Match:", all.equal(
  as.numeric(coef(direct_strat)),
  wf_strat$value,
  tolerance = 1e-6
), "\n")

## ----inspect-design-----------------------------------------------------------
# Check design type
cat_design_type(svy_simple, "annual")

# View metadata
get_metadata(svy_simple)

## ----multi-weight-------------------------------------------------------------
set.seed(42)
dt_multi <- copy(dt_strat)
dt_multi[, pw_monthly := pw * runif(.N, 0.9, 1.1)]

svy_multi <- Survey$new(
  data    = dt_multi,
  edition = "2000",
  type    = "api",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "pw", monthly = "pw_monthly")
)

# Use different weight types in workflow()
annual_est <- workflow(
  list(svy_multi),
  survey::svymean(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

monthly_est <- workflow(
  list(svy_multi),
  survey::svymean(~api00, na.rm = TRUE),
  estimation_type = "monthly"
)

cat("Annual estimate:", round(annual_est$value, 1), "\n")
cat("Monthly estimate:", round(monthly_est$value, 1), "\n")

## ----engine-------------------------------------------------------------------
# Current engine
get_engine()

# Available engines
show_engines()

## ----lazy---------------------------------------------------------------------
# Check current setting
lazy_default()

# Change for the session (not recommended for most workflows)
# set_lazy_processing(FALSE)

## ----copy---------------------------------------------------------------------
# Current setting
use_copy_default()

# In-place is faster but modifies the original
# set_use_copy(FALSE)

## ----variance-----------------------------------------------------------------
results <- workflow(
  list(svy_simple),
  survey::svymean(~api00, na.rm = TRUE),
  survey::svytotal(~enroll, na.rm = TRUE),
  estimation_type = "annual"
)

results

## ----domain-------------------------------------------------------------------
domain_results <- workflow(
  list(svy_simple),
  survey::svyby(~api00, ~stype, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

domain_results

## ----ratio--------------------------------------------------------------------
ratio_result <- workflow(
  list(svy_simple),
  survey::svyratio(~api00, ~api99),
  estimation_type = "annual"
)

ratio_result

## ----validate-steps-----------------------------------------------------------
# Step 1: Compute new variable
svy_v <- step_compute(svy_simple,
  api_diff = api00 - api99,
  comment = "API score difference"
)

# Check that the step was recorded
steps <- get_steps(svy_v)
cat("Pending steps:", length(steps), "\n")

## ----cross-validate-----------------------------------------------------------
# Method 1: Direct survey package
design <- svydesign(id = ~1, weights = ~pw, data = dt_strat)
direct_mean <- svymean(~api00, design)

# Method 2: metasurvey workflow
wf_result <- workflow(
  list(svy_simple),
  survey::svymean(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

cat("Direct estimate:", round(coef(direct_mean), 2), "\n")
cat("Workflow estimate:", round(wf_result$value, 2), "\n")
cat("Match:", all.equal(
  as.numeric(coef(direct_mean)),
  wf_result$value,
  tolerance = 1e-6
), "\n")

## ----view-graph, eval = FALSE-------------------------------------------------
# svy_viz <- step_compute(svy_simple,
#   api_diff = api00 - api99,
#   high_growth = ifelse(api00 - api99 > 50, 1L, 0L)
# )
# view_graph(svy_viz, init_step = "Load API data")

## ----cv-check-----------------------------------------------------------------
results_quality <- workflow(
  list(svy_simple),
  survey::svymean(~api00, na.rm = TRUE),
  survey::svymean(~enroll, na.rm = TRUE),
  estimation_type = "annual"
)

for (i in seq_len(nrow(results_quality))) {
  cv_pct <- results_quality$cv[i] * 100
  cat(
    results_quality$stat[i], ":",
    round(cv_pct, 1), "% CV -",
    evaluate_cv(cv_pct), "\n"
  )
}

## ----roundtrip----------------------------------------------------------------
# Create steps and recipe
svy_rt <- step_compute(svy_simple, api_diff = api00 - api99)

my_recipe <- steps_to_recipe(
  name        = "API Test",
  user        = "QA Team",
  svy         = svy_rt,
  description = "Recipe for validation",
  steps       = get_steps(svy_rt)
)

# Check documentation is correct
doc <- my_recipe$doc()
cat("Input variables:", paste(doc$input_variables, collapse = ", "), "\n")
cat("Output variables:", paste(doc$output_variables, collapse = ", "), "\n")

# Validate against the survey
my_recipe$validate(svy_rt)

## ----checklist----------------------------------------------------------------
validate_pipeline <- function(svy) {
  data <- get_data(svy)
  checks <- list(
    has_data = !is.null(data),
    has_rows = nrow(data) > 0,
    has_weights = all(
      unlist(svy$weight)[is.character(unlist(svy$weight))] %in% names(data)
    )
  )

  passed <- all(unlist(checks))
  if (passed) {
    message("All validation checks passed")
  } else {
    failed <- names(checks)[!unlist(checks)]
    warning("Failed checks: ", paste(failed, collapse = ", "))
  }
  invisible(checks)
}

validate_pipeline(svy_simple)

