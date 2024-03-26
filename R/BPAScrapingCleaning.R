# Author(s) (ordered by contribution): Hming Zama, Katja Mathesius

# Install packages if not installed, then load packages
packages <- c("rvest", "dplyr")
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))


### Pull data from 1999 to 2024
start_year <- 1999
end_year <- 2024

CustomerServiceInterruptions <- list()
TransmissionLineInterruptions <- list()
TransformerInterruptions <- list()

#Loop through the years and scrape data
for (year in start_year:end_year) {
  print(year)
  url <- paste0("https://transmission.bpa.gov/Business/Operations/Outages/OutagesCY", year, ".htm")
  outage_data <- read_html(url) %>%
    html_table()
  
  Sys.sleep(2)
  
  print(paste("Scraping data for year:", year))
  
  i <- length(CustomerServiceInterruptions) + 1
  
  if (length(outage_data) >= 3) {
    CustomerServiceInterruptions[[i]] <- outage_data[[1]]
    TransmissionLineInterruptions[[i]] <- outage_data[[2]]
    TransformerInterruptions[[i]] <- outage_data[[3]]
  }
  
  else if (length (outage_data) == 2) {
  CustomerServiceInterruptions[[i]] <- outage_data[[1]]
  TransmissionLineInterruptions[[i]] <- outage_data[[2]]
  message(paste("No data found for TransformerInterruptions", year))
  }
  else {
  CustomerServiceInterruptions[[i]] <- outage_data[[1]]
  message(paste("No data found for TransmissionLineInterruptions and  TransformerInterruptions", year))
  }
}


#Putting all years into one data frame
CustomerServiceInterruptionsFinal <- data.table::rbindlist(CustomerServiceInterruptions, fill=TRUE)

#TransmissionLineInterruptionsFinal <- data.table::rbindlist(TransmissionLineInterruptions, fill=TRUE)

#TransformerInterruptionsFinal <- data.table::rbindlist(TransformerInterruptions, fill=TRUE)

#To check how redundancy of values inside of "Dispatcher Cause" and "Field Cause" for years 1999-2013 
#and of "DispatcherCause" and "FieldCause" for years 2014-2015.

# Initialize a counter
matching_count <- 0

# Loop through lists 1 to 17
for (i in 1:17) {
  # Get the data frame
  df <- CustomerServiceInterruptions[[i]]
  
  # Check for matching values in X7 and X8
  matching_count <- matching_count + sum(df$X7 == df$X8, na.rm = TRUE)
}

# Print the total count of matching values
print(matching_count) 
#Result is 7475.

#Finding sum of rows from 1999-2015
# Initialize a variable to store the total sum
total_sum <- 0

# Loop through lists 1 to 17
for (i in 1:17) {
  # Get the data frame
  df <- CustomerServiceInterruptions[[i]]
  
  # Calculate the sum of rows and add it to the total sum
  total_sum <- total_sum + nrow(df)
}

# Print the total sum
print(total_sum)
#Result is 26170

# 7475/26170 = 0.2856324 or 28.5%.


#Do the same analysis for "ResponsibleSystemDispatch" and "ResponsibleSystemField" in years 2014-2015.
# Initialize a counter
matching_count <- 0

# Loop through lists 16 to 17
for (i in 16:17) {
  # Get the data frame
  df <- CustomerServiceInterruptions[[i]]
  
  # Check for matching values in X9 and X10
  matching_count <- matching_count + sum(df$X9 == df$X10, na.rm = TRUE)
}

# Print the total count of matching values
print(matching_count)
#Result is 409

#Finding sum of rows from 2014-2015
# Initialize a variable to store the total sum
total_sum <- 0

# Loop through lists 1 to 17
for (i in 16:17) {
  # Get the data frame
  df <- CustomerServiceInterruptions[[i]]
  
  # Calculate the sum of rows and add it to the total sum
  total_sum <- total_sum + nrow(df)
}

# Print the total sum
print(total_sum)
#Result is 2787
#409/2787 = 0.1467528 or 14.6%.


#Overwrites values in "Dispatcher Cause" with values in "Field Cause" for 1999-2013. 
#Overwrites values in "CauseDispatch" with values in "CauseField" for 2014-2015
for (i in 1:17) {
  # Check if X8 is not empty
  idx <- !is.na(CustomerServiceInterruptions[[i]]$X8) & CustomerServiceInterruptions[[i]]$X8 != ""
  
  # Update X7 with X8 where X8 is not empty
  CustomerServiceInterruptions[[i]]$X7[idx] <- CustomerServiceInterruptions[[i]]$X8[idx]
  
  # Remove the X8 column
  CustomerServiceInterruptions[[i]] <- subset(CustomerServiceInterruptions[[i]], select = -X8)
}

#Overwrites values in "ResponsibleSystemDispatch" with values in "ResponsibleSystemField" for 2014-2015. 
for (i in 16:17) {
  # Check if X10 is not empty
  idx <- !is.na(CustomerServiceInterruptions[[i]]$X10) & CustomerServiceInterruptions[[i]]$X10 != ""
  
  # Update X9 with X10 where X10 is not empty
  CustomerServiceInterruptions[[i]]$X9[idx] <- CustomerServiceInterruptions[[i]]$X10[idx]
  
  # Remove the X10 column
  CustomerServiceInterruptions[[i]] <- subset(CustomerServiceInterruptions[[i]], select = -X10)
}

#Renames colnames from "X" series to ones in dataset.
new_column_names <- c(
  "Out Datetime", "In Datetime", "Name", "Voltage(kV)", "Duration(minutes)", 
  "OutageType", "Cause", "ResponsibleSystem", "MW Intrpt", "O&MDistrict", "OutageID"
)

for (i in 1:26) {
  # Rename the columns
  colnames(CustomerServiceInterruptions[[i]]) <- new_column_names
}

#Putting all years into one data frame
CustomerServiceInterruptionsFinal <- data.table::rbindlist(CustomerServiceInterruptions, fill=TRUE)

write.csv(CustomerServiceInterruptionsFinal, "data/compressed_raw_data/CustomerServiceInterruptions.csv", row.names=FALSE)

#Creates csv files of updated dataset.
#install.packages("writexl")
#library(writexl)

#for (i in 1:26) {
#  write_xlsx(CustomerServiceInterruptions[[i]], path = paste0("output_", i, ".xlsx"))
#}
