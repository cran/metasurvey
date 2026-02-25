## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----launch-------------------------------------------------------------------
# library(metasurvey)
# 
# # Open in your default browser
# explore_recipes()
# 
# # Or specify host and port
# explore_recipes(port = 3838, host = "127.0.0.1")

## ----token--------------------------------------------------------------------
# # Use the token generated from the app
# Sys.setenv(METASURVEY_TOKEN = "your-token-here")
# 
# # Now API calls work without interactive login
# recipes <- api_list_recipes(survey_type = "ech")

