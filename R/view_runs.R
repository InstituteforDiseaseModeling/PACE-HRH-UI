# UI for the view runs module
viewRunsUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    shinyjs::useShinyjs(),
    tags$head(
      tags$script(
        HTML(
          'Shiny.addCustomMessageHandler("uncheckCheckbox", function(index) {',
          '  $("input[name=\'row_selected\']").eq(index).prop("checked", false);',
          '});'
        )
      )
    ),
    fluidRow(
      column(12, 
             tagList(
                # selectInput(ns("run_selector"), "Choose a Run To view", choices =NULL),
                dataTableOutput(ns("history_table")),
                # actionButton(ns("refreshBtn"), "Refresh Results"),
                actionButton(ns("compare_btn"), "Show / Compare Result"),
                actionButton(ns("download_resultsBtn"), "Download Results (.csv)", ),
                actionButton(ns("print_summaryBtn"), "Print PDF of Summary Plots"),
                actionButton(ns("deleteResultsBtn"), "Delete selected results"),
            )
      )
    ),
    fluidRow(
      div(HTML("<br>"), uiOutput(ns("downloadBtn"))),
    ),
    fluidRow(
      div(id = ns("search_msg"), "Searching and processing results, this may take awhile...", div(class = "spinner"), style = "display: none;"),
    ),
      div(
        id = ns("plot_area_container"),
        tabsetPanel(
          id = "main-tabs",
          # --------Insert tabs UI calls here, comma separated --------
          plotTabUI(id = ns("slide-4-tab"),
                    title = "By Clinical Category"),
          plotTabUI(id = ns("by-CadreRoles-tab"),
                    title = "By Cadre Roles"),
          plotTabUI(id = ns("by-ServiceCat-tab"),
                    title = "By Service Category"),
          plotTabUI(id = ns("by-ServiceTile-tab"),
                    title = "By Service Category Tiles"),
          plotTabUI(id = ns("service-over-time-tab"),
                    title = "Service change over time"),
          plotTabUI(id = ns("seasonality-tab"),
                    title = "Seasonality"),
        ),
      )
  )
}

