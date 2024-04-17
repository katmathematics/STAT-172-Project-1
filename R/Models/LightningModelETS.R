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
  filter(date < "2022-09-01 00:00:00")

lit_model_test <- lit_model_df %>% 
  filter(date >= "2022-09-01 00:00:00")

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
