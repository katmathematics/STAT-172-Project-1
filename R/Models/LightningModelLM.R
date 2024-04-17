# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','plotly','sf')
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
  filter(date < "2022-09-01 00:00:00")

lit_model_test <- lit_model_df %>% 
  filter(date >= "2022-09-01 00:00:00")

lit_model_train <- lit_model_train[ , !(names(lit_model_train) %in% c("date"))]

lmModel <- lm(sum_lightning ~ . , data = lit_model_train)

summary(lmModel)


lit_model_test[["lightning_forecast"]] <- predict(lmModel, lit_model_test)


lit_model_test_grp <- lit_model_test %>%
  group_by(state) 

lit_plot_data = select(lit_model_test_grp, c("state","date","sum_lightning","lightning_forecast"))

lit_plot_data <- lit_plot_data %>% mutate(absolute_error = abs(abs(sum_lightning)-abs(lightning_forecast)))

lit_plot_data = select(lit_plot_data, c("state","date","absolute_error"))

lit_plot_data_short <- lit_plot_data %>%
  group_by(state) %>%
  summarize(absolute_error = mean(absolute_error))

g <- ggplot(lit_plot_data_short) +
  geom_polygon(aes(fill=absolute_error)) +
  scale_fill_distiller("water level", palette="Spectral") +
  ggtitle("Water by State")
g
