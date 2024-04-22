# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics','data.table')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/cleaned_data/EIAInterchangeClean.csv")
#complete_data = select(complete_data, -c("flag","states_covered"))
df <- complete_data

### Predicting Interchange
# Based on: https://cran.rstudio.com/web/packages/sweep/vignettes/SW01_Forecasting_Time_Series_Groups.html
int_model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,Region) %>%
  summarize(mean_interchange = mean(mean_interchange))

int_model_train <- int_model_df %>% 
  filter(date < "2023-02-01 00:00:00")

int_model_test <- int_model_df %>% 
  filter(date >= "2023-02-01 00:00:00")

int_model_train_nest <- int_model_train %>%
  group_by(Region) %>%
  nest()
int_model_train_nest

int_model_train_nest_ts <- int_model_train_nest %>%
  mutate(data.ts = map(.x       = data, 
                       .f       = tk_ts, 
                       select   = -date, 
                       start    = 2015,
                       freq     = 12))
int_model_train_nest_ts

int_model_train_nest_fit <- int_model_train_nest_ts %>%
  mutate(fit.ets = map(data.ts, ets))
int_model_train_nest_fit

#int_model_train_nest_fit %>%
#  mutate(tidy = map(fit.ets, sw_tidy)) %>%
#  unnest(tidy) %>% 
#  spread(key = Region, value = estimate)

int_model_train_nest_fit %>%
  mutate(glance = map(fit.ets, sw_glance)) %>%
  unnest(glance)

augment_fit_ets_int <- int_model_train_nest_fit %>%
  mutate(augment = map(fit.ets, sw_augment, timetk_idx = TRUE, rename_index = "date")) %>%
  unnest(augment)

augment_fit_ets_int

augment_fit_ets_int %>%
  ggplot(aes(x = date, y = .resid, group = Region)) +
  geom_hline(yintercept = 0, color = "grey40") +
  geom_line(color = palette_light()[[2]]) +
  geom_smooth(method = "loess") +
  labs(title = "Energy Demand by Region",
       subtitle = "ETS Model Residuals", x = "") + 
  theme_tq() +
  facet_wrap(~ Region, scale = "free_y", ncol = 3) +
  theme(axis.text.x = element_text(angle = 50, hjust=1))

# Forecast Interchange
int_model_train_nest_fcast <- int_model_train_nest_fit %>%
  mutate(fcast.ets = map(fit.ets, forecast, h = 12))
int_model_train_nest_fcast

int_model_train_nest_fcast_tidy <- int_model_train_nest_fcast %>%
  mutate(sweep = map(fcast.ets, sw_sweep, fitted = FALSE, timetk_idx = TRUE)) %>%
  unnest(sweep)
int_model_train_nest_fcast_tidy

int_model_train_nest_fcast_tidy %>%
  ggplot(aes(x = index, y = mean_interchange, color = key, group = Region)) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), 
              fill = "#D5DBFF", color = NA, size = 0) +
  geom_ribbon(aes(ymin = lo.80, ymax = hi.80, fill = key), 
              fill = "#596DD5", color = NA, size = 0, alpha = 0.8) +
  geom_line() +
  labs(title = "Energy Demand by Region Forecast",
       subtitle = "ETS Model Forecasts",
       x = "", y = "Demand") +
  scale_color_tq() +
  scale_fill_tq() +
  facet_wrap(~ Region, scales = "free_y", ncol = 3) +
  theme_tq() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

int_model_fcast <- int_model_train_nest_fcast_tidy
int_model_fcast <- int_model_fcast[int_model_fcast$key == "forecast",]
int_model_fcast = select(int_model_fcast, -c("data","data.ts","fit.ets","fcast.ets","key"))

int_model_fcast <- int_model_fcast %>% 
  rename("interchange_forecast" = "mean_interchange")

int_model_fcast <- int_model_fcast %>% 
  rename("date" = "index")

int_model_test <- merge(x = int_model_test, y = int_model_fcast, by = c("Region","date"), all.x = TRUE)


int_model_test

int_model_test_grp <- int_model_test %>%
  group_by(Region) 

# Check the Mean Absolute Error
mae(int_model_test_grp$mean_interchange, int_model_test_grp$interchange_forecast)
rae(int_model_test_grp$mean_interchange, int_model_test_grp$interchange_forecast)

# List of states the stack overflow wanted me to create
states <- c("california","texas","florida","maine","vermont","new hampshire",
            "massachusetts","connecticut","rhode island","new york","kentucky",
            "ohio","west virginia","virginia","pennsylvania","maryland","delaware",
            "new jersey","tennessee","north carolina","south carolina",
            "georgia","alabama","mississippi","arkansas","louisiana","missouri",
            "illinois","iowa","wisconsin","indiana","michigan","minnesota","oklahoma",
            "kansas","south dakota","north dakota","washington","oregon","idaho","utah",
            "wyoming","montana","colorado","arizona","new mexico","nevada")

# Expand all the regions to mention the specific states they cover
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$Region, "CAL", "california")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "TEX", "texas")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "FLA", "florida")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "NE", "maine_vermont_new hampshire_massachusetts_connecticut_rhode island")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "NY", "new york")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "MIDA", "kentucky_ohio_west virginia_virginia_pennsylvania_maryland_delaware_new jersey")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "TEN", "tennessee")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "CAR", "north carolina_south carolina")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "SE", "georgia_alabama")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "MIDW", "mississippi_arkansas_louisiana_missouri_illinois_iowa_wisconsin_indiana_michigan_minnesota")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "CENT", "oklahoma_kansas_south dakota_north dakota_nebraska")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "NW", "washington_oregon_idaho_utah_wyoming_montana_colorado")
int_model_test_grp$states_covered <- str_replace(int_model_test_grp$states_covered, "SW", "arizona_new mexico_nevada")

int_model_test_grp$states_covered <- as.list(strsplit(int_model_test_grp$states_covered,"_"))

int_model_test_states <- tidyr::unnest(int_model_test_grp, cols = states_covered)




#int_plot_data <- int_model_test_states %>% mutate(absolute_error = abs(abs(mean_interchange)-abs(interchange_forecast)))
int_plot_data <- int_model_test_states[complete.cases(int_model_test_states), ]

# For condensing the data to plot
int_plot_forecast_data_short <- int_plot_data %>%
  group_by(states_covered) %>%
  summarize(interchange_forecast = mean(interchange_forecast))

int_plot_real_data_short <- int_plot_data %>%
  group_by(states_covered) %>%
  summarize(mean_interchange = mean(mean_interchange))

# Plot the data
states_map <- map_data("state")
ggplot(int_plot_real_data_short, aes(map_id = states_covered)) + 
  geom_map(aes(fill = mean_interchange), map = states_map) +
  scale_fill_gradientn(colors=c("#000000","#0072B2")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='Excess/Deficit Energy', title = "Avg. Real Energy Demand (Feb 2023-Jan 2024)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())
  

# Plot the data
states_map <- map_data("state")
ggplot(int_plot_forecast_data_short, aes(map_id = states_covered)) + 
  geom_map(aes(fill = interchange_forecast), map = states_map) +
  scale_fill_gradientn(colors=c("#000000","#0072B2")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='Excess/Deficit Energy', title = "Avg. Predicted Energy Demand (Feb 2023-Jan 2024)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())

# Write the Predictions
write.csv(int_plot_data, "data/prediction_data/InterchangePredictionsETS.csv", row.names=FALSE, quote=FALSE)
