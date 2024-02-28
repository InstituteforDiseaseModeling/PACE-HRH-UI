# Function to estimate runtime statistics based on iterations
# TODO: determine the logic to estimate file size and run time
get_estimated_run_stats <- function (iteration){
  
  if (iteration >0 ){
    runtime <- iteration* 10
    expected_size <-  iteration
  }
  
  runtime <- ifelse(runtime >0 , runtime, "--:--:--")
  expected_size <- ifelse(expected_size >0 , expected_size, "--.--")
  
  result_text <- sprintf("Given your number of replications, This model will take %s seconds to run, 
                             The detail result files, if you choose to download them, will be approximately %s mb.", runtime, expected_size)
  result_text
}


run_pacehrh_simulation <- function(rv, input_file){
  
  new_rv <- list()
  loggerServer("logger", "Initializing Simulation")
  
  pacehrh::Trace(TRUE)
  pacehrh::SetInputExcelFile(rv$input_file)
  pacehrh::InitializePopulation()
  pacehrh::InitializeScenarios(loadFromExcel = FALSE)
  pacehrh::InitializeStochasticParameters()
  pacehrh::InitializeSeasonality()
  pacehrh::InitializeCadreRoles()
  pacehrh::SetRoundingLaw("Late")
  pacehrh::SetGlobalStartEndYears(start=rv$start_year, end=rv$end_year)
  
  e <- pacehrh:::GPE
  e$scenarios <- rv$scenarios_input
  
  results_dir <- file.path(result_root, rv$run_name)
  
  tryCatch({
    
    dir.create(file.path(results_dir), recursive = TRUE)
    print(paste0("result will be saved to:", results_dir))

    
    results <- list()
    scenario_name <- e$scenarios$UniqueID[1]
    
    loggerServer("logger", paste0("Running scenario > ", scenario_name))
    loggerServer("logger", paste0(" Catchment Pop > ",e$scenarios$BaselinePop))
    loggerServer("logger", paste0(" Hrs Per Week > ",e$scenarios$HrsPerWeek))
    loggerServer("logger", paste0(" Max Utilization > ",e$scenarios$MaxUtilization))
    
    result <- pacehrh::RunExperiments(scenarioName = scenario_name,
                                      trials = rv$trial_num,
                                      debug = FALSE)
    # extract population predictions of the model
    popsummary <- SaveSuiteDemographics(result) %>%
      pivot_longer(c("Female", "Male"), names_to ="Gender", values_to = "Population")
    
    # extract fertility rates predictions of the model
    fertilityrates <- GetSuiteRates(result, "femaleFertility")
    
    results[[scenario_name]] <- result
    
    #save simulation results to csv files, by scenario
    filename <- file.path(results_dir, "results.csv")
    pacehrh::SaveSuiteResults(result, filename, scenario_name, 1)
    loggerServer("logger", paste0("Saving result: ", filename) )
    
    # extract task-level simulation results
    SR <- pacehrh::SaveExtendedSuiteResults(result)
    # extract task-level service time allocation to cadre
    CA <- pacehrh::SaveCadreAllocations(SR)
    SS <- pacehrh::ComputeSummaryStats(SR, CA)
    
    new_rv$results <- results
    new_rv$popsummary <- popsummary
    new_rv$fertilityrates <- fertilityrates
    new_rv$summarystats  <- SS
    
    new_rv$Mean_ServiceCat <- SS$Mean_ServiceCat %>%
      inner_join(e$scenarios, by= c("Scenario_ID" = "UniqueID")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Mean_MonthlyTask <- SS$Mean_AnnualTask %>%
      inner_join(e$scenarios, by=c("Scenario_ID" = "UniqueID")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Stats_TotClin <- SS$Stats_TotClin %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Mean_ClinCat <- SS$Mean_ClinCat %>%
      inner_join(e$scenarios, by=c("Scenario_ID"="UniqueID", "WeeksPerYr")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Mean_Total <- SS$Mean_Total %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Stats_ClinMonth <- SS$Stats_ClinMonth %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$ByRun_ClinMonth <- SS$ByRun_ClinMonth %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name)
    
    new_rv$Mean_Alloc <- SS$Mean_Alloc %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr")) %>%
      mutate(test_name = rv$run_name)
    
    loggerServer("logger", paste0("Saving Mean_ServiceCat to : ", file.path(results_dir, "Mean_ServiceCat.csv")))
    write.csv(new_rv$Mean_ServiceCat,file.path(results_dir, "Mean_ServiceCat.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving to Stats_TotClin: ", file.path(results_dir, "Stats_TotClin.csv")))
    write.csv(new_rv$Stats_TotClin, file.path(results_dir, "Stats_TotClin.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving Mean_ClinCat to : ", file.path(results_dir, "Mean_ClinCat.csv")))
    write.csv(new_rv$Mean_ClinCat, file.path(results_dir, "Mean_ClinCat.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving Mean_Total to : ", file.path(results_dir, "Mean_Total.csv")))
    write.csv(new_rv$Mean_Total, file.path(results_dir, "Mean_Total.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving Stats_ClinMonth to : ", file.path(results_dir, "Stats_ClinMonth.csv")))
    write.csv(new_rv$Stats_ClinMonth, file.path(results_dir, "Stats_ClinMonth.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving ByRun_ClinMonth to : ", file.path(results_dir, "ByRun_ClinMonth.csv")))
    write.csv(new_rv$ByRun_ClinMonth, file.path(results_dir, "ByRun_ClinMonth.csv"), row.names = FALSE)
    
    loggerServer("logger", paste0("Saving Mean_Alloc to : ", file.path(results_dir, "Mean_Alloc.csv")))
    write.csv(new_rv$Mean_Alloc, file.path(results_dir, "Mean_Alloc.csv"), row.names = FALSE)
    
    save_config_file <- file.path(results_dir, "config.xlsx")
    loggerServer("logger", paste0("Saving config file to : ", save_config_file))
    file.copy(input_file, save_config_file, overwrite = TRUE)
    wb <- loadWorkbook(save_config_file)
    
    # Remove region info as the sheet may have been modified
    tryCatch({
      wb <- removeWorksheet(wb, "RegionSelect")
      saveWorkbook(wb, save_config_file)
      }, error=function(e){
        loggerServer("logger", paste0("No region available: ", e$message))
    })
    
  }, error=function(e){
    loggerServer("logger", paste0("Run failed: ", e$message))
    loggerServer("logger", paste0("Please attach the log when reporting the error"), close=TRUE)
    unlink(file.path(results_dir), recursive = TRUE)
    new_rv = NULL
  })
  return(new_rv)
}
