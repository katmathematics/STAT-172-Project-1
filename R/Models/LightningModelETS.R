# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/cleaned_data/NCEICountiesClean.csv")
#complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data


### Predicting Lightning
lit_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,state) %>%
  summarize(sum_lightning = mean(sum_lightning))

lit_model_train <- lit_model_df %>% 
  filter(date < "2023-01-01 00:00:00")

lit_model_test <- lit_model_df %>% 
  filter(date >= "2023-01-01 00:00:00")

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

# Check the Mean Absolute/Squared Error
lit_model_test_complete <- lit_model_test[complete.cases(lit_model_test), ]
mae(lit_model_test_complete$sum_lightning, lit_model_test_complete$lightning_forecast)
mse(lit_model_test_complete$sum_lightning, lit_model_test_complete$lightning_forecast)

rae(lit_model_test_complete$sum_lightning, lit_model_test_complete$lightning_forecast)



# For condensing the data to plot
lit_plot_forecast_data_short <- lit_model_test_complete %>%
  group_by(state) %>%
  summarize(lightning_forecast = sum(lightning_forecast))

lit_plot_real_data_short <- lit_model_test_complete %>%
  group_by(state) %>%
  summarize(sum_lightning = sum(sum_lightning))

# Plot the data
states_map <- map_data("state")
ggplot(lit_plot_real_data_short, aes(map_id = state)) + 
  geom_map(aes(fill = sum_lightning), map = states_map) +
  scale_fill_gradientn(colors=c("#0072B2","#000000")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='# Lightning Strikes', title = "Real Annual Total Lightning Strikes (Jan 2023-Dec 2023)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())


# Plot the data
states_map <- map_data("state")
ggplot(lit_plot_forecast_data_short, aes(map_id = state)) + 
  geom_map(aes(fill = lightning_forecast), map = states_map) +
  scale_fill_gradientn(colors=c("#0072B2","#000000")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='# Lightning Strikes', title = "Predicted Annual Total Lightning Strikes (Jan 2023-Dec 2023)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

# Write the Predictions
write.csv(lit_model_test_complete, "data/prediction_data/LightningPredictionsETS.csv", row.names=FALSE, quote=FALSE)
