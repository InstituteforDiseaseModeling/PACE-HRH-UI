options(Ncpus = parallel::detectCores())

if (.Platform$OS.type == "unix") {
  type <- "source"
}else{
  type <- "binary"
}


pkgnames <- c(
'devtools', 'DT', 'shiny', 'shinyjs', 'shinyalert', 'shinyWidgets', 'shinythemes', 'shinycssloaders', 'plotly', 'truncnorm', 'shinyBS', 'openxlsx', 
'validate','readxl', 'dplyr','ggplot2', 'tidyr', 'kableExtra', 'stringr', 'plyr', 'reshape2', 'scales', 'glue', 'logr', 'tidyverse', 'showtext',
'treemapify', 'knitr', 'mockr', 'bsicons',
'shinytest2', 'uuid','ggrepel', 'assertthat'
)

print(paste0("Install Packages from Cran : ", pkgnames))
install.packages(pkgnames,
                 repos='http://cran.rstudio.com/',
                 type=type)

library(devtools)
# Install pacehrh package
install_github('InstituteforDiseaseModeling/PACE-HRH', 
               subdir='pacehrh',  
               ref ='2.0.0',
               force = TRUE, 
               dependencies = TRUE, 
               upgrade="never")


# Make sure packages are available
if (length(pkgnames[which (!pkgnames %in% installed.packages()[,'Package'])]) >0 ){
  cat(paste0("Package did not install correctly:", c(pkgnames[which (!pkgnames %in% installed.packages()[,'Package'])]), "\n"))
  stop("some packages are not available, please investigate...")
}