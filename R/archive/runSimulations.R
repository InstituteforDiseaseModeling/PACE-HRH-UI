library(pacehrh)
library(tidyr)

run_pacehrh_simulation <- function(scenarios, num_trials, year_range, input_file=NULL){
  

  
  rv <- list()
  rv$start_year <- year_range[[1]]
  rv$end_year <- year_range[[2]]
  
  loggerServer("logger", "Initializing", three_dots=T)
  
  pacehrh::Trace(TRUE)
  pacehrh::InitializePopulation()
  pacehrh::InitializeScenarios(loadFromExcel = FALSE)
  pacehrh::InitializeStochasticParameters()
  pacehrh::InitializeSeasonality()
  pacehrh::SetRoundingLaw("Late")
  pacehrh::SetGlobalStartEndYears(start=rv$start_year, end=rv$end_year)
  
  e <- pacehrh:::GPE
  e$scenarios <- scenarios
  
  results_dir <- tempdir()
  print(results_dir)
  date <- Sys.Date()
  usefuldescription <- "demo"
  
  results <- list()
  scenario_names <- c()
  results_files <- c()
  
  for (i in 1:nrow(e$scenarios)) {
    scenario_name <- e$scenarios$UniqueID[i]
    
    loggerServer("logger", paste0("Running scenario > ", scenario_name) )
    result <- pacehrh::RunExperiments(scenarioName = scenario_name,
                                      trials = num_trials,
                                      debug = FALSE)
    
    # extract population predictions of the model
    resultspop <- SaveSuiteDemographics(result) %>%
      pivot_longer(c("Female", "Male"), names_to ="Gender", values_to = "Population") %>%
      mutate(Scenario_ID = scenarios$UniqueID[i])
    if(!exists('popsummary')){
      popsummary <- resultspop
    }else{
      popsummary <- rbind(popsummary,resultspop)
    }
    # extract fertility rates predictions of the model
    resultsrates <- GetSuiteRates(result, "femaleFertility") %>%
      mutate(Scenario_ID = scenarios$UniqueID[i])
    if(!exists('fertilityrates')){
      fertilityrates <- resultsrates
    }else{
      fertilityrates <- rbind(fertilityrates,resultsrates)
    }
    
    scenario_names <- c(scenario_names, scenario_name)
    results[[scenario_name]] <- result
    
    #save simulation results to csv files, by scenario
    filename_pattern <- paste("results", usefuldescription, scenario_name, date, sep = "_")
    filename <- tempfile(pattern = filename_pattern, tmpdir = results_dir, fileext = ".csv")
    results_files <- c(results_files, filename)
    pacehrh::SaveSuiteResults(result, filename, scenario_name, 1)
    
  }
  rv$scenario_names <- scenario_names
  rv$results <- results
  rv$popsummary <- popsummary
  rv$fertilityrates <- fertilityrates
  
  loggerServer("logger", "Reading and collating result", three_dots=TRUE)
  DR_test <- pacehrh::ReadAndCollateSuiteResults(files = results_files, preProcFunc = \(x)x)
  
  loggerServer("logger", "Computing Cadre allocation", three_dots=TRUE)
  CA <- pacehrh:::ComputeCadreAllocations(DR_test)
  
  loggerServer("logger", "Computing summary stats", three_dots=TRUE)
  SS <- pacehrh:::ComputeSummaryStats(DR_test, CA)
 
  loggerServer("logger", "Attaching scenario details", three_dots=TRUE)
  rv$Mean_ServiceCat <- SS$Mean_ServiceCat %>%
    inner_join(e$scenarios, by= c("Scenario_ID" = "UniqueID"))
  rv$Mean_MonthlyTask <- SS$Mean_AnnualTask %>% 
    inner_join(e$scenarios, by=c("Scenario_ID" = "UniqueID"))
  rv$Stats_TotClin <- SS$Stats_TotClin %>%
    inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek"))
  rv$Mean_ClinCat <- SS$Mean_ClinCat %>%
    inner_join(e$scenarios, by=c("Scenario_ID"="UniqueID", "WeeksPerYr"))
  rv$Mean_Total <- SS$Mean_Total %>%
    inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek"))
  rv$Stats_ClinMonth <- SS$Stats_ClinMonth %>%
    inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek"))
  rv$ByRun_ClinMonth <- SS$ByRun_ClinMonth %>% 
    inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr", "HrsPerWeek"))
  rv$Mean_Alloc <- SS$Mean_Alloc %>%
    inner_join(e$scenarios, by= c("Scenario_ID"="UniqueID", "WeeksPerYr"))
  
  
  loggerServer("logger", "Cleaning up temporary result files", three_dots=TRUE)
  for (file in results_files){
    file.remove(file)
  }
  loggerServer("logger", "Done")
  
  return(rv)
}