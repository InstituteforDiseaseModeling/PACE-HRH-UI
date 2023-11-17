library(uuid)

load_working_config <- function(){

  file_name <- "model_inputs.xlsx"
  
  # Use file.path to create the full file paths
  orig_file <- file.path("working_config", file_name)
  if(!exists(orig_file)){
    orig_file <- file.path("orig_config", file_name)
  }  

  new_file <- file.path("config", file_name)

  # Use file.copy to copy the file and replace if it already exists
  file.copy(orig_file, new_file, overwrite = TRUE)
  print("loaded working config")
  return(new_file)
}

reload_original_config <- function(){
  # Set the file paths for the original and new directories
 
  # Set the file name to copy
  file_name <- "model_inputs.xlsx"
  
  # Use file.path to create the full file paths
  orig_file <- file.path("orig_config", file_name)
  
  new_file <- file.path("config", file_name)
  
  # Use file.copy to copy the file and replace if it already exists
  file.copy(orig_file, new_file, overwrite = TRUE)
  print("reloaded original config file")
  return(new_file)
}