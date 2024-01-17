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
config_url <- "https://github.com/InstituteforDiseaseModeling/PACE-HRH/blob/main/config/model_inputs_demo.xlsx"
config_file <- "config/model_inputs.xlsx"
content <- GET(config_url)
writeBin(content$content, config_file)
print(paste0("downloaded to ", config_file))

# pacehrh::SetInputExcelFile(config_file)
