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

movies <- read.csv("movies.csv") #done
ratings <- read.csv("ratings.csv") #Done
moviesKaggle <- read.csv("movies_metadata.csv")

moviesKaggle <- moviesKaggle[-c(1:3,5,7:20, 22, 24)]
moviesKaggleSQLString <- "SELECT id, title, vote_average
                          FROM moviesKaggle"
moviesKraggleDB <- sqldf(moviesKaggleSQLString, stringsAsFactors = FALSE)

#genre values are given as Adventure|Comedy etc
genres <- data.frame(unique(unlist(strsplit(as.character(movies$genres),'\\|'))))
genres$genreId <- 1:nrow(genres)
colnames(genres)[1] <- "genre"
dbWriteTable(conn,name="Genre", value= genres, append=FALSE, row.names=FALSE, overwrite=FALSE)

movies <- sqldf(moviesSQLString, stringsAsFactors = FALSE)

#
listTables <- dbListTables(conn)
createJointTable <- function(movieId, genreColumn){
  #The genres are given in the genreColumn as following: Adventure|Comedy|Horror etc
  movieGenre <- unlist(strsplit(as.character(genreColumn),'\\|'))
  
  #Create the table in the database if it doesn't exist. This is checked and done to make it easier to continue
  #my code on a different laptop without having to setup the entire table again.
  if (!('moviesgenre' %in% listTables)){
    createTable <- "CREATE TABLE moviesgenre(
                    movieId INT,
                    genreId INT)"
    dbSendUpdate(conn, createTable)
  }
  
  for(i in 1:length(movieGenre)){
   if (is.na(movieGenre[i]) == TRUE){ #If the genre is NA, then the movie has no relevance to my research so I skip it. 
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
  createJointTable(movies$movieId[i], movies$genres[i])
}

# createJointTableKaggle <- function(movieId){
#   minChar <- 2
# 
#   if (!('movieskagglegenre' %in% listTables)){
#     createTable <- "CREATE TABLE movieskagglegenre(
#     movieId INT,
#     genreId INT)"
#     dbSendUpdate(conn, createTable)
#   }
#   for (i in 1:length(genres$genreId)){
#     sqlString2 <- "SELECT genre
#                      FROM genres
#                      WHERE genreId = '"
#     sqlString2 <-paste(paste(sqlString2, genres$genreId[i], sep = ""), "'", sep = "")
#     genreKaggle <- sqldf(sqlString2, stringsAsFactors = FALSE)
#     
#     #print(genreKaggle %in% moviesKaggle$genres[movieId] == TRUE)
#     if(genreKaggle %in% moviesKaggle$genres[movieId] == TRUE){
#       
#       sqlUpdateQuery <- "INSERT INTO moviesgenre (movieId, genreId)
#         VALUES ('"
# 
#       sqlUpdateQuery <- paste(paste(sqlUpdateQuery, as.character(movieId), sep = ""), "', '", sep = "")
# 
#       sqlUpdateQuery <-paste(paste(sqlUpdateQuery, as.character(genres$genreId[i]), sep = ""), "')", sep = "")
#       print("sqlUpdateQuery")
#       dbSendUpdate(conn = conn, statement = sqlUpdateQuery)
#     }
#   }
# }


for (i in moviesKaggle$id) {
  createJointTableKaggle(i)
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
dbWriteTable(conn,name="MoviesKaggle", value = moviesKraggleDB, append=FALSE, row.names=FALSE, overwrite=FALSE)
dbWriteTable(conn,name="MoviesKaggleTest", value = moviesKaggle, append=FALSE, row.names=FALSE, overwrite=FALSE)
dbDisconnect(conn)





