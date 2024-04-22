# Author(s) (ordered by contribution): Katja Mathesius
install.packages("xts")
# Install packages if not installed, then load packages
packages <- c("ggplot2", "dplyr", "xts")
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}
invisible(lapply(packages, library, character.only = TRUE))

# Read in Data
BPA_CSI = read.csv("data/compressed_raw_data/CustomerServiceInterruptions.csv")

# See how many rows are in the BPA Customer Service Data
nrow(BPA_CSI)

# Consider removing any rows where the outage was planned
BPA_CSI = BPA_CSI[!(BPA_CSI$OutageType %in% "Plan"),]

# Remove strings from Duration.minutes
BPA_CSI = BPA_CSI[!(BPA_CSI$Duration.minutes. %in% "still out"),]
BPA_CSI$Duration.minutes. = as.numeric(as.character(BPA_CSI$Duration.minutes.)) 

# Rename O&M District and remove rows where O&M District is blank
colnames(BPA_CSI)[names(BPA_CSI) == "O&MDistrict"] <- "OMDistrcit"
BPA_CSI = BPA_CSI[!(BPA_CSI$O.MDistrict %in% ""),]

# Add a column relating to outage length
BPA_CSI$DurationType <- cut(BPA_CSI$Duration.minutes., c(-1, 60, 1440, Inf), 
                            labels = c('Hour', 'Day', 'Multiday'))
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
ggplot(data=BPA_CSI_FREQ, aes(x=Cause, fill = DurationType)) +
  geom_bar() +
  #geom_text(stat='count', aes(label=..count..), vjust=-1) + # Turns on labels for each bar
  theme(axis.text.x = element_text(angle = 90, hjust=1)) + 
  labs(title = "Commonly Occuring Failure Causes") #+
  #facet_wrap(~O.MDistrict, ncol = 3)


# Get only uncommonly occurring problems
BPA_CSI_UNC <- BPA_CSI %>%
  group_by(Cause) %>%
  filter(n() >= 100) %>%
  filter(n() < 750)


# Display the most common causes of failure
ggplot(data=BPA_CSI_UNC, aes(x=Cause, fill = DurationType)) +
  geom_bar() +
  #geom_text(stat='count', aes(label=..count..), vjust=-1) + 
  theme(axis.text.x = element_text(angle = 90, hjust=1)) +
  labs(title = "Uncommonly Occuring Failure Causes") #+ 
  #facet_wrap(~O.MDistrict, ncol = 3)

# Look only at outages lasting more than an hour
BPA_CSI_SRS = BPA_CSI[!(BPA_CSI$DurationType %in% "Hour"),]

# Remove infrequently occuring causes
BPA_CSI_FREQ_SRS <- BPA_CSI_SRS %>%
  group_by(Cause) %>%
  filter(n() >= 500)

# Display the most common causes of failure
ggplot(data=BPA_CSI_FREQ_SRS, aes(x=Cause, fill = DurationType)) +
  geom_bar() +
  #geom_text(stat='count', aes(label=..count..), vjust=-1) + # Turns on labels for each bar
  theme(axis.text.x = element_text(angle = 90, hjust=1)) + 
  labs(title = "Commonly Occuring Failure Causes") +
  facet_wrap(~O.MDistrict, ncol = 3)


# Get only uncommonly occurring problems
BPA_CSI_UNC_SRS <- BPA_CSI_SRS %>%
  group_by(Cause) %>%
  filter(n() >= 50) %>%
  filter(n() < 500)


# Display the uncommon causes of failure
ggplot(data=BPA_CSI_UNC_SRS, aes(x=Cause, fill = DurationType)) +
  geom_bar() +
  #geom_text(stat='count', aes(label=..count..), vjust=-1) + 
  theme(axis.text.x = element_text(angle = 90, hjust=1)) +
  labs(title = "Uncommonly Occuring Failure Causes") #+ 
  #facet_wrap(~O.MDistrict, ncol = 3)

ggsave("data_visualizations/BPA_visualizations/Uncommon_Severe_Failures_Visual.png")
1