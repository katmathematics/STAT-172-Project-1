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

avg_interchange_grouped <- avg_daily_interchange %>%
  group_by(Region)

# Most basic bubble plot
p <- ggplot(avg_interchange_grouped, aes(x=date, y=mean_interchange, group=Region, color=Region)) +
  geom_line() + 
  xlab("")
p
