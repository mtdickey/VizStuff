### Visulization of TD passes from player to player ###
library(ggplot2)
library(gridExtra)
library(stringr)
library(dplyr)
library(plotly)

# Datasets (source: pro-football-reference.com, Ex url: http://www.pro-football-reference.com/players/R/RivePh00/touchdowns/passing)#
Rivers <- read.csv("RiversTDs.csv", stringsAsFactors = F, header = F)
Brady  <- read.csv("BradyTDs.csv", stringsAsFactors = F, header = F)
Manning <- read.csv("PManningTDs.csv", stringsAsFactors = F, header = F)
Ryan    <-  read.csv("RyanTDs.csv", stringsAsFactors = F, header = F)
Stafford <- read.csv( "StaffordTDs.csv", stringsAsFactors = F, header = F)
Brees    <-  read.csv("BreesTDs.csv", stringsAsFactors = F, header = F)
Romo     <- read.csv( "RomoTDs.csv", stringsAsFactors = F, header = F)
Rodgers  <-  read.csv("RodgersTDs.csv", stringsAsFactors = F, header = F)

# Passer Identifier columns
Rivers$Passer <- "Rivers"
Brady$Passer <- "Brady"
Manning$Passer <- "Manning"
Ryan$Passer <- "Ryan"
Stafford$Passer <- "Stafford"
Brees$Passer <- "Brees"
Romo$Passer <- "Romo"
Rodgers$Passer <- "Rodgers"

## Name columns consistently
colnames(Rivers)[1:2] <- c("Receiver", "TotalTDs")
colnames(Brady)[1:2] <- c("Receiver", "TotalTDs")
colnames(Manning)[1:2] <- c("Receiver", "TotalTDs")
colnames(Ryan)[1:2] <- c("Receiver", "TotalTDs")
colnames(Stafford)[1:2] <- c("Receiver", "TotalTDs")
colnames(Brees)[1:2] <- c("Receiver", "TotalTDs")
colnames(Romo)[1:2] <- c("Receiver", "TotalTDs")
colnames(Rodgers)[1:2] <- c("Receiver", "TotalTDs")

# Combine
All <- rbind(Brady, Rivers, Manning, Ryan, Stafford, Brees, Romo, Rodgers)


## Variables for labeling
All$ReceiverLastName <- word(All$Receiver,-1)
All$together <- NA
# manually labeling for each passer
All$together[which(All$Passer == "Brady" &   All$ReceiverLastName %in% c("Gronkowski", "Edelman"))] <- "Yes"
All$together[which(All$Passer == "Brady" & !(All$ReceiverLastName %in% c("Gronkowski", "Edelman")))] <- "No"
All$together[which(All$Passer == "Rivers" &  All$ReceiverLastName %in% c("Gates", "Allen"))] <- "Yes"
All$together[which(All$Passer == "Rivers" &!(All$ReceiverLastName %in% c("Gates", "Allen")))] <- "No"
All$together[which(All$Passer == "Manning")] <- "No"
All$together[which(All$Passer == "Brees")] <- "No"
All$together[which(All$Passer == "Stafford")] <- "No"
All$together[which(All$Passer == "Rodgers" & (All$ReceiverLastName %in% c("Cobb", "Nelson")))] <- "Yes"
All$together[which(All$Passer == "Rodgers" & !(All$ReceiverLastName %in% c("Cobb", "Nelson")))] <- "No"
All$together[which(All$Passer == "Ryan" & (All$ReceiverLastName %in% c("Cobb", "Nelson")))] <- "Yes"
All$together[which(All$Passer == "Ryan" & (All$ReceiverLastName %in% c("Jones")))] <- "Yes"
All$together[which(All$Passer == "Ryan" & !(All$ReceiverLastName %in% c("Jones")))] <- "No"
All$together[which(All$Passer == "Romo" & (All$ReceiverLastName %in% c("Bryant", "Witten")))] <- "Yes"
All$together[which(All$Passer == "Romo" & !(All$ReceiverLastName %in% c("Bryant", "Witten")))] <- "No"

# Function to label only outliers
is_outlier <- function(x) {
  return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))
}

## To control ordering
All <- All[order(All$TotalTDs,decreasing = T),]
All$Passer[which(All$Passer == "Manning")] <- "P. Manning"
All$PasserSort <- factor(All$Passer, levels = unique(All$Passer[order(All$TotalTDs, decreasing = T)]))

## Visualize
viz <- All %>%
  group_by(Passer) %>%
  mutate(outlier = ifelse(TotalTDs > 30, ReceiverLastName, as.numeric(NA))) %>%
  ggplot(aes(x=PasserSort, y=TotalTDs,  fill = PasserSort)) + 
  geom_violin(alpha = .8) + geom_boxplot(width=0.1, fill="white") + 
  geom_text(aes(label = outlier, colour = factor(together)), na.rm = T, hjust = 1.1, size = 3.5) +
  scale_colour_discrete(l=40) +
  scale_fill_manual(values=c("#3182bd", "#b0e0e6", "#cfb53b", "#0D254C", "#006DB0", "#BD0D18", "#0D254C", "#203731")) +
  guides(fill = F) +
  labs(x = "QB", y = "TDs Thrown to Receiver", title = "Dynamic Duos", colour = "Active Tandem")

## Interactive
ggplotly(viz)