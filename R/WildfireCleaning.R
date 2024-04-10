rm(list = ls())
install.packages("RSQLite")
library(DBI)
library(RSQLite)
library(dplyr)
library(zoo)
library(readr)


#----Reading in the Data----
sqlite_file <- "data/web_data/wildfire_data/FPA_FOD_20221014.sqlite"
con <- dbConnect(RSQLite::SQLite(), dbname = sqlite_file)

# Query all rows from the "fires" table
fires <- dbGetQuery(con, "SELECT * FROM fires")


#----STATE Variable----
# Check for NA values in the state column. Returns 0. 
#STATE1_na <- sum(is.na(fires$STATE))
#cat("Number of NA values in the state column:", STATE1_na, "\n")

# Print unique values in the STATE column in alphabetical order
unique_states <- unique(fires$STATE)
unique_states_sorted <- sort(unique_states)
print(unique_states_sorted)

#Get count of unique values in the STATE column
#unique_state_count <- length(unique(fires$STATE))
#print(unique_state_count)

# Print abbreviations for all 50 states in 2 letter format in all caps then sort by alphabetical order.
state_abbreviations <- toupper(state.abb)
state_abbreviations_sorted <- sort(state_abbreviations)
print(state_abbreviations_sorted)

#I compared the outsides and noticed that my dataset contained US territories PR for Puerto Rico and
#DC for the District of Columbia. Moving forward, I will remove the PR and DC values from my dataset. 
#P.S. DC has had no historical wildfire incidents since records were recorded and PR is irrelevant for BHE.
# Remove rows with "PR" and "DC" in the STATE column from the fires dataset
fires <- fires %>%
  filter(STATE != "PR" & STATE != "DC")

#Here we are converting 2 letter abbreviated state names into their full state names (lowercased). Doing this so
#data can be merged easier with other datasets. Also renaming STATE to state for the same reason.
# Create a mapping table for state abbreviations to full names
state_map <- data.frame(
  abbrev = state.abb,
  full_name = tolower(state.name),
  stringsAsFactors = FALSE
)

# Merge mapping table with fires dataset to get full state names
fires <- merge(fires, state_map, by.x = "STATE", by.y = "abbrev", all.x = TRUE)

# Drop the original STATE column and rename the full_name column to state
fires <- fires %>%
  select(-STATE) %>%
  rename(state = full_name)


# Check for NA values in the state column. Returns 0!. It used to return 22k because of PR and DC values.
state_na <- sum(is.na(fires$state))
cat("Number of NA values in the state column:", state_na, "\n")

#View(fires)

#------DISCOVERY_DATE Variable-------
# In order to easily merge with other datasets, we will change date formats to "Jan-05" and then rename
# the variable to date.

# Convert DISCOVERY_DATE to character format
fires <- fires %>%
  mutate(DISCOVERY_DATE = as.character(as.Date(DISCOVERY_DATE, format = "%m/%d/%Y")))

# Format DISCOVERY_DATE as "Month-Year"
fires <- fires %>%
  mutate(DISCOVERY_DATE = format(as.Date(DISCOVERY_DATE), "%b-%y")) %>%
  rename(date = DISCOVERY_DATE)

# Check for NA values in the date column
date_na <- sum(is.na(fires$date))

# Print the number of NA values in each column. Returns 0!.
cat("Number of NA values in the date column:", date_na, "\n")

# Check the structure of the updated dataset
#View(fires)

# Group by month, year, and state, and calculate the total incidents
wildfires_group <- fires %>%
  group_by(date, state) %>%
  summarize(sum_wildfires = n())

#View(fires)

View(wildfires_group)

# Export sum_wildfires as a CSV file
write.csv(wildfires_group, "data/cleaned_data/WildfiresClean.csv", row.names = FALSE)

# Disconnect from the SQLite database
#dbDisconnect(con)