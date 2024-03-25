rm(list = ls())

library(DBI)
library(RSQLite)
library(dplyr)
library(ggplot2)
library(xts)
library(ggfortify)  # For autoplot function
library(sf)
library(zoo)
library(viridis) #color pallette
library(maps)
library(mapview)
library(scales)


#----Reading in the Data----
#sqlite_file <- "FPA_FOD_20221014.sqlite"

#sqlite_file <- "R_analysis/FPA_FOD_20221014.sqlite"

# Connect to the SQLite database using the defined path
con <- DBI::dbConnect(RSQLite::SQLite(), dbname = sqlite_file)

# Print out names of all tables in the dataset. We want to use the "Fires" table.
#DBI::dbListTables(con)

# Disconnect from the SQLite database (optional)
# dbDisconnect(con)


#----Reading in the Data----
# Define the path to your SQLite file
sqlite_file <- "/Users/hmingthanzama/Downloads/archive (1)/FPA_FOD_20221014.sqlite"

# Connect to the SQLite database using the defined path
con <- dbConnect(RSQLite::SQLite(), dbname = sqlite_file)

#Prints out names of all tables in the dataset. We want to use "Fires" table.
dbListTables(con)

# Disconnect from the SQLite database
#dbDisconnect(con)

# Query all rows from the "fires" table
fires <- dbGetQuery(con, "SELECT * FROM fires")

# View the first few rows of the "fires" table
#head(fires)
#str(fires)
#View(fires)

#Checking to verify whether or not data exists for each year. (1992-2020). Answer: Yes! It does.
table(fires$FIRE_YEAR)

#-----Checking for NA values------#

# Identify the "Shape" column as a blob column
blob_cols <- names(fires) %in% "Shape"

# Check for missing or NA values in each non-blob column
na_values <- sapply(fires[!blob_cols], function(x) sum(is.na(x) | x == ""))

# Print columns with NA values and their counts
for (col in names(na_values[na_values > 0])) {
  cat("Column:", col, "has", na_values[col], "NA values\n")
}

# Count the number of columns with NA values
#Returns 17. There are 17 columns with NA values.
num_cols_with_na <- sum(na_values > 0)
print(num_cols_with_na)


#----Graphs---
# Converting DISCOVERY_DATE to Date format
fires$DISCOVERY_DATE <- as.Date(fires$DISCOVERY_DATE, format = "%m/%d/%Y")

# Create a new column for month
fires$MONTH <- format(fires$DISCOVERY_DATE, "%m")

#Extract the year from DISCOVERY_DATE
fires$YEAR <- format(fires$DISCOVERY_DATE, "%Y")

#----Total Wildfires per State per Month----
# Convert MONTH to factor with month names as levels
fires$MONTH <- factor(monthly_incident_counts$MONTH, levels = unique(monthly_incident_counts$MONTH), labels = month.abb)

# Plot the data
ggplot(monthly_incident_counts, aes(x = MONTH, y = monthly_incident_count, fill = STATE)) +
  geom_bar(stat = "identity") +
  labs(title = "Total Count of Wildfires per State per Month",
       x = "Month",
       y = "Total Count",
       fill = "State") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
  scale_y_continuous(labels = comma_format())  # Format y-axis labels with commas


#-----Wildfires by year-----
fires %>% 
  group_by(FIRE_YEAR) %>%
  summarize(n_fires = n()) %>%
  ggplot(aes(x = FIRE_YEAR, y = n_fires/1000)) + 
  geom_bar(stat = 'identity', fill = 'black') +
  geom_smooth(method = 'lm', se = FALSE, linetype = 'dashed', linewidth = 0.4, color = 'red') + 
  geom_text(aes(label = FIRE_YEAR), angle = 90, hjust = -.2, size = 3, color = 'blue') +
  labs(x = '', y = 'Number of wildfires (thousands)', title = 'US Wildfires by Year')



