# This script subsets the prepared citibike data to a more useful dataset

## Notes
# Recall that at some point business rule changed to cap trip duration at 2 hours

## 1. Examine trip duration in more detail
summary(data_citibike_ready$tripduration)

# Up to 3rd Quartile is reasonable otherwise crazily skewed (different data gen process!)
# For this exercise, throw away everything shorter than 2 hours
tripduration_cap <- 2*60*60
data_citibike_analysis <- data_citibike_ready[data_citibike_ready$tripduration < tripduration_cap,]

# Only lose 0.4% observations
(length(data_citibike_ready$tripduration) - length(data_citibike_analysis$tripduration))/length(data_citibike_ready$tripduration) * 100

# Distribution now looks more reasonable
plot(density(data_citibike_analysis$tripduration))

# Also drop Jan 2016 data as too little of it
data_citibike_analysis <- data_citibike_analysis[as.Date(data_citibike_analysis$starttime) < as.Date("2016-01-01"),]

## 2. How many short trips start and end at same station?
data_citibike_analysis <- data_citibike_analysis %>%
                            mutate(same_start_end_station = as.factor(
                              ifelse(`start station id` == `end station id`,
                                     "Same", "Different")))

summary(data_citibike_analysis$same_start_end_station) # Not too big a problem, ~2% of trips
# Different      Same 
# 22422310    540687 

# Distribution of tripduration not markedly different for these trips, fine to leave them in
plot(density(data_citibike_analysis$tripduration[data_citibike_analysis$same_start_end_station == "Same"]))

## 3. What's the distribution of trips by station?
data_citibike_analysis$count <- 1

trips_by_station_start <- data_citibike_analysis %>%
                            group_by(`start station id`, `start station name`,
                                     `start station latitude`, 
                                     `start station longitude`) %>%
                              summarise(total_trips = sum(count)) %>%
                            ungroup() %>% arrange(-total_trips)

trips_by_station_end <- data_citibike_analysis %>%
                          group_by(`end station id`, `end station name`,
                                   `end station latitude`, 
                                   `end station longitude`) %>%
                            summarise(total_trips = sum(count)) %>%
                          ungroup() %>% arrange(-total_trips)

# Pretty similar distributions
plot(density(trips_by_station_start$total_trips))
plot(density(trips_by_station_end$total_trips))

## 4. What does a time series for a station look like?
data_citibike_analysis$year_month <- as.yearmon(data_citibike_analysis$starttime)
data_citibike_analysis$start_date <- as.Date(data_citibike_analysis$starttime)
data_citibike_analysis$stop_date <- as.Date(data_citibike_analysis$stoptime)
data_citibike_analysis$multi_day_trip <- ifelse(data_citibike_analysis$start_date !=
                                                data_citibike_analysis$stop_date, 1, 0)
summary(data_citibike_analysis$multi_day_trip) # Shows 1.3% of trips cross midnight

trips_by_station_start_monthly <- data_citibike_analysis %>%
                                    group_by(`start station id`, year_month) %>%
                                    summarise(total_trips = sum(count))

# 156 of 488 stations have six or fewer months of data, a reasonable change-set
trips_by_station_month_coverage <- trips_by_station_start_monthly %>%
                                    group_by(`start station id`) %>%
                                    tally() %>% ungroup() %>% arrange(n)

