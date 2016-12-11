# lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

library(shiny)
library(RMySQL)


ui <- fluidPage(
  sliderInput(inputId = "days", 
              label = "Choose number of days to plot", 
              value = 2, min = 1, max = 30),
  
  plotOutput(outputId = "temp_plot", height = "300px"),
  plotOutput(outputId = "humid_plot", height = "300px"),
  plotOutput(outputId = "pres_plot", height = "300px")
  
)

server <- function(input, output) {
  mydb = dbConnect(MySQL(), user='arduinouser', password='arduino', dbname='arduino_data', host='192.168.1.132')
  table <- reactive({
    table = dbGetQuery(mydb, paste("SELECT * FROM `temps` WHERE `temp_date` >= now() - INTERVAL ", input$days ," DAY;"))
  })
  
  output$temp_plot <- renderPlot({
    plot(as.POSIXct(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S")),table()$temp_c*1.8+32,
         xaxt = "n",
         main = 'recent temperature and humidity data', xlab = '', ylab = 'deg. F',
         type = 'l', col = 'red')
    axis.POSIXct(side=1, at=cut(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S"), "days"), format="%m/%d")
  })
  output$humid_plot <- renderPlot({
    plot(as.POSIXct(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S")),table()$humid,
         xaxt = "n",
         main = 'humidity', xlab = '', ylab = 'humidity (%)',
         type = 'l', col = 'green')
    axis.POSIXct(side=1, at=cut(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S"), "days"), format="%m/%d")
  })
  output$pres_plot <- renderPlot({
    plot(as.POSIXct(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S")),table()$pressure*0.000145038,
         xaxt = "n",
         main = 'pressure', xlab = '', ylab = 'psi',
         type = 'l', ylim=c(14.2,15), col = 'red')
    axis.POSIXct(side=1, at=cut(strptime(table()$temp_date, format="%Y-%m-%d %H:%M:%S"), "days"), format="%m/%d")
  })
}

shinyApp(ui = ui, server = server)


