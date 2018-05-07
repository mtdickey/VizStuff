### Half Marathon Viz ####

library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)


## Load and clean the data  ####
setwd("~/Random")
Times <- read.csv("HalfMarathon.csv", stringsAsFactors = F)
Times <- Times[,-c(9,10)]
colnames(Times) <- c("ID", "Place", "Name","Gender","Age","City","Time","Event")

## Create a time in minutes out of the "Time" string
Times$Time <- hms(Times$Time) ## convert to hours:min:seconds
Times$Time_min <- hour(Times$Time)*60 + minute(Times$Time) + second(Times$Time)/60

### Noticed that some of the listed "hours" are off... (i.e. some people in 90th place and higher had a time of 1:10 instead of 2:10)
### Correct times that were entered incorrectly
twoHrPlace <- min(Times$Place[which(Times$Time >= hms("2:00:00"))])
threeHrPlace <- min(Times$Place[which(Times$Time >= hms("3:00:00"))])
fourHrPlace <- min(Times$Place[which(Times$Time >= hms("4:00:00"))])
fiveHrPlace <- min(Times$Place[which(Times$Time >= hms("5:00:00"))])
sixHrPlace <- min(Times$Place[which(Times$Time >= hms("6:00:00"))])

## Add an hour to the people who finished after the 2 hr finisher and had less than 2 hrs worth of minutes
hour(Times$Time[which(Times$Place > twoHrPlace & Times$Time_min < 120)]) <- 
  (hour(Times$Time[which(Times$Place > twoHrPlace & Times$Time_min < 120)]) + 1)
## Add an hour to the people who finished after the 3 hr finisher and had less than 3 hrs worth of minutes
hour(Times$Time[which(Times$Place > threeHrPlace & Times$Time_min < 180)]) <- 
  (hour(Times$Time[which(Times$Place > threeHrPlace & Times$Time_min < 180)])+1)
## Add an hour to the people who finished after the 4 hr finisher and had less than 4 hrs worth of minutes
hour(Times$Time[which(Times$Place > fourHrPlace & Times$Time_min < 240)]) <- 
  (hour(Times$Time[which(Times$Place > fourHrPlace & Times$Time_min < 240)])+1)
## Add an hour to the people who finished after the 5 hr finisher and had less than 5 hrs worth of minutes
hour(Times$Time[which(Times$Place > fiveHrPlace & Times$Time_min < 300)]) <- 
  (hour(Times$Time[which(Times$Place > fiveHrPlace & Times$Time_min < 300)])+1)
## Add an hour to the people who finished after the 6 hr finisher and had less than 6 hrs worth of minutes
hour(Times$Time[which(Times$Place > sixHrPlace & Times$Time_min < 360)]) <- 
  (hour(Times$Time[which(Times$Place > sixHrPlace & Times$Time_min < 360)])+1)

## Recalculate time in minutes
Times$Time_min <- hour(Times$Time)*60 + minute(Times$Time) + second(Times$Time)/60

## Check that place aligns with "Time"
length(which(order(Times$Place) != order(Times$Time_min)))  ## it's always the same order whether you sort on place/time

## Write out a copy of the corrected data
write.csv(Times, file = "HalfMarathonCorrected.csv",row.names = F)

#### Visualize ####
Times %>% filter(Event == "Half") %>% 
  ggplot(aes(x = Time_min, fill = Gender)) + geom_density(alpha =.3) +
   geom_vline(xintercept = Times$Time_min[which(Times$Name == "Michael Dickey")],
              color = "#fb6a4a", linetype = "dashed", size = 1.2) + 
  labs(x = "Time (minutes)", y = "Density", title = "Distribution of Times at 2018 Potomac River Run Half Marathon")

## using histogram/counts
Times %>% filter(Event == "Half") %>% 
  ggplot(aes(x = Time_min, fill = Gender)) + geom_histogram(binwidth = 5, alpha =.3, position="identity") +
  geom_vline(xintercept = Times$Time_min[which(Times$Name == "Michael Dickey")],
             color = "#fb6a4a", linetype = "dashed", size = 1.2) + 
  labs(x = "Time (minutes)", y = "Count of Finishers",
       title = "Distribution of Times at 2018 Potomac River Run Half Marathon")

### Get distributions by Age Group/Gender
Times$Age_group <- ifelse(Times$Age <= 19, "19 and Under",
                          ifelse(Times$Age <= 29 & Times$Age >= 20, "20-29",
                                 ifelse(Times$Age <= 39 & Times$Age >= 30, "30-39",
                                        ifelse(Times$Age <= 49 & Times$Age >= 40, "40-49",
                                               ifelse(Times$Age <= 59 & Times$Age >= 50, "50-59",
                                                      ifelse(Times$Age <= 69 & Times$Age >= 60, "60-69",
                                                             ifelse(Times$Age >=70, "70+","None")))))))

### Boxplots by gender/age-group
Times %>% filter(Event == "Half") %>%
  ggplot(aes(x = Age_group, y = Time_min, fill = Gender)) +
  facet_wrap(~Gender) +
  geom_hline(yintercept = Times$Time_min[which(Times$Name == "Michael Dickey")],
             color = "#fb6a4a", linetype = "dashed", size = 1.2) +
  geom_boxplot()
