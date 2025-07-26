# Cyclistic Bike-Share Data Analysis: Understanding Rider Behavior

## Introduction

This project is a Capstone project provided by Google as part of the **Google Data Analytics Professional Certificate**.  
The primary goal is to analyze the **"divvy-tripdata"** datasets to answer the business problem:

> **"How do annual members and casual riders use Cyclistic bikes differently?"**

This analysis was conducted from the perspective of a junior data analyst.

---

## Data Analysis Process

As a junior data analyst, I approached this project by considering all phases of the data analysis process:

- **Ask**  
- **Prepare**  
- **Process**  
- **Analyze**  
- **Share**  
- **Act**

---

### 1. Ask

**Problem Statement:**  
The core problem is to identify the different ways Cyclistic bikes are used by two distinct customer groups: **annual members (subscribers)** and **casual riders (customers)**.

**Driving Business Decisions:**  
The insights derived from this analysis will help inform decisions regarding advertising strategies, specifically where to focus efforts and which customer groups to target when implementing new strategies.

---

### 2. Prepare

I downloaded the datasets from:  
[https://divvy-tripdata.s3.amazonaws.com/index.html](https://divvy-tripdata.s3.amazonaws.com/index.html)

These datasets consist of four quarters from **2019**:

- `Divvy_Trips_2019_Q1.csv`  
- `Divvy_Trips_2019_Q2.csv`  
- `Divvy_Trips_2019_Q3.csv`  
- `Divvy_Trips_2019_Q4.csv`  

Each file contains four months of trip data.  
The raw dataset files are also available if you wish to review them.

---

### 3. Process

To clean, organize, and transform the data, I chose the **R programming language** due to the large number of rows, which spreadsheets cannot efficiently handle. SQL could also be used as an alternative.

**The processing steps included:**

1. Importing all necessary libraries.  
2. Importing all datasets from their respective locations.  
3. Removing all null values.  
4. Standardizing column names:  
   The `Divvy_Trips_2019_Q2` dataset had different column names than the others, so they were converted to match.  
5. Converting `start_time` and `end_time` columns from string to datetime datatype.  
6. Collecting columns with the same name from all datasets into a common vector (e.g.,  
   ```R
   usertype <- c(ds1$usertype, ds2$usertype, ds3$usertype, ds4$usertype)
7.  Calculating `ride_length` for future use. 
8.  Combining all vectors into a single dataframe, named `clean_data`.  

After these steps, the data was ready for analysis.  

---

### 4. Analyze

To identify the differences in bike usage between customer types, the following steps were performed:  

1.  Limiting the analysis to a 24-hour period to avoid biased conclusions based on `ride_length`.  
2.  Calculating the average ride length for each user type.  
3.  Analyzing gender-based variations between user types.  
4.  Calculating monthly trends for both user types.  
5.  Identifying the top 10 start and end stations for each user type.  

All calculations were analyzed to provide a clear picture of user behavior.  

---

### 5. Share

Based on the analysis, several distinct differences between the two user types were identified:  

  - Casual riders (customers) have a longer average ride length compared to annual members, especially when comparing on a weekly basis.  
  - Subscribers' rides gradually increase from February, peak in August, and then slightly decrease towards November.  
  - Customer rides increase in May, peak in August, and then decline in November.  
  - Among subscribers, male rides are three times more frequent than female rides.  
  - Among customers, male rides are twice as frequent as female rides.  
  - Subscribers and customers tend to use different routes for most of their rides.  

---

### 6. Act

The insights gained from this analysis can be put into action through the following strategies:  

1.  Targeted Advertising: It is clear from which locations rides are most frequently taken. Therefore, advertising efforts should be focused more on these specific areas to attract new subscribers. 
2.  Increase Female Ridership: Female riders are comparatively low in both user groups. Strategies should be developed to encourage more women to use Cyclistic bikes. 
3.  Capitalize on Peak Season: August is the month when both subscribers and customers take the most rides. Business strategies should be developed to leverage this peak period. 

