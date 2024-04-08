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


# Read in data
complete_data = read.csv("data/model_data/ModelDataComplete.csv")
complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data

# Coax the date column into the correct format
df$date <- as.character(df$date)
df$date <- paste("01",df$date)
df$date <- as.Date(df$date, format =  '%d %b %Y')
str(df)


### Examine the Data
## Interchange Examination
df_interchange_mean <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(mean_interchange = mean(mean_interchange))

avg_interchange_plot <- ggplot(df_interchange_mean, aes(x=date, y=mean_interchange)) +
  geom_line() + 
  xlab("Date") +
  ylab("Avg. Interchange") +
  labs(title = "Average Interchange in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
avg_interchange_plot

# In-Demand/Excess Ratio
df_deficit_excess <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,Region) %>%
  summarize(mean_interchange = mean(mean_interchange))

df_deficit_excess$deficit <- with(df_deficit_excess, ifelse(mean_interchange > 0, 'Excess', 'Deficit'))

deficit_excess_plot <- ggplot(df_deficit_excess) +
  xlab("Energy Excess vs Deficit") +
  ylab("Count") +
  ggtitle("Count of Months of Energy Excess or Deficit by Region ") +
  geom_bar(aes(x = deficit, fill=deficit), 
            stat = "count") + 
  guides(fill=guide_legend(title="Energy Needs")) +
  facet_wrap(~Region)
deficit_excess_plot

# Frequency distribution of mean interchange
freq_interchange_plot <- ggplot(df_interchange_mean, aes(x = mean_interchange)) +
  xlab("Avg. Interchange") +
  ylab("# Occurrences") +
  labs(title = "Frequency of Interchange in the US") +
  geom_histogram(color = "black", fill = "black")
freq_interchange_plot

## Wildfires Examination
df_wildfires_sum <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_wildfires = sum(sum_wildfires))

sum_wildfires_plot <- ggplot(df_wildfires_sum, aes(x=date, y=sum_wildfires)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Wildfires") +
  labs(title = "Wildfires in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_wildfires_plot

## Lightning Examination
df_lightning_sum <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date) %>%
  summarize(sum_lightning = sum(sum_lightning))

sum_lightning_plot <- ggplot(df_lightning_sum, aes(x=date, y=sum_lightning)) +
  geom_line() + 
  xlab("Date") +
  ylab("Total Lightning") +
  labs(title = "Lightning in the US over time") +
  geom_smooth(method="lm", se=FALSE) +
  theme(axis.text.x = element_text(angle = 70, hjust=1))
sum_lightning_plot

### Predicting Lightning
lit_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,state) %>%
  summarize(sum_lightning = mean(sum_lightning))

lit_model_train <- lit_model_df %>% 
  filter(date < "2020-01-01 00:00:00")

lit_model_test <- lit_model_df %>% 
  filter(date >= "2020-01-01 00:00:00")

lit_model_train_nest <- lit_model_train %>%
  group_by(state) %>%
  nest()
lit_model_train_nest

lit_model_train_nest_ts <- lit_model_train_nest %>%
  mutate(data.ts = map(.x       = data, 
                       .f       = tk_ts, 
                       select   = -date, 
                       start    = 2015,
                       freq     = 12))
lit_model_train_nest_ts

lit_model_train_nest_fit <- lit_model_train_nest_ts %>%
  mutate(fit.ets = map(data.ts, ets))
lit_model_train_nest_fit

#int_model_train_nest_fit %>%
#  mutate(tidy = map(fit.ets, sw_tidy)) %>%
#  unnest(tidy) %>% 
#  spread(key = Region, value = estimate)

lit_model_train_nest_fit %>%
  mutate(glance = map(fit.ets, sw_glance)) %>%
  unnest(glance)

augment_fit_ets_lit <- lit_model_train_nest_fit %>%
  mutate(augment = map(fit.ets, sw_augment, timetk_idx = TRUE, rename_index = "date")) %>%
  unnest(augment)

