## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

has_eph <- requireNamespace("eph", quietly = TRUE)
has_pnad <- requireNamespace("PNADcIBGE", quietly = TRUE)
has_ipumsr <- requireNamespace("ipumsr", quietly = TRUE)
has_haven <- requireNamespace("haven", quietly = TRUE)

# Handle strata with a single PSU (common in example/sample data)
options(survey.lonely.psu = "adjust")

## ----ech----------------------------------------------------------------------
library(metasurvey)
library(data.table)

dt_ech <- fread(
  system.file("extdata", "ech_2023_sample.csv", package = "metasurvey")
)

svy_ech <- Survey$new(
  data    = dt_ech,
  edition = "2023",
  type    = "ech",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "W_ANO")
)

svy_ech <- svy_ech |>
  step_recode(labor_status,
    POBPCOAC == 2 ~ "Employed",
    POBPCOAC %in% 3:5 ~ "Unemployed",
    POBPCOAC %in% c(6:10, 1) ~ "Inactive or under 14",
    comment = "ILO labor force status"
  ) |>
  step_compute(
    income_pc = HT11 / nper,
    comment = "Per capita household income"
  ) |>
  bake_steps()

workflow(
  list(svy_ech),
  survey::svymean(~HT11, na.rm = TRUE),
  estimation_type = "annual"
)

## ----eph, eval = has_eph------------------------------------------------------
library(eph)

data("toybase_individual_2016_04", package = "eph")
dt_eph <- data.table(toybase_individual_2016_04)

svy_eph <- Survey$new(
  data    = dt_eph,
  edition = "201604",
  type    = "eph",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(quarterly = "PONDERA")
)

svy_eph <- svy_eph |>
  step_recode(labor_status,
    ESTADO == 1 ~ "Employed",
    ESTADO == 2 ~ "Unemployed",
    ESTADO == 3 ~ "Inactive",
    .default = NA_character_,
    comment = "Labor force status (INDEC)"
  ) |>
  step_recode(sex,
    CH04 == 1 ~ "Male",
    CH04 == 2 ~ "Female",
    .default = NA_character_,
    comment = "Sex from CH04"
  ) |>
  step_compute(
    employed = ifelse(ESTADO == 1, 1L, 0L),
    comment = "Employment indicator"
  ) |>
  bake_steps()

# Employment rate
workflow(
  list(svy_eph),
  survey::svymean(~employed, na.rm = TRUE),
  estimation_type = "quarterly"
)

## ----pnadc, eval = has_pnad---------------------------------------------------
library(PNADcIBGE)

dt_pnadc <- data.table(read_pnadc(
  microdata = system.file("extdata", "exampledata.txt", package = "PNADcIBGE"),
  input_txt = system.file("extdata", "input_example.txt", package = "PNADcIBGE")
))

svy_pnadc <- Survey$new(
  data    = dt_pnadc,
  edition = "202301",
  type    = "pnadc",
  psu     = "UPA",
  strata  = "Estrato",
  engine  = "data.table",
  weight  = add_weight(quarterly = "V1028")
)

svy_pnadc <- svy_pnadc |>
  step_recode(sex,
    V2007 == 1 ~ "Male",
    V2007 == 2 ~ "Female",
    .default = NA_character_,
    comment = "Sex (V2007)"
  ) |>
  step_compute(
    age = as.integer(V2009),
    comment = "Age in years"
  ) |>
  bake_steps()

workflow(
  list(svy_pnadc),
  survey::svymean(~age, na.rm = TRUE),
  estimation_type = "quarterly"
)

## ----cps, eval = has_ipumsr---------------------------------------------------
library(ipumsr)

ddi <- read_ipums_ddi(
  system.file("extdata", "cps_00160.xml", package = "ipumsr")
)
dt_cps <- data.table(read_ipums_micro(ddi, verbose = FALSE))

svy_cps <- Survey$new(
  data    = dt_cps,
  edition = "2011",
  type    = "cps",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "ASECWT")
)

svy_cps <- svy_cps |>
  step_recode(health_status,
    HEALTH == 1 ~ "Excellent",
    HEALTH == 2 ~ "Very good",
    HEALTH == 3 ~ "Good",
    HEALTH == 4 ~ "Fair",
    HEALTH == 5 ~ "Poor",
    .default = NA_character_,
    comment = "Self-reported health status"
  ) |>
  step_compute(
    log_income = log(INCTOT + 1),
    comment = "Log total income"
  ) |>
  bake_steps()

