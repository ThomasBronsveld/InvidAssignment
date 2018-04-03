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

# getAPIRatings <- function(genre = "Adventure"){
#   print(genre)
#   gemiddeldeScore <- 0
#   sqlString <- "SELECT title
#                 FROM movies m INNER JOIN moviesgenre mg ON m.movieId = mg.movieId
#                 WHERE mg.genreId = (SELECT g.genreId
#                                     FROM genres g
#                                     WHERE g.genre = '"
#   sqlString <- paste(paste(sqlString, genre, sep = ""), "')", sep = "")
# 
#   moviesDatabase <- dbGetQuery(conn, sqlString)
# 
#   listScores <- list()
#   for(i in 1:length(moviesDatabase$title)){
#     test2 <- find_by_title(moviesDatabase$title[i])
#     listScores[[i]] <- test2$imdbRating[1]
#   }
#   gemiddeldeScore <- mean(unlist(listScores))
#   databaseNaam2 <- "omdb"
#   dataFrame2 <- data.frame(databaseNaam, gemiddeldeScore)
#   return(dataFrame2)
# }

#Deze functie 

getKaggleRatings <- function(genreKaggle = "Adventure"){
  sqlStringKaggle <- "SELECT AVG(vote_average)
                      FROM movieskaggle
                      WHERE genres LIKE '%"
  sqlStringKaggle <- paste(paste(sqlStringKaggle, genreKaggle, sep = ""), "%'", sep = "")
  resultKaggle <- dbGetQuery(conn, sqlStringKaggle)
  databaseNaam <- "Kaggle"
  databaseScorekaggle <- data.frame(databaseNaam, resultKaggle)
  return(databaseScorekaggle)
}

getMovieLensRatings <- function(genre = "Adventure"){
  
  sqlString <- "SELECT AVG(gemiddeldeRating)
                FROM averageratings a INNER JOIN moviesgenre mg ON a.movieId = mg.movieId
                WHERE mg.genreId = (SELECT g.genreId
                FROM genres g
                WHERE g.genre = '"
  sqlString <- paste(paste(sqlString, genre, sep = ""), "')", sep = "")
  movieLensrating <- dbGetQuery(conn, sqlString)
  gemiddeldeScore <- as.list(movieLensrating * 2)
  databaseNaam <- "Movielens"
  databaseScore <- data.frame(databaseNaam, gemiddeldeScore)
  return(databaseScore)
}


# Define UI for application that draws a histogram
ui <- fluidPage(
   
   # Application title
   titlePanel("Ratatoskr"),
   
   # Sidebar with a slider input for number of bins 
   sidebarLayout(
      sidebarPanel(
         selectInput(inputId = "genres_var",
                     label = "genres:",
                     choices = genres,
                     selected = "Adventure",
                     selectize = TRUE
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
   
  getTheRatings <- reactive({
    kaggleRating <- getKaggleRatings(input$genres_var)
    colnames(kaggleRating)[2] <- "gemiddeldeScore"
    movieLensRating <- getMovieLensRatings(input$genres_var)
    colnames(movieLensRating)[2] <- "gemiddeldeScore"
    plotData <- rbind(movieLensRating, kaggleRating)
    return(plotData)
  })
  
  output$distPlot <- renderPlot({
      plotData <- getTheRatings()
      ggplot(data = plotData, aes(x =plotData$databaseNaam , y = plotData$gemiddeldeScore)) +
        geom_bar(stat = "identity", fill = "#FF6666") +
        labs(x = "De database", y = "De gemiddelde gegeven score")
   })
}

# Run the application 
shinyApp(ui = ui, server = server)

