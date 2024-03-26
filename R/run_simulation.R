sim_pages<- c("Configuration", "Input Validation", "Run Simulation")

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
                    numericInput(ns("start_year"), div(id=ns("info_start_year"), "Start Year ", bs_icon("question-circle")), 2020, min=2000, max=2040),
                    bsPopover(ns("info_start_year"), "Start year for simulation", placement = "top", options = list(container = "body")),
             ),
             column(6,
                    numericInput(ns("catchment_pop"), div(id=ns("info_catchment_pop"), "Catchment Pop ",  bs_icon("question-circle")), 10000, min=1000, max=100000),
                    bsPopover(ns("info_catchment_pop"), "Catchment population for simulation, usually set to 10,000", placement = "top", options = list(container = "body")),
             ),
             
           ),
           fluidRow(
             column(6,
                    numericInput(ns("end_year"), div(id =ns("info_end_year"), "End Year ",  bs_icon("question-circle")), 2040, min =2000, max=2090),
                    bsPopover(ns("info_end_year"), "End year for simulation", placement = "top", options = list(container = "body")),
             ),
             column(6,
                    numericInput(ns("hrs_wk"), div(id = ns("info_hrs_wk"), "Hours worked per week ",  bs_icon("question-circle")), 40, min=1, max = 60),
                    bsPopover(ns("info_hrs_wk"), "Working hours of Week, usually under 40 Hrs", placement = "top", options = list(container = "body")),
             )
             
           ),
           fluidRow(
             column(6,
                    selectInput(ns("region"), "Region ", choices = names(region_config_files), selected = names(region_config_files)[length(names(region_config_files))]), 
                    bsPopover(ns("region"), "Switch to use regional data, must be supplied from data collection.", placement = "top", options = list(container = "body")),
             ),
             column(6,
                    numericInput(ns("hrh_utilization"), div(id =ns("info_hrh_utilization"), "Target HRH utilization (%) ",  bs_icon("question-circle")), value=100, min=0, max =100, step = 1,),
                    bsPopover(ns("info_hrh_utilization"), "TBD", placement = "top", options = list(container = "body")),
             )
           ),
           fluidRow(
             column(6, 
                    actionButton(ns("optional_params"), div("Other Inputs (Optional)",  bs_icon("question-circle"))),
                    bsPopover(ns("optional_params"), "Click here to view and modify simulation data", placement = "top", options = list(container = "body")),
             )
           )
  ),
  tabPanel(sim_pages[2], 
           fluidRow(
             column(12, h5(validation_intro_str))
           ),
           tabsetPanel(
             id ="validation",
             tabPanel("Population Pyramid", simpleplotUI(ns("population-tab"))),
             tabPanel("Fertility Rates", simpleplotUI(ns("fertility-tab"))),
             tabPanel("Mortality Rates", simpleplotUI(ns("mortality-tab"))),
             tabPanel("Seasonality", simpleplotUI(ns("season-tab"))),
           )
  ),
  tabPanel(sim_pages[3], 
           fluidRow(column(12, h5(num_replication_str))
           ),
           fluidRow(column(6, offset= 3,  numericInput(ns("num_trials"), "Number of Replications:", 100, min=2, max=100000))
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
             column(12,  HTML("<br>"))
           ),
           fluidRow(column(12, 
                           hidden(div(id="sim_logger_area",loggerUI("logger"))),
                           hidden(actionButton(ns("close_sim_log"), "Close Log Window", width = "200px", style = "display: block; margin: 0 auto; position: relative; bottom: 30px;")))
                    ),
           
  
  ),
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
        column(12, div(sim_tabs(ns = ns)), class='sim_row'),
      ),
      
      fluidRow(
        column(2, hidden(div(id = ns("prevDiv"), 
                             actionButton(ns("prevBtn"), "Previous"), align="center"))),
        column(8, HTML("<br>")),
        column(2, div(id = ns("nextDiv"), 
                      actionButton(ns("nextBtn"), "Next",  class ="green-button"), align="right")),
      ),

      fluidRow(column(12, HTML("<br>"))
      ),
      fluidRow(
        column(3, offset=9, div(id=ns("skipAll"), bs_icon("question-circle", size=20),  "  ", actionButton(ns("skipBtn"), "Skip To Run Simulation"), align="right"),style="margin-bottom: 100px;"),
        bsPopover(ns("skipAll"), "Warning", "Proceed directly to run simulation, Unchecked inputs may have problems.",
                   placement = "top", options = list(container = "body")),
       
      ),
    )
}

