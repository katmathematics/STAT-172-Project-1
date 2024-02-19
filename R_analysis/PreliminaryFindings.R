#install.packages("ggplot2")
library(ggplot2) # For visualizing data

BPA_CSI_DATA = read.csv("data/compressed_raw_data/CustomerServiceInterruptions.csv")

ggplot(data=BPA_CSI_DATA, aes(x=Cause)) +
  geom_bar() +
  geom_text(stat='count', aes(label=..count..), vjust=-1)
