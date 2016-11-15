## UI ####

library(shiny)
library(igraph)
library(googleVis)

setwd("C:/Users/Michael/Documents/Shiny Apps/2016 Election")

## Data (from Wikipedia - https://en.wikipedia.org/wiki/United_States_presidential_election,_2016)
TrumpClinton <- read.csv("2016election.csv", stringsAsFactors =  F)
ObamaRomney <- read.csv("2012election.csv", stringsAsFactors = F)

## Note: Obama/Romney dataset does not have Demographic Types: Education by race/ethnicity, First time voter,
#        Gender by race/ethnicity, Issue regarded as most important, Party by Gender
## Note: Trump/Clinton does not have Region demographic type

# To avoid errors, let's just use these as choices
DemoChoices <- sort(unique(ObamaRomney$Demographic.type[which(ObamaRomney$Demographic.type != "Region")]))

shinyUI(fluidPage(
  h2("Election Demographic Comparisons"),
  fluidRow(
    column(3, 
           h4("2012 Visualization:"),
           htmlOutput("gvis2012")
    ),
    column(5, offset = 3,
      h4("2016 Visualization:"),
      htmlOutput("gvis2016")
    )
  ),
  br(),
  selectInput("DemoType", "Demographic Type:", 
                       choices=DemoChoices, selected="Age")
)
)