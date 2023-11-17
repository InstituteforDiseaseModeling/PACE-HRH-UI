library("rjson")
library("rvest")

dependencies <- unique(renv::dependencies()['Package'])
packages_order <- order(dependencies$Package)
lock <- fromJSON(file="renv.lock")
lock_packages <- lock$Packages

#construct libraries dataframe
libraries <- data.frame(
  package = character(),
  version = character(),
  license = character(),
  package_url = character()
)

update_licenses_info <- function(){
  for( i in 1:length(packages_order)){
    package_index <- packages_order[i]
    package_name <- dependencies[[package_index,'Package']]
    package_info <- lock_packages[package_name]
    version <- package_info[[package_name]]$Version
    if (is.null(package_name) || 
        is.na(package_name) || 
        toupper(package_name) == "NA" ) next
    if (package_name == "tools") next
    #perform scraping 
    cran_url <- ""
    package_url <- ""
    license <- ""
    if (package_name == "renv" || 
        (package_info[[package_name]]$Source == "Repository" && 
        package_info[[package_name]]$Repository == "CRAN")) {
      cran_url <- paste("https://CRAN.R-project.org/package=",
                        package_name, sep="")
      
      tables <- read_html(cran_url) %>% html_elements("table")
      package_info_table <- tables[1] %>% html_table()
      package_info_table <- package_info_table[[1]]
      for( j in 1:nrow(package_info_table)){
        key = package_info_table[[j,1]]
        if (key == "License:"){
          license <- paste(license,package_info_table[[j,2]], sep = "")
        } else if (key == "URL:"){
          package_url <- paste(package_url, package_info_table[[j,2]], sep = "")
        }
      }
    }

    
    row <- c(package_name, version, license, package_url)
    libraries[i,] <- row
  }
  write.csv(libraries, 'licenses_info.csv',row.names = F)
  
}


update_licenses_info()
