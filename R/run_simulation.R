config_intro_str <- "Edit your key inputs here before you run the model,
  The model comes pre-populated with default valuesspecific to your region, 
  but if you want to edit those, you can use the optional button at the bottom of this screen.
  "

num_replication_str <- " Indicate how many replications (trials) that you want to run, More will be more accurate, 
but also require more time and larger data files. We recommend running between 100 and 1000.
"

sim_pages<- c("Configuration", "Input Validation", "Run Simulation", "View Results")

# Simulation steps

sim_tabs <- function(ns){
  tabsetPanel(
  id = ns("simulation_steps"),
  type = "hidden",
  tabPanel(sim_pages[1],
           fluidRow(
             column(12, 
                    h5(config_intro_str)
             ),
           ),
           fluidRow(
             column(6,
                    numericInput(ns("start_year"), "Start Year", 2020, min=2000, max=2040)      
             ),
             column(6,
                    numericInput(ns("catchment_pop"), "Catchment Pop", 10000, min=1000, max=100000)      
             ),
             
           ),
           fluidRow(
             column(6,
                    numericInput(ns("end_year"), "End Year", 2040, min =2000, max=2090)      
             ),
             column(6,
                    numericInput(ns("hrs_wk"), "Hours worked per week", 40, min=1, max = 60)      
             )
             
           ),
           fluidRow(
             column(6,
                    textInput(ns("region"), "Region")      
             ),
             column(6,
                    textInput(ns("hrh_utilization"), "Target HRH utilization")      
             )
           ),
           fluidRow(
             column(6, 
                    actionButton(ns("optional_params"), "Other Inputs (Optional)")
             )
           )
  ),
  tabPanel(sim_pages[2], 
           tabsetPanel(
             id ="validation",
             plotTabUI(id = ns("population-tab"),
                       title = "Population Pyramid"),
             plotTabUI(id = ns("fertility-tab"),
                       title = "Fertility Rates"),
             plotTabUI(id = ns("mortality-tab"),
                       title = "Mortality Rates"),
             plotTabUI(id = ns("disease-tab"),
                       title = "Disease Incidence"),
           )
  ),
  tabPanel(sim_pages[3], 
           fluidRow(column(12, h5(num_replication_str))
           ),
           fluidRow(column(6, offset= 3,  numericInput(ns("num_trials"), "Number of Replications:", 100))
           ),
           fluidRow(column(6, offset = 3, actionButton(ns("run_simBtn"), "Run Simulations"))
           ),
           fluidRow(
             column(12,  HTML("<br><br><br><br><br><br><br><br><br><br>"))
           )
  
  ),
  tabPanel(sim_pages[4], 
           fluidRow(
             column(4, actionButton(ns("print_summaryBtn"), "Print PDF of Summary Plots"), ), 
             column(4, offset=2, actionButton(ns("save_resultsBtn"), "Save Results for later comparison"))
           ),
           fluidRow(
             column(12, HTML("<br><br>"))
           ),
           fluidRow(
             column(4, downloadButton(ns("download_resultsBtn"), "Download Results (.csv)")), 
             column(4, offset=2, actionButton(ns("compareBtn"), "Select Previous runs to compare"))
           ),
           fluidRow(
             column(12,  HTML("<br><br><br><br><br><br><br><br><br><br>"))
           )
  )
)}

# UI for the run simulation module

runSimulationUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    shinyjs::useShinyjs(),
    
      fluidRow(
        column(12,uiOutput(ns("step_title")))
      ),
      
      fluidRow(
        column(12, sim_tabs(ns = ns)),
      ),
    
      # fluidRow(column(12, HTML("<br><br>"))
      # ),
      
      fluidRow(
        column(2, hidden(div(id = ns("prevDiv"), 
                             actionButton(ns("prevBtn"), "Previous"), align="right"))),
        column(8, HTML("<br>")),
        column(2, div(id = ns("nextDiv"), 
                      actionButton(ns("nextBtn"), "Next"), align="right")),
      ),
      
      fluidRow(column(12, HTML("<br>"))
      ),
    
      fluidRow(
        column(3, offset=9, div(id=ns("skipAll"), actionButton(ns("skipBtn"), "Skip To Run Simulation"), align="center"))
      )
    )
}

runSimulationServer <- function(id, config_file, store = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    ### initialize the page to configuration
    rv <- reactiveValues(page = 1)
    output$step_title <- renderUI({
      HTML(paste0("<h2>", sim_pages[rv$page], "</h2>"))
    })

    ### handle conditional button appearance
    observe({
      hide("prevDiv")
      hide("nextDiv")
      show("skipAll")
      if(rv$page > 1){
        show("prevDiv")
      }
      if(rv$page < length(sim_pages)){
        show("nextDiv")
      }
      if(rv$page >= which(sim_pages == "Run Simulation")){
        hide("skipAll")
      }
    })

    ### navigate Page to the corresponding UI
    navPage <- function(direction, sim=FALSE) {
      if (sim){
        # go to sim Page 
        sim_index <- which(sim_pages == "Run Simulation")
        print(sim_index)
        rv$page <- sim_index
      }
      else{
        rv$page <- rv$page + direction
      }
      if (rv$page >0 & rv$page <= length(sim_pages)){
        print(paste0("Select ", sim_pages[rv$page]))
        output$step_title <- renderUI({
          HTML(paste0("<h2>", sim_pages[rv$page], "</h2>"))
        })
        updateTabsetPanel(inputId = "simulation_steps", selected = sim_pages[rv$page])
      }
    }
    
    ### handle main parameters
    save_values <- function(){
      if (rv$page==1){
        rv$start_year = input$start_year
        rv$end_year = input$endyear
        rv$catchment_pop = input$catchment_pop
        rv$hrs_wk = input$hrs_wk
        rv$region = input$region
        rv$hrh_utilization = input$hrh_utilization
        print(rv$start_year)
      }
    }
    
    observeEvent(input$prevBtn, navPage(-1))
    observeEvent(input$nextBtn, {
      save_values()
      navPage(1)
    })
    
    observeEvent(input$skipBtn, {
      save_values()
      navPage(0, sim=TRUE)
    })
    
    ### handle optional parameters
    observeEvent(input$optional_params, {
      showModal(modalDialog(
        title = "Enter some optional Values",
        size = "l",  # large size,
        tabsetPanel(
          id = ns("tabset_optional_data"),
          tabPanel("Population Pyramid", DTOutput(ns("pop_data"))),
          tabPanel("Seasonality Curves", DTOutput(ns("seasonality_data"))),
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(ns("saveValue"), "Save")
        )
      ))
    })
    
    values <- reactiveValues(
      pop1 = read_excel(config_file, sheet = "TotalPop"),
      season1 = read_excel(config_file, sheet = "SeasonalityCurves")
    )
    
    # Render the pop data
    output$pop_data <- renderDT({
      datatable(values$pop1, editable = TRUE)
    })
    
    # Render the second editable data table
    output$seasonality_data <- renderDT({
      datatable(values$season1, editable = TRUE)
    })
    
    # Observe changes in edit
    observeEvent(input$pop_data_cell_edit, {
      info <- input$pop_data_cell_edit
      print(info)  # For debugging
      values$pop1 <- editData(values$pop1, info)
    })
    
    observeEvent(input$saveValue, {
      # Save the value when 'Save' button is clicked
      print("TBD: how / what to save?")
      
      # Close the modal after saving
      removeModal()
      print(paste0("value is ", head(values$pop1))) # Debugging
    })
  
  })
}