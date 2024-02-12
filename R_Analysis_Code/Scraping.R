rm(list = ls())

library(rvest)
library(dplyr)

# Definie a funct to scrape data for given year

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

# Combine all years into data frames
#CustomerServiceInterruptionsFinal <- bind_rows(lapply(CustomerServiceInterruptions, function(x) {
#  cols <- max(sapply(CustomerServiceInterruptions, function(y) ncol(y)))
#  if (ncol(x) < cols) {
#    x <- cbind(x, matrix("", nrow = nrow(x), ncol = cols - ncol(x)))
#  }
#  return(x)
#}))

#TransmissionLineInterruptionsFinal <- bind_rows(lapply(TransmissionLineInterruptions, function(x) {
#  cols <- max(sapply(TransmissionLineInterruptions, function(y) ncol(y)))
#  if (ncol(x) < cols) {
#    x <- cbind(x, matrix("", nrow = nrow(x), ncol = cols - ncol(x)))
#  }
#  return(x)
#}))

#TransformerInterruptionsFinal <- bind_rows(lapply(TransformerInterruptions, function(x) {
#  cols <- max(sapply(TransformerInterruptions, function(y) ncol(y)))
#  if (ncol(x) < cols) {
#    x <- cbind(x, matrix("", nrow = nrow(x), ncol = cols - ncol(x)))
#  }
#  return(x)
#}))

#Putting all years into one data frame
#CustomerServiceInterruptionsFinal <- data.table::rbindlist(CustomerServiceInterruptions, fill=TRUE)

#TransmissionLineInterruptionsFinal <- data.table::rbindlist(TransmissionLineInterruptions, fill=TRUE)

#TransformerInterruptionsFinal <- data.table::rbindlist(TransformerInterruptions, fill=TRUE)



# Set column names for all data frames

# Assuming CustomerServiceInterruptionsFinal is your dataframe
#CustomerServiceInterruptionsFinal <- subset(CustomerServiceInterruptionsFinal, select = 1:(ncol(CustomerServiceInterruptionsFinal) - 1))

#colnames(CustomerServiceInterruptionsFinal) <- c("Out Datetime", "In Datetime", "Name", "Voltage(kV)", "Duration(minutes)", "OutageType", "Dispatcher Cause", "Field Cause", "System In Control", "MW Intrpt", "District", "OutageID")  # Adjust column names accordingly
#colnames(TransmissionLineInterruptionsFinal) <- c("Out Datetime", "In Datetime", "Name", "Voltage(kV)", "GenFlag", "Length(miles)", "Duration(minutes", "OutageType", "Cause", "ResponsibleSystem", "O&MDistrict", "TransmissionOwnerNERC TADS", "OutageID")  # Adjust column names accordingly
#colnames(TransformerInterruptionsFinal) <- c("Out Datetime", "In Datetime", "Name", "VoltageHigh (kV)", "VoltageLow (kV)", "Duration(minutes)", "OutageType", "Cause", "ResponsibleSystem", "O&MDistrict", "TransmissionOwnerNERC TADS", "OutageID")  # Adjust column names accordingly


# Determine the number of columns in CustomerServiceInterruptionsFinal
#num_columns <- ncol(CustomerServiceInterruptionsFinal)

# Check the number of columns you're trying to assign
#num_column_names <- length(c("Out Datetime", "In Datetime", "Name", "Voltage(kV)", "Duration(minutes)", "OutageType", "Dispatcher Cause", "Field Cause", "System In Control", "MW Intrpt", "District", "OutageID"))

# Compare the numbers
#if (num_columns == num_column_names) {
  # Assign column names
  #colnames(CustomerServiceInterruptionsFinal) <- c("Out Datetime", "In Datetime", "Name", "Voltage(kV)", "Duration(minutes)", "OutageType", "Dispatcher Cause", "Field Cause", "System In Control", "MW Intrpt", "District", "OutageID")
#} else {
  # Print an error message
 # message("Number of column names does not match the number of columns in the data table.")
#}
