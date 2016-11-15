### Visualization of How QBs Distribute Their Yardage ###
setwd("~/Random/Football")

library(ggplot2)
library(gridExtra)
library(stringr)
library(dplyr)
library(plotly)

# Play-by-Play Dataset #
Plays <- read.csv("2016NFLData.csv", stringsAsFactors = F)

## Clean up #
Plays <- Plays[-which(substr(Plays$Detail,1,1) == "("),] # Gets rid of weird observations like this "(tackle by Zach Sanchez)"
Plays <- Plays[-grep("Two Point Attempt: ", Plays$Detail),] # Get rid of extra text that gets in the way of word operation below

# Text Operations on "Detail" Column
Plays$QB <- paste0(word(Plays$Detail,2), ", ", substr(word(Plays$Detail,1), 1, 1), ".")  # 51 Passers with Completions matches Pro-football-reference
Plays$Receiver <- paste0(word(Plays$Detail,9), ", ", substr(word(Plays$Detail,8),1,1), ".") # We have 381 people with receptions compared to their 378

## 2 manual corrections
Plays$Receiver[which(Plays$Detail == "Drew Brees pass complete middle to Mark Ingram for -1 yards (tackle by Vic Beasley)")] <- "Ingram, Mark"
Plays$Receiver[which(Plays$Detail == "Derek Carr pass complete to Seth Roberts for 19 yards touchdown")] <- "Roberts, Seth"

# Factorize
Plays$QB <- as.factor(Plays$QB)
Plays$Receiver <- as.factor(Plays$Receiver)

# Use Dplyr to summarise the way we'd like initially
Summary <- Plays %>% group_by(QB, Receiver) %>% summarise(TotalYds = sum(Yds, na.rm = T))

# Summarize further into % of Yards by #1 receiver, #2, etc., keep only top 10 yardage QBs
Summary2 <- Summary %>% group_by(QB) %>% arrange(desc(TotalYds)) %>% mutate(Total = sum(TotalYds,na.rm=T), 
                                                                            my_ranks = order(TotalYds, decreasing = T),
                                                                            percent = TotalYds/Total) %>%
                        filter(Total > 1800) # to keep only top 10 yardage QBs

Summary2$my_ranks <- as.character(Summary2$my_ranks)                        
Summary2$my_ranks[which(as.numeric(Summary2$my_ranks) >= 4)] <- "4+"
Summary2$my_ranks <- as.factor(Summary2$my_ranks)

temp <- Summary2 %>% group_by(QB) %>%
  filter(min_rank(desc(Total)) <= 10) %>% group_by(QB, my_ranks) %>% summarise(Perc = sum(percent), Receiver = unique(Receiver)[1], Total = mean(Total))
temp$Receiver <- as.character(temp$Receiver)
temp$Receiver[which(temp$my_ranks == "4+")] <- paste0(temp$Receiver[which(temp$my_ranks == "4+")], " + Others")


## To control ordering by #1 receiver
temp$QB <- as.character(temp$QB)
temp$QBSort <-  factor(temp$QB, levels = unique(temp$QB[which(temp$my_ranks=="1")][order(temp$Perc[which(temp$my_ranks == "1")], decreasing = T)]))
temp$CumulativePercent <- round(temp$Perc*100, 3)

## Visualize
ggplot(temp, aes(x = QBSort, y = CumulativePercent, fill = my_ranks, label = Receiver)) + geom_bar(stat = "identity") +
  ggtitle(expression(atop("Proportion of Yards/Receiver for Top 10 Yardage QBs", atop(italic("2016 Season - Through Week 7"), "")))) +
  labs(x = "QB", y = "Percent of Yards", fill = "Receiver Rank") +
  theme(legend.title = element_text(size = 10))

# Modifying so it interacts well with Plotly
temp$QB <- temp$QBSort
VizInt <- ggplot(temp, aes(x = QB, y = CumulativePercent, fill = my_ranks, label = Receiver)) + geom_bar(stat = "identity") +
  labs(title = "Proportion of Yards/Receiver for Top 10 Yardage QBs", x = "QB", y = "Percent of Yards", fill = "WR Rank") +
  theme(legend.title = element_text(size = 10))

## Interactive
VizInt %>% ggplotly(tooltip = c("x", "y", "label"))
