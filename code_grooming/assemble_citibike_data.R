# This script assembles the CSVs downloaded and unzipped in to a useable structure

## Notes
# 

# 1. Make a list of the CSV files and load them all in to a data frame
files_list <- as.list(list.files(path = "data_raw/system-data/", pattern = "\\.csv", full.names = TRUE))

files_list <- files_list[1:5]

# Trusty read.csv chews up memory pretty quickly
# data_citibike_raw <- do.call("rbind", lapply(files_list, read.csv, stringsAsFactors = FALSE))

# Trying out the new(ish) readr package, still memory-intensive
data_citibike_raw <- files_list %>%
                      lapply(read_csv, col_types = "iccicddicddicci") %>%
                      bind_rows


# 2. Treat each column for data quality and convert to more useful types

