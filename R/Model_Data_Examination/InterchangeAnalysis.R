# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
interchange_data = read.csv("data/cleaned_data/EIAInterchangeClean.csv")

## Interchange Examination
interchange_mean_df <- interchange_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(mean_interchange = mean(mean_interchange))


## Average Interchange
avg_interchange_plot <- ggplot(interchange_mean_df, aes(x=date, y=mean_interchange)) +
  geom_line() + 
  xlab("Date") +
  ylab("Avg. Interchange") +
  labs(title = "Average Interchange in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
avg_interchange_plot

## In-Demand/Excess Ratio Plot
df_deficit_excess <- interchange_data %>%
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

## Frequency distribution of mean interchange Plot
freq_interchange_plot <- ggplot(interchange_mean_df, aes(x = mean_interchange)) +
  xlab("Avg. Interchange") +
  ylab("# Occurrences") +
  labs(title = "Frequency of Interchange in the US") +
  geom_histogram(color = "black", fill = "black")
freq_interchange_plot

## Time Series Decomposition