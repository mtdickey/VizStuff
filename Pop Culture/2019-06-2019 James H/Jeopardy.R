### Visualizing the Best of Jeopardy! ####
library(rvest)
library(dplyr)
library(stringr)
library(scales)
library(ggplot2)
library(XML)
library(plotly)

#### 1 - Collect Data ####
### Scan through J-Archive's season pages to get episode info ####
urls <- c("http://j-archive.com/showseason.php?season=20", 
          # ^ start with 2003 - season 21 (More than 5 wins in a row was not allowed before 2003)
          "http://j-archive.com/showseason.php?season=21",
          "http://j-archive.com/showseason.php?season=22",
          "http://j-archive.com/showseason.php?season=23",
          "http://j-archive.com/showseason.php?season=24",
          "http://j-archive.com/showseason.php?season=25",
          "http://j-archive.com/showseason.php?season=26",
          "http://j-archive.com/showseason.php?season=27",
          "http://j-archive.com/showseason.php?season=28",
          "http://j-archive.com/showseason.php?season=29",
          "http://j-archive.com/showseason.php?season=30",
          "http://j-archive.com/showseason.php?season=31",
          "http://j-archive.com/showseason.php?season=32",
          "http://j-archive.com/showseason.php?season=33",
          "http://j-archive.com/showseason.php?season=34"
          ## Through 34 (Current season - began 2017-09-11)
          )

games <- data.frame() # Initialize
for(url in urls){ # iterate through urls
  season_games <- (url %>%
    read_html() %>%  ## Use rvest to read the html
    html_nodes(xpath='//table') %>%
    html_table())[[1]]   # gather the table on the page, and store as a data frame
  season_games$link <- getHTMLLinks(url, xpQuery = "//table//@href")[grep("http://www.j-archive.com/showgame",
                                                                          getHTMLLinks(url, xpQuery = "//table//@href"))]
  season_games$season <- as.integer(substr(url,(nchar(url)-1),nchar(url))) # save season ID
  games <- rbind(games, season_games)
}
colnames(games) <- c("gameID", "competitors", "comments","link", "season")
games$Date <- as.Date(substr(as.character(games$gameID), (nchar(games$gameID)-9),nchar(games$gameID)), format = "%Y-%m-%d")

## Austin Roger's streak in Season 34 ###
url <- "https://thejeopardyfan.com/statistics/austin-rogers-jeopardy-statistics" # Season 34 not available, using alt. site
austin_wins <- (url %>%
  read_html() %>%  ## Use rvest to read the html
  html_nodes(xpath='//table') %>%
  html_table())[[1]]
austin_wins <- austin_wins[1:13,] # get rid of last two rows with totals/blank line
austin_wins$Winnings <- as.numeric(gsub("[^\\d]+", "", austin_wins$Winnings, perl=TRUE))
austin_wins$date_parse <- as.Date(austin_wins$Date, format = "%b %d, %Y")

games <- merge(games, austin_wins[,which(colnames(austin_wins) %in% c("date_parse","Winnings"))],
               by.x = "Date", by.y = "date_parse", all.x = T)

