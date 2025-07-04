
# visit cohorts -----
cdm$inpatient <- conceptCohort(
  cdm = cdm,
  conceptSet = list(inpatient = c(9201, 262, 9203)),
  name = "inpatient"
)

# high cost drug cohorts -----
cli::cli_inform("Creating high cost medicines cohorts")
drug_codes <- importCodelist(path = here("cohorts", "drug_codelists"), type = "csv")
cdm$high_cost_meds <- conceptCohort(cdm, 
                                    conceptSet = drug_codes, 
                                    name = "high_cost_meds", 
                                    exit = "event_end_date")
# all records in study period
cdm$high_cost_meds_all <- cdm$high_cost_meds |> 
  requireInDateRange(dateRange = study_period, 
                     name = "high_cost_meds_all")
attr(cdm$high_cost_meds_all, "cohort_set") <- attr(cdm$high_cost_meds_all, "cohort_set") |> 
  mutate(cohort_name = paste0(cohort_name, "_all"))

# keep first ever and in study period
cdm$high_cost_meds_first <- cdm$high_cost_meds |> 
  requireIsFirstEntry(name = "high_cost_meds_first") |> 
  requireInDateRange(dateRange = study_period,
                     name = "high_cost_meds_first")
attr(cdm$high_cost_meds_first, "cohort_set") <- attr(cdm$high_cost_meds_first, "cohort_set") |> 
  mutate(cohort_name = paste0(cohort_name, "_first"))

cdm <- bind(cdm$high_cost_meds_all, cdm$high_cost_meds_first,
     name = "high_cost_meds")
dropSourceTable(cdm,
                c("high_cost_meds_all", "high_cost_meds_first"))

# require at least 
cdm$high_cost_meds <- cdm$high_cost_meds |> 
  requireMinCohortCount(minCohortCount =  min_cell_count)
# remove cohorts with zero counts
high_cost_meds_with_count <- cohortCount(cdm$high_cost_meds) |>
  filter(number_subjects > 0) |> 
  dplyr::pull("cohort_definition_id")
if(length(high_cost_meds_with_count) > 0){
  cdm$high_cost_meds <- subsetCohorts(cdm$high_cost_meds,
                                      cohortId = high_cost_meds_with_count, 
                                      name = "high_cost_meds")
} 
if(length(high_cost_meds_with_count) == 0){
  cli::cli_abort("All high cost drugs cohorts are empty")
}

# icd cohorts ----
cli::cli_inform("Creating ICD cohorts")
icd_codes <- importCodelist(path = here("cohorts", "icd"), type = "csv")
cdm$icd <- conceptCohort(cdm, 
                         conceptSet = icd_codes, 
                         name = "icd", 
                         exit = "event_start_date",
                         subsetCohort = "high_cost_meds")
# remove cohorts with zero counts
icd_with_count <- cohortCount(cdm$icd) |>
  filter(number_subjects > 0) |> 
  dplyr::pull("cohort_definition_id")
if(length(icd_with_count) > 0){
  cdm$icd <- subsetCohorts(cdm$icd,
                           cohortId = icd_with_count, 
                           name = "icd")
}

# procedure cohorts ----
cli::cli_inform("Creating ICD cohorts")
procedure_codes <- importCodelist(path = here("cohorts", "procedures"), type = "csv")
cdm$procedures <- conceptCohort(cdm, 
                         conceptSet = icd_codes, 
                         name = "procedures", 
                         exit = "event_start_date",
                         subsetCohort = "high_cost_meds")
# remove cohorts with zero counts
procedures_with_count <- cohortCount(cdm$procedures) |>
  filter(number_subjects > 0) |> 
  dplyr::pull("cohort_definition_id")
if(length(procedures_with_count) > 0){
  cdm$procedures <- subsetCohorts(cdm$procedures,
                           cohortId = procedures_with_count, 
                           name = "procedures")
}