runSimulationServer <- function(id, return_event, rv, store = NULL) {
  
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    rv$current_region <- names(region_config_files)[length(names(region_config_files))]
    # function to trigger config file saving before simulation
    trigger_file_saving <- function(ns){
      js_code = sprintf("Shiny.setInputValue('%s', 'starting', {priority: 'event'});" ,ns("saving"))
      print(gsub("\n", "", js_code))
      shinyjs::runjs(gsub("\n", "", js_code))
    }
    
    # Set sheet data based on input scenario
    observe({
      if (!is.null(rv$uid)) {
        rv$scenario_selected <- rv$scenarios_input$UniqueID
        rv$seasonality_sheet <- rv$scenarios_input$sheet_SeasonalityCurves
        rv$seasonality_input <- read_excel(rv$input_file, sheet = rv$seasonality_sheet)
        rv$task_sheet <- rv$scenarios_input$sheet_TaskValues
        rv$task_input <- read_excel(rv$input_file, sheet = rv$task_sheet)
        rv$pop_input <- read_excel(rv$input_file, sheet = "TotalPop")
        rv$pop_values <- read_excel(rv$input_file, sheet = rv$scenarios_input$sheet_PopValues)
      }
   
      if(sim_pages[rv$page]=="Configuration"){
        if(!rv$show_region){
          isolate(updateSelectInput(session, "region", label = "Region (Unavailable)"))
          shinyjs::disable("region")
        }
        else{
          isolate(updateSelectInput(session, "region", label = "Region"))
          shinyjs::enable("region")
        }
      }
    })
    
    
    # Reload optional data when region changes
    observeEvent(input$region, {
      if (!is.null(input$region) &&  input$region != "" &&  input$region!=rv$current_region){
        # show warning
        showModal(
          modalDialog(
            title = "Confirmation Needed",
            "Are you sure you want to proceed? Change to new region will reset your data from the original template, 
            the data that you previously changed will be lost!",
            footer = tagList(
              actionButton(ns("proceedRegionBtn"), "Proceed"),
              actionButton(ns("cancelRegionBtn"), "Cancel")
            )
          )
        )
      }
    })
    
    observeEvent(input$proceedRegionBtn, {
      removeModal()
      rv$current_region <- input$region
      reload_config(rv$uid, region_config_files[[rv$current_region]])
      rv$scenarios_input <- first(read_excel(rv$input_file, sheet = rv$scenarios_sheet))
      # reload optional data
      rv$task_input <- read_excel(rv$input_file, sheet = rv$task_sheet)
      rv$seasonality_input <- read_excel(rv$input_file, sheet = rv$seasonality_sheet)
      rv$pop_input <- read_excel(rv$input_file, sheet = "TotalPop")
    })
    
    observeEvent(input$cancelRegionBtn, {
      removeModal()
      if (!is.null(rv$current_region)){
        isolate(updateSelectInput(session, "region", selected=rv$current_region))
      }
    })
  

    ### handle conditional button appearance
    observe({
      hide("prevDiv")
      hide("nextDiv")
      show("skipAll")
      if(rv$page > 1){
        show("prevDiv")
      }
      if(rv$page <= length(sim_pages)){
        show("nextDiv")
      }
      if(rv$page >= which(sim_pages == "Run Simulation")){
        hide("skipAll")
        updateActionButton(session, "nextBtn", label = "Go To Results")
        shinyjs::runjs(sprintf('document.getElementById("%s").classList.remove("green-button");', ns("nextBtn")))
        shinyjs::runjs(sprintf('document.getElementById("%s").classList.add("green-button");', ns("run_simBtn")))
      }else{
        updateActionButton(session, "nextBtn", label = "Next")
        shinyjs::runjs(sprintf('document.getElementById("%s").classList.add("green-button");', ns("nextBtn")))
      }
      
      output$step_title <- renderUI({
        image_filename <- paste0("assets/step", rv$page, ".png")
        img(src = image_filename, width = "600px", height = "150px", class="center_icon")
        # HTML(paste0("<h2>", sim_pages[rv$page], "</h2>"))
      })
    })

    ### navigate Page to the corresponding UI
    navPage <- function(direction, sim=FALSE, restart=FALSE) {
      if (sim){
        # go to sim Page
        rv$page <- which(sim_pages == "Run Simulation")
      }
      else if(restart){
        rv$page <- which(sim_pages == "Configuration")
      }
      else{
        rv$page <- rv$page + direction
      }
      if (rv$page >0 & rv$page <= length(sim_pages)){
        print(paste0("Select ", sim_pages[rv$page]))
        updateTabsetPanel(inputId = "simulation_steps", selected = sim_pages[rv$page])
      }
      
      if(sim_pages[rv$page]=="Input Validation"){
        if (!is.null(rv$pop_input)) {
          print("sending plot command:")
          print(head(rv$pop_input))
          simpleplotServer("population-tab", get_population_pyramid_plot, rv)
          simpleplotServer("fertility-tab", get_fertility_rates_plot, rv)
          simpleplotServer("mortality-tab", get_mortality_rates_plot, rv)
          simpleplotServer("season-tab", get_seasonality_validation_plot, rv)
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
        rv$scenarios_input$MaxUtilization <- (input$hrh_utilization) /100.0
        rv$scenarios_input$DeliveryModel <- ifelse(is.null(rv$scenarios_input$DeliveryModel), "Basic", rv$scenarios_input$DeliveryModel)
        rv$region <- input$region
        print(rv$scenarios_input)
      }
    }
    
    observeEvent(input$prevBtn, navPage(-1))
    observeEvent(input$nextBtn, {
      save_values()
      if (rv$page >= which(sim_pages == "Run Simulation")) {
        return_event(TRUE)
        rv$sim_refresh <- TRUE
        navPage(0, restart=TRUE)
      }
      else{
        navPage(1)
      }
    })
    
    observeEvent(input$skipBtn, {
      save_values()
      navPage(0, sim=TRUE)
    })
    
    ### handle optional parameters
    observeEvent(input$optional_params, {
      # save current values
      rv$pop_input_curent <- data.frame(rv$pop_input)
      rv$seasonality_input_current <- data.frame(rv$seasonality_input)
      rv$task_input_current <- data.frame(rv$task_input)
      
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
          actionButton(ns("cancelDataChange"), "Cancel"),
          actionButton(ns("saveValue"), "Save", class="green-button")
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
      # print(paste0("value is ", head(rv$pop_input))) # Debugging
      rv$sim_triggered <- FALSE
      trigger_file_saving(ns)
    })
    
    # handle cancel change, revert to previous state
    observeEvent(input$cancelDataChange, {
      # Close the modal after cancelling
      removeModal()
      if (!is.null(rv$pop_input_curent)){
        rv$pop_input <- data.frame(rv$pop_input_curent)
        
      }
      if (!is.null(rv$pop_input_curent)){
        rv$pop_input <- data.frame(rv$pop_input_curent)
        
      }
      if (!is.null(rv$pop_input_curent)){
        rv$pop_input <- data.frame(rv$pop_input_curent)
      }
    })
    
    # handle saving and notify when it's done
    observeEvent(input$saving, {
      if (input$saving == 'starting'){
        uid <- rv$uid
        isolate({
          if (is.null(rv$sim_triggered) || rv$sim_triggered == FALSE) session$sendCustomMessage("notify_handler", paste0("saving user config:", rv$input_file, " This may take awhile..."))
          # save all changes 
          if (!is.null(rv$sim_triggered) && rv$sim_triggered == TRUE) loggerServer("logger", paste0("Saving User param > ", rv$input_file))
          wb <- openxlsx::loadWorkbook(rv$input_file)
          if (!is.null(rv$sim_triggered) && rv$sim_triggered == TRUE) loggerServer("logger", paste0(rv$input_file, " saved"))
          
          # save scenario sheet
          scenario_sheet <- read_xlsx(rv$input_file, sheet = rv$scenarios_sheet)
          scenario_sheet$HrsPerWeek[1] <- rv$scenarios_input$HrsPerWeek
          scenario_sheet$MaxUtilization[1] <- rv$scenarios_input$MaxUtilization
          scenario_sheet$BaselinePop[1] <- rv$scenarios_input$BaselinePop
          scenario_sheet <- scenario_sheet[1, , drop = FALSE]
          
          if (!is.null(rv$sim_triggered) && rv$sim_triggered == TRUE) loggerServer("logger", paste0("Prepare config file for simulation"))
        
          openxlsx::writeData(wb, rv$scenarios_sheet, scenario_sheet)
          
          # save optional data changes  
          openxlsx::writeData(wb, "TotalPop", rv$pop_input)
          openxlsx::writeData(wb, rv$seasonality_sheet , rv$seasonality_input)
          openxlsx::writeData(wb, rv$task_sheet , rv$task_input)
          openxlsx::saveWorkbook(wb, rv$input_file, overwrite = TRUE)
        })
        
        
        print("Saving Complete")
        if (rv$sim_triggered){
          # if this file saving is triggered by the simulation step, set sim_ready to continue simulation
          # session$sendCustomMessage("notify_handler", paste0("user config is saved to:", rv$input_file))
          js_code_done <- sprintf("Shiny.setInputValue('%s', 'done'); Shiny.setInputValue('%s', 'TRUE');", ns('saving'), ns('sim_ready'))
          shinyjs::runjs(js_code_done)
        }
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
          textAreaInput(ns("runInfo"), "Description"),
          span(textOutput(ns("errorRunName")), style="color:red"),
          footer = tagList(
            modalButton("Cancel"),
            actionButton(ns("saveNameButton"), "Save", class="green-button")
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
        output$errorRunName <- renderText({""})
        # Update config again if anything changed before running sim
        shinyjs::show(id="sim_logger_area", asis=TRUE)
        rv$sim_triggered <- TRUE 
        trigger_file_saving(ns)
        rv$run_name <- input$runNameInput
        rv$run_info <- input$runInfo
      }
    })
    
    # run simulation and save results
    observeEvent(input$sim_ready, {
      if (input$sim_ready){
        response <- run_pacehrh_simulation(rv, input_file = rv$input_file)
        if (!is.null(response) && length(response) != 0){
          #map the key value pairs from the response to the reactive value
          keys <- names(response)
          for (key in keys) {
            rv[[key]] <- response[[key]]
          }
          # save run_name to localstorage
          
          js_code_save <-"
          var new_run = {
            name: '%s',
            date: new Date().toLocaleString(),
            start_year: '%s',
            end_year: '%s',
            catchment_pop: '%s',
            hrs_per_wk: '%s',
            max_utilization: '%s',
            region: '%s'
          };
          var test_names = JSON.parse(localStorage.getItem('test_names')) || [];
          test_names.push(new_run);
          localStorage.setItem('test_names', JSON.stringify(test_names));
          "
          js_code_save <- sprintf(js_code_save, 
                                  rv$run_name, 
                                  rv$start_year, 
                                  rv$end_year, 
                                  rv$scenarios_input$BaselinePop, 
                                  rv$scenarios_input$HrsPerWeek,
                                  rv$scenarios_input$MaxUtilization,
                                  ifelse(is.null(rv$region), 'NA', rv$region)
                                  )
        
          print(js_code_save)
          shinyjs::runjs(js_code_save)
          loggerServer("logger", paste0("Simulation completed : ", rv$run_name))
          shinyjs::runjs(sprintf("Shiny.setInputValue('%s', 'FALSE');", ns('sim_ready')))
          shinyjs::show(id=ns("close_sim_log"), asis=TRUE)
          shinyjs::runjs(sprintf('document.getElementById("%s").classList.add("green-button");', ns("nextBtn")))
          shinyjs::runjs(sprintf('document.getElementById("%s").classList.remove("green-button");', ns("run_simBtn")))
        }
      }
    })
    
    # close simulation logs
    observeEvent(input$close_sim_log, {
      shinyjs::html(id="log-display", "", asis=TRUE)
      shinyjs::hide(id="sim_logger_area", asis=TRUE)
      shinyjs::hide(id=ns("close_sim_log"), asis=TRUE)
    })
    
  })
}
