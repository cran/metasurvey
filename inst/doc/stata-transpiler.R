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
# # Write the example do-file to a temp location
# # Note: STATA macros use backtick-quote (`var') which we build with paste0
# bt <- "`" # backtick
# sq <- "'" # single quote
# do_lines <- c(
#   "rename id hh_id",
#   "rename nper person_id",
#   "gen weight_yr = pesoano",
#   "gen weight_qt = pesotri",
#   "gen sex = q01",
#   "g relationship = -9",
#   "replace relationship = 1 if q05 == 1",
#   "replace relationship = 2 if q05 == 2",
#   "replace relationship = 3 if inrange(q05, 3, 5)",
#   "replace relationship = 4 if q05 == 6",
#   "replace relationship = 5 if q05 == 7",
#   "gen area = .",
#   "replace area = 1 if region == 1",
#   "replace area = 2 if region == 2",
#   "replace area = 3 if region == 3",
#   "recode q20 (2=2) (3=-9) (4=3) (5=4), gen(edu_compat)",
#   "bysort hh_id: egen max_age = max(edad)",
#   "bysort hh_id: egen n_members = count(person_id)",
#   "foreach i of numlist 1/3 {",
#   paste0("gen contrib", bt, "i", sq, " = 0"),
#   paste0("replace contrib", bt, "i", sq, " = amount if provider == ", bt, "i", sq),
#   "}",
#   "mvencode contrib1 contrib2 contrib3, mv(0)",
#   "drop region q01 q05 q20",
#   'lab var sex "Sex"',
#   'lab var relationship "Relationship to household head"',
#   'lab def sex_lbl 1 "Male" 2 "Female"',
#   "lab val sex sex_lbl",
#   'lab def rel_lbl 1 "Head" 2 "Spouse" 3 "Child" 4 "Other relative" 5 "Non-relative"',
#   "lab val relationship rel_lbl"
# )
# do_file <- tempfile(fileext = ".do")
# writeLines(do_lines, do_file)
# 
# result <- transpile_stata(do_file)

## -----------------------------------------------------------------------------
# cat("Translated:", result$stats$translated, "\n")
# cat("Skipped:   ", result$stats$skipped, "\n")
# cat("Manual:    ", result$stats$manual_review, "\n")

## -----------------------------------------------------------------------------
# # Print the generated steps
# for (s in result$steps) cat(s, "\n")

## -----------------------------------------------------------------------------
# str(result$labels$var_labels)
# str(result$labels$val_labels)