### Go through games with links and identify total winnings from the "Final Scores" Table ####
final_scores <- data.frame()
## This gets ugly because the formatting of tables is not consistent and takes awhile to restructure it all ###
for(link in games$link){
  if(length(link%>%
      read_html() %>%  ## Use rvest to read the html
      html_nodes(xpath="//h3[contains(., 'Final scores:')]/following-sibling::table") %>%
      html_table()) > 0){ # if there's a final scores header
    final_score <- (link%>%
                      read_html() %>%  ## Use rvest to read the html
                      html_nodes(xpath="//h3[contains(., 'Final scores:')]/following-sibling::table") %>%
                      html_table())[[1]]
    
    if(nrow(final_score) > 0 &
       (length(grep("co-champion", c(final_score$X1[3],final_score$X2[3],final_score$X3[3]))) == 0 & # no co-champions
        length(grep("(champion|Winner|Automatic semifinalist|Finalist)", c(final_score$X1[3],
                                                                           final_score$X2[3],
                                                                           final_score$X3[3]))) == 1 # and one winner
        ) 
       ){
      if(!is.na(final_score[3,1])){
      if( (final_score[3,1] != "" & final_score[3,2] != "" & final_score[3,3] != "")){
        ### Manipulate the table so it is 1 row (1st place name, 1st place winnings, 2nd place name, 2nd place winnings, ...)
        final_score_new <- data.frame(first_place_name = final_score[1,grep("(champion|Winner|Automatic semifinalist|Finalist)", c(final_score$X1[3],
                                                                                          final_score$X2[3],
                                                                                          final_score$X3[3]))],
                                      first_place_winnings = as.numeric(gsub("[^\\d]+", "",
                                                            final_score[2,grep("(champion|Winner|Automatic semifinalist|Finalist)", c(final_score$X1[3],
                                                                                  final_score$X2[3],
                                                                                  final_score$X3[3]))], perl=TRUE))
                                      # ,second_place_name = final_score[1,grep("2nd", c(final_score$X1[3],
                                      #                                                      final_score$X2[3],
                                      #                                                      final_score$X3[3]))],
                                      # second_place_winnings = 2000,
                                      #                            # as.numeric(gsub(",", "",
                                      #                            #            gsub("(^2)[^\\d]+", "",
                                      #                            #                  final_score[3,grep("2nd", c(final_score$X1[3],
                                      #                            #                  final_score$X2[3],
                                      #                            #                  final_score$X3[3]))], perl=TRUE))
                                      #                            #         ),
                                      # third_place_name = final_score[1,grep("3rd", c(final_score$X1[3],
                                      #                                                     final_score$X2[3],
                                      #                                                     final_score$X3[3]))],
                                      # third_place_winnings = 1000
                                      #                 # as.numeric(gsub(",", "",
                                      #                 #                        gsub("(^3)[^\\d]+", "",
                                      #                 #                             final_score[3,grep("3rd", c(final_score$X1[3],
                                      #                 #                                                         final_score$X2[3],
                                      #                 #                                                         final_score$X3[3]))], perl=TRUE)))
                                                            )
        
        colnames(final_score_new) <- gsub(".X1|.X2|.X3","",colnames(final_score_new))
        final_score_new$link <- link
        final_scores <- rbind(final_score_new, final_scores)
      } else{
        final_score_new <- data.frame(first_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                                                     gsub("[^\\d]+", "",
                                                                     final_score[2,1:3], perl=TRUE))) == 
                                                                            max(as.numeric(gsub(",", "",
                                                                            gsub("[^\\d]+", "",
                                                                                 final_score[2,1:3], perl=TRUE)))))],
                                      first_place_winnings = max(as.numeric(gsub(",", "",
                                                                   gsub("[^\\d]+", "",
                                                                         final_score[2,1:3], perl=TRUE))))
                                      # ,second_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                      #                                  gsub("[^\\d]+", "",
                                      #                                  final_score[2,1:3], perl=TRUE))) != 
                                      #                                  max(as.numeric(gsub(",", "",
                                      #                                  gsub("[^\\d]+", "",
                                      #                                  final_score[2,1:3], perl=TRUE)))) 
                                      #                                 & 
                                      #                                 as.numeric(gsub(",", "",
                                      #                                 gsub("[^\\d]+", "",
                                      #                                 final_score[2,1:3], perl=TRUE))) != 
                                      #                                 min(as.numeric(gsub(",", "",
                                      #                                 gsub("[^\\d]+", "",
                                      #                                 final_score[2,1:3], perl=TRUE)))) 
                                      #                               )],
                                      # second_place_winnings = 2000,
                                      # # as.numeric(gsub(",", "",
                                      # #            gsub("(^2)[^\\d]+", "",
                                      # #                  final_score[3,grep("2nd", c(final_score$X1[3],
                                      # #                  final_score$X2[3],
                                      # #                  final_score$X3[3]))], perl=TRUE))
                                      # #         ),
                                      # third_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                      #                                         gsub("[^\\d]+", "",
                                      #                                         final_score[2,1:3], perl=TRUE))) == 
                                      #                                          min(as.numeric(gsub(",", "",
                                      #                                                         gsub("[^\\d]+", "",
                                      #                                                         final_score[2,1:3], perl=TRUE)))))],
                                      # third_place_winnings = 1000
                                      # # as.numeric(gsub(",", "",
                                      # #                        gsub("(^3)[^\\d]+", "",
                                      # #                             final_score[3,grep("3rd", c(final_score$X1[3],
                                      # #                                                         final_score$X2[3],
                                      # #                                                         final_score$X3[3]))], perl=TRUE)))
        )
        colnames(final_score_new) <- gsub(".X1|.X2|.X3","",colnames(final_score_new))
        
        final_score_new$link <- link
        final_scores <- rbind(final_score_new, final_scores)
        
      }
      } else{
        final_score_new <- data.frame(first_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                                                                             gsub("[^\\d]+", "",
                                                                                                  final_score[2,1:3], perl=TRUE))) == 
                                                                             max(as.numeric(gsub(",", "",
                                                                                                 gsub("[^\\d]+", "",
                                                                                                      final_score[2,1:3], perl=TRUE)))))],
                                      first_place_winnings = max(as.numeric(gsub(",", "",
                                                                                 gsub("[^\\d]+", "",
                                                                                      final_score[2,1:3], perl=TRUE))))
                                      # ,second_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                      #                                                         gsub("[^\\d]+", "",
                                      #                                                              final_score[2,1:3], perl=TRUE))) != 
                                      #                                         max(as.numeric(gsub(",", "",
                                      #                                                             gsub("[^\\d]+", "",
                                      #                                                                  final_score[2,1:3], perl=TRUE)))) 
                                      #                                         & 
                                      #                                         as.numeric(gsub(",", "",
                                      #                                                         gsub("[^\\d]+", "",
                                      #                                                              final_score[2,1:3], perl=TRUE))) != 
                                      #                                         min(as.numeric(gsub(",", "",
                                      #                                                             gsub("[^\\d]+", "",
                                      #                                                                  final_score[2,1:3], perl=TRUE)))) 
                                      # )],
                                      # second_place_winnings = 2000,
                                      # # as.numeric(gsub(",", "",
                                      # #            gsub("(^2)[^\\d]+", "",
                                      # #                  final_score[3,grep("2nd", c(final_score$X1[3],
                                      # #                  final_score$X2[3],
                                      # #                  final_score$X3[3]))], perl=TRUE))
                                      # #         ),
                                      # third_place_name = final_score[1,which(as.numeric(gsub(",", "",
                                      #                                                        gsub("[^\\d]+", "",
                                      #                                                             final_score[2,1:3], perl=TRUE))) == 
                                      #                                        min(as.numeric(gsub(",", "",
                                      #                                                            gsub("[^\\d]+", "",
                                      #                                                                 final_score[2,1:3], perl=TRUE)))))],
                                      # third_place_winnings = 1000
                                      # # as.numeric(gsub(",", "",
                                      # #                        gsub("(^3)[^\\d]+", "",
                                      # #                             final_score[3,grep("3rd", c(final_score$X1[3],
                                      # #                                                         final_score$X2[3],
                                      # #                                                         final_score$X3[3]))], perl=TRUE)))
        )
        colnames(final_score_new) <- gsub(".X1|.X2|.X3","",colnames(final_score_new))
        
        final_score_new$link <- link
        final_scores <- rbind(final_score_new, final_scores)
        
      }
    } 
  }
}

