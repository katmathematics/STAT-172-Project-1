#install.packages("ggplot2")
library(ggplot2) # For visualizing data
library(dplyr) # Clean Data

setwd("Github/STAT-190-Project-1")

# Read in Data
BPA_CSI = read.csv("data/compressed_raw_data/CustomerServiceInterruptions.csv")

nrow(BPA_CSI)
# Check how many causes there are in the dataset
unique(BPA_CSI["Cause"])

### Clean Cause values to condense down the data ###

# Trees
BPA_CSI$Cause[BPA_CSI$Cause == "Tree blown"] <- "Tree Blown"
BPA_CSI$Cause[BPA_CSI$Cause == "Tree cut"] <- "Tree Cut"
BPA_CSI$Cause[BPA_CSI$Cause == "Tree growth"] <- "Tree"
BPA_CSI$Cause[BPA_CSI$Cause == "Tree Cut"] <- "Tree"
BPA_CSI$Cause[BPA_CSI$Cause == "Tree Blown"] <- "Tree"

# Foreign? Not sure if its reasonable to group these together
BPA_CSI$Cause[BPA_CSI$Cause == "Foreign Request"] <- "Foreign Trouble"
BPA_CSI$Cause[BPA_CSI$Cause == "Foreign Utility"] <- "Foreign Trouble"
BPA_CSI$Cause[BPA_CSI$Cause == "Foreign Object"] <- "Foreign Trouble"

# Similar Things
BPA_CSI$Cause[BPA_CSI$Cause == "Emergency"] <- "Urgent"
BPA_CSI$Cause[BPA_CSI$Cause == "Earth slide"] <- "Landslide"
BPA_CSI$Cause[BPA_CSI$Cause == "Bird droppings"] <- "Bird or Animal"
BPA_CSI$Cause[BPA_CSI$Cause == "Smoke"] <- "Fire"
BPA_CSI$Cause[BPA_CSI$Cause == "Not Reported"] <- "Unknown"
BPA_CSI$Cause[BPA_CSI$Cause == "Machinery, Farming"] <- "Agriculture"
BPA_CSI$Cause[BPA_CSI$Cause == "Agricultural"] <- "Agriculture"
BPA_CSI$Cause[BPA_CSI$Cause == "Machinery, Construction"] <- "Construction"

# These all sound like unplanned equipment failures
BPA_CSI$Cause[BPA_CSI$Cause == "Terminal Equipment Failure"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Line or Bank charging"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Improper Relaying"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Arc while switching"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Overload"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Out of step"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Voltage"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Galloping Conductors"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Frequency"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Power System Condition"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Line Material Failure"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Load Control"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Equipment/Miscellaneous"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "TT Noise"] <- "Equipment Failure"
BPA_CSI$Cause[BPA_CSI$Cause == "Voltage Control"] <- "Equipment Failure"



# Drop rows that weren't damages (i.e. scheduled maintenance and tests)
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Staged Test"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Maintenance"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Substation Operations"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Maintenance - TOp"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Testing"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "RAS Initiated"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Forced"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Forced (Configuration)"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "PCS Cellular Work"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Fiber Optic Work"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Switching"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Oper Plan/RTCA Reqd Action"),]
BPA_CSI = BPA_CSI[!(BPA_CSI$Cause %in% "Imp Install/Design/Applica"),]
# Do we think "Normally Out" falls under this?

# Check how many causes there are in the dataset
unique(BPA_CSI["Cause"])


# Remove infrequently occuring causes
BPA_CSI_FREQ <- BPA_CSI %>%
  group_by(Cause) %>%
  filter(n() >= 750)

# Display the most common causes of failure
ggplot(data=BPA_CSI_FREQ, aes(x=Cause)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1) + 
  theme(axis.text.x = element_text(angle = 45, hjust=1)) + 
  labs(title = "Commonly Occuring Failure Causes")



# Get only uncommonly occurring problems
BPA_CSI_UNC <- BPA_CSI %>%
  group_by(Cause) %>%
  filter(n() >= 100) %>%
  filter(n() < 750)

# Display the most common causes of failure
ggplot(data=BPA_CSI_UNC, aes(x=Cause)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1) + 
  theme(axis.text.x = element_text(angle = 45, hjust=1)) +
  labs(title = "Uncommonly Occuring Failure Causes")
