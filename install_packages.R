options(Ncpus = parallel::detectCores())

pkgnames <- c(
'devtools', 'DT', 'shiny', 'shinyjs', 'shinyalert', 'shinyWidgets', 'shinythemes', 'shinycssloaders', 'plotly', 'truncnorm', 'shinyBS', 'openxlsx', 
'validate','readxl', 'dplyr','ggplot2', 'tidyr', 'kableExtra', 'stringr', 'plyr', 'reshape2', 'scales', 'glue', 'logr', 'tidyverse', 'showtext',
'treemapify', 'ggrepel', 'knitr', 'mockr',
'shinytest2', 'uuid'
)

print(paste0("Install Packages from Cran : ", pkgnames))
install.packages(pkgnames,
                 repos='http://cran.rstudio.com/')

# Make sure packages are available
if (length(pkgnames[which (!pkgnames %in% installed.packages()[,'Package'])]) >0 ){
  cat(paste0("Package did not install correctly:", c(pkgnames[which (!pkgnames %in% installed.packages()[,'Package'])]), "\n"))
  stop("some packages are not available, please investigate...")
}