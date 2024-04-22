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

lmModel <- lm(sum_wildfires ~ . , data = fir_model_train)

summary(lmModel)


fir_model_test[["wildfire_forecast"]] <- predict(lmModel, fir_model_test)


fir_model_test_grp <- fir_model_test %>%
  group_by(state) 

fir_plot_data = select(fir_model_test_grp, c("state","date","sum_wildfires","wildfire_forecast"))

# Check the Mean Absolute Error
fir_plot_data_complete <- fir_plot_data[complete.cases(fir_plot_data), ]
mae(fir_plot_data_complete$sum_wildfires, fir_plot_data_complete$wildfire_forecast)
rae(fir_plot_data_complete$sum_wildfires, fir_plot_data_complete$wildfire_forecast)




# For condensing the data to plot
fir_plot_forecast_data_short <- fir_plot_data_complete %>%
  group_by(state) %>%
  summarize(wildfire_forecast = sum(wildfire_forecast))

fir_plot_real_data_short <- fir_plot_data_complete %>%
  group_by(state) %>%
  summarize(sum_wildfires = sum(sum_wildfires))

# Plot the data
states_map <- map_data("state")
ggplot(fir_plot_real_data_short, aes(map_id = state)) + 
  geom_map(aes(fill = sum_wildfires), map = states_map) +
  scale_fill_gradientn(colors=c("#0072B2","#000000")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='# Wildfires', title = "Real Annual Total Wildfires (Jan 2020-Dec 2020)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())


# Plot the data
states_map <- map_data("state")
ggplot(fir_plot_forecast_data_short, aes(map_id = state)) + 
  geom_map(aes(fill = wildfire_forecast), map = states_map) +
  scale_fill_gradientn(colors=c("#0072B2","#000000")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='# Wildfires', title = "Predicted Annual Total Wildfires (Jan 2020-Dec 2020)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

# Write the Predictions
write.csv(fir_plot_data_complete, "data/prediction_data/WildfirePredictionsLM.csv", row.names=FALSE, quote=FALSE)
