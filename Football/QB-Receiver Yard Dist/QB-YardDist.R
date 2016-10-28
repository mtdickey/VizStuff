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
Plays$Receiver <- paste0(word(Plays$Detail,9), ", ", word(Plays$Detail,8)) # We have 381 people with receptions compared to their 378

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
  filter(min_rank(desc(Total)) <= 10) %>% group_by(QB, my_ranks) %>% summarise(Perc = sum(percent))

## To control ordering by #1 receiver
temp$QB <- as.character(temp$QB)
temp$QBSort <-  factor(temp$QB, levels = unique(temp$QB[which(temp$my_ranks=="1")][order(temp$Perc[which(temp$my_ranks == "1")], decreasing = T)]))

ggplot(temp, aes(x = QBSort, y = Perc, fill = my_ranks)) + geom_bar(stat = "identity") +
  labs(title = "Receiver Distributions for Top 10 Yardage QBs", x = "QB", y = "Percent of Yards", fill = "Receiver Rank")

## Visualize
(viz <- All %>%
  group_by(Passer) %>%
  mutate(outlier = ifelse(TotalTDs > 30, ReceiverLastName, as.numeric(NA))) %>%
  ggplot(aes(x=PasserSort, y=TotalTDs,  fill = PasserSort)) + 
  geom_violin(alpha = .8) + geom_boxplot(width=0.1, fill="white") + 
  geom_text(aes(label = outlier, colour = factor(together)), na.rm = T, hjust = 1.1, size = 3.5) +
  scale_colour_discrete(l=40) +
  scale_fill_manual(values=c("#3182bd", "#AF1E2C", "#b0e0e6", "008E97", "#cfb53b", "#0D254C", "#00338D", "#3182bd",
                             "#203731", "#006DB0", "#AF1E2C", "#BD0D18", "#0D254C", "#203731", "#FB4F14")) +
  guides(fill = F) +
  labs(x = "QB", y = "TDs Thrown to Receiver", title = "Dynamic Duos", colour = "Active Tandem"))

## Interactive
ggplotly(viz, tooltip = c("x","y", "label"))
