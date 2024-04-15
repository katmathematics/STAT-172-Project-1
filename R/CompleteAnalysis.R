# Author(s) (ordered by contribution): Katja Mathesius

# We want to predict which counties will have the best prospects overtime for analysis
# Seems like we should make 3 models and then have a classifier at the end to decide what's good/bad

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/model_data/ModelDataComplete.csv")
complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data

# Coax the date column into the correct format
df$date <- as.character(df$date)
df$date <- paste("01",df$date)
df$date <- as.Date(df$date, format =  '%d %b %Y')
str(df)


### Examine the Data
## Interchange Examination
df_interchange_mean <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(mean_interchange = mean(mean_interchange))

avg_interchange_plot <- ggplot(df_interchange_mean, aes(x=date, y=mean_interchange)) +
  geom_line() + 
  xlab("Date") +
  ylab("Avg. Interchange") +
  labs(title = "Average Interchange in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
avg_interchange_plot

# In-Demand/Excess Ratio
df_deficit_excess <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,Region) %>%
  summarize(mean_interchange = mean(mean_interchange))

df_deficit_excess$deficit <- with(df_deficit_excess, ifelse(mean_interchange > 0, 'Excess', 'Deficit'))

deficit_excess_plot <- ggplot(df_deficit_excess) +
  xlab("Energy Excess vs Deficit") +
  ylab("Count") +
  ggtitle("Count of Months of Energy Excess or Deficit by Region ") +
  geom_bar(aes(x = deficit, fill=deficit), 
            stat = "count") + 
  guides(fill=guide_legend(title="Energy Needs")) +
  facet_wrap(~Region)
deficit_excess_plot

# Frequency distribution of mean interchange
freq_interchange_plot <- ggplot(df_interchange_mean, aes(x = mean_interchange)) +
  xlab("Avg. Interchange") +
  ylab("# Occurrences") +
  labs(title = "Frequency of Interchange in the US") +
  geom_histogram(color = "black", fill = "black")
freq_interchange_plot

## Wildfires Examination
df_wildfires_sum <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_wildfires = sum(sum_wildfires))

sum_wildfires_plot <- ggplot(df_wildfires_sum, aes(x=date, y=sum_wildfires)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Wildfires") +
  labs(title = "Wildfires in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_wildfires_plot

## Lightning Examination
df_lightning_sum <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_lightning = sum(sum_lightning))

sum_lightning_plot <- ggplot(df_lightning_sum, aes(x=date, y=sum_lightning)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Lightning") +
  labs(title = "Lightning in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_lightning_plot


### Run Interchange Prediction Models
source("R/Models/InterchangeModelETS.R")
source("R/Models/InterchangeModelLM.R")


### Run Lightning Prediction Models
source("R/Models/LightningModelETS.R")

### Run Wildfire Prediction Models
source("R/Models/WildfireModelETS.R")