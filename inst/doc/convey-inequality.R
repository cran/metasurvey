## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)
can_run <- requireNamespace("convey", quietly = TRUE)

## ----setup, eval = can_run----------------------------------------------------
library(metasurvey)
library(survey)
library(convey)
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

## ----convey-prep, eval = can_run----------------------------------------------
svy$ensure_design()
svy$design[["annual"]] <- convey_prep(svy$design[["annual"]])

## ----gini, eval = can_run-----------------------------------------------------
gini <- workflow(
  list(svy),
  convey::svygini(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

gini

## ----atkinson, eval = can_run-------------------------------------------------
atk_05 <- workflow(
  list(svy),
  convey::svyatk(~api00, epsilon = 0.5),
  estimation_type = "annual"
)

atk_1 <- workflow(
  list(svy),
  convey::svyatk(~api00, epsilon = 1),
  estimation_type = "annual"
)

rbind(atk_05, atk_1)

## ----qsr, eval = can_run------------------------------------------------------
qsr <- workflow(
  list(svy),
  convey::svyqsr(~api00, na.rm = TRUE),
  estimation_type = "annual"
)

qsr

## ----gei, eval = can_run------------------------------------------------------
theil <- workflow(
  list(svy),
  convey::svygei(~api00, epsilon = 1),
  estimation_type = "annual"
)

mld <- workflow(
  list(svy),
  convey::svygei(~api00, epsilon = 0),
  estimation_type = "annual"
)

rbind(theil, mld)

## ----arpt, eval = can_run-----------------------------------------------------
arpt <- workflow(
  list(svy),
  convey::svyarpt(~meals, na.rm = TRUE),
  estimation_type = "annual"
)

arpt

## ----arpr, eval = can_run-----------------------------------------------------
arpr <- workflow(
  list(svy),
  convey::svyarpr(~meals, na.rm = TRUE),
  estimation_type = "annual"
)

arpr

## ----fgt, eval = can_run------------------------------------------------------
threshold <- 50

fgt0 <- workflow(
  list(svy),
  convey::svyfgt(~meals, g = 0, abs_thresh = threshold, na.rm = TRUE),
  estimation_type = "annual"
)

fgt1 <- workflow(
  list(svy),
  convey::svyfgt(~meals, g = 1, abs_thresh = threshold, na.rm = TRUE),
  estimation_type = "annual"
)

fgt2 <- workflow(
  list(svy),
  convey::svyfgt(~meals, g = 2, abs_thresh = threshold, na.rm = TRUE),
  estimation_type = "annual"
)

rbind(fgt0, fgt1, fgt2)

## ----full-pipeline, eval = can_run--------------------------------------------
dt_full <- data.table(apistrat)

svy_full <- Survey$new(
  data    = dt_full,
  edition = "2000",
  type    = "api",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "pw")
)

# Transform: compute a derived variable
svy_full <- step_compute(svy_full,
  api_growth = api00 - api99,
  comment = "API score growth"
)

# Bake the steps
svy_full <- bake_steps(svy_full)

# Prepare for convey
svy_full$ensure_design()
svy_full$design[["annual"]] <- convey_prep(svy_full$design[["annual"]])

# Inequality: Gini on derived variable, Atkinson on api00 (must be positive)
results <- workflow(
  list(svy_full),
  convey::svygini(~api_growth, na.rm = TRUE),
  convey::svyatk(~api00, epsilon = 1),
  estimation_type = "annual"
)

results

## ----cv-assessment, eval = can_run--------------------------------------------
for (i in seq_len(nrow(results))) {
  cv_val <- results$cv[i] * 100
  cat(
    results$stat[i], ":",
    round(cv_val, 1), "% CV -",
    evaluate_cv(cv_val), "\n"
  )
}

## ----table, eval = can_run && requireNamespace("gt", quietly = TRUE)----------
workflow_table(
  results,
  title = "Inequality of API Score Growth",
  subtitle = "California Schools, 2000"
)

## ----provenance, eval = can_run-----------------------------------------------
prov <- provenance(results)
prov
cat("metasurvey version:", prov$environment$metasurvey_version, "\n")
cat("Steps applied:", length(prov$steps), "\n")

