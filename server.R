library(shiny)
library(pROC)
library(readxl)
library(dplyr)
library(glmnet)
library(ggplot2)

# Define server logic
function(input, output, session) {
  # Reactive for handling file uploads and processing data
  data <- reactive({
    req(input$dataFile)  # Ensure file is uploaded
    tryCatch({
      df <- read_excel(input$dataFile$datapath)
      df
    }, error = function(e) {
      showNotification("Error reading file. Please make sure it is a valid Excel file.", type = "error")
      return(NULL)
    })
  })
  
  # Reactive output for selecting the group column
  output$groupSelect <- renderUI({
    req(data())  # Ensure data is loaded
    selectInput("groupColumn", "Select Group Column:", 
                choices = c("", names(data())), 
                selected = "")
  })
  
  # Reactive output for selecting predictors
  output$predictorSelect <- renderUI({
    req(data())  # Ensure data is loaded
    colnames <- setdiff(names(data()), input$groupColumn)  # Exclude the group column from predictors
    tagList(
      selectInput("predictor1", "Select Predictor 1:", choices = c("", colnames), selected = ""),
      selectInput("predictor2", "Select Predictor 2:", choices = c("", colnames), selected = ""),
      selectInput("predictor3", "Select Predictor 3:", choices = c("", colnames), selected = ""),
      selectInput("predictor4", "Select Predictor 4:", choices = c("", colnames), selected = ""),
      selectInput("predictor5", "Select Predictor 5:", choices = c("", colnames), selected = "")
    )
  })
  
  # Reactive values for storing multiple ROC results
  roc_results <- reactiveValues(roc_list = list(), plot = NULL)
  
  # Observe button click to process data and generate multiple ROC plots
  observeEvent(input$submit, {
    req(data())  # Ensure data is loaded
    
    # Ensure group column is selected
    if (input$groupColumn == "") {
      showNotification("Group column must be selected.", type = "error")
      return()
    }
    
    # Collect selected predictors
    predictors <- c(input$predictor1, input$predictor2, input$predictor3, input$predictor4, input$predictor5)
    predictors <- predictors[predictors != "" & !is.null(predictors)]
    
    # Check for duplicate predictors
    if(length(predictors) != length(unique(predictors))) {
      showNotification("Predictors must be unique. Please select different predictors.", type = "error")
      return()
    }
    
    if(length(predictors) == 0) {
      showNotification("At least one predictor must be selected.", type = "error")
      return()
    }
    
    # Convert the selected group column to a factor and ensure it's binary
    df_with_binary_group <- data()
    tryCatch({
      df_with_binary_group[[input$groupColumn]] <- as.factor(df_with_binary_group[[input$groupColumn]])
      if(length(levels(df_with_binary_group[[input$groupColumn]])) != 2) {
        showNotification("Group column must contain exactly two levels for ROC analysis.", type = "error")
        return()
      }
      df_with_binary_group[[input$groupColumn]] <- as.numeric(df_with_binary_group[[input$groupColumn]]) - 1
    }, error = function(e) {
      showNotification("Error processing group column. Ensure it is suitable for binary classification.", type = "error")
      return()
    })
    
    # Clear previous ROC results
    roc_results$roc_list <- list()
    
    # Fit logistic regression models for each selected predictor and store ROC results
    for(predictor in predictors) {
      tryCatch({
        formula <- as.formula(paste(input$groupColumn, "~", predictor))
        mylogit <- glm(formula, data = df_with_binary_group, family = "binomial")
        prob <- predict(mylogit, type = "response")
        df_with_binary_group$prob <- prob
        
        roc_curve <- roc(response = df_with_binary_group[[input$groupColumn]], predictor = prob, plot = FALSE)
        auc_value <- round(auc(roc_curve), 2) * 100
        roc_name <- paste("AUC =", auc_value, "%", predictor)
        
        roc_results$roc_list[[roc_name]] <- roc_curve
      }, error = function(e) {
        showNotification(paste("Error with predictor", predictor, ":", e$message), type = "error")
      })
    }
    
    # Combine selected predictors into one model and add its ROC curve
    if(length(predictors) > 1) {
      tryCatch({
        combined_formula <- as.formula(paste(input$groupColumn, "~", paste(predictors, collapse = "+")))
        combined_logit <- glm(combined_formula, data = df_with_binary_group, family = "binomial")
        combined_prob <- predict(combined_logit, type = "response")
        df_with_binary_group$combined_prob <- combined_prob
        
        combined_roc_curve <- roc(response = df_with_binary_group[[input$groupColumn]], predictor = combined_prob, plot = FALSE)
        combined_auc_value <- round(auc(combined_roc_curve), 2) * 100
        combined_roc_name <- paste("AUC =", combined_auc_value, "% Combined")
        
        roc_results$roc_list[[combined_roc_name]] <- combined_roc_curve
      }, error = function(e) {
        showNotification("Error with combined predictors: ", e$message, type = "error")
      })
    }
    
    # Generate the plot
    roc_results$plot <- ggroc(roc_results$roc_list, legacy.axes = TRUE) +
      xlab('False Positive Rate') +
      ylab('True Positive Rate') +
      theme(legend.position = "none", 
            legend.position.inside = c(0.8, 0.2)) +
      theme_bw() +
      geom_abline(linetype = "dotted") +
      coord_fixed()
  })
  
  # Output combined ROC plot
  output$rocPlot <- renderPlot({
    req(roc_results$plot)  # Ensure roc_results are calculated
    print(roc_results$plot)
  })
  
  # Download handler for the plot
  output$downloadPlot <- downloadHandler(
    filename = function() {
      paste("ROC_Plot_", Sys.Date(), ".", input$fileFormat, sep = "")
    },
    content = function(file) {
      ggsave(file, plot = roc_results$plot, device = input$fileFormat, width = input$plotWidth, height = input$plotHeight)
    },
    contentType = "application/octet-stream"
  )
}
