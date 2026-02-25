## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

## ----install------------------------------------------------------------------
library(metasurvey)
library(data.table)

## ----create-survey------------------------------------------------------------
library(metasurvey)
library(data.table)

# Load a sample of real ECH 2023 microdata (200 households, ~500 persons)
dt <- fread(system.file("extdata", "ech_2023_sample.csv", package = "metasurvey"))

# Create Survey object
svy <- Survey$new(
  data    = dt,
  edition = "2023",
  type    = "ech",
  engine  = "data.table",
  weight  = add_weight(annual = "W_ANO")
)

## ----inspect------------------------------------------------------------------
head(get_data(svy), 3)

## ----step-compute-------------------------------------------------------------
svy <- step_compute(svy,
  # Convert income to thousands for readability
  ht11_thousands = HT11 / 1000,

  # Create employment indicator following ILO definitions
  employed = ifelse(POBPCOAC == 2, 1, 0),

  # Working age population (14+ years, ECH standard)
  working_age = ifelse(e27 >= 14, 1, 0),
  comment = "Basic labor force indicators"
)

## ----step-compute-grouped-----------------------------------------------------
# Calculate mean household income per department
svy <- step_compute(svy,
  mean_income_dept = mean(HT11, na.rm = TRUE),
  .by = "dpto",
  comment = "Department-level income averages"
)

## ----step-recode--------------------------------------------------------------
# Recode labor force status (POBPCOAC) into meaningful categories
svy <- step_recode(svy, labor_status,
  POBPCOAC == 2 ~ "Employed",
  POBPCOAC %in% 3:5 ~ "Unemployed",
  POBPCOAC %in% 6:10 ~ "Inactive",
  .default = "Not classified",
  comment = "Labor force status - ILO standard"
)

# Create standard age groups for labor statistics
svy <- step_recode(svy, age_group,
  e27 < 25 ~ "Youth (14-24)",
  e27 < 45 ~ "Adult (25-44)",
  e27 < 65 ~ "Mature (45-64)",
  .default = "Elderly (65+)",
  .to_factor = TRUE, # Convert to factor
  ordered = TRUE, # Ordered factor
  comment = "Age groups for labor analysis"
)

# Recode sex into descriptive labels
svy <- step_recode(svy, gender,
  e26 == 1 ~ "Male",
  e26 == 2 ~ "Female",
  .default = "Other",
  comment = "Gender classification"
)

## ----step-filter--------------------------------------------------------------
# Keep only working-age individuals (14+)
svy <- step_filter(svy,
  e27 >= 14,
  comment = "Working-age population only"
)

## ----step-rename--------------------------------------------------------------
svy <- step_rename(svy,
  age = e27, # Rename e27 to age
  sex_code = e26 # Keep original as sex_code
)

## ----step-remove--------------------------------------------------------------
# Remove intermediate calculations
svy <- step_remove(svy, working_age, mean_income_dept)

## ----step-join----------------------------------------------------------------
# Poverty lines by region (illustrative values in UYU, 2023)
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

## ----bake---------------------------------------------------------------------
svy <- bake_steps(svy)
head(get_data(svy), 3)

## ----get-steps----------------------------------------------------------------
steps <- get_steps(svy)
length(steps) # Number of transformation steps

# View step details
cat("Step 1:", steps[[1]]$name, "\n")
cat("Comment:", steps[[1]]$comment, "\n")

## ----view-graph, eval = FALSE-------------------------------------------------
# view_graph(svy, init_step = "Load ECH 2023")

## ----workflow-mean------------------------------------------------------------
# Estimate mean household income
result <- workflow(
  list(svy),
  survey::svymean(~HT11, na.rm = TRUE),
  estimation_type = "annual"
)

result

## ----workflow-multi-----------------------------------------------------------
results <- workflow(
  list(svy),
  survey::svymean(~HT11, na.rm = TRUE),
  survey::svytotal(~employed, na.rm = TRUE),
  survey::svymean(~labor_status, na.rm = TRUE),
  estimation_type = "annual"
)

results

## ----workflow-domain----------------------------------------------------------
# Mean income by gender
income_by_gender <- workflow(
  list(svy),
  survey::svyby(~HT11, ~gender, survey::svymean, na.rm = TRUE),
  estimation_type = "annual"
)

income_by_gender

## ----cv-----------------------------------------------------------------------
# Check quality of mean income estimate
cv_percentage <- results$cv[1] * 100
quality <- evaluate_cv(cv_percentage)

cat("CV:", round(cv_percentage, 2), "%\n")
cat("Quality:", quality, "\n")

## ----recipe-create------------------------------------------------------------
# Convert current steps to a recipe
labor_recipe <- steps_to_recipe(
  name = "ECH Labor Force Indicators",
  user = "National Statistics Office",
  svy = svy,
  description = paste(
    "Standard labor force indicators following ILO definitions.",
    "Creates employment status, age groups, and gender classifications."
  ),
  steps = get_steps(svy),
  topic = "labor_statistics"
)

class(labor_recipe)
labor_recipe$name

## ----recipe-doc---------------------------------------------------------------
doc <- labor_recipe$doc()
names(doc)

# Input variables required
doc$input_variables

# Output variables created
doc$output_variables

## ----config-------------------------------------------------------------------
# Check current lazy-processing setting
lazy_default() # TRUE = steps recorded but not executed immediately

# Check data-copy behavior
use_copy_default() # TRUE = operate on copies (safer but slower)

# View available computation engines
show_engines() # "data.table", "dplyr", etc.

## ----config-set---------------------------------------------------------------
# Disable lazy evaluation (execute steps immediately)
set_lazy_processing(FALSE)

# Modify inplace (faster, but modifies original data)
set_use_copy(FALSE)

# Reset to defaults
set_lazy_processing(TRUE)
set_use_copy(TRUE)