# Server logic for the view runs module
viewRunsServer <- function(id, rv, store) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # run once when loaded
    shinyjs::runjs(sprintf("get_test_names('%s', '%s')", ns("test_names_loaded"), ns("test_history")))
    
    selectedRows <- reactiveVal(c(TRUE))
    redraw <- reactiveVal(FALSE)
    rv_results <- reactiveValues()
    download_filenames <- reactiveVal(NULL)
    pdf_filenames <- reactiveVal(NULL)
   
    # autoInvalidate <- reactiveTimer(10000)
    # observeEvent(input$refreshBtn, {
    #   # autoInvalidate()
    #   shinyjs::runjs(sprintf("get_test_names('%s', '%s')", ns("test_names_loaded"), ns("test_history")))
    #   isolate(updateSelectInput(session, "run_selector",
    #                     label = "Choose a Run To view",
    #                     choices = input$test_names_loaded,
    #   ))
    # })
    
    read_info <- function(name) {
      file_path <- file.path(result_root, name, "info.txt")
      if (file.exists(file_path)) {
        return(readLines(file_path))
      } else {
        return("Info Missing")
      }
    }
    
    showWarningModalIllegalFiles <- function(text="") {
      if (text==""){
        text <- "You do not have any result to view, please run at least one simulation!"
      }
      shiny::showModal(
        modalDialog(
          title = "Warning",
          text,
          footer = tagList(
            actionButton(ns("closeNoFileModal"), "Close", icon = icon("times"))
          )
        )
      )
    }
    observeEvent(input$closeNoFileModal, {
      shiny::removeModal()
    })
    
    observeEvent(input$test_history, {
      df_history <- jsonlite::fromJSON(input$test_history)
      if (length(df_history) == 0){
        shinyjs::hide(id=ns("history_table"), asis = TRUE)
      } else{
        shinyjs::show(id=ns("history_table"), asis = TRUE)
      }
      
      df_history$summary <- apply(df_history, 1, function(row) {
        read_info(row["name"])
      })
      df_history$datetime <- as.POSIXct(df_history$date, format = "%m/%d/%Y, %I:%M:%S %p", tz = "UTC")
      rv$df_history <-  df_history%>% arrange(desc(datetime))  %>% select(-(datetime), -(catchment_pop), -(hrs_per_wk), -(max_utilization))
      selectedRows(c(TRUE, rep(FALSE, nrow(rv$df_history)-1)))
      output$history_table <- renderDT({
        checkboxData <- transform(rv$df_history, Select = sprintf('<input type="checkbox" name="row_selected" %s/>', ifelse(selectedRows(), "checked", "")))
        datatable(
          checkboxData,
          class ='compact',
          escape = FALSE,
          filter = 'top',
          selection = 'none',
          options = list(
            pageLength = 5,
            preDrawCallback = JS('function() { Shiny.unbindAll(this.api().table().node()); }'),
            drawCallback = JS(
              'function() {',
              '  var api = this.api();',
              '  var pageInfo = api.page.info();',
              sprintf('  Shiny.setInputValue("%s", pageInfo.page + 1);', ns("currentPage")),
              '  Shiny.bindAll(this.api().table().node());',
              '}'
            )
            ),
          callback = JS(
            'function updateSelectedRows(checkbox) {',
            '  var row = $(checkbox).closest("tr");',
            '  var rowIdx = row[0]._DT_RowIndex;',
            '  var selected = $(checkbox).prop("checked");',
            sprintf('  Shiny.setInputValue("%s", {index: rowIdx, selected: selected}, {priority: "event"});', ns("rowSelected")),
            '}',
            '$(document).on("change", "input[name=\'row_selected\']", function() {',
            '  updateSelectedRows(this);',
            '});'
          )
        )
      }, server = FALSE)
    },ignoreNULL = TRUE)
    
    observeEvent(input$rowSelected, {
      selections <- selectedRows()
      selections[input$rowSelected$index + 1] <- input$rowSelected$selected
      selectedRows(selections)
      
      # only allow up to 4 comparison
      # if (sum(selections) > 4) {
      #   selections[input$rowSelected$index + 1] <- FALSE
      #   selectedRows(selections)
      #   session$sendCustomMessage(type = "uncheckCheckbox", input$rowSelected$index)
      # }
      # stay on the same page
      if (!is.null(input$currentPage)) {
        dataTableProxy('history_table') %>% selectPage(as.numeric(input$currentPage))
      }
    })
    
    combine_selected_data <- function(selected){
      # Check of start/end year is consistent for all data
      if (length(unique(rv$df_history[selected, 'start_year'])) == 1 &
          length(unique(rv$df_history[selected, 'end_year'])) == 1){
        data_is_valid <- TRUE
        rv_results$start_year <- as.integer(unique(rv$df_history[selected, 'start_year']))
        rv_results$end_year <- as.integer(unique(rv$df_history[selected, 'end_year']))
      }
      else{
        data_is_valid <- FALSE
        session$sendCustomMessage("notify_handler", "Unable to compare different start /end year results!")
      }
      if(all(file.exists(file.path(result_root, rv$df_history[selected, 'name'])))){
        filenames <- unique(list.files(file.path(result_root, rv$df_history[selected, 'name']), pattern = "\\.csv$"))
        # filenames <- filenames[filenames != "result.csv"] # exclude results
        directories <- file.path(result_root, rv$df_history[selected, 'name'])
        
        # Function to read and combine files for each filename
        read_and_combine <- function(filename, directories) {
          filepaths <- paste0(directories, "/", filename)
          combined_data <- do.call(rbind, lapply(filepaths, read.csv, stringsAsFactors = FALSE))
          return(combined_data)
        }
        for (filename in filenames) {
          combined_data <- read_and_combine(filename, directories)
          # Remove file extension and use it as the name for the reactiveVal
          name <- tools::file_path_sans_ext(filename)
          rv_results[[name]] <- combined_data
        }
      } else{
        data_is_valid <- FALSE
        session$sendCustomMessage("notify_handler", paste0("results not ready for ", rv$df_history[selected, 'name']))
      }
      return (data_is_valid)
    }
    
    observeEvent(input$compare_btn, {
      if(!is.null(rv$df_history)){
        selected <- which(selectedRows())
        if (length(selected) >0 & length(selected) <= 4){
          shinyjs::show(id=ns("search_msg"), asis = TRUE)
          # print(paste0("selected ", length(selected)))
          test_selected <- rv$df_history[selected, 'name']
          redraw(combine_selected_data(selected))    
          shinyjs::hide(id=ns("search_msg"), asis = TRUE)
        }
        else if (length(selected) > 4){
          showWarningModalIllegalFiles("You can only select up to four results to compare.")
        }
        else{
          showWarningModalIllegalFiles("You did not select any result to compare.")
        }
      }
      else{
        showWarningModalIllegalFiles()
      }
    })
    
    observeEvent(input$deleteResultsBtn, {
      if(!is.null(rv$df_history)){
        selected <- which(selectedRows())
        if (length(selected) > 0)
        {
          showModal(
            modalDialog(
              title = "Delete Results",
              "Are you sure you want to delete the selected results?",
              footer = tagList(
                actionButton(ns("deleteResultsConfirmBtn"), "Yes"),
                modalButton("No")
              )
            )
          )
        }else{
          showWarningModalIllegalFiles("You did not select any result to delete.")
        }
      }
    })
    
    observeEvent(input$deleteResultsConfirmBtn, {
      shiny::removeModal()
      selected <- which(selectedRows())
      if (length(selected) > 0)
      {
        test_selected <- rv$df_history[selected, 'name']
        tryCatch({
          for (testname in test_selected){
            # remove localstorage entries
            shinyjs::runjs(sprintf("delete_tests(['%s'], '%s', '%s', '%s')", testname, ns("test_history"), ns("history_table"), ns("plot_area_container")))
            resultdir <- file.path(result_root, testname)
            if (dir.exists(resultdir)){
              unlink(resultdir, recursive = TRUE)
            }
          }
          shinyjs::runjs(sprintf("get_test_names('%s', '%s')", ns("test_names_loaded"), ns("test_history")))
        },
        error = function(e){
            session$sendCustomMessage("notify_handler", paste0("Error occurred deleting ", test_selected))
        })
      }
    })
    
    observe ({
        if (rv$sim_refresh){
          print(paste0("rv$sim_refresh: ", rv$sim_refresh))
          shinyjs::runjs(sprintf("get_test_names('%s', '%s')", ns("test_names_loaded"), ns("test_history")))
          isolate(updateSelectInput(session, "run_selector",
                                    label = "Choose a Run To view",
                                    choices = input$test_names_loaded,
          ))
          rv$sim_refresh <- FALSE   
        }
       if (redraw()){
            shinyjs::show(ns("plot_area_container"), asis = TRUE)
            plotTabServer(
              id = "slide-4-tab",
              plotting_function = "get_slide_4_plot",
              rv = rv_results)
            
            plotTabServer(
              id = "by-CadreRoles-tab",
              plotting_function = "byCadreRoles_plot",
              rv = rv_results)
            
            plotTabServer(
              id = "by-ServiceCat-tab",
              plotting_function = "byServiceCat_plot",
              rv = rv_results)
            
            plotTabServer(
              id = "by-ServiceTile-tab",
              plotting_function = "byServiceTile_plot",
              rv = rv_results)
            
            plotTabServer(
              id = "service-over-time-tab",
              plotting_function = "serviceOverTime_plot",
              rv = rv_results)
            
            plotTabServer(
              id = "seasonality-tab",
              plotting_function = "seasonality_plot",
              rv = rv_results)
            
            redraw(FALSE)
          }
         
       
    })
    
    ### handle download
    
    before_download <- function(){
      shinyjs::hide(ns("downloadZipBtn"), asis = TRUE)
      shinyjs::hide(ns("downloadPDFBtn"), asis = TRUE)
      shinyjs::show(id=ns("search_msg"), asis = TRUE)
    }
    
    observeEvent(input$download_resultsBtn, {
      
      if(!is.null(rv$df_history)){
        download_filenames(NULL)
        selected <- which(selectedRows())
        if (length(selected) > 0){
          before_download()
          test_selected <- rv$df_history[selected, 'name']
          folder_name <- file.path(result_root, test_selected)
          download_filenames(zip_folders(folder_name))
          shinyjs::hide(id=ns("search_msg"), asis = TRUE)
          
          output$downloadBtn <- renderUI({
            req(download_filenames())
            downloadButton(
              outputId = ns("downloadZipBtn"),
              label = "Download your zip file here!",
              onclick = sprintf('Shiny.setInputValue("%s", true);', ns("download_clicked")),
              class = "download-button"
            )
          })
          shinyjs::show(ns("downloadZipBtn"), asis = TRUE)
        }
        else{
          showWarningModalIllegalFiles("You did not select any result to download.")
        }
      }
      else{
        showWarningModalIllegalFiles()
      }
    })
    
    output$downloadZipBtn <- downloadHandler(
      filename = basename(download_filenames()),
      content = function(file) {
        file.copy(download_filenames(), file)
      },
    )
    
    observeEvent(input$download_clicked, {
      # Hide the download button after it's clicked
      if (input$download_clicked){
        print("downloaded. remove the link...")
        shinyjs::runjs(sprintf('Shiny.setInputValue("%s", false);', ns("download_clicked")))
        shinyjs::hide(ns("downloadZipBtn"), asis = TRUE)
        shinyjs::hide(ns("downloadPDFBtn"), asis = TRUE)
      }
    })
    
    ### handle pdf report
    observeEvent(input$print_summaryBtn, {
      if(!is.null(rv$df_history)){
        selected <- which(selectedRows())
        if (length(selected) > 0){
          before_download()
          test_selected <- rv$df_history[selected, 'name']
          if(combine_selected_data(selected)){
            filename1 <- get_pdf_report(rv=rv_results)
          }
          pdf_filenames(filename1)
          shinyjs::hide(id=ns("search_msg"), asis = TRUE)
          
          output$downloadBtn <- renderUI({
            req(pdf_filenames())
            downloadButton(
              outputId = ns("downloadPDFBtn"),
              label = "Download your pdf report here!",
              onclick = sprintf('Shiny.setInputValue("%s", true);', ns("download_clicked")),
              class = "download-button"
            )
          })
          shinyjs::show(ns("downloadPDFBtn"), asis = TRUE)
        }
        else{
          showWarningModalIllegalFiles("You did not select any result to print.")
        }
      } else{
        showWarningModalIllegalFiles()
      }
    })
    
    output$downloadPDFBtn <- downloadHandler(
      filename = basename(pdf_filenames()),
      content = function(file) {
        file.copy(pdf_filenames(), file)
      },
    )
    
  })
}