augment_fit_ets_lit

augment_fit_ets_lit %>%
  ggplot(aes(x = date, y = .resid, group = state)) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_line(color = palette_light()[[2]]) +
  geom_smooth(method = "loess") +
  labs(title = "Energy Demand by Region",
       subtitle = "ETS Model Residuals", x = "") + 
  theme_tq() +
  facet_wrap(~ state, scale = "free_y", ncol = 3) +
  theme(axis.text.x = element_text(angle = 50, hjust=1))

# Forecast Lightning
lit_model_train_nest_fcast <- lit_model_train_nest_fit %>%
  mutate(fcast.ets = map(fit.ets, forecast, h = 12))
lit_model_train_nest_fcast

lit_model_train_nest_fcast_tidy <- lit_model_train_nest_fcast %>%
  mutate(sweep = map(fcast.ets, sw_sweep, fitted = FALSE, timetk_idx = TRUE)) %>%
  unnest(sweep)
lit_model_train_nest_fcast_tidy

lit_model_train_nest_fcast_tidy %>%
  ggplot(aes(x = index, y = sum_lightning, color = key, group = state)) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), 
              fill = "#D5DBFF", color = NA, size = 0) +
  geom_ribbon(aes(ymin = lo.80, ymax = hi.80, fill = key), 
              fill = "#596DD5", color = NA, size = 0, alpha = 0.8) +
  geom_line() +
  labs(title = "Lightning Frequency by Region Forecast",
       subtitle = "ETS Model Forecasts",
       x = "", y = "Lightning") +
  scale_color_tq() +
  scale_fill_tq() +
  facet_wrap(~ state, scales = "free_y", ncol = 3) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

lit_model_fcast <- lit_model_train_nest_fcast_tidy
lit_model_fcast <- lit_model_fcast[lit_model_fcast$key == "forecast",]
lit_model_fcast = select(lit_model_fcast, -c("data","data.ts","fit.ets","fcast.ets","key"))

lit_model_fcast <- lit_model_fcast %>% 
  rename("lightning_forecast" = "sum_lightning")

lit_model_fcast <- lit_model_fcast %>% 
  rename("date" = "index")

lit_model_test <- merge(x = lit_model_test, y = lit_model_fcast, by = c("state","date"), all.x = TRUE)


lit_model_test

lit_model_test_grp <- lit_model_test %>%
  group_by(state) 

# Check the Mean Absolute Error
lit_model_test_complete <- lit_model_test[complete.cases(lit_model_test), ]
mae(lit_model_test_complete$sum_lightning, lit_model_test_complete$lightning_forecast)

ggplot()+
  geom_line(data=lit_model_test_grp,aes(y=sum_lightning,x= date,colour="Actual"),size=1 )+
  geom_line(data=lit_model_test_grp,aes(y=lightning_forecast,x= date,colour="Predicted"),size=1) +
  scale_color_manual(name = "2020 Forecast Results", values = c("Actual" = "black", "Predicted" = "red")) +
  facet_wrap(~ state, scales = "free_y", ncol = 3) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Lightning States Forecast 2020 Predicted vs Actual",
       subtitle = "ETS Model Forecasts",
       x = "", y = "Demand")

### Predicting Wildfires
fir_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,state) %>%
  summarize(sum_wildfires = mean(sum_wildfires))

fir_model_train <- fir_model_df %>% 
  filter(date < "2020-01-01 00:00:00")

fir_model_test <- fir_model_df %>% 
  filter(date >= "2020-01-01 00:00:00")

fir_model_train_nest <- fir_model_train %>%
  group_by(state) %>%
  nest()
fir_model_train_nest

fir_model_train_nest_ts <- fir_model_train_nest %>%
  mutate(data.ts = map(.x       = data, 
                       .f       = tk_ts, 
                       select   = -date, 
                       start    = 2015,
                       freq     = 12))
fir_model_train_nest_ts

