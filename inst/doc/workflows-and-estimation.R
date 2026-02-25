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
dt <- data.table(apistrat)

svy <- Survey$new(
  data    = dt,
  edition = "2000",
  type    = "api",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "pw")
)

## ----mean---------------------------------------------------------------------
result <- workflow(
  list(svy),
  survey::svymean(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

result

## ----total--------------------------------------------------------------------
result_total <- workflow(
  list(svy),
  survey::svytotal(~enroll, na.rm = TRUE),
  estimation_type = "annual"
)

result_total

## ----multiple-----------------------------------------------------------------
results <- workflow(
  list(svy),
  survey::svymean(~api00, na.rm = TRUE),
  survey::svytotal(~enroll, na.rm = TRUE),
  estimation_type = "annual"
)

results

## ----domain-------------------------------------------------------------------
# Mean API score by school type
api_by_type <- workflow(
  list(svy),
  survey::svyby(~api00, ~stype, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

api_by_type

## ----domain-award-------------------------------------------------------------
# Mean enrollment by awards status
enroll_by_award <- workflow(
  list(svy),
  survey::svyby(~enroll, ~awards, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

enroll_by_award

## ----cv-----------------------------------------------------------------------
# Evaluate quality of the API score estimate
cv_pct <- results$cv[1] * 100
quality <- evaluate_cv(cv_pct)

cat("CV:", round(cv_pct, 2), "%\n")
cat("Quality:", quality, "\n")

## ----create-wf----------------------------------------------------------------
wf <- RecipeWorkflow$new(
  name = "API Score Analysis 2000",
  description = "Mean API score estimation by school type",
  user = "Research Team",
  survey_type = "api",
  edition = "2000",
  estimation_type = "annual",
  recipe_ids = character(0),
  calls = list(
    "survey::svymean(~api00, na.rm = TRUE)",
    "survey::svyby(~api00, ~stype, survey::svymean, na.rm = TRUE)"
  )
)

wf

## ----wf-registry--------------------------------------------------------------
# Configure a local backend
wf_path <- tempfile(fileext = ".json")
set_workflow_backend("local", path = wf_path)

# Publish
publish_workflow(wf)

# Discover workflows
all_wf <- list_workflows()
length(all_wf)

# Search by text
found <- search_workflows("income")
length(found)

# Filter by survey type
ech_wf <- filter_workflows(survey_type = "ech")
length(ech_wf)

## ----find-for-recipe----------------------------------------------------------
# Create a workflow that references a recipe
wf2 <- RecipeWorkflow$new(
  name            = "Labor Market Estimates",
  user            = "Team",
  survey_type     = "ech",
  edition         = "2023",
  estimation_type = "annual",
  recipe_ids      = c("labor_force_recipe_001"),
  calls           = list("survey::svymean(~employed, na.rm = TRUE)")
)

publish_workflow(wf2)

# Find all workflows that use this recipe
related <- find_workflows_for_recipe("labor_force_recipe_001")
length(related)
if (length(related) > 0) cat("Found:", related[[1]]$name, "\n")

## ----full-pipeline------------------------------------------------------------
# 1. Create survey from real data
dt_full <- data.table(apistrat)

svy_full <- Survey$new(
  data    = dt_full,
  edition = "2000",
  type    = "api",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "pw")
)

# 2. Apply steps: compute derived variables
svy_full <- step_compute(svy_full,
  api_growth = api00 - api99,
  high_growth = ifelse(api00 - api99 > 50, 1L, 0L),
  comment = "API score growth indicators"
)

svy_full <- step_recode(svy_full, school_level,
  stype == "E" ~ "Elementary",
  stype == "M" ~ "Middle",
  stype == "H" ~ "High",
  .default = "Other",
  comment = "School level classification"
)

# 3. Estimate means
estimates <- workflow(
  list(svy_full),
  survey::svymean(~api_growth, na.rm = TRUE),
  survey::svymean(~high_growth, na.rm = TRUE),
  estimation_type = "annual"
)

estimates

## ----full-pipeline-domain-----------------------------------------------------
# 4. Domain estimation (by school type)
by_school <- workflow(
  list(svy_full),
  survey::svyby(~api00, ~stype, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

by_school

## ----full-pipeline-cv---------------------------------------------------------
# 5. Assess quality
for (i in seq_len(nrow(estimates))) {
  cv_val <- estimates$cv[i] * 100
  cat(
    estimates$stat[i], ":",
    round(cv_val, 1), "% CV -",
    evaluate_cv(cv_val), "\n"
  )
}

## ----provenance---------------------------------------------------------------
# Provenance is populated automatically after bake_steps()
prov <- provenance(svy_full)
prov

## ----provenance-workflow------------------------------------------------------
prov_wf <- provenance(estimates)
cat("metasurvey version:", prov_wf$environment$metasurvey_version, "\n")
cat("Steps applied:", length(prov_wf$steps), "\n")

## ----provenance-json, eval = FALSE--------------------------------------------
# provenance_to_json(prov, "audit_trail.json")

## ----provenance-diff, eval = FALSE--------------------------------------------
# diff <- provenance_diff(prov_2022, prov_2023)
# diff$steps_changed
# diff$n_final_changed

## ----workflow-table, eval = requireNamespace("gt", quietly = TRUE)------------
workflow_table(estimates)

## ----workflow-table-opts, eval = requireNamespace("gt", quietly = TRUE)-------
# Spanish locale, hide SE, custom title
workflow_table(
  estimates,
  locale = "es",
  show_se = FALSE,
  title = "API Growth Indicators",
  subtitle = "California Schools, 2000"
)

## ----workflow-table-domain, eval = requireNamespace("gt", quietly = TRUE)-----
workflow_table(by_school)

## ----workflow-table-export, eval = FALSE--------------------------------------
# tbl <- workflow_table(estimates)
# gt::gtsave(tbl, "estimates.html")
# gt::gtsave(tbl, "estimates.docx")
# gt::gtsave(tbl, "estimates.png")

