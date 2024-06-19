library(shiny)

# Define the user interface
shinyUI(fluidPage(
  tags$head(
    tags$style(HTML("
            .fixed-width {
                width: 400px;
            }
        "))
  ),
  titlePanel("Dynamic ROC Curve Plotter"),
  h4("by Junjie:P"),
  
  fluidRow(
    column(6, class = "fixed-width",
           wellPanel(
             fileInput("dataFile", "Choose Excel File", accept = ".xlsx"),
             uiOutput("groupSelect"),  # Dropdown to select the group column
             uiOutput("predictorSelect"),  # Dynamic UI for selecting up to 5 predictors
             actionButton("submit", "Generate ROC Plot"),
             helpText("Ensure predictors are selected only once and format is correct for ROC analysis.")
           ),
           wellPanel(
             h4("Output Options"),
             selectInput("fileFormat", "Select File Format:", choices = c("png", "pdf"), selected = "png"),
             numericInput("plotWidth", "Plot Width (inches):", value = 8, min = 5),
             numericInput("plotHeight", "Plot Height (inches):", value = 8, min = 5),
             downloadButton("downloadPlot", "Download Plot")
           )
    ),
    column(6,
           plotOutput("rocPlot")
    )
  )
))
