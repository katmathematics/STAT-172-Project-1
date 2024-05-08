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


### Examine the Data
source("R/Model_Data_Examination/InterchangeAnalysis.R")
source("R/Model_Data_Examination/LightningAnalysis.R")
source("R/Model_Data_Examination/WildfireAnalysis.R")


### Run Interchange Prediction Models
source("R/Models/InterchangeModelETS.R")
source("R/Models/InterchangeModelLM.R")
source("R/Models/InterchangeModelDecision.R")

### Run Lightning Prediction Models
source("R/Models/LightningModelETS.R")
source("R/Models/LightningModelLM.R")
source("R/Models/LightningModelDecision.R")


### Run Wildfire Prediction Models
source("R/Models/WildfireModelETS.R")
source("R/Models/WildfireModelLM.R")
source("R/Models/WildfireModelDecision.R")

### Complete Forecast Map
source("R/Models/UnifiedModel.R")
