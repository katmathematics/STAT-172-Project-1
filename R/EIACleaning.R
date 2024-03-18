# Author(s) (ordered by contribution): Katja Mathesius
install.packages(c('tidyverse', 'ggplot2', 'readr','zoo'))

library(tidyverse)
library(readr)
library(ggplot2)
library(zoo)

raw_data <- list.files(path = "data/web_data/eia_data/interchange", pattern = "\\.csv$", full.names = TRUE) %>%
  lapply(read_csv) %>%
  bind_rows

# Write the Appended Data
#write.csv(raw_data, "data/compressed_raw_data/EIAInterchange.csv", row.names=FALSE, quote=FALSE)

# Remove spaces from column name
clean_data <- raw_data %>% 
  rename("interchange" = "Interchange (MW)")

# Put date into a date format
clean_data$date <- as.Date(clean_data$"UTC Time at End of Hour", format =  "%m/%d/%Y %H:%M:%S")

# Condense the data by taking the average of the date
avg_daily_interchange <- clean_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date, Region) %>%
  summarize(mean_interchange = mean(interchange))

# Write the Cleaned Data 
write.csv(avg_daily_interchange, "data/cleaned_data/EIAInterchangeClean.csv", row.names=FALSE, quote=FALSE)