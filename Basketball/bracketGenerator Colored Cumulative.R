## Bracket Generator -- 538 Round by Round Style ####

library(dplyr)

# This script creates a pdf out of Round by Round Prediction files
rm(list=ls()) # Clear workspace
#pdf(paste0("C:/Users/michael.t.dickey/Documents/ARC/March Madness 2018/RoundByRound bracket 2018 logistic.pdf"),width=11,height=8.5)

### Load and merge datasets
submission<-read.csv("C:/Users/michael.t.dickey/Documents/ARC/March Madness 2018/roundByRoundProbs.csv", stringsAsFactors = F)
teams<-read.csv("C:/Users/michael.t.dickey/Documents/ARC/March Madness 2018/Teams.csv")
teams <- teams[,1:2]
seeds<-read.csv("C:/Users/michael.t.dickey/Documents/ARC/March Madness 2018/NCAATourneySeeds.csv")
seeds <- seeds[which(seeds$Season == 2018),]  ## 
seeds$Region<-substr(seeds$Seed,1,1)          ## Region
seeds$Seed<-as.numeric(substr(seeds$Seed,2,3))
names(teams)<-c("teamID", "Team")
submission<-merge(submission,teams)
submission<-merge(submission,seeds, by.x = "teamID", by.y = "TeamID")

### Draw a bracket ####
x<-seq(0,220,(221/67))  ## initialization grid points
y<-0:66  ## initialization grid points

### Base plot
plot(x,y,type="l", col.axis="white", col.lab="white", bty="n", 
     axes=F, col="white")  # Start a base white canvas plot

#### Bracket lines ###
### Left side
segments(0,c(seq(0,30,2),seq(34,64,2)),20,c(seq(0,30,2),seq(34,64,2)))  ## Left side horizontal
segments(20,c(seq(0,28,4),seq(34,62,4)),20,c(seq(2,30,4),seq(36,64,4))) ## connect two teams (R64)
segments(20,c(seq(1,29,4),seq(35,63,4)),40,c(seq(1,29,4),seq(35,63,4))) ## Left side R1 winner line
segments(40,c(seq(1,25,8),seq(35,59,8)),40,c(seq(5,29,8),seq(39,63,8))) ## connect two teams (R32)
segments(40,c(3,11,19,27,37,45,53,61),60,c(3,11,19,27,37,45,53,61))     ## Left side R2 winner line
segments(60,c(3,19,37,53),60,c(11,27,45,61))                            ## connect two teams (Sweet 16)
segments(60,c(7,23,41,57),80,c(7,23,41,57))                             ## Left side S16 winner line
segments(80,c(7,41),80,c(23,57))                                        ## connect two teams (Elite 8)
segments(80,c(15,49),100,c(15,49))                                      ## Left side Elite 8 Winner Lines

### Right side
segments(200,c(seq(0,30,2),seq(34,64,2)),220,c(seq(0,30,2),seq(34,64,2))) ## Right side horizontal
segments(200,c(seq(0,28,4),seq(34,62,4)),200,c(seq(2,30,4),seq(36,64,4))) ## connect two teams (R64)
segments(180,c(seq(1,29,4),seq(35,63,4)),200,c(seq(1,29,4),seq(35,63,4))) ## Right side R1 winner line
segments(180,c(seq(1,25,8),seq(35,59,8)),180,c(seq(5,29,8),seq(39,63,8))) ## connect two teams (R32)
segments(160,c(3,11,19,27,37,45,53,61),180,c(3,11,19,27,37,45,53,61))     ## Right side R2 winner line
segments(160,c(3,19,37,53),160,c(11,27,45,61))                            ## connect two teams (Sweet 16)
segments(140,c(7,23,41,57),160,c(7,23,41,57))                             ## Right side S16 winner line
segments(140,c(7,41),140,c(23,57))                                        ## connect two teams (Elite 8)
segments(120,c(15,49),140,c(15,49))                                       ## Right side Elite 8 Winner Lines

### Middle
#segments(100,c(27,37),120,c(27,37)) ## Championship lines

