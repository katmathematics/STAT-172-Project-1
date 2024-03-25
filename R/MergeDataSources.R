# Author(s) (ordered by contribution): Katja Mathesius
packages <- c('tidyverse')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

interchange_data = read.csv("data/cleaned_data/EIAInterchangeClean.csv")

lightning_data = read.csv("data/cleaned_data/NCEICountiesCleaned.csv")

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


int_light_merge <- left_join(lightning_data,
                             interchange_data %>% mutate(states = sapply(strsplit(interchange_data$states_covered, "_"), 
                                       function(x) first(intersect(states, x)))),
          by = c("state_county" = "states")) %>% 
  select(-states_covered)