### Election Viz ####

setwd("C:/Users/Michael/Downloads/")

library(googleVis)
library(dplyr)
library(RColorBrewer)

## Data (from Wikipedia - https://en.wikipedia.org/wiki/United_States_presidential_election,_2016)
TrumpClinton <- read.csv("2016election.csv", stringsAsFactors =  F)
ObamaRomney <- read.csv("2012election.csv", stringsAsFactors = F)
## Note: Obama/Romney dataset does not have Demographic Types: Education by race/ethnicity, First time voter,
#        Gender by race/ethnicity, Issue regarded as most important, Party by Gender
## Note: Trump/Clinton does not have Region demographic type

### Design will be: 
  ## From: nlevels(Demographic Subgroup) within Demographic
  ## To: 3 Options (Democrat candidate, Republican Candidate, Other)
  ## Weight: Use Pct of Vote 

## First try for Age Demographic for each (before making arbitrary for any selection)
subgroups <- (TrumpClinton %>% filter(Demographic.type == "Age") %>% distinct(Demographic.subgroup))$Demographic.subgroup

weights <- rep(0, length(subgroups)*3) # initialize something to store weights
for(i in 1:length(subgroups)){
    weights[(i*3-2):(i*3)] <- c(TrumpClinton$Clinton[which(TrumpClinton$Demographic.type == "Age" &
                                            TrumpClinton$Demographic.subgroup == subgroups[i])],
                              TrumpClinton$Trump[which(TrumpClinton$Demographic.type == "Age" &
                                           TrumpClinton$Demographic.subgroup == subgroups[i])],
                              TrumpClinton$Other[which(TrumpClinton$Demographic.type == "Age" &
                                           TrumpClinton$Demographic.subgroup == subgroups[i])])
}

## Tried this out and it was in the wrong order 
# (instead of Dem, Rep, Other for each level it should be level1-dem/rep/other, level2-d/r/o, level3-d/r/o, etc...)
from <- rep("", length(subgroups)*3)
for(i in 1:(length(subgroups))){
  from[(i*3-2):(i*3)] <- subgroups[i]
}
  
Election <- data.frame(From = from, # replicate 3 times for (Dem, Rep, and Other)
                       To = c(rep(colnames(TrumpClinton)[3:5], length(subgroups))),
                       Pct = weights)

colors_link <- c('#045a8d', '#e31a1c','#fed976')
colors_link_array <- paste0("[", paste0("'", colors_link,"'", collapse = ','), "]")


colors_node <- c(brewer.pal(length(subgroups),"Set2")[1], '#045a8d', '#e31a1c', '#fed976', brewer.pal(length(subgroups),"Set2")[2:6])
colors_node_array <- paste0("[", paste0("'", colors_node,"'", collapse = ','), "]")


Sankey <- gvisSankey(Election, from="From", to="To", weight="Pct",
                     options=list(
                       sankey=paste0("{link: {colorMode: 'target', colors:  ", colors_link_array, "},
                       node: { colors: ", colors_node_array , " },
                       label: { color: '#871b47' } }")))
plot(Sankey)


## Functionize
sankeyVote <- function(data, DemoType){
  subgroups <- (data %>% filter(Demographic.type == DemoType) %>% distinct(Demographic.subgroup))$Demographic.subgroup
  
  weights <- rep(0, length(subgroups)*3) # initialize something to store weights
  for(i in 1:length(subgroups)){
    weights[(i*3-2):(i*3)] <- c(data[,3][which(data$Demographic.type == DemoType &
                                                 data$Demographic.subgroup == subgroups[i])],
                                data[,4][which(data$Demographic.type == DemoType &
                                                 data$Demographic.subgroup == subgroups[i])],
                                data[,5][which(data$Demographic.type == DemoType &
                                                 data$Demographic.subgroup == subgroups[i])])
  }
  
  ## Tried this out and it was in the wrong order 
  # (instead of Dem, Rep, Other for each level it should be level1-dem/rep/other, level2-d/r/o, level3-d/r/o, etc...)
  from <- rep("", length(subgroups)*3)
  for(i in 1:(length(subgroups))){
    if(subgroups[i] != "Other"){
      from[(i*3-2):(i*3)] <- subgroups[i]
    } else{
      from[(i*3-2):(i*3)] <- "(Other)"
    }
  }
  
  Election <- data.frame(From = from, # replicate 3 times for (Dem, Rep, and Other)
                         To = c(rep(colnames(data)[3:5], length(subgroups))),
                         Pct = weights)
  
  colors_link <- c('#045a8d', '#e31a1c','#fed976')
  colors_link_array <- paste0("[", paste0("'", colors_link,"'", collapse = ','), "]")
  
  
  colors_node <- c(brewer.pal(length(subgroups),"Set2")[1], '#045a8d', '#e31a1c', '#fed976', brewer.pal(length(subgroups),"Set2")[2:length(subgroups)])
  colors_node_array <- paste0("[", paste0("'", colors_node,"'", collapse = ','), "]")
  
  
  Sankey <- gvisSankey(Election, from="From", to="To", weight="Pct",
                       options=list(
                         sankey=paste0("{link: {colorMode: 'target', colors:  ", colors_link_array, "},
                                       node: { colors: ", colors_node_array , " },
                                       label: { color: '#871b47' } }")))
  return(Sankey)
}
 
# datSK <- data.frame(From=c(rep("A",3), rep("B", 3)),
#                     To=c(rep(c("X", "Y", "Z"),2)),
#                     Weight=c(5,7,6,2,9,4))
# 
# Sankey <- gvisSankey(datSK, from="From", to="To", weight="Weight",
#                      options=list(
#                        sankey="{link: {color: { fill: '#d799ae' } },
#                        node: { color: { fill: '#a61d4c' },
#                        label: { color: '#871b47' } }}"))
# plot(Sankey)
