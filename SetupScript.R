#@Author Thomas Bronsveld <500757630 thomas.bronsveld@hva.nl> 
#Dit script is gebruikt om alles te filteren, op te zetten en wegschrijven naar mijn MySQL database.

#Laad de nodige libraries.

library("RJDBC")
library("sqldf")
library("DBI")
library("dplyr")
library("RSQLite")

#Zet de huidige working directory waar alle csv's staan.
setwd("C:/Users/ThomasBronsveld/Documents/Big Data/DataStorage/InvidAssignment")

#Locatie jar
drv <- JDBC("com.mysql.jdbc.Driver", "C:/Users/ThomasBronsveld/Documents/Big Data/DataStorage/mysql-connector-java-5.1.45-bin.jar")

#De connectie
conn <- dbConnect(drv, "jdbc:mysql://localhost/opdrachtstorage", "root", "Jikdepok12345@", useSSL=FALSE)
getGenres <- "SELECT genre
              FROM genres"
genres <- dbSendQuery(conn, getGenres)
#Lees alle csv's in.
listTables <- dbListTables(conn)

movies <- read.csv("movies.csv") #done
ratings <- read.csv("ratings.csv") #Done

genres <- data.frame(unique(unlist(strsplit(as.character(movies$genres),'\\|'))))
genres$genreId <- 1:nrow(genres)
colnames(genres)[1] <- "genre"

createJointTable <- function(movieId, genreColumn){
  movieGenre <- unlist(strsplit(as.character(genreColumn),'\\|'))
  
  if (!('moviesgenre' %in% listTables)){
    createTable <- "CREATE TABLE moviesgenre(
                    movieId INT,
                    genreId INT)"
    dbSendUpdate(conn, createTable)
  }
  for(i in 1:length(movieGenre)){
   if (is.na(movieGenre[i]) == TRUE){
       next
   }
    sqlString <- "SELECT genreId
                  FROM genres
                  WHERE genre = '"
    sqlString <- paste(paste(sqlString, as.character(movieGenre[i]), sep = ""), "'", sep = "")
    idGenre <- sqldf(sqlString, stringsAsFactors = FALSE)
    sqlUpdateQuery <- "INSERT INTO moviesgenre (movieId, genreId)
                       VALUES ('"
    sqlUpdateQuery <-  paste(paste(sqlUpdateQuery, as.character(movieId), sep = ""), "', '", sep = "")
    sqlUpdateQuery <- paste(paste(sqlUpdateQuery, as.character(idGenre), sep = ""), "')", sep = "")
    dbSendUpdate(conn = conn, statement = sqlUpdateQuery)
  }
}

for (i in movies$movieId) {
  createJointTable(movies$movieId[i], unlist(strsplit(as.character(movies$genres[i]), '\\|')))
}

movies$title<-paste0(substr(movies$title,1,nchar(as.character(movies$title))-6))

sqlStringMovies <- "SELECT movieId, title
                      FROM movies"
movies <- sqldf(sqlStringMovies, stringsAsFactors = FALSE)

sqlStringRatings <- "SELECT movieId, AVG(rating)
                     FROM ratings
                     GROUP BY movieId
                     ORDER BY movieId"

# sqlStringOuterJoin <- "SELECT movies.movieId
#                        FROM movies 
#                        LEFT JOIN ratings ON movies.movieId = ratings.movieId
#                        WHERE ratings.movieId IS NULL"
gemiddeldeRating <- sqldf(sqlStringRatings, stringsAsFactors = FALSE)
#@test <- sqldf(sqlStringOuterJoin, stringsAsFactors = FALSE)
colnames(gemiddeldeRating)[2] <- "gemiddeldeRating"

#Wegschrijven van de genome-tags csv. Aangezien hier alles al georderd is.
dbWriteTable(conn,name="Movies", value= movies, append=FALSE, row.names=FALSE, overwrite=FALSE)
dbWriteTable(conn,name="AverageRatings", value= gemiddeldeRating, append=FALSE, row.names=FALSE, overwrite=FALSE)
dbWriteTable(conn,name="Genre", value= genres, append=FALSE, row.names=FALSE, overwrite=FALSE)






