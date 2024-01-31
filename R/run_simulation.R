config_intro_str <- "Edit your key inputs here before you run the model,
  The model comes pre-populated with default valuesspecific to your region, 
  but if you want to edit those, you can use the optional button at the bottom of this screen.
  "

num_replication_str <- " Indicate how many replications (trials) that you want to run, More will be more accurate, 
but also require more time and larger data files. We recommend running between 100 and 1000.
"

sim_pages<- c("Configuration", "Input Validation", "Run Simulation", "View Results")

# Simulation steps as hidden tabs to create step by step effect

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
                    selectInput(ns("region"), "Region", choices = NULL),      
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
             tabPanel("Population Pyramid", simpleplotUI(ns("population-tab"))),
             tabPanel("Fertility Rates", simpleplotUI(ns("fertility-tab"))),
             tabPanel("Mortality Rates", simpleplotUI(ns("mortality-tab"))),
             tabPanel("Disease Incidence", simpleplotUI(ns("disease-tab"))),
           )
  ),
  tabPanel(sim_pages[3], 
           fluidRow(column(12, h5(num_replication_str))
           ),
           fluidRow(column(6, offset= 3,  numericInput(ns("num_trials"), "Number of Replications:", 100))
           ),
           fluidRow(
             column(12,  HTML("<br><br>"))
           ),
           fluidRow(column(12, textOutput(ns("run_estimate")))),
           fluidRow(
             column(12,  HTML("<br><br>"))
           ),
           fluidRow(column(6, offset = 3, actionButton(ns("run_simBtn"), "Run Simulations"))
           ),
           fluidRow(column(12, uiOutput(ns("runSimMsg")))
                    ), 
           fluidRow(
             column(12,  HTML("<br><br><br><br><br>"))
           )
  
  ),
  tabPanel(sim_pages[4], 
           fluidRow(
             column(4, actionButton(ns("print_summaryBtn"), "Print PDF of Summary Plots", class='menuButton'), ), 
             # column(4, offset=2, actionButton(ns("save_resultsBtn"), "Save Results for later comparison"))
             column(4, downloadButton(ns("download_resultsBtn"), "Download Results (.csv)", class='menuButton')), 
             column(4, actionButton(ns("compareBtn"), "Select Previous runs to compare", class='menuButton'))
             
           ),
           fluidRow(
             column(12,  HTML("<br><br><br><br><br>"))
           )
  )
)}

# UI for the run simulation module

runSimulationUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    includeScript("www/js/message.js"),
    shinyjs::useShinyjs(),
    
      fluidRow(
        column(12,uiOutput(ns("step_title")))
      ),
      
      fluidRow(
        column(12, div(sim_tabs(ns = ns)), class='sim_row'),
      ),
      
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
        column(3, offset=9, div(id=ns("skipAll"), actionButton(ns("skipBtn"), "Skip To Run Simulation"), align="center")),
        bsTooltip(ns("skipBtn"), "Proceed directly to run simulation, Warning: Unchecked inputs may have problems.",
                  "left", options = list(container = "body"))
      )
    )
}

