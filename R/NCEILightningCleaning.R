# Author(s) (ordered by contribution): Caleb Patterson
install.packages("tidyverse")
install.packages("sf")
install.packages("mapview")
install.packages("maps")
library(tidyverse)
library(sf)
library(mapview)
library(maps)

#read in data
lightning = read.csv("C:/Users/clbpt/OneDrive/Documents/GitHub/STAT-172-Project-1/data/web_data/ncei_data/nldn-tiles-2020.csv", nrows = 10000)

# Plot lightning data
mapview(lightning, xcol = "CENTERLON", ycol = "CENTERLAT", crs = 4269, grid = FALSE)

