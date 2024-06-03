# Function to estimate runtime statistics based on iterations
# TODO: determine the logic to estimate file size and run time
get_estimated_run_stats <- function (iterations, num_tasks, num_years){
  
  #Function to generate scaling ratio
  run_benchmark = function(n=200){
    
    reference <- 0.09344006 # Time in seconds that a fast computer takes to run this benchmark 
    
    #Start timing
    start <- Sys.time() 
    matrix_a <- matrix(rnorm(n*1000),nrow=n, ncol=1000)
    # Perform the big computation 
    result <- t(matrix_a) %*% matrix_a
    timeelapsed <- Sys.time() - start # Stop timing
    
    ratio <- as.numeric(timeelapsed) / reference
    
    return(ratio)
  }
  
  scalingratio <- run_benchmark() * 1.10
  
  runtime= -18.51 + .03955 * iterations + .9659 * num_years + .2366 * num_tasks
  runtime = runtime * scalingratio
  runtime = max(round(runtime / 60), 1)
  
  expected_size = -12740 + 18.29 *iterations + 390.5 * num_years + 296.7 * num_tasks
  expected_size = max(round(expected_size), 3) 
  
  
  runtime <- ifelse(runtime >0 , runtime, "--:--:--")
  expected_size <- ifelse(expected_size >0 , expected_size, "--.--")
  
  result_text <- sprintf("Given your number of replications, This run time may take up to %s minutes to complete, 
                             The detailed result files, if you choose to download them, will be approximately %s KB.", runtime, expected_size)
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
    
    cadreOverheadHrs <- pacehrh::SaveCadreOverheadData(filepath = file.path(results_dir, "cadre_overhead.csv"))
    cadreOverheadHrs$Year = as.integer(cadreOverheadHrs$Year)
    AnnualOverheadTime <- cadreOverheadHrs %>% 
      group_by(Scenario_ID, Year) %>% 
      dplyr::summarise(CI05 = sum(OverheadTime), 
                       CI25 = sum(OverheadTime), 
                       MeanHrs = sum(OverheadTime),
                       CI75 = sum(OverheadTime), 
                       CI95 = sum(OverheadTime)) %>% 
      dplyr::mutate(ClinicalOrNon = "Overhead", ClinicalCat = "-") %>% 
      filter(Year>=rv$start_year & Year<=rv$end_year)
    
    
    
    new_rv$Mean_ServiceCat <- SS$Mean_ServiceCat %>%
      inner_join(e$scenarios, by= c("Scenario_ID" = "UniqueID")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Mean_MonthlyTask <- SS$Mean_AnnualTask %>%
      inner_join(e$scenarios, by=c("Scenario_ID" = "UniqueID")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Stats_TotClin <- SS$Stats_TotClin %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Mean_ClinCat <- SS$Mean_ClinCat %>%
      select(-WeeksPerYr) %>% 
      rbind(AnnualOverheadTime) %>%
      inner_join(e$scenarios, by=c("Scenario_ID"="UniqueID")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Mean_Total <- SS$Mean_Total %>%
      select(-WeeksPerYr, -HrsPerWeek) %>% 
      rbind(AnnualOverheadTime[,1:7]) %>% 
      group_by(Scenario_ID, Year) %>% 
      dplyr::summarise(CI05 = sum(CI05),
                       CI25 = sum(CI25),
                       MeanHrs = sum(MeanHrs),
                       CI75 = sum(CI75),
                       CI95 = sum(CI95)) %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Stats_ClinMonth <- SS$Stats_ClinMonth %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$ByRun_ClinMonth <- SS$ByRun_ClinMonth %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
    new_rv$Mean_Alloc <- SS$Mean_Alloc %>%
      separate(col = Cadre,into =  c("Role_ID", "suffix"), sep = "_", remove = FALSE) %>% 
      left_join(cadreOverheadHrs, by = c("Scenario_ID","Role_ID", "Year")) %>% 
      left_join(rv$cadreroles, by = c("Scenario_ID"="ScenarioID", "Role_ID"="RoleID")) %>% 
      group_by(Scenario_ID, Year, RoleDescription) %>% 
      dplyr::summarise(CI05 = sum(CI05+OverheadTime), 
                       CI25 = sum(CI25+OverheadTime), 
                       CI50 = sum(CI50+OverheadTime), 
                       CI75 = sum(CI75+OverheadTime), 
                       CI95 = sum(CI95+OverheadTime)) %>%
      inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID")) %>%
      mutate(test_name = rv$run_name, region=rv$region)
    
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
    
    loggerServer("logger", paste0("Saving run info to : ", file.path(results_dir, "info.txt")))
    writeLines(rv$run_info, file.path(results_dir, "info.txt"))
    
  }, error=function(e){
    loggerServer("logger", paste0("Run failed: ", e$message))
    loggerServer("logger", paste0("Please attach the log when reporting the error"))
    unlink(file.path(results_dir), recursive = TRUE)
    new_rv = NULL
  })
  return(new_rv)
}
