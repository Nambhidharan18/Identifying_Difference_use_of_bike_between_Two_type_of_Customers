library(tidyverse)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(scales)
library(openxlsx)

ds1 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q1.csv")
ds2 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q2.csv")
ds3 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q3.csv")
ds4 <- read.csv("D:/Capstone_project/dataset/Divvy_Trips_2019_Q4.csv")



ds1 <- na.omit(ds1)
ds2 <- na.omit(ds2)
ds3 <- na.omit(ds3)
ds4 <- na.omit(ds4)

#To convert ds2 column name from different to same as all other data frame
ds2$start_time <-ds2$X01...Rental.Details.Local.Start.Time
ds2$end_time <- ds2$X01...Rental.Details.Local.End.Time
ds2$tripduration <-ds2$X01...Rental.Details.Duration.In.Seconds.Uncapped
ds2$from_station_name <- ds2$X03...Rental.Start.Station.Name
ds2$to_station_name <- ds2$X02...Rental.End.Station.Name
ds2$usertype <- ds2$User.Type
ds2$gender <-ds2$Member.Gender


# collecting all data into one cleaned data frame
start_time <- ymd_hms(c(ds1$start_time, ds2$start_time, 
                ds3$start_time, ds4$start_time))
end_time <- ymd_hms(c(ds1$end_time ,ds2$end_time,
              ds3$end_time ,ds4$end_time))
start_station <- c(ds1$from_station_name, ds2$from_station_name,
                   ds3$from_station_name, ds4$from_station_name)
end_station   <- c(ds1$to_station_name, ds2$to_station_name,
                   ds3$to_station_name, ds4$to_station_name)
gender <- c(ds1$gender ,ds2$gender,
            ds3$gender ,ds4$gender )
tripduration <- c(ds1$tripduration ,ds2$tripduration, 
                  ds3$tripduration ,ds4$tripduration )
usertype <- c(ds1$usertype ,ds2$usertype, ds3$usertype ,ds4$usertype )

ride_length = (end_time - start_time) *60



clean_data <- data.frame(start_station = start_station,
                         end_station = end_station ,
                         start_time=start_time,
                         end_time = end_time,
                         trip_duration = (tripduration),
                         ride_length = (ride_length),
                         user_type = usertype,
                         gender = gender,
                         day_of_week = wday(start_time, label = TRUE)
                         )

# Limitting the analysis to 1 day

clean_data <- clean_data %>% filter(ride_length <= 1440 & ride_length > 10)

# Average ride length of each user type per day of week
avg_user <- clean_data %>% 
  group_by(user_type,day_of_week) %>%
  summarise(avg_ride_length = mean(ride_length) / 60)%>%
  arrange(avg_ride_length)

print(avg_user)

ggplot(data = avg_user, aes(x= day_of_week, 
                            y = avg_ride_length,
                            fill = user_type))+
  geom_col(position = "dodge")+
  labs(title = "Total Rides by Day of Week and Rider Type",
       x = "Day of Week",
       y = "Average Ride Length in hours",
       fill = "Rider Type")

#Finding gender population in each user type
population_of_user <- clean_data %>%
  group_by(gender, user_type) %>%
  summarise(total_count = n())%>%
  filter(gender == "Male" | gender == "Female") %>%
  arrange(desc(total_count))
print(population_of_user)

ggplot(data = population_of_user, mapping = aes(x=gender,
                                                y = total_count,
                                                fill = user_type))+
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
  
#In which month each user had many rides
monthly_most_rides <- clean_data %>%
  group_by(user_type,month= month(start_time, label = TRUE, abbr = FALSE)) %>%
  summarise(total_count = n()) %>%
  arrange(month )

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



# Find the top 10 most popular start stations and end station of subscriber
most_popular_start_stations_Subscriber <- clean_data %>%
  group_by(user_type, start_station, end_station) %>%
  summarise(total_trips = n(),
            avg_ride_length_hours = mean(ride_length)/ 60,
            .groups = 'drop') %>%
  filter(user_type == "Subscriber") %>%
  arrange(desc(total_trips),desc(avg_ride_length_hours)) %>%
  slice_head(n = 10)

print(most_popular_start_stations_Subscriber)



# This single pipeline gets the top 10 routes for both user types
top_routes_by_user_type <- clean_data %>%
  group_by(user_type, start_station, end_station) %>%
  summarise(total_trips = n(),
            avg_ride_length_hours = mean(ride_length) / 60,
            .groups = 'drop') %>%
  # Use slice_max to get the top 10 for each user_type
  slice_max(total_trips, n = 10, by = user_type) %>%
  arrange(user_type, desc(total_trips), desc(avg_ride_length_hours))

print(top_routes_by_user_type)

plot_data <- top_routes_by_user_type %>%
  mutate(route = paste0(start_station, " -> ", end_station)) %>%
  # Arrange by total_trips so the plot orders the bars correctly
  arrange(user_type, desc(total_trips)) %>%
  # Convert to a factor to preserve the sort order in the plot
  mutate(route = factor(route, levels = unique(route)))

# Create the faceted bar chart
ggplot(plot_data, aes(x = total_trips, y = route, fill = as.numeric(avg_ride_length_hours))) +
  geom_bar(stat = "identity") +
  facet_wrap(~user_type, scales = "free_y") + # Use free_y to make each y-axis independent
  labs(
    title = "Top 10 Most Popular Routes by User Type",
    subtitle = "Customer routes are concentrated in leisure areas, while Subscribers use commuter routes",
    x = "Total Trips",
    y = "Route (Start -> End Station)",
    fill = "Avg. Ride Length (min)"
  ) +
  scale_fill_viridis_c() + # Use a nice color scale for ride length
  scale_x_continuous(labels = comma) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 8),
    legend.position = "bottom"
  )
 
presentation <- list("Average_ride_per_week_of_days" = avg_user,
                     "Monthly_trend" = monthly_most_rides,
                     "Gender_difference" = population_of_user,
                     "Route_difference" = plot_data)
# saving the data frame

write.xlsx(presentation, "presentation.xlsx")