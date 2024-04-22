# Author(s) (ordered by contribution): Caleb Patterson, Katja Mathesius
### Does Maps actually get used at all?

# Install packages if not installed, then load packages
packages <- c('tidyverse', 'sf','mapview','maps','stringi','sp','maps','dplyr','zoo')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

#install.packages("maptools", repos = "https://packagemanager.posit.co/cran/2023-10-13")
#library(maptools)

# Function for converting longitude and latitude to US counties
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


#read in data
#lightning = read.csv("data/web_data/ncei_data/nldn-tiles-2020.csv", nrows = 10000)
NCEI_files <- list.files(path = "data/web_data/ncei_data", pattern = "\\.csv$", full.names = TRUE)

datalist = list()
i <- 1
for (file in NCEI_files) {
  raw_data <- read.csv(file)
  lightningPoints <- data.frame(x = raw_data$CENTERLON, y = raw_data$CENTERLAT)
  raw_data$county <- lonlat_to_county_sp(lightningPoints)
  raw_data = raw_data[!is.na(raw_data$county),]
  raw_data = select(raw_data, -c("CENTERLON", "CENTERLAT"))
  raw_data[c('state', 'county')] <- str_split_fixed(raw_data$county, ',', 2)
  raw_data$county <- paste(raw_data$state, raw_data$county)
  # Put date into a date format
  raw_data["str_date"] <- as.character(raw_data[['X.ZDAY']])
  raw_data$date <- as.Date(raw_data$str_date, format =  "%Y%m%d")
  lightning_monthly_count <- raw_data %>%
    mutate(date = zoo::as.yearmon(date)) %>%
    group_by(date, state, county) %>%
    summarize(sum_lightning = sum(TOTAL_COUNT))
  datalist[[i]] <- lightning_monthly_count
  i <- i+1
}


combined_data = do.call(rbind, datalist)


# Write the Compressed Data 
write.csv(combined_data, "data/cleaned_data/NCEICountiesClean.csv", row.names=FALSE, quote=FALSE)


