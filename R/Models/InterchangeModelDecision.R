# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','plotly','sf','ISLR','rpart','rpart.plot')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

# Read in data
complete_data = read.csv("data/cleaned_data/EIAInterchangeClean.csv")
#complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data

int_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(Region,date) %>%
  summarize(mean_interchange = mean(mean_interchange))

for(lag_val in 12:23) {
  lag_col_name <- paste("lag_", lag_val,sep="")
  int_model_df[[lag_col_name]] <- dplyr::lag(int_model_df$mean_interchange, n=lag_val)
}

int_model_clean = int_model_df[int_model_df[["date"]] >= "2017-06-01", ]

int_model_train <- int_model_clean %>% 
  filter(date < "2023-03-01 00:00:00")

int_model_test <- int_model_clean %>% 
  filter(date >= "2023-03-01 00:00:00")

int_model_train <- int_model_train[ , !(names(int_model_train) %in% c("date"))]

#build the initial tree
interchange_tree <- rpart(mean_interchange ~ ., data=int_model_train, control=rpart.control(cp=.0001))

#identify best cp value to use
best <- interchange_tree$cptable[which.min(interchange_tree$cptable[,"xerror"]),"CP"]

#produce a pruned tree based on the best cp value
pruned_interchange_tree <- prune(interchange_tree, cp=best)

#plot the pruned tree (makes a really big tree, bad idea)
#prp(lightning_tree,
#    faclen=0, #use full names for factor labels
#    extra=1, #display number of obs. for each terminal node
#    roundint=F, #don't round to integers in output
#    digits=5) #display 5 decimal places in output

# Forecast lightning
int_model_test[["interchange_forecast"]] <- predict(pruned_interchange_tree, int_model_test)
mae(int_model_test$mean_interchange, int_model_test$interchange_forecast)
rae(int_model_test$mean_interchange, int_model_test$interchange_forecast)

# Write the Predictions
write.csv(lit_plot_data, "data/prediction_data/InterchangePredictionsDecision.csv", row.names=FALSE, quote=FALSE)