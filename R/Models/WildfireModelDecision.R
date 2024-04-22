# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','plotly','sf')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/cleaned_data/WildfiresClean.csv")
#complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data

# Read the lightning data's date as a date
df$date <- as.character(df$date)
df$date <- paste("01",df$date)
df$date <- gsub('-', ' ', df$date)
df$date <- format(as.Date(df$date, format =  '%d %b %y'), '%b %Y')
str(df)


fir_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(state,date) %>%
  summarize(sum_wildfires = mean(sum_wildfires))

for(lag_val in 12:23) {
  lag_col_name <- paste("lag_", lag_val,sep="")
  fir_model_df[[lag_col_name]] <- dplyr::lag(fir_model_df$sum_wildfires, n=lag_val)
}

fir_model_clean = fir_model_df[fir_model_df[["date"]] >= "1994-03-01", ]

fir_model_train <- fir_model_clean %>% 
  filter(date < "2020-01-01 00:00:00")

fir_model_test <- fir_model_clean %>% 
  filter(date >= "2020-01-01 00:00:00")

fir_model_train <- fir_model_train[ , !(names(fir_model_train) %in% c("date"))]

#build the initial tree
wildfire_tree <- rpart(sum_wildfires ~ ., data=fir_model_train, control=rpart.control(cp=.0001))

#identify best cp value to use
best <- wildfire_tree$cptable[which.min(wildfire_tree$cptable[,"xerror"]),"CP"]

#produce a pruned tree based on the best cp value
pruned_wildfire_tree <- prune(wildfire_tree, cp=best)

#plot the pruned tree (makes a really big tree, bad idea)
#prp(lightning_tree,
#    faclen=0, #use full names for factor labels
#    extra=1, #display number of obs. for each terminal node
#    roundint=F, #don't round to integers in output
#    digits=5) #display 5 decimal places in output

# Forecast lightning
fir_model_test[["wildfires_forecast"]] <- as.numeric(predict(pruned_wildfire_tree, fir_model_test))

mae(fir_model_test$sum_wildfires, fir_model_test$wildfires_forecast)
rae(fir_model_test$sum_wildfires, fir_model_test$wildfires_forecast)
