# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('ggplot2', 'dplyr')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in Data
EIA_Int = read.csv("data/cleaned_data/EIAInterchangeClean.csv")

#print(unique(EIA_Int$Region))


avg_interchange_grouped <- EIA_Int %>%
  group_by(Region)

avg_interchange_grouped_date <- avg_interchange_grouped

avg_interchange_grouped_date$date <- format(as.Date(avg_interchange_grouped_date$"date", format =  "%b %Y"),"%y-%m")
str(avg_interchange_grouped_date)

p <- ggplot(avg_interchange_grouped_date, aes(x=date, y=mean_interchange, group=Region, color=Region)) +
  geom_line() + 
  xlab("Date") +
  theme(axis.text.x = element_text(angle = 90, hjust=1))
p
ggsave("data_visualizations/EIA_visualizations/p.png")