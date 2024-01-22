library(desc)
library(httr)
library(pacehrh)

# parse DESCRIPTION file 
desc_content <- description$new()
project_info <- desc_content[[".__enclos_env__"]][["private"]][["data"]]
project_title <- project_info[["Title"]][["value"]]
project_description <- project_info[["Description"]][["value"]]

our_license_text <- paste (project_title,
                           project_info[["OurLicenseText"]][["value"]], sep=" ")

our_license_link <- project_info[["OurLicenseLink"]][["value"]]

# download sample config
print("download sample config...")
config_url <- "https://raw.githubusercontent.com/InstituteforDiseaseModeling/PACE-HRH/main/config/model_inputs_demo.xlsx"
config_file <- "config/model_inputs_demo.xlsx"
content <- GET(config_url)

content_type <- headers(content)[["content-type"]]

# Decide how to save based on content type
if (grepl("zip", content_type, fixed = TRUE)) {
  # unzip to xlsx
  writeBin(content$content, paste0(config_file, ".zip"))
  print(paste0("downloaded to ", paste0(config_file, ".zip")))
  unzip(paste0(config_file, ".zip"), exdir = "config")
  # unzip this file to get the Excel document
} else {
  writeBin(content$content, config_file)
} 

input_file <- "config/model_inputs_user.xlsx"
# pacehrh::SetInputExcelFile(config_file)
