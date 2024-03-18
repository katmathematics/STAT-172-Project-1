# Author(s) (ordered by contribution): Caleb Patterson
### Does Maps actually get used at all?

# Install packages if not installed, then load packages
packages <- c('tidyverse', 'sf','mapview','maps')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

#read in data
lightning = read.csv("data/web_data/ncei_data/nldn-tiles-2020.csv", nrows = 10000)

# Plot lightning data
mapview(lightning, xcol = "CENTERLON", ycol = "CENTERLAT", crs = 4269, grid = FALSE)