runSimulationServer <- function(id, config_file, return_event, rv, store = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
   
    # Set sheet data based on input scenario
    observe({
      rv$scenario_selected <- rv$scenarios_input$UniqueID
      rv$seasonality_sheet <- rv$scenarios_input$sheet_SeasonalityCurves
      rv$seasonality_input <- read_excel(config_file, sheet = rv$seasonality_sheet)
      rv$task_sheet <- rv$scenarios_input$sheet_TaskValues
      rv$task_input <- read_excel(config_file, sheet = rv$task_sheet)
      rv$pop_input = read_excel(config_file, sheet = "TotalPop")
      
      if(sim_pages[rv$page]=="Configuration"){
        if(file.exists(region_list)){
          region_names <- readLines(region_list)
          updateSelectInput(session, "region", choices = region_names)
        }
        else{
          updateSelectInput(session, "region", label = "Region (Unavailable)")
          shinyjs::disable("region")
        }
      }
    })
    
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
      
      if(sim_pages[rv$page]=="Input Validation"){
        if (!is.null(rv$pop_input)) {
           simpleplotServer("population-tab", get_population_pyramid_plot, rv)
        }
      }
    }
    
    ### handle main parameters
    save_values <- function(){
      if (rv$page==1){
        rv$start_year <- input$start_year
        rv$end_year <- input$end_year
        rv$scenarios_input$BaselinePop <- input$catchment_pop
        rv$scenarios_input$HrsPerWeek <- input$hrs_wk
        rv$scenarios_input$MaxUtilization <- input$hrh_utilization
        rv$scenarios_input$DeliveryModel <- ifelse(is.null(rv$scenarios_input$DeliveryModel), "Basic", rv$scenarios_input$DeliveryModel)
        rv$region <- input$region
        print(rv$scenarios_input)
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
        title = "Modify Optional Sheet Values",
        # size = "l",  # large size,
        fluidPage(
          # selectInput(ns("scenario"), "Choose a Scenario to View or Modify",
          #             choices = rv$scenarios_input$UniqueID), 
          tabsetPanel(
            id = ns("tabset_optional_data"),
            tabPanel("Population Pyramid", 
                      tagList(
                        DTOutput(ns("preview_pop")),
                        selectInput(ns("preload_pop"), "Select Preloaded Population", choices= c("Choose", names(preload_pop_list)), selected = ""), 
                        fileInput(ns("file_pop"), "Upload Population File", accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv"))
                      )
            ),
            tabPanel("Seasonality Curves",
                     tagList(
                       DTOutput(ns("preview_seasonality")),
                       fileInput(ns("file_seasonality"), "Upload Seasonality File", accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv"))
                     )
            ),
            tabPanel("Select Task Values",
                     tagList(
                       DTOutput(ns("preview_task")),
                       fileInput(ns("file_task"), "Upload Task values File", accept = c("text/csv", "text/comma-separated-values,text/plain", ".csv"))
                     )
            )
          )
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(ns("saveValue"), "Save")
        )
      ))
      
    })
  
    ### Handle sheet preview
    output$preview_pop <- renderDT({
      rv$pop_input
    })
    
    output$preview_seasonality <- renderDT({
      rv$seasonality_input
    })
    
    output$preview_task <- renderDT({
      rv$task_input
    })
    
    observeEvent(input$file_pop, {
      if (!is.null(input$file_pop)) {
        rv$pop_input <- read.csv(input$file_pop$datapath)
      }
    })

    observeEvent(input$file_seasonality, {
      if (!is.null(input$file_seasonality)) {
        rv$seasonality_input <- read.csv(input$file_seasonality$datapath)
      }
    })
    
    observeEvent(input$file_task, {
      if (!is.null(input$file_task)) {
        rv$task_input <- read.csv(input$file_task$datapath)
      }
    })
    
    observeEvent(input$preload_pop, {
      selected_file <- input$preload_pop
      print("Getting Population File Preloaded")
      if (!is.null(selected_file) & selected_file != "Choose") {
        actual_filename <- preload_pop_list[names(preload_pop_list) == selected_file]
        file_content <- read.csv(actual_filename, row.names = NULL) # assuming the file is a CSV
        rv$pop_input <- file_content
      }
    })
    
    
    ### handle sheet change saving
    observeEvent(input$saveValue, {
     
      # Close the modal after saving
      removeModal()
      print(paste0("value is ", head(rv$pop_input))) # Debugging
      
      js_code = sprintf("
                function set_uid(){
                  if (localStorage.getItem('uid')) {
                    return localStorage.getItem('uid');
                  } 
                  else {
                    v = (Math.random() + 1).toString(36).substring(7);
                    localStorage.setItem('uid', v);
                    return v;
                  }
                }
                var uid = localStorage.getItem('uid'); 
                Shiny.setInputValue('%s', uid);
                Shiny.setInputValue('%s', 'starting', {priority: 'event'});"
                , ns("uid"), ns("saving"))
      print(gsub("\n", "", js_code))
      shinyjs::runjs(gsub("\n", "", js_code))
                
    })
    
    # handle saving and notify when it's done
    observeEvent(input$saving, {
      if (input$saving == 'starting'){
        uid <- input$uid
        
        isolate({
          
          # create a inputfile for the current user based on uid 
          prefix <- unlist(strsplit(config_file, "\\."))[1]
          input_file <- paste0(prefix, "_", uid, ".xlsx")
          
          if  (!file.exists(input_file)){
            file.copy(config_file, input_file, overwrite = TRUE)
          }
          
          
          if ("RegionSelect" %in% excel_sheets(input_file)){
            command = paste0("cd vbscript & cscript updateRegion.vbs ", rv$region, " ../", input_file)
            system(command ="cmd", input=command,  wait =TRUE)
            
          }
          
          # save all changes to a new config (input_file)
          wb <- openxlsx::loadWorkbook(input_file)
          
          openxlsx::writeData(wb, "TotalPop", rv$pop_input)
          openxlsx::writeData(wb, rv$seasonality_sheet , rv$seasonality_input)
          openxlsx::writeData(wb, rv$task_sheet , rv$task_input)
          openxlsx::saveWorkbook(wb, input_file, overwrite = TRUE)
        })
        
        rv$input_file <- input_file
        print("Saving Complete")
        session$sendCustomMessage("done_handler", input_file)
        js_code_done <- sprintf("Shiny.setInputValue('%s', 'done');", ns('saving'))
        shinyjs::runjs(js_code_done)
      }
      
    })
    
    ### handle Run simulation
    # estimate time
    observe({
      
      rv$trial_num <- ifelse(is.null(input$num_trials), 0, input$num_trials)
      
      output$run_estimate <- renderText({
        get_estimated_run_stats(rv$trial_num)
      })
      
    })
    
    # save run name
    observeEvent(input$run_simBtn, {
      showModal(
        modalDialog(
          title = "Enter Run Name",
          textInput(ns("runNameInput"), "Run Name:", ""),
          span(textOutput(ns("errorRunName")), style="color:red"),
          footer = tagList(
            modalButton("Cancel"),
            actionButton(ns("saveNameButton"), "Save")
          )
        )
      )
    })
    
    observeEvent(input$saveNameButton, {
      # Check if this name already exist
      if (input$runNameInput %in% list.dirs(result_root, full.names = FALSE)){
        output$errorRunName <- renderText({
          "The test name already exists, please choose a new name!"
        })
      }
      else{
        removeModal()
        rv$run_name <- input$runNameInput
     
        response <-
          run_pacehrh_simulation(rv, input_file = input_file)
        #map the key value pairs from the response to the reactive value
        keys <- names(response)
        for (key in keys) {
          rv[[key]] <- response[[key]]
        }
        # save run_name to localstorage
        js_code_save <- "
          var new_run = {
            name: '%s',
            date: new Date().toLocaleString()
          };
          var test_names = JSON.parse(localStorage.getItem('test_names')) || [];
          test_names.push(new_run);
          localStorage.setItem('test_names', JSON.stringify(test_names));
        "
        shinyjs::runjs(sprintf(js_code_save, rv$run_name))
        output$runSimMsg <- renderUI(
            HTML(paste0("<div style='color:green;'>", "Simulation completed", "</div>"))
        )
      }
    })
    
    ### handle result viewing
    
    output$download_resultsBtn <- downloadHandler(
      filename = paste0("results_", rv$run_name, ".zip"),
      content = function(file) 
      {
        folder_name <- file.path(result_root, rv$run_name)
        zip(file, files = list.files(folder_name, full.names = TRUE))
      })
    
    ### handle view results from run simulation step 4
    observeEvent(input$compareBtn, {
      return_event(TRUE)
    })
    
  })
}