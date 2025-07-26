# Load required libraries for data manipulation, visualization, and date handling
library(tidyverse)  # Loads ggplot2, dplyr, tidyr, readr, and other tidyverse packages
library(ggplot2)    # For creating visualizations
library(dplyr)      # For data manipulation (filter, group_by, summarise, etc.)
library(tidyr)      # For data reshaping
library(lubridate)  # For working with dates and times
library(scales)     # For formatting scales in plots (e.g., commas in axis labels)
library(openxlsx)   # For working with Excel files

# Load Divvy trip datasets for all four quarters of 2019
ds1 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q1.csv")
ds2 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q2.csv")
ds3 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q3.csv")
ds4 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q4.csv")

# Remove rows with missing values from each dataset
ds1 <- na.omit(ds1)
ds2 <- na.omit(ds2)
ds3 <- na.omit(ds3)
ds4 <- na.omit(ds4)

# --- DATA CLEANING & COLUMN STANDARDIZATION ---

# The Q2 dataset uses different column names. We standardize them to match Q1, Q3, Q4.
ds2$start_time <- ds2$X01...Rental.Details.Local.Start.Time
ds2$end_time <- ds2$X01...Rental.Details.Local.End.Time
ds2$tripduration <- ds2$X01...Rental.Details.Duration.In.Seconds.Uncapped
ds2$from_station_name <- ds2$X03...Rental.Start.Station.Name
ds2$to_station_name <- ds2$X02...Rental.End.Station.Name
ds2$usertype <- ds2$User.Type
ds2$gender <- ds2$Member.Gender

# --- MERGING & PREPARING MASTER DATASET ---

# Combine data from all quarters into single vectors
start_time <- ymd_hms(c(ds1$start_time, ds2$start_time, 
                        ds3$start_time, ds4$start_time))
end_time <- ymd_hms(c(ds1$end_time, ds2$end_time,
                      ds3$end_time, ds4$end_time))
start_station <- c(ds1$from_station_name, ds2$from_station_name,
                   ds3$from_station_name, ds4$from_station_name)
end_station <- c(ds1$to_station_name, ds2$to_station_name,
                 ds3$to_station_name, ds4$to_station_name)
gender <- c(ds1$gender, ds2$gender, ds3$gender, ds4$gender)
tripduration <- c(ds1$tripduration, ds2$tripduration, 
                  ds3$tripduration, ds4$tripduration)
usertype <- c(ds1$usertype, ds2$usertype, ds3$usertype, ds4$usertype)

# Calculate ride length in minutes (end_time - start_time)
ride_length = (end_time - start_time) * 60

# Create a clean consolidated dataframe with relevant columns
clean_data <- data.frame(
  start_station = start_station,
  end_station = end_station,
  start_time = start_time,
  end_time = end_time,
  trip_duration = tripduration,
  ride_length = ride_length,
  user_type = usertype,
  gender = gender,
  day_of_week = wday(start_time, label = TRUE) # Extract day of week (Mon-Sun)
)

# Filter out outliers: limit ride_length to 10–1440 minutes (1 day)
clean_data <- clean_data %>% filter(ride_length <= 1440 & ride_length > 10)

# --- ANALYSIS & VISUALIZATION ---

# 1. Average ride length (in hours) for each user type by day of week
avg_user <- clean_data %>% 
  group_by(user_type, day_of_week) %>%
  summarise(avg_ride_length = mean(ride_length) / 60) %>%
  arrange(avg_ride_length)

print(avg_user)

# Bar chart: Average ride length by user type across days of the week
ggplot(data = avg_user, aes(x = day_of_week, y = avg_ride_length, fill = user_type)) +
  geom_col(position = "dodge") +
  labs(title = "Total Rides by Day of Week and Rider Type",
       x = "Day of Week",
       y = "Average Ride Length in Hours",
       fill = "Rider Type")

# 2. Gender distribution within each user type
population_of_user <- clean_data %>%
  group_by(gender, user_type) %>%
  summarise(total_count = n()) %>%
  filter(gender == "Male" | gender == "Female") %>% # Ignore 'Unknown' or empty gender
  arrange(desc(total_count))

print(population_of_user)

# Bar chart: User count by gender and user type
ggplot(data = population_of_user, aes(x = user_type, y = total_count, fill = gender)) +
  geom_bar(stat = "identity", position = "dodge") +
  geom_text(aes(label = scales::comma(total_count)), vjust = -0.5, position = position_dodge(width = 0.9)) +
  labs(
    title = "User Count by Gender and User Type",
    x = "User Type",
    y = "Total Count",
    fill = "Gender"
  ) +
  scale_y_continuous(labels = scales::comma) +
  theme_minimal()

# 3. Monthly ride trends for each user type
monthly_most_rides <- clean_data %>%
  group_by(user_type, month = month(start_time, label = TRUE, abbr = FALSE)) %>%
  summarise(total_count = n()) %>%
  arrange(month)

# Line plot: Monthly ride counts by user type
ggplot(monthly_most_rides, aes(x = month, y = total_count, group = user_type, color = user_type)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  labs(
    title = "Monthly Ride Counts by User Type",
    subtitle = "Showing a clear seasonal trend for both groups",
    x = "Month",
    y = "Total Ride Count",
    color = "User Type"
  ) +
  scale_y_continuous(labels = scales::comma) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# 4. Top 10 most popular routes for each user type
top_routes_by_user_type <- clean_data %>%
  group_by(user_type, start_station, end_station) %>%
  summarise(
    total_trips = n(),
    avg_ride_length_hours = mean(ride_length) / 60,
    .groups = 'drop'
  ) %>%
  slice_max(total_trips, n = 10, by = user_type) %>%
  arrange(user_type, desc(total_trips), desc(avg_ride_length_hours))

print(top_routes_by_user_type)

# Prepare data for route visualization
plot_data <- top_routes_by_user_type %>%
  mutate(route = paste0(start_station, " -> ", end_station)) %>%
  arrange(user_type, desc(total_trips)) %>%
  mutate(route = factor(route, levels = unique(route)))

# Faceted bar chart: Top 10 routes by user type
ggplot(plot_data, aes(x = total_trips, y = route, fill = as.numeric(avg_ride_length_hours))) +
  geom_bar(stat = "identity") +
  facet_wrap(~user_type, scales = "free_y") +
  labs(
    title = "Top 10 Most Popular Routes by User Type",
    subtitle = "Customer routes are concentrated in leisure areas, while Subscribers use commuter routes",
    x = "Total Trips",
    y = "Route (Start -> End Station)",
    fill = "Avg. Ride Length (min)"
  ) +
  scale_fill_viridis_c() +
  scale_x_continuous(labels = comma) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 8),
    legend.position = "bottom"
  )
  