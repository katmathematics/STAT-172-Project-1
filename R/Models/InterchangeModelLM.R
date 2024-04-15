# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/model_data/ModelDataComplete.csv")
complete_data = select(complete_data, -c("flag","states_covered"))
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
  filter(date < "2020-01-01 00:00:00")

int_model_test <- int_model_clean %>% 
  filter(date >= "2020-01-01 00:00:00")

int_model_train <- int_model_train[ , !(names(int_model_train) %in% c("date"))]

lmModel <- lm(mean_interchange ~ . , data = int_model_train)

summary(lmModel)
