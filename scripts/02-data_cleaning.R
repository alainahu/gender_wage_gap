#### Preamble ####
# Purpose: Cleans the raw data from various sources and merges them together to form the analysis dataset. 
# Author: Alaina Hu
# Date: 18 April 2024
# Contact: alaina.hu@utoronto.ca 
# License: MIT
# Pre-requisites: Have access to the raw datasets from the Global Gender Gap Report, OECD Database, and World Bank Data Portal.
# Any other information needed? Data cleaning here uses the files in data/raw_data. To ensure replicability, the raw data have all been uploaded to the folder. 

#### Workspace setup ####
library(tidyverse)
library(readxl)
library(arrow)
#### Clean data ####
attitude_data <- read_csv("data/raw_data/raw_data.csv")

gendergap_data <- read_excel("data/raw_data/global-gender-gap-index-2023.xlsx")

gdp_data <- read_csv("data/raw_data/gdp_data.csv")



attitude_data <-
  attitude_data |>
  select(Region, LOCATION, Country, Variables, Value) |>
  filter(Region == "All regions") |> 
  filter(Variables %in%  c("Attitudes on women's income", "Attitudes justifying intimate-partner violence", "Attitudes on women's ability to be a political leader")) |>
  mutate(Value = as.numeric(Value)) |>
  select(-Region, -Variables) |>
  rename(attitude = Value) 

attitude_data <- attitude_data |>
  group_by(Country) |>
  mutate(attitude_id = row_number()) |>
  ungroup()

attitude_data <- attitude_data |>
  pivot_wider(
    names_from = attitude_id,
    values_from = attitude,
    names_prefix = "attitude_"
    )


attitude_data <- attitude_data |>
  rename(
    `Income Attitude` = attitude_1,
    `Violence Attitude` = attitude_2,
    `Political Attitude` = attitude_3
  )


column_names <- names(gendergap_data)
column_names[1] <- "Country"
column_names[2] <- "Gender Gap"
names(gendergap_data) <- column_names


column_names_1 <- names(gdp_data)
column_names_1 <- c("Series", "Series Code", "Country", "Code", "GDP")
names(gdp_data) <- column_names_1

gdp_data <-
  gdp_data |>
  select(Country, Code, GDP)


merged_data <- left_join(attitude_data, gdp_data, by = "Country")  
merged_data <- left_join(merged_data, gendergap_data, by = "Country")
merged_data <- merged_data |>
  select(-LOCATION) |>
  drop_na()

merged_data <- arrange(merged_data, Country)
merged_data <- merged_data |>
  mutate(`Income Attitude` = as.numeric(`Income Attitude`),
         `Violence Attitude`= as.numeric(`Violence Attitude`),
         `Political Attitude` = as.numeric(`Political Attitude`),
         GDP = as.numeric(GDP),
         `Gender Gap` = as.numeric(`Gender Gap`)
         )
merged_data <- merged_data |>
  mutate(GDP = round(GDP, 2)) |>
  mutate(`Gender Gap` = 1 - `Gender Gap`) |>
  filter(Country != "Lebanon")



#### Save data ####
write_csv(merged_data, "data/analysis_data/analysis_data.csv")
write_parquet(merged_data, "data/analysis_data/analysis_data.parquet")