#-----Wildfires by year per state-----
# Count the number of incidents per state per year
yearly_incident_counts <- fires %>%
  group_by(YEAR, STATE) %>%
  summarize(yearly_incident_count = n())

# Plot the data
ggplot(yearly_incident_counts, aes(x = YEAR, y = yearly_incident_count, fill = STATE)) +
  geom_bar(stat = "identity") +
  labs(title = "Number of Wildfire Incidents by State per Year",
       x = "Year",
       y = "Number of Incidents",
       fill = "State") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

#----Causes 1-----
# Create a dataframe with the counts of each cause
cause_counts <- table(fires$NWCG_CAUSE_CLASSIFICATION)
cause_data <- data.frame(cause = names(cause_counts), count = as.numeric(cause_counts))

# Create the bar plot
ggplot(cause_data, aes(x = cause, y = count)) +
  geom_bar(stat = "identity", fill = "black") +
  labs(title = "Wildfire Incidents by Cause",
       x = "Cause",
       y = "Number of Incidents") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for better readability

#---General Causes (looks more detailed)----
# Create a dataframe with the counts of each general cause
general_cause_counts <- table(fires$NWCG_GENERAL_CAUSE)
general_cause_data <- data.frame(cause = names(general_cause_counts), count = as.numeric(general_cause_counts))

# Create the bar plot
#ggplot(general_cause_data, aes(x = cause, y = count)) +
#  geom_bar(stat = "identity", fill = "black") +
#  labs(title = "Wildfire Incidents by General Cause",
#       x = "General Cause",
#       y = "Number of Incidents") +
#  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for better readability

# Generate 13 colors from the viridis palette
colors <- viridis(13)

# Create the bar plot with specified colors
ggplot(general_cause_data, aes(x = cause, y = count, fill = cause)) +
  geom_bar(stat = "identity") +
  labs(title = "Wildfire Incidents by General Cause",
       x = "General Cause",
       y = "Number of Incidents") +
  scale_fill_manual(values = colors) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + # Rotate x-axis labels for better readability
 scale_y_continuous(labels = comma_format()) 

#----Check to see if total count matches up.----
# Sum up the counts to get the total number of incidents
total_incidents <- sum(cause_counts)
total_incidents
#2303566

# Sum up the counts to get the total number of incidents
total_incidents2 <- sum(general_cause_counts)
total_incidents2
#2303566


#----Map of Wildfire per state per month--
# Create an sf object
fires_sf <- st_as_sf(fires, coords = c("LONGITUDE", "LATITUDE"), crs = 4326)

# Define filters
filters <- list(
  list(type = "select", item = "STATE", values = unique(fires$STATE)),
  list(type = "slider", item = "FIRE_YEAR", values = c(min(fires$FIRE_YEAR), max(fires$FIRE_YEAR)))
)

# Plot the points using mapview with filters
mapview(fires_sf, mapviewOptions = list(filters = filters))



#---Last 5 years. Causes graph----
# Assuming your dataframe is named 'fires'
fires_subset <- fires %>%
  filter(YEAR >= 2015 & YEAR <= 2020)

View(fires_subset)
# Create a dataframe with the counts of each general cause
general_cause_counts2 <- table(fires_subset$NWCG_GENERAL_CAUSE)
general_cause_data2 <- data.frame(cause = names(general_cause_counts2), count = as.numeric(general_cause_counts2))

# Generate 13 colors from the viridis palette
colors <- viridis(13)

# Create the bar plot with specified colors
ggplot(general_cause_data2, aes(x = cause, y = count, fill = cause)) +
  geom_bar(stat = "identity") +
  labs(title = "Wildfire Incidents by General Cause (2015-2020)",
       x = "General Cause",
       y = "Number of Incidents") +
  scale_fill_manual(values = colors) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + # Rotate x-axis labels for better readability
  scale_y_continuous(labels = comma_format()) 
