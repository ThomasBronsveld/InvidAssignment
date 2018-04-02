#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library("sqldf")
library("RJDBC")
library("DBI")

setwd("C:/Users/ThomasBronsveld/Documents/Big Data/DataStorage/InvidAssignment")
drv <- JDBC("com.mysql.jdbc.Driver", "C:/Users/ThomasBronsveld/Documents/Big Data/DataStorage/mysql-connector-java-5.1.45-bin.jar")
conn <- dbConnect(drv, "jdbc:mysql://localhost/opdrachtstorage", "root", "Jikdepok12345@", useSSL=FALSE)

getGenres <- "SELECT genre
              FROM genres"
genres <- dbGetQuery(conn, getGenres)

# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Ratatoskr"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         selectInput(inputId = "genres",
                     label = "genres:",
                     choices = genres
                     )
      ),
      
      # Show a plot of the generated distribution
      mainPanel(
         plotOutput("distPlot")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  getAPIRating <- reactive({
    req(input$genres)
    gemiddeldeScore <- 0
    sqlString <- "SELECT title
    FROM movies m INNER JOIN moviesgenre mg ON m.movieId = mg.movieId
    WHERE mg.genreId = (SELECT g.genreId
    FROM genres g
    WHERE g.genre = '"
    sqlString <- paste(paste(sqlString, select(input$genres), sep = ""), "')", sep = "")
    
    moviesDatabase <- dbGetQuery(conn, sqlString)
    
    listScores <- list()
    for(i in 1:200){
      test2 <- find_by_title(test$title[i])
      listScores <- cbind(listScores, test2$imdbRating[1]) 
      gemiddeldeScore <- mean(unlist(listScores))
    }
    return(gemiddeldeScore)
  })
  
  getMovieLensRatings <- reactive({
    req(input$genres)
    gemiddeldeScore <- 0
    sqlString <- "SELECT AVG(gemiddeldeRating)
    FROM averageratings a INNER JOIN moviesgenre mg ON a.movieId = mg.movieId
    WHERE mg.genreId = (SELECT g.genreId
    FROM genres g
    WHERE g.genre = '"
    sqlString <- paste(paste(sqlString, select(input$genres), sep = ""), "')", sep = "")
    
    movieLensrating <- dbGetQuery(conn, sqlString)
    gemiddeldeScore <- movieLensrating * 2
    return(gemiddeldeScore)
  })
   output$distPlot <- renderPlot({
      # generate bins based on input$bins from ui.R
      x    <- faithful[, 2] 
      bins <- seq(min(x), max(x), length.out = input$bins + 1)
      
      # draw the histogram with the specified number of bins
      hist(x, breaks = bins, col = 'darkgray', border = 'white')
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

