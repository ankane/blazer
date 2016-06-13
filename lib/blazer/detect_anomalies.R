library(AnomalyDetection)

args <- commandArgs(trailingOnly = TRUE)

con <- textConnection(args[1])
data <- read.csv(con, stringsAsFactors = FALSE)
data$timestamp <- as.POSIXct(data$timestamp)

res = AnomalyDetectionTs(data, direction = "both", alpha = 0.05)
write.csv(res$anoms)
