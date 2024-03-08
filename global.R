library(desc)
library(httr)
library(pacehrh)
library(readxl)
library(openxlsx)
library(tidyr)

options(devtools.upgrade = "never")

# parse DESCRIPTION file 
desc_content <- description$new()
project_info <- desc_content[[".__enclos_env__"]][["private"]][["data"]]
project_title <- project_info[["Title"]][["value"]]
project_description <- project_info[["Description"]][["value"]]

our_license_text <- paste (project_title,
                           project_info[["OurLicenseText"]][["value"]], sep=" ")

our_license_link <- project_info[["OurLicenseLink"]][["value"]]

# Install pacehrh package
if (!requireNamespace("pacehrh", quietly = TRUE)) {
  devtools::install_github('InstituteforDiseaseModeling/PACE-HRH', 
                           subdir='pacehrh',  
                           force = TRUE, 
                           dependencies = TRUE)
}

# download sample config
global_config_file <- "config/model_inputs_demo.xlsx"
if (!file.exists(global_config_file)){
  print("download sample config...")
  config_url <- "https://raw.githubusercontent.com/InstituteforDiseaseModeling/PACE-HRH/main/config/model_inputs_demo.xlsx"
  content <- GET(config_url)
  
  content_type <- headers(content)[["content-type"]]
  
  # Decide how to save based on content type
  if (grepl("zip", content_type, fixed = TRUE)) {
    # unzip to xlsx
    writeBin(content$content, paste0(global_config_file, ".zip"))
    print(paste0("downloaded to ", paste0(global_config_file, ".zip")))
    unzip(paste0(global_config_file, ".zip"), exdir = "config")
    # unzip this file to get the Excel document
  } else {
    writeBin(content$content, global_config_file)
  }
}

# Preload population options

preload_pop_files <- list.files("config/population", full.names = TRUE)
preload_pop_list <- setNames(preload_pop_files, gsub(".csv","", gsub("_", " ", basename(preload_pop_files))))

# Preload Region if available

has_region <- FALSE
region_config_files  <- NULL
region_folder = "config/region"
region_dirs <- list.dirs(region_folder, recursive = FALSE)
region_config_files <- lapply(region_dirs, function(x) {
  f <- list.files(x, full.names = TRUE, pattern = "*.xlsx")
  f <- f[file.exists(f)]
  return(f)
})
names(region_config_files) <- basename(region_dirs)
region_config_files[["ethiopia"]] <- global_config_file


result_root <- "pace_results"
show_log <- FALSE

