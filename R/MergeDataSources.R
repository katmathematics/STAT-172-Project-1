# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load the packages
packages <- c('tidyverse')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

# Read in the data
interchange_data = read.csv("data/cleaned_data/EIAInterchangeClean.csv")

lightning_data = read.csv("data/cleaned_data/NCEICountiesClean.csv")

wildfire_data = read.csv("data/cleaned_data/WildfiresClean.csv")

# List of states the stack overflow wanted me to create
states <- c("california","texas","florida","maine","vermont","new hampshire",
            "massachusetts","connecticut","rhode island","new york","kentucky",
            "ohio","west virginia","virginia","pennsylvania","maryland","delaware",
            "new jersey","tennessee","north carolina","south carolina",
            "georgia","alabama","mississippi","arkansas","louisiana","missouri",
            "illinois","iowa","wisconsin","indiana","michigan","minnesota","oklahoma",
            "kansas","south dakota","north dakota","washington","oregon","idaho","utah",
            "wyoming","montana","colorado","arizona","new mexico","nevada")

# Expand all the regions to mention the specific states they cover
interchange_data$states_covered <- str_replace(interchange_data$Region, "CAL", "california")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "TEX", "texas")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "FLA", "florida")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "NE", "maine_vermont_new hampshire_massachusetts_connecticut_rhode island")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "NY", "new york")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "MIDA", "kentucky_ohio_west virginia_virginia_pennsylvania_maryland_delaware_new jersey")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "TEN", "tennessee")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "CAR", "north carolina_south carolina")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "SE", "georgia_alabama")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "MIDW", "mississippi_arkansas_louisiana_missouri_illinois_iowa_wisconsin_indiana_michigan_minnesota")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "CENT", "oklahoma_kansas_south dakota_north dakota")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "NW", "washington_oregon_idaho_utah_wyoming_montana_colorado")
interchange_data$states_covered <- str_replace(interchange_data$states_covered, "SW", "arizona_new mexico_nevada")

# Read the lightning data's date as a date
lightning_data$date <- as.character(lightning_data$date)
lightning_data$date <- paste("01",lightning_data$date)
lightning_data$date_date <- format(as.Date(lightning_data$date, format =  '%d %b %Y'), '%b %Y')
str(lightning_data)

# Read the wildfire data's date as a date
wildfire_data$date <- as.character(wildfire_data$date)
wildfire_data$date <- paste("01",wildfire_data$date)
wildfire_data$date <- gsub(" ", "-", wildfire_data$date)
wildfire_data$date <- format(as.Date(wildfire_data$date, format =  '%d-%b-%y'), '%b %Y')
str(wildfire_data)


# Read the interchange data's date as a date
interchange_data$date <- as.character(interchange_data$date)
interchange_data$date <- paste("01",interchange_data$date)
interchange_data$date_date <- format(as.Date(interchange_data$date, format =  "%d %b %Y"), '%b %Y')
str(interchange_data)

# Many-to-many merge by date
merged_data <- merge(lightning_data, interchange_data, by = "date_date", all.x = TRUE) 
merged_data = select(merged_data, -c("date.x", "date.y"))
merged_data$state <- gsub(" ", "-", merged_data$state)
merged_data$states_covered <- gsub(" ", "-", merged_data$states_covered)

# Reduce the data down to get the correct merge 
EIA_NCEI_data <- merged_data
EIA_NCEI_data$flag <- mapply(grepl, EIA_NCEI_data$state, EIA_NCEI_data$states_covered)
EIA_NCEI_data <- EIA_NCEI_data[EIA_NCEI_data$flag == TRUE,]
EIA_NCEI_data = select(EIA_NCEI_data, -c("flag"))

# Merge in the wildfire data
colnames(EIA_NCEI_data)[names(EIA_NCEI_data) == "date_date"] <- "date"
final_data <- merge(x = EIA_NCEI_data, y = wildfire_data, by = c("state","date"), all.x = TRUE)


# Write the Merged Data 
write.csv(final_data, "data/model_data/ModelDataLeftOuter.csv", row.names=FALSE, quote=FALSE)

# Write the Merged Data where every row is complete
complete_data <- final_data[complete.cases(final_data), ]
write.csv(complete_data, "data/model_data/ModelDataComplete.csv", row.names=FALSE, quote=FALSE)