games <- merge(games,final_scores,by="link",all.x = T)

## Dataset with streaks and game-by-game winnings
streak_games <- games[grep(" game ", games$comments),]
streak_games$comments_one_sentence <- gsub("\\..*","",streak_games$comments)
streak_games$game_number <- as.numeric(str_extract(streak_games$comments_one_sentence, "(?i)(?<=game\\D)\\d+"))
streak_games$competitor  <- str_extract(streak_games$comments_one_sentence, "\\D+(?>=game)")
streak_games <- streak_games[-grep("Tournament of Champions|College Championship|Kids Week|Teen Tournament|Teachers Tournament|Power Players|Celebrity Jeopardy!|4th regular play|Battle of the Decades|First|IBM Challenge|Last|Second", streak_games$competitor),]

#### 2 - Visualize ####
### Top streaks ####
# number of games won for each competitor
streak_lengths <- streak_games %>% group_by(competitor) %>% summarise(Streak = (max(game_number,na.rm=T)-1)) %>% filter(Streak > 5) %>% arrange(desc(Streak))
ggplot(streak_lengths, aes(reorder(competitor, -Streak))) + geom_bar(aes(weight = Streak))

### Top earners ####
## fill missing with Austin's scraped on another source
streak_games$first_place_winnings[which(is.na(streak_games$first_place_winnings))] <- 
  streak_games$Winnings[which(is.na(streak_games$first_place_winnings))]
