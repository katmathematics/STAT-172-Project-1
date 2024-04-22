# Author(s) (ordered by contribution): Katja Mathesius

# Install packages if not installed, then load packages
packages <- c('tidyverse','ggplot2','zoo','dplyr','smooth','timetk','forecast','tidyquant','sweep','Metrics')
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


# Read in data
complete_data = read.csv("data/model_data/ModelDataComplete.csv")
complete_data = select(complete_data, -c("flag"))
df <- complete_data

# Read the data's date as a date
df$date <- as.character(df$date)
df$date <- paste("01",df$date)
df$date <- format(as.Date(df$date, format =  '%d %b %Y'), '%b %Y')
str(df)

# Set up the data
model_df <- df %>%
  mutate(date = zoo::as.yearmon(date)) %>%
  group_by(date,state,Region,states_covered,sum_wildfires,mean_interchange) %>%
  summarize(sum_lightning = sum(sum_lightning))

int_model_df <- model_df %>%
  group_by(date,Region) %>%
  summarize(mean_interchange = mean(mean_interchange)) %>%
  select(c("date","Region","mean_interchange"))

lit_model_df <- model_df %>%
  group_by(date,state) %>%
  select(c("date","state","sum_lightning"))

fir_model_df <- model_df %>%
  group_by(date,state) %>%
  select(c("date","state","sum_wildfires"))

### Interchange
int_model_df <- int_model_df %>% 
  filter(date < "2019-01-01 00:00:00")

int_model_train_nest <- int_model_df %>%
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

# Forecast Interchange
int_model_train_nest_fcast <- int_model_train_nest_fit %>%
  mutate(fcast.ets = map(fit.ets, forecast, h = 12))
int_model_train_nest_fcast

int_model_train_nest_fcast_tidy <- int_model_train_nest_fcast %>%
  mutate(sweep = map(fcast.ets, sw_sweep, fitted = FALSE, timetk_idx = TRUE)) %>%
  unnest(sweep)
int_model_train_nest_fcast_tidy


int_model_fcast <- int_model_train_nest_fcast_tidy
int_model_fcast <- int_model_fcast[int_model_fcast$key == "forecast",]
int_model_fcast = select(int_model_fcast, -c("data","data.ts","fit.ets","fcast.ets","key"))

int_model_fcast <- int_model_fcast %>% 
  rename("interchange_forecast" = "mean_interchange")


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
int_model_fcast$states_covered <- str_replace(int_model_fcast$Region, "CAL", "california")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "TEX", "texas")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "FLA", "florida")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "NE", "maine_vermont_new hampshire_massachusetts_connecticut_rhode island")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "NY", "new york")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "MIDA", "kentucky_ohio_west virginia_virginia_pennsylvania_maryland_delaware_new jersey")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "TEN", "tennessee")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "CAR", "north carolina_south carolina")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "SE", "georgia_alabama")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "MIDW", "mississippi_arkansas_louisiana_missouri_illinois_iowa_wisconsin_indiana_michigan_minnesota")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "CENT", "oklahoma_kansas_south dakota_north dakota_nebraska")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "NW", "washington_oregon_idaho_utah_wyoming_montana_colorado")
int_model_fcast$states_covered <- str_replace(int_model_fcast$states_covered, "SW", "arizona_new mexico_nevada")

int_model_fcast$states_covered <- as.list(strsplit(int_model_fcast$states_covered,"_"))

int_model_test_states <- tidyr::unnest(int_model_fcast, cols = states_covered)


#int_plot_data <- int_model_test_states %>% mutate(absolute_error = abs(abs(mean_interchange)-abs(interchange_forecast)))
int_plot_data <- int_model_test_states[complete.cases(int_model_test_states), ]

# For condensing the data to plot
int_plot_forecast_data_short <- int_plot_data %>%
  group_by(states_covered) %>%
  summarize(interchange_forecast = mean(interchange_forecast))

colnames(int_plot_forecast_data_short)[colnames(int_plot_forecast_data_short) == 'states_covered'] <- 'state'

### Lightning
lit_model_df <- lit_model_df %>% 
  filter(date < "2019-01-01 00:00:00")

lit_model_train_nest <- lit_model_df %>%
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

# For condensing the data to plot
lit_plot_forecast_data_short <- lit_model_fcast %>%
  group_by(state) %>%
  summarize(lightning_forecast = sum(lightning_forecast))

### Wildfire
for(lag_val in 12:23) {
  lag_col_name <- paste("lag_", lag_val,sep="")
  fir_model_df[[lag_col_name]] <- dplyr::lag(fir_model_df$sum_wildfires, n=lag_val)
}

fir_model_train <- fir_model_df %>% 
  filter(date < "2019-01-01 00:00:00")

fir_model_test <- fir_model_df %>% 
  filter(date >= "2019-01-01 00:00:00")



fir_model_train <- fir_model_train[ , !(names(fir_model_train) %in% c("date"))]

lmModel <- lm(sum_wildfires ~ . , data = fir_model_train)

summary(lmModel)


fir_model_test[["wildfire_forecast"]] <- predict(lmModel, fir_model_test)

fir_plot_forecast_data <- fir_model_test %>% 
  select(c("state","date","wildfire_forecast")) %>%
  group_by(state) %>%
  summarize(wildfire_forecast = sum(wildfire_forecast))


### Combine and Display
final_data <- full_join(x = int_plot_forecast_data_short, y = lit_plot_forecast_data_short, by = "state")
final_data <- full_join(x = final_data, y = fir_plot_forecast_data, by = "state")

scaled_final_data <- final_data %>%
  select(-state) %>%
  transmute_if(is.numeric, scale) %>% 
  add_column(state = final_data$state)
scaled_final_data[is.na(scaled_final_data)] <- 0

scaled_final_data$custom_metric <- with(scaled_final_data, -1*(-2*interchange_forecast + lightning_forecast + wildfire_forecast))

plot_final_data = int_model_fcast = select(scaled_final_data, c("state","custom_metric"))


# Plot the data
states_map <- map_data("state")
ggplot(plot_final_data, aes(map_id = state)) + 
  geom_map(aes(fill = custom_metric), map = states_map) +
  scale_fill_gradientn(colors=c("#000000","#0072B2")) + 
  expand_limits(x = states_map$long, y = states_map$lat) + 
  borders("state", colour = "#222222") + 
  labs(fill='Desirability Score', title = "Forecasted Ideal Expansion Areas (2021)") +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank())
