# This script assembles the CSVs downloaded and unzipped in to a useable structure

## Notes
# 

## 1. Make a list of the CSV files and load them all in to a data frame
files_list <- as.list(list.files(path = "data_raw/system-data/", pattern = "\\.csv", full.names = TRUE))
  files_list_length <- length(files_list)

# Trusty read.csv chews up memory pretty quickly
# data_citibike_raw <- do.call("rbind", lapply(files_list, read.csv, stringsAsFactors = FALSE))

# Read in using new(ish) readr package
# (needs about 7-8GB of RAM, see end of file for batched approach using .rda files)
data_citibike_raw <- files_list %>%
                      lapply(read_csv, col_types = "iccicddicddicci") %>%
                      bind_rows

# How many rows?
dim(data_citibike_raw) # 23,056,370 trips matches other published studies

# Save an rda file just in case
save(data_citibike_raw, file = "data_intermediate/data_citibike_raw.rda")  

## 2. Treat each column for data quality and convert to more useful types
# load(file = "data_intermediate/data_citibike_raw.rda")



## BATCHED VERSION OF READING IN CSVs
# Batch up the reading just to be safe
batch_size <- 5
number_of_batches <- ceiling(files_list_length/batch_size)
batch_number <- gl(number_of_batches, batch_size, length = files_list_length)
batch_list <- split(files_list, batch_number)

# Read in using new(ish) readr package and save an intermediate .rda file
for(b in 1:number_of_batches){
  files_to_process <- batch_list[[b]]
  data_int <- files_to_process %>%
    lapply(read_csv, col_types = "iccicddicddicci") %>%
    bind_rows
  #df_name <- paste0("data_int_", b)
  file_name <- paste0("data_intermediate/data_int_", b, ".rda")
  #eval(parse(text = paste0(df_name, "<-data_int")))
  save(data_int, file = file_name)
  rm(data_int)
  gc()
}
