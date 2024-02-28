# Author(s) (ordered by contribution): Katja Mathesius
library(tidyverse)

setwd("Github/STAT-190-Project-1/data/web_data/eia_data/interchange")

files <- list.files(pattern = "\\.csv$")

DF <-  read.csv(files[1])
DF %>% select(order(colnames(DF)))
DF[DF == ""] <- NA 

print(unique(DF$Region))

# Maybe we should try compressing the data by month and then writing to the file
#reading each file within the range and append them to create one file
for (f in files[-1]){
  #print(f)
  df <- read.csv(f)      # read the file
  #print(unique(df$Region))
  df %>% select(order(colnames(df)))
  df[df == ""] <- NA 
  DF <- rbind(DF, df)    # append the current file
  #print(unique(DF$Region))
}

#writing the appended file  
write.csv(DF, "../../../compressed_raw_data/EIAInterchange.csv", row.names=FALSE, quote=FALSE)
