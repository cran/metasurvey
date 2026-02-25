## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  warning = FALSE,
  message = FALSE
)

## ----create-panel-------------------------------------------------------------
library(metasurvey)
library(data.table)
set_use_copy(TRUE)

set.seed(42)
n <- 100

make_survey <- function(edition) {
  dt <- data.table(
    id       = 1:n,
    age      = sample(18:80, n, replace = TRUE),
    income   = round(runif(n, 5000, 80000)),
    employed = sample(0:1, n, replace = TRUE),
    w        = round(runif(n, 0.5, 3.0), 4)
  )
  Survey$new(
    data = dt, edition = edition, type = "ech",
    psu = NULL, engine = "data.table",
    weight = add_weight(annual = "w")
  )
}

# Implantation: 2023 wave 1
impl <- make_survey("2023")

# Follow-ups: waves 2 through 4
fu_2 <- make_survey("2023")
fu_3 <- make_survey("2023")
fu_4 <- make_survey("2023")

panel <- RotativePanelSurvey$new(
  implantation   = impl,
  follow_up      = list(fu_2, fu_3, fu_4),
  type           = "ech",
  default_engine = "data.table",
  steps          = list(),
  recipes        = list(),
  workflows      = list(),
  design         = NULL
)

## ----access-panel-------------------------------------------------------------
# Implantation survey
imp <- get_implantation(panel)
class(imp)
head(get_data(imp), 3)

## ----access-followup----------------------------------------------------------
# Follow-up surveys
follow_ups <- get_follow_up(panel)
cat("Number of follow-ups:", length(follow_ups), "\n")

## ----panel-steps--------------------------------------------------------------
# Transform the implantation survey
panel$implantation <- step_compute(panel$implantation,
  income_k = income / 1000,
  comment = "Income in thousands"
)

# Apply the same step to each follow-up
panel$follow_up <- lapply(panel$follow_up, function(svy) {
  step_compute(svy, income_k = income / 1000, comment = "Income in thousands")
})

## ----workflow-impl------------------------------------------------------------
result_impl <- workflow(
  list(panel$implantation),
  survey::svymean(~income, na.rm = TRUE),
  estimation_type = "annual"
)

result_impl

## ----workflow-followup--------------------------------------------------------
results <- rbindlist(lapply(seq_along(panel$follow_up), function(i) {
  r <- workflow(
    list(panel$follow_up[[i]]),
    survey::svymean(~income, na.rm = TRUE),
    estimation_type = "annual"
  )
  r$period <- panel$follow_up[[i]]$edition
  r
}))

results[, .(period, stat, value, se, cv)]

## ----pool-create--------------------------------------------------------------
s1 <- make_survey("2023")
s2 <- make_survey("2023")
s3 <- make_survey("2023")

pool <- PoolSurvey$new(
  list(annual = list("q1" = list(s1, s2, s3)))
)

class(pool)

## ----pool-workflow------------------------------------------------------------
pool_result <- workflow(
  pool,
  survey::svymean(~income, na.rm = TRUE),
  estimation_type = "annual"
)

pool_result

## ----pool-groups--------------------------------------------------------------
s4 <- make_survey("2023")
s5 <- make_survey("2023")
s6 <- make_survey("2023")

pool_semester <- PoolSurvey$new(
  list(annual = list(
    "q1" = list(s1, s2, s3),
    "q2" = list(s4, s5, s6)
  ))
)

result_semester <- workflow(
  pool_semester,
  survey::svymean(~income, na.rm = TRUE),
  estimation_type = "annual"
)

result_semester

## ----extract------------------------------------------------------------------
# Extract specific follow-ups by index
first_two <- extract_surveys(panel, index = 1:2)
class(first_two)

## ----time-patterns------------------------------------------------------------
# Extract periodicity from edition strings
extract_time_pattern("2023")
extract_time_pattern("2023-06")

## ----validate-time------------------------------------------------------------
# Validate edition format
validate_time_pattern(svy_type = "ech", svy_edition = "2023")

## ----group-dates--------------------------------------------------------------
# Group dates by period
dates <- as.Date(c(
  "2023-01-15", "2023-03-20", "2023-06-10",
  "2023-09-05", "2023-11-30"
))
group_dates(dates, type = "quarterly")
group_dates(dates, type = "biannual")

