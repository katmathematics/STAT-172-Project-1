# File Author(s) (ordered by contribution): Caleb Patterson
# Project Contributors (ordered alphabetically): Katja Mathesius, Caleb Patterson, Hming Zama
# Description: An analysis aiming to utilize publicly available information about grid demand and
#              commonly occurring risks to the grid in order to evaluate ideal locations to expand
#              resources into
# Active Maintenance Time frame: Feb 2024-May 2024
# Github: https://github.com/katmathematics/STAT-190-Project-1
install.packages("sp")
install.packages("maps")
install.packages("maptools", repos = "https://packagemanager.posit.co/cran/2023-10-13")
install.packages("zoo")
install.packages("dplyr")
library(sp)
library(maps)
library(maptools)
library(dplyr)
library(zoo)


## pointsDF: A data.frame whose first column contains longitudes and
##           whose second column contains latitudes.
##
## states:   An sf MULTIPOLYGON object with 50 states plus DC.
##
## name_col: Name of a column in `states` that supplies the states'
##           names.

#read in data
raw_data = read.csv("data/compressed_raw_data/NCEICountiesCompressed.csv")



lightning_monthly_count <- raw_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date, state_county, county) %>%
  summarize(sum_lightning = sum(TOTAL_COUNT))

# Write the Compressed Data 
write.csv(lightning_monthly_count, "data/cleaned_data/NCEICountiesClean.csv", row.names=FALSE, quote=FALSE)



# Plot lightning data
#mapview(lightning, xcol = "CENTERLON", ycol = "CENTERLAT", crs = 4269, grid = FALSE)