streak_games$Winnings <- streak_games$first_place_winnings
last_games <- streak_games %>% group_by(competitor) %>% 
                mutate(maxGame = max(game_number)) %>% filter(game_number == maxGame) %>% group_by()
last_games$Winnings_fixed <- 2000 ## last game winnings should only be 2000 (bad assumption that they got second)
streak_games <- merge(streak_games, last_games[,c("link","Winnings_fixed")], all.x = T)
streak_games$Winnings_fixed[which(is.na(streak_games$Winnings_fixed))] <- streak_games$Winnings[which(is.na(streak_games$Winnings_fixed))]
streak_games$Winnings_fixed[which(streak_games$link == "http://www.j-archive.com/showgame.php?game_id=4411")] <- 18200 #manually add Arthur Chu game 2
streak_games <- streak_games %>% arrange(game_number) %>%
  group_by(competitor)%>%
  mutate(CumulativeWinnings=cumsum(Winnings_fixed)) %>% # calculate cumulative earnings
  group_by() 
streak_lengths <- streak_games %>% group_by(competitor) %>% summarise(Streak = (max(game_number,na.rm=T)-1))
streak_games <- merge(streak_games,streak_lengths,by="competitor",all.x=T)

### Cumulative money earned by game (Austin Rogers vs Others) ####
streak_games %>% filter(Streak > 10) %>%
  ggplot(aes(x = game_number, y = CumulativeWinnings)) + geom_line(aes(color = competitor), size = 1.1, alpha = .6) +
  scale_y_continuous(labels = scales::dollar) +
  labs(x = "Game Number", y = "Cumulative Winnings", color = "Competitor") ## full

streak_games %>% filter(Streak > 10 & game_number <= 20) %>%
  ggplot(aes(x = game_number, y = CumulativeWinnings)) + geom_line(aes(color = competitor), size = 1.1, alpha = .6) +
  scale_y_continuous(labels = scales::dollar) +
  labs(x = "Game Number", y = "Cumulative Winnings", color = "Competitor") ## zoomed

ggplotly(streak_games %>% filter(Streak > 10) %>%
  ggplot(aes(x = game_number, y = CumulativeWinnings)) + geom_line(aes(color = competitor), size = 1.1, alpha = .6) +
  scale_y_continuous(labels = scales::dollar) +
  labs(x = "Game Number", y = "Cumulative Winnings", color = "Competitor")) ## interactive
