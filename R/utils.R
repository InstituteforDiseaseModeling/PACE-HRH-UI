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
  if (is.null(base_config_file)){
    base_config_file <- global_config_file
  }
  # create a inputfile for the current user based on uid
  prefix <- unlist(strsplit(global_config_file, "\\."))[1]
  new_input_file <- paste0(prefix, "_", uid, ".xlsx")
  file.copy(base_config_file, new_input_file, overwrite = TRUE)
  return (new_input_file)
}

get_result_folders_dt <- function(names_to_filter = NULL){
  # Get the list of result folders containing config.xlsx
  folder_df <- NULL
  folder_list <- list.files(path = result_root, pattern = "config.xlsx", recursive = TRUE, full.names = TRUE)
  # Extract folder names
  folder_names <- basename(dirname(folder_list))
  if (!is.null(names_to_filter)){
    folder_names <- folder_names[folder_names %in% names_to_filter]
  }
  if (length(folder_names) > 0){
    # Create a data frame to display in DT
    folder_df <- data.frame("run_name" = folder_names)
  }
  return (folder_df)
}

zip_folders <- function(folders_to_zip){
  # Check if the folders exist
  existing_folders <- folders_to_zip[file.exists(folders_to_zip)]
  
  if (length(existing_folders) == 0) {
    cat("None of the specified folders exist.\n")
    return(NULL)
  }
  
  output_zip_file <- file.path(result_root, paste0("pacehrh_results_", format(Sys.Date(), "%Y-%m-%d"), "_", format(Sys.time(), "%H-%M-%S"), ".zip"))
  output_dir <- dirname(output_zip_file)
  if (!file.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  # Zip each folder separately into the final zip file
  zip(output_zip_file, files = unlist(
    lapply(existing_folders, 
          function(folder) {
            list.files(folder, recursive = TRUE, full.names = TRUE)
          }
        )
    )
  )
  print(paste0("Folders zipped successfully into", output_zip_file))
  return (output_zip_file)
}


