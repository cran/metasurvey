## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE,
  warning = FALSE,
  message = FALSE
)

## -----------------------------------------------------------------------------
# library(metasurvey)
# 
# svy <- survey_empty(type = "ech", edition = "2023")
# svy

## -----------------------------------------------------------------------------
# set.seed(42)
# n <- 200
# dt <- data.table::data.table(
#   id       = rep(1:50, each = 4),
#   nper     = rep(1:4, 50),
#   pesoano  = runif(n, 50, 300),
#   e26      = sample(1:2, n, replace = TRUE),
#   e27      = sample(0:90, n, replace = TRUE),
#   e30      = sample(1:7, n, replace = TRUE),
#   e51_2    = sample(c(0:6, -9), n, replace = TRUE),
#   region_4 = sample(1:4, n, replace = TRUE)
# )
# 
# svy <- svy |> set_data(dt)

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_rename(
#     hh_id = "id", person_id = "nper",
#     comment = "Standardize identifiers"
#   )

## -----------------------------------------------------------------------------
# names(get_data(svy))[1:4]

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_recode(sex,
#     e26 == 1 ~ "Male",
#     e26 == 2 ~ "Female",
#     .default = NA_character_,
#     comment = "Sex from e26"
#   )

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_recode(age_group,
#     e27 >= 0 & e27 <= 13 ~ "Child",
#     e27 >= 14 & e27 <= 17 ~ "Adolescent",
#     e27 >= 18 & e27 <= 29 ~ "Young adult",
#     e27 >= 30 & e27 <= 64 ~ "Adult",
#     e27 >= 65 ~ "Elderly",
#     .default = NA_character_,
#     comment = "Age groups from e27"
#   )

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_recode(relationship,
#     e30 == 1 ~ "Head",
#     e30 == 2 ~ "Spouse",
#     e30 >= 3 & e30 <= 5 ~ "Child",
#     e30 == 6 ~ "Other relative",
#     e30 == 7 ~ "Non-relative",
#     .default = "Unknown",
#     comment = "Relationship from e30"
#   )

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_recode(edu_level,
#     e51_2 == 0 ~ "None",
#     e51_2 >= 1 & e51_2 <= 2 ~ "Primary",
#     e51_2 >= 3 & e51_2 <= 4 ~ "Secondary",
#     e51_2 >= 5 & e51_2 <= 6 ~ "Tertiary",
#     .default = NA_character_,
#     comment = "Education level from e51_2"
#   )

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_recode(area,
#     region_4 == 1 ~ "Montevideo",
#     region_4 == 2 ~ "Urban >5k",
#     region_4 == 3 ~ "Urban <5k",
#     region_4 == 4 ~ "Rural",
#     .default = NA_character_,
#     comment = "Geographic area from region_4"
#   )

## -----------------------------------------------------------------------------
# svy <- svy |>
#   step_remove(e26, e27, e30, e51_2, region_4,
#     comment = "Drop raw ECH variables"
#   )

## -----------------------------------------------------------------------------
# length(get_steps(svy))

## ----eval = FALSE-------------------------------------------------------------
# view_graph(svy)

## -----------------------------------------------------------------------------
# for (s in get_steps(svy)) {
#   cat(sprintf("[%s] %s\n", s$type, s$comment %||% ""))
# }

## -----------------------------------------------------------------------------
# rec <- steps_to_recipe(
#   name = "ECH Demographics (minimal)",
#   user = "research_team",
#   svy = svy,
#   steps = get_steps(svy),
#   description = paste(
#     "Harmonized demographics: sex, age group, relationship,",
#     "education level, and geographic area."
#   ),
#   topic = "demographics"
# )
# 
# rec

## -----------------------------------------------------------------------------
# doc <- rec$doc()
# cat("Input variables: ", paste(doc$input_variables, collapse = ", "), "\n")
# cat("Output variables:", paste(doc$output_variables, collapse = ", "), "\n")
# cat("Pipeline steps:  ", length(doc$pipeline), "\n")

## -----------------------------------------------------------------------------
# svy <- bake_steps(svy)

## -----------------------------------------------------------------------------
# head(get_data(svy)[, .(
#   hh_id, person_id, sex, age_group, relationship,
#   edu_level, area
# )])

## -----------------------------------------------------------------------------
# "e26" %in% names(get_data(svy))

## -----------------------------------------------------------------------------
# f <- tempfile(fileext = ".json")
# save_recipe(rec, f)

## -----------------------------------------------------------------------------
# rec2 <- read_recipe(f)
# rec2$name
# length(rec2$steps)

## -----------------------------------------------------------------------------
# cat(readLines(f, n = 15), sep = "\n")

## -----------------------------------------------------------------------------
# rec_loaded <- read_recipe(f)
# 
# svy_2024 <- survey_empty(type = "ech", edition = "2024") |>
#   set_data(data.table::data.table(
#     id       = rep(1:30, each = 3),
#     nper     = rep(1:3, 30),
#     pesoano  = runif(90, 50, 300),
#     e26      = sample(1:2, 90, replace = TRUE),
#     e27      = sample(0:90, 90, replace = TRUE),
#     e30      = sample(1:7, 90, replace = TRUE),
#     e51_2    = sample(c(0:6, -9), 90, replace = TRUE),
#     region_4 = sample(1:4, 90, replace = TRUE)
#   )) |>
#   add_recipe(rec_loaded) |>
#   bake_recipes()
# 
# head(get_data(svy_2024)[, .(hh_id, person_id, sex, age_group, area)])

