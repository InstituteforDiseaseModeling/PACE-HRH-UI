# Configuration Structure

This document outlines the structure of the configuration directory used in PACE-HRH-UI. The configuration settings are crucial for ensuring the application runs with the correct parameters tailored for different population, cadre roles and regions.

## Directory Overview

The configuration files are organized within a directory named `config`. This directory contains various subfolders and files that define the simulation parameters of the application. Below is a detailed description of these components:

### Config Folder

The `config` folder serves as the central repository for all configuration-related files. The default setting is using `model_inputs_demo.xlsx` If you wish to change the file name, please also modify [global.R Line 23](https://github.com/InstituteforDiseaseModeling/PACE-HRH-UI/blob/main/global.R#L23) <br>
An example folder structure may look like this:<br>

```
config/
│
├── population/ # Folder containing population data that can be selected from the app
│
├── region/ # Folder containing config files with region-specific data
│
└── model_inputs_demo.xlsx # Excel file with default model input 
```

#### Population Subfolder

You should create CSV files with following required column names, for example:

| Age  | Male | Female | Total |
|------|------|--------|-------|
| <1   |  120 |  110   |  230  |
| 1    |  130 |  125   |  255  |
| 2    |  140 |  135   |  275  |
| 3    |  150 |  145   |  295  |



These files represent the population pyramid of a region and will be available for the users to select in the configuration step.

#### Region Subfolder

A complete configuration file with regional specific data is required for each region. The folder name will be loaded in the `region` dropdown of the configuration page if a valid configuration file with .xlsx extension is present in the folder. You can use the default configuration file  `model_inputs_demo.xlsx` as a template to create a new one and update with your own dataset.  You can learn more details for rules required for each sheet in: [Configuration Details](https://institutefordiseasemodeling.github.io/PACE-HRH/articles/pacehrh.html#configure-the-model). Currently for simplicity, we only allow one scenario in the configuration file.


### Notes
The application allows users to select configuration from "previous run" and use it for subsequent simulation. However, the original region setting will NOT be preserved for previous runs as users' change were not validated for the region. As a maintainer, it is your responsibility to ensure that validated data are added to the `region` folder that serve as a template for users to select from.


