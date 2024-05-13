# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

lightning_data = read.csv("data/cleaned_data/NCEICountiesClean.csv")

## Lightning Examination
df_lightning_sum <- lightning_data %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_lightning = sum(sum_lightning))

# Total Lightning overtime
sum_lightning_plot <- ggplot(df_lightning_sum, aes(x=date, y=sum_lightning)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Lightning") +
  labs(title = "Lightning in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_lightning_plot
ggsave("data_visualizations/NCEI_visualizations/Average_Interchange_in_the_US_Over_Time.png")
