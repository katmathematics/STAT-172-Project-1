# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','plotly','sf')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/model_data/ModelDataComplete.csv")
complete_data = select(complete_data, -c("county","Region","flag"))
df <- complete_data


fir_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(state,date) %>%
  summarize(sum_wildfires = mean(sum_wildfires))

for(lag_val in 12:23) {
  lag_col_name <- paste("lag_", lag_val,sep="")
  fir_model_df[[lag_col_name]] <- dplyr::lag(fir_model_df$sum_wildfires, n=lag_val)
}

fir_model_clean = fir_model_df[fir_model_df[["date"]] >= "2017-06-01", ]

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

fir_plot_data <- fir_plot_data %>% mutate(absolute_error = abs(abs(sum_wildfires)-abs(wildfire_forecast)))

fir_plot_data = select(fir_plot_data, c("state","date","absolute_error"))

fir_plot_data_short <- fir_plot_data %>%
  group_by(state) %>%
  summarize(absolute_error = mean(absolute_error))

g <- ggplot(lit_plot_data_short) +
  geom_polygon(aes(fill=absolute_error)) +
  scale_fill_distiller("water level", palette="Spectral") +
  ggtitle("Water by State")
g