# Author(s) (ordered by contribution): Caleb Patterson, Katja Mathesius
### Does Maps actually get used at all?

# Install packages if not installed, then load packages
packages <- c('tidyverse', 'sf','mapview','maps','stringi')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


library(sp)
library(maps)
library(maptools)
library(dplyr)
library(zoo)


#read in data
#lightning = read.csv("data/web_data/ncei_data/nldn-tiles-2020.csv", nrows = 10000)
raw_data <- list.files(path = "data/web_data/ncei_data", pattern = "\\.csv$", full.names = TRUE) %>%
  lapply(read_csv) %>%
  bind_rows

lonlat_to_county_sp <- function(pointsDF) {
  # Prepare SpatialPolygons object with one SpatialPolygon
  # per state (plus DC, minus HI & AK)
  states <- map('county', fill=TRUE, col="transparent", plot=FALSE)
  IDs <- sapply(strsplit(states$names, ":"), function(x) x[1])
  states_sp <- map2SpatialPolygons(states, IDs=IDs,
                                   proj4string=CRS("+proj=longlat +datum=WGS84"))
  
  # Convert pointsDF to a SpatialPoints object 
  pointsSP <- SpatialPoints(pointsDF, 
                            proj4string=CRS("+proj=longlat +datum=WGS84"))
  
  # Use 'over' to get _indices_ of the Polygons object containing each point 
  indices <- over(pointsSP, states_sp)
  
  # Return the state names of the Polygons object containing each point
  stateNames <- sapply(states_sp@polygons, function(x) x@ID)
  stateNames[indices]
}

lightningPoints <- data.frame(x = raw_data$CENTERLON, y = raw_data$CENTERLAT)

raw_data$county <- lonlat_to_county_sp(lightningPoints)


raw_data = raw_data[!is.na(raw_data$county),]


colnames(raw_data)
clean_data = select(raw_data, -c("...1", "CENTERLON", "CENTERLAT"))

clean_data[c('state_county', 'county')] <- str_split_fixed(df$county, ',', 2)

# Write the Compressed Data 
write.csv(clean_data, "data/compressed_raw_data/NCEICountiesCompressed.csv", row.names=FALSE, quote=FALSE)


