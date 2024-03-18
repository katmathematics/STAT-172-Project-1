# Author(s) (ordered by contribution): Katja Mathesius

#install.packages("ggplot2")
library(ggplot2) # For visualizing data
library(dplyr) # Clean Data

setwd("Github/STAT-190-Project-1")

# Read in Data
EIA_Int = read.csv("data/compressed_raw_data/EIAInterchange.csv")

unique(EIA_Int["Region"])
print(unique(EIA_Int$Region))