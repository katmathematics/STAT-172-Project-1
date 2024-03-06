# Author(s) (ordered by contribution): Katja Mathesius
library(tidyverse)
library(readr)
library(ggplot2)
library(zoo)

setwd("Github/STAT-190-Project-1/")

raw_data <- list.files(path = "data/web_data/eia_data/interchange", pattern = "\\.csv$", full.names = TRUE) %>%
  lapply(read_csv) %>%
  bind_rows

print(unique(raw_data$Region))

raw_data$date <- as.Date(raw_data$"UTC Time at End of Hour", format =  "%m/%d/%Y %H:%M:%S")
df$Month_Yr <- 

raw_data <- raw_data %>% 
  rename("interchange" = "Interchange (MW)")

avg_daily_interchange <- raw_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date, Region) %>%
  summarize(mean_interchange = mean(interchange))

#aggregate(raw_data_region["Interchange (MW)"], by=raw_data_region[], sum)

avg_interchange_grouped <- avg_daily_interchange %>%
  group_by(Region)

# Most basic bubble plot
p <- ggplot(avg_interchange_grouped, aes(x=date, y=mean_interchange, group=Region, color=Region)) +
  geom_line() + 
  xlab("")
p

#writing the appended file  
write.csv(raw_data, "data/compressed_raw_data/EIAInterchange.csv", row.names=FALSE, quote=FALSE)