fir_model_train_nest_fit <- fir_model_train_nest_ts %>%
  mutate(fit.ets = map(data.ts, ets))
fir_model_train_nest_fit

#int_model_train_nest_fit %>%
#  mutate(tidy = map(fit.ets, sw_tidy)) %>%
#  unnest(tidy) %>% 
#  spread(key = Region, value = estimate)

fir_model_train_nest_fit %>%
  mutate(glance = map(fit.ets, sw_glance)) %>%
  unnest(glance)

augment_fit_ets_fir <- fir_model_train_nest_fit %>%
  mutate(augment = map(fit.ets, sw_augment, timetk_idx = TRUE, rename_index = "date")) %>%
  unnest(augment)

augment_fit_ets_fir

augment_fit_ets_fir %>%
  ggplot(aes(x = date, y = .resid, group = state)) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_line(color = palette_light()[[2]]) +
  geom_smooth(method = "loess") +
  labs(title = "Wildfire Occurences by State",
       subtitle = "ETS Model Residuals", x = "") + 
  theme_tq() +
  facet_wrap(~ state, scale = "free_y", ncol = 3) +
  theme(axis.text.x = element_text(angle = 50, hjust=1))

# Forecast Interchange
fir_model_train_nest_fcast <- fir_model_train_nest_fit %>%
  mutate(fcast.ets = map(fit.ets, forecast, h = 12))
fir_model_train_nest_fcast

fir_model_train_nest_fcast_tidy <- fir_model_train_nest_fcast %>%
  mutate(sweep = map(fcast.ets, sw_sweep, fitted = FALSE, timetk_idx = TRUE)) %>%
  unnest(sweep)
fir_model_train_nest_fcast_tidy

fir_model_train_nest_fcast_tidy %>%
  ggplot(aes(x = index, y = sum_wildfires, color = key, group = state)) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), 
              fill = "#D5DBFF", color = NA, size = 0) +
  geom_ribbon(aes(ymin = lo.80, ymax = hi.80, fill = key), 
              fill = "#596DD5", color = NA, size = 0, alpha = 0.8) +
  geom_line() +
  labs(title = "Lightning Occurences by State Forecast",
       subtitle = "ETS Model Forecasts",
       x = "", y = "Occurences") +
  scale_color_tq() +
  scale_fill_tq() +
  facet_wrap(~ state, scales = "free_y", ncol = 3) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

fir_model_fcast <- fir_model_train_nest_fcast_tidy
fir_model_fcast <- fir_model_fcast[fir_model_fcast$key == "forecast",]
fir_model_fcast = select(fir_model_fcast, -c("data","data.ts","fit.ets","fcast.ets","key"))

fir_model_fcast <- fir_model_fcast %>% 
  rename("wildfire_forecast" = "sum_wildfires")

fir_model_fcast <- fir_model_fcast %>% 
  rename("date" = "index")

fir_model_test <- merge(x = fir_model_test, y = fir_model_fcast, by = c("state","date"), all.x = TRUE)

fir_model_test

fir_model_test_grp <- fir_model_test %>%
  group_by(state) 

# Check the Mean Absolute Error
fir_model_test_complete <- fir_model_test[complete.cases(fir_model_test), ]
mae(fir_model_test_complete$sum_wildfires, fir_model_test_complete$wildfire_forecast)


ggplot()+
  geom_line(data=fir_model_test_grp,aes(y=sum_wildfires,x= date,colour="Actual"),size=1 )+
  geom_line(data=fir_model_test_grp,aes(y=wildfire_forecast,x= date,colour="Predicted"),size=1) +
  scale_color_manual(name = "2020 Forecast Results", values = c("Actual" = "black", "Predicted" = "red")) +
  facet_wrap(~ state, scales = "free_y", ncol = 3) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Wildfire Occurences by State Forecast 2020 Predicted vs Actual",
       subtitle = "ETS Model Forecasts",
       x = "", y = "Occurences")

### 