# PACE-HRH-UI

In the rapidly evolving landscape of population health management, 
there is a critical and pressing need for tools that enable efficient capacity estimation, 
taking into account various dynamic factors such as population demographics, seasonal trends, 
and health-related tasks. 
To address this challenge, we introduce an open-source software designed to serve as 
a population-aware capacity estimator. 
This application offers users the ability to configure inputs related to 
population size, seasonal variations, and specific health tasks, 
thereby providing customized capacity planning solutions tailored to different regions and diverse needs.
<br><br>
PACE-HRH-UI is a shinyapp that encapulates the [PACE-HRH](https://github.com/InstituteforDiseaseModeling/PACE-HRH/releases) package
which employs stochastic simulation for capacity projections based on excel spreadsheets configurations, 
it offers users a friendly interface to visualization the input data and simulation results. 
Users can also download and coompare results from different run for further analysis. 


### Setup
Install the most recent version of the PACE-HRH-UI binary file from our [releases](https://github.com/InstituteforDiseaseModeling/PACE-HRH-UI/releases)


### Run the app locally 
In RStudio open `app.R` and click on "Run App". Alternatively you can launch the app from the RStudio console with the following: 
```
library(shiny)
runApp()
```

### Installation and Run on windows without Rstudio
To install the app in a separate environment: 
<br>
Run `install_pace_ui.bat` which will give you a step by step guide for installation and running the app
<br>


### Screenshots

- From Homepage you can start a new simulation from scrtach or use a previous run config to start.

![Home Page](./screenshots/1.homepage.png)


- Configure page for simulation paramaters.
![Configuration Page](./screenshots/2.configuration.png)

- Configure page for input data allow you to upload and preview custom data.
![Configuration Data](./screenshots/3.configure_data.png)

- Visualize your input data.
![Validation Page](./screenshots/4.validation.png)

- Run simulation page allow you set simulation iterations.
![Run simulation Page](./screenshots/5.Run_simulation.png)

- Check simulation logs for progress and potential issues.
![simulation Logs Page](./screenshots/6.Run_simulation_log.png)

- Visualize and download the pdf file.
![Download Pdf Data](./screenshots/7.result_compare.png)

- Download result files to your desktop and do your own analysis.
![Download result files Page](./screenshots/9.download_files.png)

        
        
      
     
       
