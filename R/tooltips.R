# Define text used for tooltips or descriptions

# Configuration Page

config_intro_str <- "Edit your key inputs here before you run the model,
  The model comes pre-populated with default values specific to your region, 
  but if you want to edit those, you can use the optional button at the bottom of this screen.
  
  If you would like to use your own configuration files, you can do so.
  This allows you to input different assumptions about your population pyramid, fertility and mortality rates, and specify a modified list of tasks and disease incidence rates.
  To do so, please see instructions from: https://github.com/InstituteforDiseaseModeling/PACE-HRH-UI/blob/main/Configuration.md.
  
"


# Validation Page

validation_intro_str <- "Validate that your data inputs are correct by reviewing these data summary plots. 
If you find something that does not look correct, navigate to the input Excel file in your project folder, update the values, save the file, and restart this application. The program will reload these input values and you can check again that they have been updated correctly.
The population pyramid represents the portion of the population that is of a particular age and gender at the start of the modeled timeframe, and should match your current local demographics. Fertility and mortality rates will determine how this population changes over time, and the values should match your current situation. Seasonality is applied to particular tasks performed by the health worker(s) and represents the changes in demand for healthcare throughout the year.

"

# Simulation Page

num_replication_str <- " Indicate how many replications (trials) that you want to run, More will be more accurate, 
but also require more time and larger data files. We recommend running between 100 and 1000.
"

