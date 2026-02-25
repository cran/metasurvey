## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----configure----------------------------------------------------------------
# library(metasurvey)
# 
# # Point to your self-hosted API
# configure_api("https://your-api-host.example.com")
# 
# # Or use an environment variable
# Sys.setenv(METASURVEY_API_URL = "https://your-api-host.example.com")

## ----register-----------------------------------------------------------------
# # Individual account (auto-approved)
# api_register("Ana Garcia", "ana@example.com", "password123")
# 
# # Institutional member (requires admin review)
# api_register(
#   "Carlos Rodriguez",
#   "carlos@ine.gub.uy",
#   "password123",
#   user_type = "institutional_member",
#   institution = "INE Uruguay"
# )

## ----login--------------------------------------------------------------------
# api_login("ana@example.com", "password123")

## ----session------------------------------------------------------------------
# # View current user profile
# api_me()
# 
# # Refresh token
# api_refresh_token()
# 
# # Logout
# api_logout()

## ----token--------------------------------------------------------------------
# Sys.setenv(METASURVEY_TOKEN = "your-long-lived-token")
# 
# # API calls work without interactive login
# recipes <- api_list_recipes(survey_type = "ech")

## ----list-recipes-------------------------------------------------------------
# # All recipes
# all <- api_list_recipes()
# 
# # Filter by survey type
# ech <- api_list_recipes(survey_type = "ech")
# 
# # Search by text
# labor <- api_list_recipes(search = "empleo")
# 
# # Filter by topic
# income <- api_list_recipes(topic = "income")
# 
# # Filter by certification level
# official <- api_list_recipes(certification = "official")
# 
# # Pagination
# page2 <- api_list_recipes(limit = 10, offset = 10)

## ----get-recipe---------------------------------------------------------------
# recipe <- api_get_recipe("ech_employment_001")

## ----publish-recipe-----------------------------------------------------------
# api_login("ana@example.com", "password123")
# api_publish_recipe(my_recipe)

## ----workflow-api-------------------------------------------------------------
# # List workflows for ECH
# wf <- api_list_workflows(survey_type = "ech")
# 
# # Find workflows that use a specific recipe
# wf <- api_list_workflows(recipe_id = "ech_employment_001")
# 
# # Get specific workflow
# w <- api_get_workflow("wf_labor_market_001")
# 
# # Publish
# api_publish_workflow(my_workflow)

## ----anda---------------------------------------------------------------------
# # Get all ECH variables
# vars <- api_get_anda_variables(survey_type = "ech")
# 
# # Get specific variables
# vars <- api_get_anda_variables(
#   survey_type = "ech",
#   var_names = c("pobpcoac", "e27", "ht11")
# )

