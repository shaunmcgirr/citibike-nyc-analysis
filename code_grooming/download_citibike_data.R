# This script downloads the data from https://www.citibikenyc.com/system-data

## Notes
# Methodology for daily ridership and membership data changed "recently", from reporting trips more than 5 seconds but less than 6 hours, to more than 1 minute and capped at 2 hours.


# 1. Scrape links to zipped CSVs (notice they are in an S3 bucket, more stable endpoint than web page)
# url <- "https://www.citibikenyc.com/system-data"
s3_url <- "https://s3.amazonaws.com/tripdata/"
s3_got <- GET(s3_url)
s3_content <- content(s3_got, type = "text/xml")

xml_fields <- xmlToDataFrame(s3_content)
links_to_process <- as.list(paste0(s3_url, (xml_fields$Key)[grep("\\.zip", xml_fields$Key)]))
links_to_process <- Filter((function(x) (!x %in% 
     c("https://s3.amazonaws.com/tripdata/201307-201402-citibike-tripdata.zip"))), links_to_process)
  # Exclude this file as it contains others that will be downloaded separately

# 2. Download and unzip to the data_raw folder, using a function applied to the list above
download_unzip_file <- function(link){
  print(paste0("Downloading and unzipping ", link))
  temp <- tempfile()
  download(as.character(link), temp)
  unzip(temp, overwrite = F, exdir = "data_raw/system-data")
}

lapply(links_to_process, download_unzip_file)


## Other interesting data to consider downloading
# Historical station status data (supply/demand mapping) http://www.theopenbus.com/
# Yellow Taxi Trip Data https://nycopendata.socrata.com/view/gn7m-em8n
# Bicycle traffic counts https://data.cityofnewyork.us/Transportation/Bike-Counts/sf3b-xntp
# Derelict bicycle reports https://data.cityofnewyork.us/Social-Services/derelict-bikes/4ne5-22ne
# Manhattan bike injuries https://data.cityofnewyork.us/Public-Safety/manhattan_bike-injury/tisn-ga4h
# NYPD Motor Vehicle Collisions https://data.cityofnewyork.us/Public-Safety/NYPD-Motor-Vehicle-Collisions/h9gi-nx95
# Report on relationship with subway system http://wagner.nyu.edu/rudincenter/publication/citi-bike-takes-new-york-2/

