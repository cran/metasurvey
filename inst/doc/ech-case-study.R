## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

## ----load-data----------------------------------------------------------------
library(metasurvey)
library(data.table)

# Load real ECH 2023 sample
dt <- fread(system.file("extdata", "ech_2023_sample.csv", package = "metasurvey"))

svy <- Survey$new(
  data    = dt,
  edition = "2023",
  type    = "ech",
  engine  = "data.table",
  weight  = add_weight(annual = "W_ANO")
)

head(get_data(svy), 3)

## ----demographics-------------------------------------------------------------
# Recode sex from INE codes (e26: 1=Male, 2=Female)
svy <- step_recode(svy, sex,
  e26 == 1 ~ "Male",
  e26 == 2 ~ "Female",
  .default = NA_character_,
  comment = "Sex: 1=Male, 2=Female (INE e26)"
)

# Recode age groups (standard ECH grouping, e27 = age)
svy <- step_recode(svy, age_group,
  e27 < 14 ~ "Child (0-13)",
  e27 < 25 ~ "Youth (14-24)",
  e27 < 45 ~ "Adult (25-44)",
  e27 < 65 ~ "Mature (45-64)",
  .default = "Senior (65+)",
  .to_factor = TRUE,
  ordered = TRUE,
  comment = "Standard age groups for labor statistics"
)

## ----labor--------------------------------------------------------------------
svy <- step_recode(svy, labor_status,
  POBPCOAC == 2 ~ "Employed",
  POBPCOAC %in% 3:5 ~ "Unemployed",
  POBPCOAC %in% 6:10 ~ "Inactive",
  .default = NA_character_,
  comment = "ILO labor force status from POBPCOAC"
)

# Create binary indicators
svy <- step_compute(svy,
  employed = ifelse(POBPCOAC == 2, 1L, 0L),
  unemployed = ifelse(POBPCOAC %in% 3:5, 1L, 0L),
  active = ifelse(POBPCOAC %in% 2:5, 1L, 0L),
  working_age = ifelse(e27 >= 14, 1L, 0L),
  comment = "Labor force binary indicators"
)

## ----income-------------------------------------------------------------------
svy <- step_compute(svy,
  income_pc = HT11 / nper,
  income_thousands = HT11 / 1000,
  log_income = log(HT11 + 1),
  comment = "Income transformations"
)

## ----geography----------------------------------------------------------------
poverty_lines <- data.table(
  region = 1:3,
  poverty_line = c(19000, 12500, 11000),
  region_name = c("Montevideo", "Interior loc. >= 5000", "Interior loc. < 5000")
)

svy <- step_join(svy,
  poverty_lines,
  by = "region",
  type = "left",
  comment = "Add poverty lines by region"
)

## ----recipe-------------------------------------------------------------------
ech_recipe <- steps_to_recipe(
  name = "ECH Labor Market Indicators",
  user = "Research Team",
  svy = svy,
  description = paste(
    "Standard labor market indicators for the ECH.",
    "Includes demographic recoding, ILO labor classification,",
    "income transformations, and geographic joins."
  ),
  steps = get_steps(svy),
  topic = "labor"
)

ech_recipe

## ----recipe-doc---------------------------------------------------------------
doc <- ech_recipe$doc()

# What variables does the recipe need?
doc$input_variables

# What variables does it create?
doc$output_variables

## ----recipe-publish-----------------------------------------------------------
# Set up a local registry
set_backend("local", path = tempfile(fileext = ".json"))
publish_recipe(ech_recipe)

# Now anyone can retrieve it by ID
r <- get_recipe("ech_labor")
print(r)

## ----estimation---------------------------------------------------------------
# Mean household income
result_income <- workflow(
  list(svy),
  survey::svymean(~HT11, na.rm = TRUE),
  estimation_type = "annual"
)

result_income

## ----estimation-labor---------------------------------------------------------
# Employment rate (proportion employed among total population)
result_employment <- workflow(
  list(svy),
  survey::svymean(~employed, na.rm = TRUE),
  estimation_type = "annual"
)

result_employment

## ----domain-------------------------------------------------------------------
# Mean income by region name
income_region <- workflow(
  list(svy),
  survey::svyby(~HT11, ~region_name, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

income_region

## ----domain-sex---------------------------------------------------------------
# Employment by sex
employment_sex <- workflow(
  list(svy),
  survey::svyby(~employed, ~sex, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

employment_sex

## ----quality------------------------------------------------------------------
results_all <- workflow(
  list(svy),
  survey::svymean(~HT11, na.rm = TRUE),
  survey::svymean(~employed, na.rm = TRUE),
  estimation_type = "annual"
)

for (i in seq_len(nrow(results_all))) {
  cv_pct <- results_all$cv[i] * 100
  cat(
    results_all$stat[i], ":",
    round(cv_pct, 1), "% CV -",
    evaluate_cv(cv_pct), "\n"
  )
}

