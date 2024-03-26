# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse', 'ggplot2', 'readr','zoo')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

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

# Check how many NA are in the interchange column
percent_na = sum(is.na(clean_data$interchange))/nrow(clean_data)
if (percent_na > .005) {
  warning("HIGH PERCENT OF MISSING INTERCHANGE DATA DETECTED")
}

clean_data = clean_data[!is.na(clean_data$interchange),]


# Condense the data by taking the average of the date
avg_daily_interchange <- clean_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date, Region) %>%
  summarize(mean_interchange = mean(interchange))

# Write the Cleaned Data 
write.csv(avg_daily_interchange, "data/cleaned_data/EIAInterchangeClean.csv", row.names=FALSE, quote=FALSE)
