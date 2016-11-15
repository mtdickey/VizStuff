### Server ####

library(shiny)
library(googleVis)
library(dplyr)
library(RColorBrewer)
library(igraph)

setwd("C:/Users/Michael/Documents/Shiny Apps/2016 Election")

## Data (from Wikipedia - https://en.wikipedia.org/wiki/United_States_presidential_election,_2016)
TrumpClinton <- read.csv("2016election.csv", stringsAsFactors =  F)
ObamaRomney <- read.csv("2012election.csv", stringsAsFactors = F)

load("sankeyVote.RData")

shinyServer(function(input, output) {
  
  output$gvis2016 <- renderGvis({
    sankeyVote(TrumpClinton, input$DemoType)   
  })
  
  output$gvis2012 <- renderGvis({
    sankeyVote(ObamaRomney, input$DemoType)   
  })
  
})