### Top Left (Y) ####
#First Round, top left (Region Y)
text(9.8,64.75,submission$Team[which(submission$Seed == 1 & submission$Region == "Y")],cex=.7) #1st seed
text(9.8,62.75,submission$Team[which(submission$Seed == 16 & submission$Region == "Y")],cex=.7) #16th seed
text(9.8,60.75,submission$Team[which(submission$Seed == 8 & submission$Region == "Y")],cex=.7)
text(9.8,58.75,submission$Team[which(submission$Seed == 9 & submission$Region == "Y")],cex=.7)
text(9.8,56.75,submission$Team[which(submission$Seed == 5 & submission$Region == "Y")],cex=.7)
text(9.8,54.75,submission$Team[which(submission$Seed == 12 & submission$Region == "Y")],cex=.7)
text(9.8,52.75,submission$Team[which(submission$Seed == 4 & submission$Region == "Y")],cex=.7)
text(9.8,50.75,submission$Team[which(submission$Seed == 13 & submission$Region == "Y")],cex=.7)
text(9.8,48.75,submission$Team[which(submission$Seed == 6 & submission$Region == "Y")],cex=.7)
text(9.8,46.75,submission$Team[which(submission$Seed == 11 & submission$Region == "Y")],cex=.7)
text(9.8,44.75,submission$Team[which(submission$Seed == 3 & submission$Region == "Y")],cex=.7)
text(9.8,42.75,submission$Team[which(submission$Seed == 14 & submission$Region == "Y")],cex=.7)
text(9.8,40.75,submission$Team[which(submission$Seed == 7 & submission$Region == "Y")],cex=.7)
text(9.8,38.75,submission$Team[which(submission$Seed == 10 & submission$Region == "Y")],cex=.7)
text(9.8,36.75,submission$Team[which(submission$Seed == 2 & submission$Region == "Y")],cex=.7)
text(9.8,34.75,submission$Team[which(submission$Seed == 15 & submission$Region == "Y")],cex=.7) # 15th seed


