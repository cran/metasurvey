## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----architecture-diagram, echo=FALSE, eval=TRUE, out.width="100%", fig.cap="metasurvey self-hosting infrastructure"----
knitr::include_graphics("metasurvey-infrastructure.png")

## ----publish-indicator--------------------------------------------------------
# library(metasurvey)
# 
# # 1. Load survey data (private -- stays on your server)
# svy <- Survey$new(
#   data = my_survey_data,
#   edition = "2024",
#   type = "ech",
#   engine = "data.table",
#   weight = add_weight(annual = "W_ANO")
# )
# 
# # 2. Apply a recipe (defines variables like unemployment status)
# svy <- step_compute(svy,
#   pd = data.table::fcase(
#     pobpcoac == 2, 1L,
#     pobpcoac %in% c(1, 3), 0L
#   ),
#   comment = "Unemployed: POBPCOAC == 2"
# )
# svy <- bake_steps(svy)
# 
# # 3. Run the estimation (workflow)
# result <- workflow(
#   svy = list(svy),
#   survey::svymean(~pd, na.rm = TRUE),
#   estimation_type = "annual"
# )
# 
# # result is a data.table:
# #       stat      value     se     cv
# # svymean: pd    0.082  0.003  0.037

## ----publish-to-api-----------------------------------------------------------
# # Connect to your local API
# configure_api("http://localhost:8787")
# api_login("admin@example.com", "your-password")
# 
# # Build the indicator payload
# indicator <- list(
#   name = "Unemployment Rate 2024",
#   description = "Annual unemployment rate, population 14+",
#   recipe_id = "ech_employment_001",
#   workflow_id = "ech_wf_labor",
#   survey_type = "ech",
#   edition = "2024",
#   estimation_type = "annual",
#   stat = result$stat[1],
#   value = result$value[1],
#   se = result$se[1],
#   cv = result$cv[1],
#   confint_lower = result$confint_lower[1],
#   confint_upper = result$confint_upper[1],
#   metadata = list(
#     formula = "~pd",
#     estimation_function = "svymean"
#   )
# )
# 
# # Publish (requires authentication)
# resp <- httr2::request("http://localhost:8787/indicators") |>
#   httr2::req_headers(
#     Authorization = paste("Bearer", Sys.getenv("METASURVEY_TOKEN"))
#   ) |>
#   httr2::req_body_json(indicator) |>
#   httr2::req_perform()
# 
# httr2::resp_body_json(resp)
# # {ok: true, id: "ind_1708099200_42"}

