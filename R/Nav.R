# Author(s) (ordered by contribution): Hming Zama

# Install packages if not installed, then load packages
packages <- c('shiny', 'leaflet','maps', 'shinydashboard')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

# UI
ui <- navbarPage(
  title = "STAT191",
  tabPanel("Map",
           sidebarLayout(
             sidebarPanel(
               # Dataset selection
               radioButtons("dataset", "Data Sets:",
                            choices = c("Merged", "Demand", "Lightning", "Wildfire"),
                            selected = "Merged"),
               textInput("model", "Model:", value = "Your Model Name"),
               shinydashboard::valueBoxOutput("MAE"),
               shinydashboard::valueBoxOutput("RAE")
             ),
             mainPanel(
               leafletOutput("map")
             )
           )),
  tabPanel("Summary Outputs",
           sidebarLayout(
             sidebarPanel(
             ),
             mainPanel(
               plotOutput("plot2")
             )
           ))
)

server <- function(input, output) {
  
  # Read the datasets
  wildfire_data <- read.csv("WildfirePredictionsLM.csv")
  lightning_data <- read.csv("LightningPredictionsETS.csv")
  interchange_data <- read.csv("InterchangePredictionsETS.csv")
  unified_data <- read.csv("UnifiedPredictions.csv")
  
  # Check the first few rows of each dataset
  observe({
    print(head(wildfire_data))
    print(head(lightning_data))
    print(head(interchange_data))
    print(head(unified_data))
  })
  
  # Switch between datasets based on the selected radio button
  selected_data <- reactive({
    switch(input$dataset,
           "Merged" = unified_data,
           "Demand" = interchange_data,
           "Lightning" = lightning_data,
           "Wildfire" = wildfire_data)
  })
  
  # Update the value boxes based on the selected dataset
  output$MAE <- renderValueBox({
    valueBox("Mean Absolute Error", 108)
  })
  
  output$RAE <- renderValueBox({
    valueBox("Relative Absolute Error", "44.85%")
  })
  
  output$map <- renderLeaflet({
    ####
    us_states <- map("state", fill = TRUE, plot = FALSE)
    
    leaflet(data = us_states) %>%
      addTiles() %>%
      addPolygons(fillColor = "white", color = "black", weight = 1, fillOpacity = 0.5) %>%
      addLegend(position = "bottomright", 
                colors = "white", 
                labels = "",
                title = input$dataset)
  })
}

# Connection
shinyApp(ui = ui, server = server)