# Round 32, top left (Region Y)
## Determine winners/probabilities from 1st round and carry forward
top_left_1_16_winner <- round((submission %>% filter(Region == "Y" & Seed %in% c(1,16)) %>% top_n(1,wt = Round2) %>% select(Round2))$Round2*100,1)
top_left_8_9_winner  <- (submission %>% filter(Region == "Y" & Seed %in% c(8,9)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_5_12_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(5,12)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_4_13_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(4,13)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_6_11_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(6,11)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_3_14_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(3,14)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_7_10_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(7,10)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_left_2_15_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(2,15)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
## Write it out
text(29.8,59.75,top_left_8_9_winner,cex=.7, col = "#737373")
text(29.8,55.75,top_left_5_12_winner,cex=.7,col = "#737373")
text(29.8,51.75,top_left_4_13_winner,cex=.7,col = "#737373")
text(29.8,47.75,top_left_6_11_winner,cex=.7,col = "#737373")
text(29.8,43.75,top_left_3_14_winner,cex=.7,col = "#737373")
text(29.8,39.75,top_left_7_10_winner,cex=.7,col = "#737373")
text(29.8,35.75,top_left_2_15_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(29.8,64.5,paste0(top_left_1_16_winner,"%"),cex=.7)  
segments(20,63,40,63, lwd = 9*(top_left_1_16_winner/100), col = "#F84C1E")
segments(40,61,40,63, lwd = 9*(top_left_1_16_winner/100), col = "#F84C1E") ## connect two teams (R32)

# Sweet 16, top left (Region Y)
## Determine winners/probabilities from 1st round and carry forward
top_left_s16_1_winner <- round((submission %>% filter(Region == "Y" & Seed %in% c(1,16,8,9)) %>% top_n(1,wt = Sweet16) %>% select(Sweet16))$Sweet16*100,1)
top_left_s16_2_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(5,12,4,13)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
top_left_s16_3_winner <-  (submission %>% filter(Region == "Y" & Seed %in% c(6,11,3,14)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
top_left_s16_4_winner <-  (submission %>% filter(Region == "Y" & Seed %in% c(7,10,2,15)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team

## Determine winners/probabilities from 2nd round and carry forward
text(49.8,53.75,top_left_s16_2_winner,cex=.7,col = "#737373")
text(49.8,45.75,top_left_s16_3_winner,cex=.7,col = "#737373")
text(49.8,37.75,top_left_s16_4_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(49.8,62.5,paste0(top_left_s16_1_winner,"%"),cex=.7)  
segments(40,61,60,61, lwd = 9*(top_left_s16_1_winner/100), col = "#F84C1E") ## Left side R2 winner line
segments(60,57,60,61, lwd = 9*(top_left_s16_1_winner/100), col = "#F84C1E") ## connect two teams (Sweet 16)



# Elite 8, top left (Region Y)
top_left_e8_1_winner <- round((submission %>% filter(Region == "Y" & Seed %in% c(1,16,8,9,5,12,4,13)) %>% top_n(1,wt = Elite8) %>% select(Elite8))$Elite8*100,1)
top_left_e8_2_winner <- (submission %>% filter(Region == "Y" & Seed %in% c(6,11,3,14,7,10,2,15)) %>% top_n(1,wt = Elite8) %>% select(Team))$Team
## Determine winners/probabilities from Sweet 16 and carry forward
text(69.8,42.25,top_left_e8_2_winner,cex=.9,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(69.8,58.5,paste0(top_left_e8_1_winner,"%"),cex=.9)
segments(60,57,80,57, lwd = 9*(top_left_e8_1_winner/100), col = "#F84C1E") ## Left side S16 winner line
segments(80,49,80,57, lwd = 9*(top_left_e8_1_winner/100), col = "#F84C1E") ## connect two teams (Elite 8)

### Bottom Left (Z) ####
# first round, bottom left (Region Z)
text(9.8,30.75,submission$Team[which(submission$Seed == 1 & submission$Region == "Z")],cex=.7) 
text(9.8,28.75,submission$Team[which(submission$Seed == 16 & submission$Region == "Z" & submission$Round1 > 0.5)],cex=.7)
text(9.8,26.75,submission$Team[which(submission$Seed == 8 & submission$Region == "Z")],cex=.7)
text(9.8,24.75,submission$Team[which(submission$Seed == 9 & submission$Region == "Z")],cex=.7)
text(9.8,22.75,submission$Team[which(submission$Seed == 5 & submission$Region == "Z")],cex=.7)
text(9.8,20.75,submission$Team[which(submission$Seed == 12 & submission$Region == "Z")],cex=.7)
text(9.8,18.75,submission$Team[which(submission$Seed == 4 & submission$Region == "Z")],cex=.7)
text(9.8,16.75,submission$Team[which(submission$Seed == 13 & submission$Region == "Z")],cex=.7)
text(9.8,14.75,submission$Team[which(submission$Seed == 6 & submission$Region == "Z")],cex=.7)
text(9.8,12.75,submission$Team[which(submission$Seed == 11 & submission$Region == "Z")],cex=.7) ## Play in
text(9.8,10.75,submission$Team[which(submission$Seed == 3 & submission$Region == "Z")],cex=.7)
text(9.8, 8.75, submission$Team[which(submission$Seed == 14 & submission$Region == "Z")],cex=.7)
text(9.8, 6.75, submission$Team[which(submission$Seed == 7 & submission$Region == "Z")],cex=.7)
text(9.8, 4.75, submission$Team[which(submission$Seed == 10 & submission$Region == "Z")],cex=.7)
text(9.8, 2.75, submission$Team[which(submission$Seed == 2 & submission$Region == "Z")],cex=.7)
text(9.8, 0.75, submission$Team[which(submission$Seed == 15 & submission$Region == "Z")],cex=.7)


# Round 32, bottom left (Region Z)
## Determine winners/probabilities from 1st round and carry forward
bottom_left_2_15_winner <- round((submission %>% filter(Region == "Z" & Seed %in% c(2,15)) %>% top_n(1,wt = Round2) %>% select(Round2))$Round2*100,1)
bottom_left_8_9_winner  <- (submission %>% filter(Region == "Z" & Seed %in% c(8,9)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_5_12_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(5,12)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_4_13_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(4,13)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_6_11_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(6,11)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_3_14_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(3,14)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_7_10_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(7,10)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_left_1_16_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(1,16)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
## Write it out
text(29.8,29.75, bottom_left_1_16_winner, cex=.7,col = "#737373")
text(29.8,25.75, bottom_left_8_9_winner, cex=.7,col = "#737373")
text(29.8,21.75, bottom_left_5_12_winner, cex=.7,col = "#737373")
text(29.8,17.75, bottom_left_4_13_winner, cex=.7,col = "#737373")
text(29.8,13.75, bottom_left_6_11_winner, cex=.7,col = "#737373")
text(29.8, 9.75, bottom_left_3_14_winner,cex=.7,col = "#737373")
text(29.8, 5.75, bottom_left_7_10_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(29.8,2.25,paste0(bottom_left_2_15_winner,"%"),cex=.7)  
segments(20,1,40,1, lwd = 9*(bottom_left_2_15_winner/100), col = "#4B9CD3") ## Left side R1 winner line
segments(40,1,40,3, lwd = 9*(bottom_left_2_15_winner/100), col = "#4B9CD3") ## connect two teams (R32)


# Sweet 16, bottom left (Region Z)
## Determine winners/probabilities from 1st round and carry forward
bottom_left_s16_1_winner <-  (submission %>% filter(Region == "Z" & Seed %in% c(1,16,8,9)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_left_s16_2_winner <-  (submission %>% filter(Region == "Z" & Seed %in% c(5,12,4,13)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_left_s16_3_winner <-  (submission %>% filter(Region == "Z" & Seed %in% c(6,11,3,14)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_left_s16_4_winner <- round((submission %>% filter(Region == "Z" & Seed %in% c(7,10,2,15)) %>% top_n(1,wt = Sweet16) %>% select(Sweet16))$Sweet16*100,1)

## Determine winners/probabilities from 2nd round and carry forward
text(49.8,27.75,bottom_left_s16_1_winner,cex=.7,col = "#737373")
text(49.8,19.75,bottom_left_s16_2_winner,cex=.7,col = "#737373")
text(49.8,11.75,bottom_left_s16_3_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(49.8,4.25,paste0(bottom_left_s16_4_winner,"%"),cex=.7)  
segments(40,3,60,3, lwd = 9*(bottom_left_s16_4_winner/100), col = "#4B9CD3") ## Left side R2 winner line
segments(60,3,60,7, lwd = 9*(bottom_left_s16_4_winner/100), col = "#4B9CD3") ## connect two teams (Sweet 16)


## Elite 8, bottom left (Region Z)
## Determine winners/probabilities from Sweet 16 and carry forward
bottom_left_e8_1_winner <- (submission %>% filter(Region == "Z" & Seed %in% c(1,16,8,9,5,12,4,13)) %>% top_n(1,wt = Elite8) %>% select(Team))$Team
bottom_left_e8_2_winner <- round((submission %>% filter(Region == "Z" & Seed %in% c(6,11,3,14,7,10,2,15)) %>% top_n(1,wt = Elite8) %>% select(Elite8))$Elite8*100,1)
text(69.8,24.25,bottom_left_e8_1_winner,cex=.9,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(69.8, 8.25,paste0(bottom_left_e8_2_winner,"%"),cex=.9)
segments(60,7,80,7, lwd = 9*(bottom_left_e8_2_winner/100), col = "#4B9CD3") ## Left side S16 winner line
segments(80,7,80,15, lwd = 9*(bottom_left_e8_2_winner/100), col = "#4B9CD3") ## connect two teams (Elite 8)


### Top Right (W) ####
# First round, top right (Region W)
text(209.8,64.75,submission$Team[which(submission$Seed == 1 & submission$Region == "W")],cex=.7)
text(209.8,62.75,submission$Team[which(submission$Seed == 16 & submission$Region == "W" & submission$Round1 > 0.5)],cex=.7)
text(209.8,60.75,submission$Team[which(submission$Seed == 8 & submission$Region == "W")],cex=.7)
text(209.8,58.75,submission$Team[which(submission$Seed == 9 & submission$Region == "W")],cex=.7)
text(209.8,56.75,submission$Team[which(submission$Seed == 5 & submission$Region == "W")],cex=.7)
text(209.8,54.75,submission$Team[which(submission$Seed == 12 & submission$Region == "W")],cex=.7)
text(209.8,52.75,submission$Team[which(submission$Seed == 4 & submission$Region == "W")],cex=.7)
text(209.8,50.75,submission$Team[which(submission$Seed == 13 & submission$Region == "W")],cex=.7)
text(209.8,48.75,submission$Team[which(submission$Seed == 6 & submission$Region == "W")],cex=.7)
text(209.8,46.75,submission$Team[which(submission$Seed == 11 & submission$Region == "W" & submission$Round1 > 0.5)],cex=.7)
text(209.8,44.75,submission$Team[which(submission$Seed == 3 & submission$Region == "W")],cex=.7)
text(209.8,42.75,submission$Team[which(submission$Seed == 14 & submission$Region == "W")],cex=.7)
text(209.8,40.75,submission$Team[which(submission$Seed == 7 & submission$Region == "W")],cex=.7)
text(209.8,38.75,submission$Team[which(submission$Seed == 10 & submission$Region == "W")],cex=.7)
text(209.8,36.75,submission$Team[which(submission$Seed == 2 & submission$Region == "W")],cex=.7)
text(209.8,34.75,submission$Team[which(submission$Seed == 15 & submission$Region == "W")],cex=.7)

# Round 32, top right (Region W)
## Determine winners/probabilities from 1st round and carry forward
top_right_1_16_winner <- round((submission %>% filter(Region == "W" & Seed %in% c(1,16)) %>% top_n(1,wt = Round2) %>% select(Round2))$Round2*100,1)
top_right_8_9_winner  <- (submission %>% filter(Region == "W" & Seed %in% c(8,9)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_5_12_winner <- (submission %>% filter(Region == "W" & Seed %in% c(5,12)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_4_13_winner <- (submission %>% filter(Region == "W" & Seed %in% c(4,13)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_6_11_winner <- (submission %>% filter(Region == "W" & Seed %in% c(6,11)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_3_14_winner <- (submission %>% filter(Region == "W" & Seed %in% c(3,14)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_7_10_winner <- (submission %>% filter(Region == "W" & Seed %in% c(7,10)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
top_right_2_15_winner <- (submission %>% filter(Region == "W" & Seed %in% c(2,15)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
## Write it out
text(189.8,59.75,top_right_8_9_winner,cex=.7 ,col = "#737373")
text(189.8,55.75,top_right_5_12_winner,cex=.7,col = "#737373")
text(189.8,51.75,top_right_4_13_winner,cex=.7,col = "#737373")
text(189.8,47.75,top_right_6_11_winner,cex=.7,col = "#737373")
text(189.8,43.75,top_right_3_14_winner,cex=.7,col = "#737373")
text(189.8,39.75,top_right_7_10_winner,cex=.7,col = "#737373")
text(189.8,35.75,top_right_2_15_winner,cex=.7,col = "#737373")

## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(189.8,64.5,paste0(top_right_1_16_winner,"%"),cex=.7)  
segments(180,63,200,63, lwd = 9*(top_right_1_16_winner/100), col = "#001F5B") ## Right side R1 winner line
segments(180,61,180,63, lwd = 9*(top_right_1_16_winner/100), col = "#001F5B") ## connect two teams (R32)


# Sweet 16, top right (Region W)
## Determine winners/probabilities from 1st round and carry forward
top_right_s16_1_winner <- round((submission %>% filter(Region == "W" & Seed %in% c(1,16,8,9)) %>% top_n(1,wt = Sweet16) %>% select(Sweet16))$Sweet16*100,1)
top_right_s16_2_winner <- (submission %>% filter(Region == "W" & Seed %in% c(5,12,4,13)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
top_right_s16_3_winner <-  (submission %>% filter(Region == "W" & Seed %in% c(6,11,3,14)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
top_right_s16_4_winner <-  (submission %>% filter(Region == "W" & Seed %in% c(7,10,2,15)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
text(169.8,53.75,top_right_s16_2_winner,cex=.7,col = "#737373")
text(169.8,45.75,top_right_s16_3_winner,cex=.7,col = "#737373")
text(169.8,37.75,top_right_s16_4_winner,cex=.7,col = "#737373")

## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(169.8,62.5,paste0(top_right_s16_1_winner,"%"),cex=.7, col = "#001F5B")  
segments(160,61,180,61, lwd = 9*(top_right_s16_1_winner/100), col = "#001F5B") ## Right side R2 winner line
segments(160,57,160,61, lwd = 9*(top_right_s16_1_winner/100), col = "#001F5B") ## connect two teams (Sweet 16)


## Elite 8, top right (Region W)
## Determine winners/probabilities from Sweet 16 and carry forward
top_right_e8_1_winner <- round((submission %>% filter(Region == "W" & Seed %in% c(1,16,8,9,5,12,4,13)) %>% top_n(1,wt = Elite8) %>% select(Elite8))$Elite8*100,1)
top_right_e8_2_winner <- (submission %>% filter(Region == "W" & Seed %in% c(6,11,3,14,7,10,2,15)) %>% top_n(1,wt = Elite8) %>% select(Team))$Team
text(149.8,42.25,top_right_e8_2_winner,cex=.9,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(149.8,58.5,paste0(top_right_e8_1_winner,"%"),cex=.9)
segments(140,57,160,57, lwd = 9*(top_right_e8_1_winner/100), col = "#001F5B") ## Left side S16 winner line
segments(140,49,140,57, lwd = 9*(top_right_e8_1_winner/100), col = "#001F5B") ## connect two teams (Elite 8)


### Bottom Right (X) ####
#First round, bottom right (Region X)
text(209.8,30.75,submission$Team[which(submission$Seed == 1 & submission$Region == "X")],cex=.7)
text(209.8,28.75,submission$Team[which(submission$Seed == 16 & submission$Region == "X")],cex=.7)
text(209.8,26.75,submission$Team[which(submission$Seed == 8 & submission$Region == "X")],cex=.7)
text(209.8,24.75,submission$Team[which(submission$Seed == 9 & submission$Region == "X")],cex=.7)
text(209.8,22.75,submission$Team[which(submission$Seed == 5 & submission$Region == "X")],cex=.7)
text(209.8,20.75,submission$Team[which(submission$Seed == 12 & submission$Region == "X")],cex=.7)
text(209.8,18.75,submission$Team[which(submission$Seed == 4 & submission$Region == "X")],cex=.7)
text(209.8,16.75,submission$Team[which(submission$Seed == 13 & submission$Region == "X")],cex=.7)
text(209.8,14.75,submission$Team[which(submission$Seed == 6 & submission$Region == "X")],cex=.7)
text(209.8,12.75,submission$Team[which(submission$Seed == 11 & submission$Region == "X" & submission$Round1 > 0.5)],cex=.7)
text(209.8,10.75,submission$Team[which(submission$Seed == 3 & submission$Region == "X")],cex=.7)
text(209.8, 8.75, submission$Team[which(submission$Seed == 14 & submission$Region == "X")],cex=.7)
text(209.8, 6.75, submission$Team[which(submission$Seed == 7 & submission$Region == "X")],cex=.7)
text(209.8, 4.75, submission$Team[which(submission$Seed == 10 & submission$Region == "X")],cex=.7)
text(209.8, 2.75, submission$Team[which(submission$Seed == 2 & submission$Region == "X")],cex=.7)
text(209.8, 0.75, submission$Team[which(submission$Seed == 15 & submission$Region == "X")],cex=.7)

# Round 32, bottom right (Region X)
## Determine winners/probabilities from 1st round and carry forward
bottom_right_2_15_winner <- round((submission %>% filter(Region == "X" & Seed %in% c(2,15)) %>% top_n(1,wt = Round2) %>% select(Round2))$Round2*100,1)
bottom_right_8_9_winner  <- (submission %>% filter(Region == "X" & Seed %in% c(8,9)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_5_12_winner <- (submission %>% filter(Region == "X" & Seed %in% c(5,12)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_4_13_winner <- (submission %>% filter(Region == "X" & Seed %in% c(4,13)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_6_11_winner <- (submission %>% filter(Region == "X" & Seed %in% c(6,11)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_3_14_winner <- (submission %>% filter(Region == "X" & Seed %in% c(3,14)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_7_10_winner <- (submission %>% filter(Region == "X" & Seed %in% c(7,10)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
bottom_right_1_16_winner <- (submission %>% filter(Region == "X" & Seed %in% c(1,16)) %>% top_n(1,wt = Round2) %>% select(Team))$Team
## Write it out
text(189.8,29.75,bottom_right_1_16_winner,cex=.7,col = "#737373")
text(189.8,25.75, bottom_right_8_9_winner,cex=.7,col = "#737373")
text(189.8,21.75,bottom_right_5_12_winner,cex=.7,col = "#737373")
text(189.8,17.75,bottom_right_4_13_winner,cex=.7,col = "#737373")
text(189.8,13.75,bottom_right_6_11_winner,cex=.7,col = "#737373")
text(189.8, 9.75,bottom_right_3_14_winner,cex=.7,col = "#737373")
text(189.8, 5.75,bottom_right_7_10_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(189.8,2.25,paste0(bottom_right_2_15_winner,"%"),cex=.7)  
segments(180,1,200,1, lwd = 9*(bottom_right_2_15_winner/100), col = "#001A57") ## Left side R1 winner line
segments(180,1,180,3, lwd = 9*(bottom_right_2_15_winner/100), col = "#001A57") ## connect two teams (R32)



# Sweet 16, bottom right (Region X)
## Determine winners/probabilities from 1st round and carry forward
bottom_right_s16_1_winner <-  (submission %>% filter(Region == "X" & Seed %in% c(1,16,8,9)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_right_s16_2_winner <-  (submission %>% filter(Region == "X" & Seed %in% c(5,12,4,13)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_right_s16_3_winner <-  (submission %>% filter(Region == "X" & Seed %in% c(6,11,3,14)) %>% top_n(1,wt = Sweet16) %>% select(Team))$Team
bottom_right_s16_4_winner <- round((submission %>% filter(Region == "X" & Seed %in% c(7,10,2,15)) %>% top_n(1,wt = Sweet16) %>% select(Sweet16))$Sweet16*100,1)
## Write it out
text(169.8,27.75,bottom_right_s16_1_winner,cex=.7,col = "#737373")
text(169.8,19.75,bottom_right_s16_2_winner,cex=.7,col = "#737373")
text(169.8,11.75,bottom_right_s16_3_winner,cex=.7,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(169.8,4.25,paste0(bottom_right_s16_4_winner,"%"),cex=.7)  
segments(160,3,180,3, lwd = 9*(bottom_right_s16_4_winner/100), col = "#001A57") ## Left side R2 winner line
segments(160,3,160,7, lwd = 9*(bottom_right_s16_4_winner/100), col = "#001A57") ## connect two teams (Sweet 16)

# Elite 8, bottom right (Region X)
## Determine winners/probabilities from Sweet 16 and carry forward
bottom_right_e8_1_winner <- (submission %>% filter(Region == "X" & Seed %in% c(1,16,8,9,5,12,4,13)) %>% top_n(1,wt = Elite8) %>% select(Team))$Team
bottom_right_e8_2_winner <- round((submission %>% filter(Region == "X" & Seed %in% c(6,11,3,14,7,10,2,15)) %>% top_n(1,wt = Elite8) %>% select(Elite8))$Elite8*100,1)
## Write it out
text(149.8,24.25,bottom_right_e8_1_winner,cex=.9,col = "#737373")
## For Final 4 team, write the probability and redraw the line to be colored and weighted by prob
text(149.8, 8.25,paste0(bottom_right_e8_2_winner,"%"),cex=.9)
segments(140,7,160,7, lwd = 9*(bottom_right_e8_2_winner/100), col =  "#001A57") ## Left side S16 winner line
segments(140,7,140,15, lwd = 9*(bottom_right_e8_2_winner/100), col = "#001A57") ## connect two teams (Elite 8)



### Final four!!  ####
## Calculate who makes it
top_left_final_four <- round((submission %>% filter(Region == "Y") %>% top_n(1,wt = Final4) %>% select(Final4))$Final4*100,1)
bottom_left_final_four <- round((submission %>% filter(Region == "Z") %>% top_n(1,wt = Final4) %>% select(Final4))$Final4*100,1)
top_right_final_four <- round((submission %>% filter(Region == "W") %>% top_n(1,wt = Final4) %>% select(Final4))$Final4*100,1)
bottom_right_final_four <- round((submission %>% filter(Region == "X") %>% top_n(1,wt = Final4) %>% select(Final4))$Final4*100,1)
## Write them out
text(129.8,50.5,paste0(top_right_final_four,"%"),cex=.9) # Champ Top Right (W)
text(129.8,16.5,paste0(bottom_right_final_four,"%"),cex=.9) # Champ Bottom Right (X)
text(89.8,50.5, paste0(top_left_final_four,"%"),cex=.9) # Champ Top Left (Y)
text(89.8,16.5, paste0(bottom_left_final_four,"%"),cex=.9) # Champ Bottom Left (Z)

### Final Four lines
segments(80,49,100,49,lwd = 9*(top_left_final_four/100), col = "#F84C1E")  ## Top Left Elite 8 Winner Lines
segments(80,15,100,15,lwd = 9*(bottom_left_final_four/100), col = "#4B9CD3")  ## Bottom Left Elite 8 Winner Lines
segments(120,49,140,49,lwd = 9*(top_right_final_four/100), col = "#001F5B") ## Top Right Elite 8 Winner Line
segments(120,15,140,15,lwd = 9*(bottom_right_final_four/100), col = "#001A57") ## Bottom Right Elite 8 Winner Lines



###Championship game
## Calculate who goes
champ_right  <- round((submission %>% filter(Region %in% c("W","X")) %>% top_n(1,wt = Final) %>% select(Final))$Final*100,0)
champ_left <- round((submission %>% filter(Region %in% c("Y","Z")) %>% top_n(1,wt = Final) %>% select(Final))$Final*100,0)
## Write it out
text(109.8,38.25,paste0(champ_left ,"%"),cex=.9)
text(109.8,28.25,paste0(champ_right,"%"),cex=.9)

#Champ!
winner      <- (submission %>% top_n(1,wt = Champ) %>% select(Team))$Team
winner_prob <- round((submission %>% top_n(1,wt = Champ) %>% select(Champ))$Champ*100)
text(109.8,32.5,paste0(winner, " - ", winner_prob, "%"),cex=2.5)

## Champ lines
segments(100,49,100,37, lwd = 9*(champ_left/100),col = "#F84C1E") ## Championship lines left
segments(100,37,115,37, lwd = 9*(champ_left/100),col = "#F84C1E") ## Championship lines left
segments(105,27,120,27, lwd = 9*(champ_right/100),col = "#001F5B") ## Championship lines right
segments(120,49,120,35, lwd = 9*(champ_right/100),col = "#001F5B") ## Championship lines right
segments(120,27,120,29, lwd = 9*(champ_right/100),col = "#001F5B") ## Championship lines right

#dev.off()