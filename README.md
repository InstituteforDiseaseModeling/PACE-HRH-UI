# PACE-HRH-UI

A shiny app for the pacehrh package. 

## Local Development 
Note: the following instructions work best when used with RStudio. 
### Clone the repository 

```
git clone git@github.com:InstituteforDiseaseModeling/PACE-HRH-UI.git
```
### Open the project 
Double-click the .Rproj file to launch the project in RStudio. 

### Setup environment 

#### Install PACE-HRH
Install the most recent version of the PACE-HRH package binary file from the [releases page](https://github.com/InstituteforDiseaseModeling/PACE-HRH/releases)

#### Install required packages
```
install.packages('devtools', repos='http://cran.rstudio.com/')
devtools::install_github('trestletech/shinyStore')
devtools::install_github('statistikat/codeModules')
install.packages('shiny', repos='http://cran.rstudio.com/')
install.packages('shinyWidgets', repos='http://cran.rstudio.com/')
install.packages('shinythemes', repos='http://cran.rstudio.com/')
install.packages('shinycssloaders', repos='http://cran.rstudio.com/')
install.packages('plotly', repos='http://cran.rstudio.com/')
install.packages('truncnorm', repos='http://cran.rstudio.com/')
install.packages('shinyBS', repos='http://cran.rstudio.com/')
install.packages('openxlsx', repos='http://cran.rstudio.com/')
```

#### Note:
You might need to turn off Warp by cloudflare in order to install packaes from GitHub

### Run the app locally 
In RStudio open `app.R` and click on "Run App". Alternatively you can launch the app from the RStudio console with the following: 
```
library(shiny)
runApp()
```

### Docker
To run the app in a docker container run the following: 
```
docker-compose down
docker-compose build
docker-compose up
```

#### Note:
You might need to turn off Warp by cloudflare during the image build in order to install packages from GitHub

### Testing
Run the following to run tests defined in the `tests` directory: 
```
shiny::runTests()
```
where `path` is the parent directory of `tests`-- if `tests` directory 
is located in the project root, you do not need to pass anything to 
`runTests()`. 

### Updating / adding packages

After installing additional packages or upgrading/downgrading existing packages, update the `Dockerfile` to record the current dependencies. 
