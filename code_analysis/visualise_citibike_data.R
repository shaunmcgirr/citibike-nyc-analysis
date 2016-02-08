# This script maps stations experiencing a surplus vs a deficit of bikes

## Notes
# Goal is to make system operator's business decision about moving bikes easier

## 1. Decide a period of analysis and use it to reshape the data

# Start with day
trips_started_by_station <- data_citibike_analysis %>%
                              filter(multi_day_trip == 0) %>% # Exclude trips crossing midnight
                              group_by(`start station id`,
                                       `start station latitude`,
                                       `start station longitude`,
                                       start_date) %>%
                              summarise(trips_started = sum(count)) %>%
                              rename(station_id = `start station id`,
                                     station_lat = `start station latitude`,
                                     station_lon = `start station longitude`,
                                     date =  start_date)

trips_ended_by_station <- data_citibike_analysis %>%
                              filter(multi_day_trip == 0) %>% # Exclude trips crossing midnight
                              group_by(`end station id`,
                                       `end station latitude`,
                                       `end station longitude`,
                                       stop_date) %>%
                              summarise(trips_ended = sum(count)) %>%
                              rename(station_id = `end station id`,
                                station_lat = `end station latitude`,
                                station_lon = `end station longitude`,
                                date =  stop_date)

# Join to create trips started/ended dataset
trips_started_ended_by_station <- trips_started_by_station %>%
                                    inner_join(trips_ended_by_station) %>% # Left join useless
                                    mutate(surplus = as.factor(ifelse(
                                      trips_started >= trips_ended, "surplus_starts", 
                                      "surplus_ends")),
                                      magnitude = trips_started-trips_ended,
                                      proportion = trips_started/trips_ended)
                                    

# Set a threshold parameter for "out of whack" trip starts vs ends
threshold_proportion <- 2 # Identifies days with twice as many starts as ends and v-v
threshold_magnitude <- 5 # Identifies days with five or more bikes surplus/deficit

# Filter on magnitude because main business cost will be number of bikes shifted
stations_with_problems <- trips_started_ended_by_station %>%
                            filter((magnitude >= threshold_magnitude) |
                                   (magnitude <= -threshold_magnitude)) %>%
                            group_by(station_id, station_lat, station_lon, surplus) %>%
                              summarise(days_with_problem = n()) %>% ungroup() %>%
                            spread(key = surplus, value = days_with_problem) %>%
                            rename(days_with_surplus_starts = surplus_starts,
                                   days_with_surplus_ends = surplus_ends) %>%
                            mutate(days_with_problem = days_with_surplus_starts + days_with_surplus_ends,
                                   imbalance_in_days = days_with_surplus_starts - days_with_surplus_ends) %>% # Positive number means more days with risk of no bikes
                            arrange(-abs(imbalance_in_days))

# Output a histogram for the report
stations_with_problems_hist <- ggplot(stations_with_problems, aes(days_with_problem)) +
                                  geom_histogram(bins = 20) +
                                  ggtitle("Distribution of problematic days\n (5 or more trips surplus/deficit)\n") +
                                  labs(x = "\nNumber of problematic days at the station",
                                       y = "Count of stations\n")
print(stations_with_problems_hist)
ggsave("figures/stations_with_problems_hist.pdf")

# How many trips per month across whole dataset?
trips_per_month <- data_citibike_analysis %>%
                    group_by(year_month) %>%
                    summarise(total_trips = n())

# How are problematic days distributed across the year?
problematic_days_per_month <- trips_started_ended_by_station %>%
                                mutate(year_month = as.yearmon(date)) %>%
                                filter((magnitude >= threshold_magnitude) |
                                       (magnitude <= -threshold_magnitude)) %>%
                                group_by(year_month) %>%
                                  summarise(total_problematic_station_days = n())

# Re-do the histogram separating out Jan/Feb from rest of months?
# Looking at the past few winters, expecting less of a drop in problematic days
# Could also redo by surplus_start vs surplus_end


## 2. Build decision support tools

# Map of top-100 most problematic stations, for all time
stations_with_problems_top_100 <- stations_with_problems[1:100,] %>%
                                    rename(Imbalance = imbalance_in_days)

map_base_layer <- qmplot(station_lon, station_lat, data=stations_with_problems_top_100,
                      source = "stamen")

map_top_100 <- map_base_layer +
                geom_point(data = stations_with_problems_top_100, 
                           aes(x = station_lon, y = station_lat, 
                               color = Imbalance), size=3) +
                scale_colour_gradient2(low = "blue", mid = "purple", high = "red") +
                ggtitle("\n100 most imbalanced stations Jul 2013-Dec 2015\n (days with surplus starts - days with surplus ends)\n")

print(map_top_100)
ggsave("figures/map_top_100.pdf", scale = 2)


# Map of stations with fastest-growing problems in 2015
stations_with_problems_growth <- trips_started_ended_by_station %>%
                                 filter((magnitude >= threshold_magnitude) |
                                        (magnitude <= -threshold_magnitude)) %>%
                                 mutate(year_month = as.yearmon(date)) %>%
                                 group_by(station_id, station_lat, station_lon,
                                          year_month, surplus) %>%
                                   summarise(days_with_problem = n()) %>% ungroup() %>%
                                 spread(key = surplus, value = days_with_problem) %>%
                                 rename(days_with_surplus_starts = surplus_starts,
                                        days_with_surplus_ends = surplus_ends) %>%
                                 mutate(days_with_problem = days_with_surplus_starts + days_with_surplus_ends,
                                        imbalance_in_days = days_with_surplus_starts - days_with_surplus_ends) %>% # Positive number means more days with risk of no bikes
                                 group_by(station_id) %>%
                                    mutate(change = abs(imbalance_in_days) - lag(abs(imbalance_in_days)), absolute_change = abs(change), year = year(year_month)) %>% ungroup() %>%
                                 group_by(station_id, station_lat, station_lon, year) %>%
                                  summarise(sum(absolute_change)) %>% ungroup() %>%
                                 filter(year == 2015) %>%
                                 rename(Change = `sum(absolute_change)`) %>%
                                 arrange(-Change)
                                
stations_with_problems_growth_top_100 <- stations_with_problems_growth[1:100,]

map_top_100_growth <- map_base_layer +
                        geom_point(data = stations_with_problems_growth_top_100, 
                                   aes(x = station_lon, y = station_lat, 
                                       color = Change), size=3) +
                        scale_colour_gradient(low = "orange", high = "red") +
                        ggtitle("\n100 stations with greatest month-on-month change in imbalance, 2015\n (imbalance = days with surplus starts - days with surplus ends)\n")

print(map_top_100_growth)
ggsave("figures/map_top_100_growth.pdf", scale = 2)

