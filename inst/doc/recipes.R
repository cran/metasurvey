## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

## ----build-recipe-------------------------------------------------------------
library(metasurvey)
library(data.table)

set.seed(42)
n <- 200

# Simulate survey microdata (standing in for load_survey)
dt <- data.table(
  id = 1:n,
  age = sample(18:80, n, replace = TRUE),
  sex = sample(c(1, 2), n, replace = TRUE),
  income = round(runif(n, 5000, 80000)),
  activity = sample(c(2, 3, 5, 6), n,
    replace = TRUE,
    prob = c(0.55, 0.05, 0.05, 0.35)
  ),
  weight = round(runif(n, 0.5, 3.0), 4)
)

svy <- Survey$new(
  data    = dt,
  edition = "2023",
  type    = "ech",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "weight")
)

# Develop transformations interactively
svy <- step_compute(svy,
  income_thousands = income / 1000,
  employed = ifelse(activity == 2, 1L, 0L),
  comment = "Income scaling and employment indicator"
)

svy <- step_recode(svy, labor_status,
  activity == 2 ~ "Employed",
  activity %in% 3:5 ~ "Unemployed",
  activity %in% 6:8 ~ "Inactive",
  .default = "Other",
  comment = "ILO labor force classification"
)

svy <- step_recode(svy, age_group,
  age < 25 ~ "Youth",
  age < 45 ~ "Adult",
  age < 65 ~ "Mature",
  .default = "Senior",
  comment = "Standard age groups"
)

# Convert all steps to a recipe
labor_recipe <- steps_to_recipe(
  name        = "Labor Force Indicators",
  user        = "Research Team",
  svy         = svy,
  description = "Standard labor force indicators following ILO definitions",
  steps       = get_steps(svy),
  topic       = "labor"
)

labor_recipe

## ----recipe-doc---------------------------------------------------------------
doc <- labor_recipe$doc()
names(doc)

## ----recipe-doc-detail--------------------------------------------------------
# What variables does the recipe need?
doc$input_variables

# What variables does it create?
doc$output_variables

# Step-by-step pipeline
doc$pipeline

## ----recipe-validate----------------------------------------------------------
labor_recipe$validate(svy)

## ----apply-recipe-------------------------------------------------------------
# Create a fresh survey with same structure (simulating a new edition)
set.seed(99)
dt2 <- data.table(
  id = 1:100,
  age = sample(18:80, 100, replace = TRUE),
  sex = sample(c(1, 2), 100, replace = TRUE),
  income = round(runif(100, 5000, 80000)),
  activity = sample(c(2, 3, 5, 6), 100,
    replace = TRUE,
    prob = c(0.55, 0.05, 0.05, 0.35)
  ),
  weight = round(runif(100, 0.5, 3.0), 4)
)

svy2 <- Survey$new(
  data = dt2, edition = "2024", type = "ech",
  psu = NULL, engine = "data.table",
  weight = add_weight(annual = "weight")
)

# Attach and bake
svy2 <- add_recipe(svy2, labor_recipe)
svy2 <- bake_recipes(svy2)

head(get_data(svy2)[, .(id, income_thousands, labor_status, age_group)], 5)

## ----categories---------------------------------------------------------------
cats <- default_categories()
vapply(cats, function(c) c$name, character(1))

## ----add-category-------------------------------------------------------------
labor_recipe <- add_category(labor_recipe, "labor_market", "Labor market analysis")
labor_recipe <- add_category(labor_recipe, "income", "Income-related indicators")
labor_recipe

