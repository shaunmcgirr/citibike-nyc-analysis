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
# head(data_citibike_raw)

# Do the date columns all have the same number of characters?
date_width <- nchar(data_citibike_raw$starttime)
  unique(date_width) # No! 13-19 characters...so they've changed date format along the way!

# All dates <19 characters seem to have similar formats, variation due to no leading zeroes
short_dates_13 <- data_citibike_raw$starttime[date_width == 13]
  head(short_dates_13) # From 2015 onwards, no seconds
short_dates_14 <- data_citibike_raw$starttime[date_width == 14]
  head(short_dates_14) # From 2015 onwards, no seconds
short_dates_15 <- data_citibike_raw$starttime[date_width == 15]
  head(short_dates_15) # In 2014, changed to US-format dates
short_dates_17 <- data_citibike_raw$starttime[date_width == 17]
  head(short_dates_17)
short_dates_18 <- data_citibike_raw$starttime[date_width == 18]
  head(short_dates_18)

# Now create a 'ready' dataset applying lessons learned above
data_citibike_ready <- data_citibike_raw

data_citibike_ready$starttime <- parse_date_time(data_citibike_ready$starttime,
                                                 orders = c("Y m d H M S", 
                                                            "m d Y H M S",
                                                            "m d Y H M"),
                                                 tz = "America/New_York")
data_citibike_ready$stoptime <- parse_date_time(data_citibike_ready$stoptime,
                                                orders = c("Y m d H M S", 
                                                           "m d Y H M S",
                                                           "m d Y H M"),
                                                tz = "America/New_York")
data_citibike_ready$usertype <- as.factor(data_citibike_ready$usertype)
data_citibike_ready$`birth year` <- as.integer(ifelse(data_citibike_ready$`birth year`
                                                      %in% c("\\N", ""), NA,
                                                      data_citibike_ready$`birth year`))
data_citibike_ready$gender <- as.factor(ifelse(data_citibike_ready$gender == 0 , NA,
                                        ifelse(data_citibike_ready$gender == 1, "Male",
                                        ifelse(data_citibike_ready$gender == 2, "Female",
                                                                                "Error"))))

rm(data_citibike_raw); gc()
save(data_citibike_ready, file = "data_intermediate/data_citibike_ready.rda")


###### BATCHED VERSION OF READING IN CSVs (if memory problems)
## Batch up the reading just to be safe
# batch_size <- 5
# number_of_batches <- ceiling(files_list_length/batch_size)
# batch_number <- gl(number_of_batches, batch_size, length = files_list_length)
# batch_list <- split(files_list, batch_number)

## Read in using new(ish) readr package and save an intermediate .rda file
# for(b in 1:number_of_batches){
#   files_to_process <- batch_list[[b]]
#   data_int <- files_to_process %>%
#     lapply(read_csv, col_types = "iccicddicddicci") %>%
#     bind_rows
#   #df_name <- paste0("data_int_", b)
#   file_name <- paste0("data_intermediate/data_int_", b, ".rda")
#   #eval(parse(text = paste0(df_name, "<-data_int")))
#   save(data_int, file = file_name)
#   rm(data_int)
#   gc()
# }
