# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','plotly','sf','ISLR','rpart','rpart.plot')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))



# Read in data
complete_data = read.csv("data/cleaned_data/NCEICountiesClean.csv")
complete_data = select(complete_data, -c("county"))
df <- complete_data


lit_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(state,date) %>%
  summarize(sum_lightning = mean(sum_lightning))


for(lag_val in 12:23) {
  lag_col_name <- paste("lag_", lag_val,sep="")
  lit_model_df[[lag_col_name]] <- dplyr::lag(lit_model_df$sum_lightning, n=lag_val)
}

lit_model_clean = lit_model_df[lit_model_df[["date"]] >= "2017-06-01", ]

lit_model_train <- lit_model_df %>% 
  filter(date < "2023-01-01 00:00:00")

lit_model_test <- lit_model_df %>% 
  filter(date >= "2023-01-01 00:00:00")

lit_model_train <- lit_model_train[ , !(names(lit_model_train) %in% c("date"))]

#build the initial tree
lightning_tree <- rpart(sum_lightning ~ ., data=lit_model_train, control=rpart.control(cp=.0001))

#identify best cp value to use
best <- lightning_tree$cptable[which.min(lightning_tree$cptable[,"xerror"]),"CP"]

#produce a pruned tree based on the best cp value
pruned_lightning_tree <- prune(lightning_tree, cp=best)

#plot the pruned tree (makes a really big tree, bad idea)
#prp(lightning_tree,
#    faclen=0, #use full names for factor labels
#    extra=1, #display number of obs. for each terminal node
#    roundint=F, #don't round to integers in output
#    digits=5) #display 5 decimal places in output

# Forecast lightning
lit_model_test[["lightning_forecast"]] <- predict(pruned_lightning_tree, lit_model_test)
mae(lit_model_test$sum_lightning, lit_model_test$lightning_forecast)
rae(lit_model_test$sum_lightning, lit_model_test$lightning_forecast)

# Write the Predictions
write.csv(lit_plot_data, "data/prediction_data/LightningPredictionsDecision.csv", row.names=FALSE, quote=FALSE)
