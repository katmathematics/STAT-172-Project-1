# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

#wildfire_data = read.csv("data/cleaned_data/WildfiresClean.csv")

## Wildfires Examination
df_wildfires_sum <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_wildfires = sum(sum_wildfires))

sum_wildfires_plot <- ggplot(df_wildfires_sum, aes(x=date, y=sum_wildfires)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Wildfires") +
  labs(title = "Wildfires in the US Over Time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_wildfires_plot
ggsave("data_visualizations/Wildfire_visualizations/Wildfires_in_the_US_Over_Time.png")