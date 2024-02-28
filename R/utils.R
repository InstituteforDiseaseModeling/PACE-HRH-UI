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

reload_config <- function(uid, base_config_file = NULL){
  # create a inputfile for the current user based on uid
  
  # region_list indicates there is region available so we need to clear it 
  if (file.exists(region_list)){
    file.remove(region_list)
  }
  
  # Only support region with default global config
  if (is.null(base_config_file)){
    base_config_file <- global_config_file
    if ("RegionSelect" %in% excel_sheets(base_config_file)){
      command = paste0("cd vbscript & cscript selectRegion.vbs ../",base_config_file)
      system(command ="cmd", input=command,  wait =TRUE)
    }
  }
  prefix <- unlist(strsplit(global_config_file, "\\."))[1]
  new_input_file <- paste0(prefix, "_", uid, ".xlsx")
  file.copy(base_config_file, new_input_file, overwrite = TRUE)
  return (new_input_file)
}

get_result_folders_dt <- function(){
  # Get the list of result folders containing config.xlsx
  folder_list <- list.files(path = result_root, pattern = "config.xlsx", recursive = TRUE, full.names = TRUE)
  # Extract folder names
  folder_names <- basename(dirname(folder_list))
  
  # Create a data frame to display in DT
  folder_df <- data.frame("run_name" = folder_names)
  return (folder_df)
  
}