workflow(
  list(svy_cps),
  survey::svymean(~INCTOT, na.rm = TRUE),
  estimation_type = "annual"
)

## ----enigh--------------------------------------------------------------------
set.seed(42)
dt_enigh <- data.table(
  id = 1:200,
  upm = rep(1:40, each = 5),
  est_dis = rep(1:10, each = 20),
  factor = runif(200, 100, 500),
  sexo_jefe = sample(1:2, 200, replace = TRUE),
  edad_jefe = sample(18:80, 200, replace = TRUE),
  ing_cor = rlnorm(200, 10, 1),
  tam_hog = sample(1:8, 200, replace = TRUE)
)

svy_enigh <- Survey$new(
  data    = dt_enigh,
  edition = "2022",
  type    = "enigh",
  psu     = "upm",
  strata  = "est_dis",
  engine  = "data.table",
  weight  = add_weight(annual = "factor")
)

svy_enigh <- svy_enigh |>
  step_recode(sex_head,
    sexo_jefe == 1 ~ "Male",
    sexo_jefe == 2 ~ "Female",
    .default = NA_character_,
    comment = "Sex of household head"
  ) |>
  step_compute(
    income_pc = ing_cor / tam_hog,
    comment = "Per capita household income"
  ) |>
  bake_steps()

workflow(
  list(svy_enigh),
  survey::svymean(~income_pc, na.rm = TRUE),
  estimation_type = "annual"
)

## ----dhs, eval = FALSE--------------------------------------------------------
# library(haven)
# 
# # Download the model Individual Recode (no credentials needed)
# tf <- tempfile(fileext = ".zip")
# download.file(
#   "https://dhsprogram.com/data/model_data/dhs/zzir62dt.zip",
#   tf,
#   mode = "wb", quiet = TRUE
# )
# td <- tempdir()
# unzip(tf, exdir = td)
# dta_file <- list.files(td,
#   pattern = "\\.DTA$", full.names = TRUE,
#   ignore.case = TRUE
# )
# dt_dhs <- data.table(read_dta(dta_file[1]))
# 
# # DHS weights must be divided by 1,000,000
# dt_dhs[, wt := as.numeric(v005) / 1e6]
# 
# svy_dhs <- Survey$new(
#   data    = dt_dhs,
#   edition = "2020",
#   type    = "dhs",
#   psu     = "v001",
#   strata  = "v023",
#   engine  = "data.table",
#   weight  = add_weight(annual = "wt")
# )
# 
# svy_dhs <- svy_dhs |>
#   step_recode(education,
#     v106 == 0 ~ "No education",
#     v106 == 1 ~ "Primary",
#     v106 == 2 ~ "Secondary",
#     v106 == 3 ~ "Higher",
#     .default = NA_character_,
#     comment = "Education level (v106)"
#   ) |>
#   step_compute(
#     children = as.numeric(v201),
#     comment = "Children ever born"
#   ) |>
#   bake_steps()
# 
# workflow(
#   list(svy_dhs),
#   survey::svymean(~children, na.rm = TRUE),
#   estimation_type = "annual"
# )

## ----recipe-portability-------------------------------------------------------
set.seed(42)
dt_demo <- data.table(
  id     = 1:100,
  age    = sample(18:65, 100, replace = TRUE),
  income = round(runif(100, 1000, 5000), 2),
  w      = round(runif(100, 0.5, 2), 4)
)

svy_demo <- Survey$new(
  data    = dt_demo,
  edition = "2023",
  type    = "demo",
  psu     = NULL,
  engine  = "data.table",
  weight  = add_weight(annual = "w")
)

svy_demo <- svy_demo |>
  step_compute(indicator = ifelse(age > 30, 1L, 0L)) |>
  step_recode(age_group,
    age < 30 ~ "Young",
    age >= 30 ~ "Adult",
    .default = NA_character_
  )

my_recipe <- steps_to_recipe(
  name        = "Demo Indicators",
  user        = "Research Team",
  svy         = svy_demo,
  description = "Reusable demographic indicators",
  steps       = get_steps(svy_demo),
  topic       = "demographics"
)

doc <- my_recipe$doc()
cat("Inputs:", paste(doc$input_variables, collapse = ", "), "\n")
cat("Outputs:", paste(doc$output_variables, collapse = ", "), "\n")

