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
          "http://j-archive.com/showseason.php?season=35"
          ## Through 35 (Current season - began 2018-09-10)
          )

get_games <- function(url){
  ## function to get links for all games in the seasons
  season_games <- (url %>%
    read_html() %>%  ## Use rvest to read the html
    html_nodes(xpath='//table') %>%
    html_table())[[1]]   # gather the table on the page, and store as a data frame
  season_games$link <- getHTMLLinks(url, xpQuery = "//table//@href")[grep("http://www.j-archive.com/showgame",
                                                                     getHTMLLinks(url, xpQuery = "//table//@href"))]
  season_games$season <- as.integer(substr(url,(nchar(url)-1),nchar(url))) # save season ID
  
  ## Name columns
  colnames(season_games) <- c("gameID", "competitors", "comments","link", "season")
  
  ## add date column
  season_games$Date <- as.Date(substr(as.character(season_games$gameID),
                                      (nchar(season_games$gameID)-9),nchar(season_games$gameID)), format = "%Y-%m-%d")
  return(season_games)
}

## Apply the function to the list of season URLs
games <- lapply(urls, get_games) # get list of dfs
games <- bind_rows(games, .id = "column_label") # bind together
games <- games[,2:ncol(games)] ## drop ID column


### Go through games with links and identify total winnings from the "Final Scores" Table ####
get_final_scores <- function(url){
  if(length(url%>%
            read_html() %>%  ## Use rvest to read the html
            html_nodes(xpath="//h3[contains(., 'Final scores:')]/following-sibling::table") %>%
            html_table()) > 0){ # if there's a final scores header
    final_score <- (url%>%
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
          )
          
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
          )
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
        )
        
      }
      colnames(final_score_new) <- gsub(".X1|.X2|.X3","",colnames(final_score_new))
      final_score_new$link <- url
      return(final_score_new)
    } 
  }
}

## Apply the function to the list of game URLs
final_scores <- lapply(games$link, get_final_scores)
final_scores <- bind_rows(final_scores, .id = "column_label")
final_scores <- final_scores[,2:ncol(final_scores)]
games <- merge(games,final_scores,by="link",all.x = T)

## Dataset with streaks and game-by-game winnings
streak_games <- games[grep(" game ", games$comments),]
streak_games$comments_one_sentence <- gsub("\\..*","",streak_games$comments)
streak_games$game_number <- as.numeric(str_extract(streak_games$comments_one_sentence, "(?i)(?<=game\\D)\\d+"))
streak_games$competitor  <- sapply(str_split(streak_games$comments_one_sentence, " game "), "[", 1)

#### 2 - Visualize ####
### Top streaks ####
# number of games won for each competitor
streak_lengths <- streak_games %>% group_by(competitor) %>%
  summarise(Streak = (max(game_number,na.rm=T)-1)) %>%
  filter(Streak > 10)
ggplot(streak_lengths, aes(reorder(competitor, -Streak))) + geom_bar(aes(weight = Streak))

### Top earners ####
streak_games <- streak_games %>% mutate(Winnings = ifelse(first_place_name %in% c("Ken",
                                                                            "James"),
                                                          first_place_winnings, 2000)) ## assume last game they got 2nd
streak_games <- streak_games %>% arrange(game_number) %>%
  group_by(competitor)%>%
  mutate(CumulativeWinnings=cumsum(Winnings)) %>% # calculate cumulative earnings
  group_by() 
streak_lengths <- streak_games %>% group_by(competitor) %>% summarise(Streak = (max(game_number,na.rm=T)-1))
streak_games <- merge(streak_games,streak_lengths,by="competitor",all.x=T)

### Cumulative money earned by game (James vs Ken) ####
streak_games %>% filter(competitor %in% c("Ken Jennings", "James Holzhauer")) %>%
  ggplot(aes(x = game_number, y = CumulativeWinnings)) + geom_step(aes(color = competitor), size = 1.1, alpha = .6) +
  scale_y_continuous(labels = scales::dollar) +
  guides(color = F) +
  labs(title = "Jeopardy! James vs. Ken Jennings", x = "\nGame Number",
       y = "Cumulative Winnings\n", color = "Competitor") +
  theme()


ggplotly(streak_games %>% filter(Streak > 10 & competitor %in% c("Ken Jennings", "James Holzhauer")) %>%
  ggplot(aes(x = game_number, y = CumulativeWinnings)) + geom_step(aes(color = competitor), size = 1.1, alpha = .6) +
  scale_y_continuous(labels = scales::dollar) +
  labs(x = "Game Number", y = "Cumulative Winnings", color = "Competitor")) ## interactive


## Distributions of $$ per game ####


## $$ earned from daily doubles #### 