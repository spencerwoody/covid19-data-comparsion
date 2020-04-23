
library(dplyr)
library(ggplot2)
library(lubridate)
library(cowplot)
library(stringr)
library(tidyr)
library(gridExtra)
library(readr)

theme_set(theme_half_open())

## State abbreviations and fips codes
state_abbr <- read.csv("data/state_fips_abbr.csv", stringsAsFactors = FALSE)

## Population by state
uspop <- read.csv('data/state_pop.csv', stringsAsFactors = FALSE)



###############################################################################
                                        #               NYT data              #
###############################################################################


## Data from New York Times -- https://github.com/nytimes/covid-19-data
nyt_raw <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')

glimpse(nyt_raw)

nyt <- nyt_raw %>%
  filter(state %in% state_abbr$Name) %>% #Choose only 50 states + DC
  mutate(date = ymd(date)) %>% 
  group_by(state, date) %>%
  summarize(cumulative_deaths=sum(deaths)) %>% #Cumulative deaths
  ungroup() %>%
  merge(uspop, by.x = 'state', by.y = 'location') %>% #Add population numbers
  arrange(state, date) %>%
  rename(population = Pop_Est_2019) %>%
  group_by(state) %>%
  mutate(deaths = diff(c(0,cumulative_deaths))) %>% #Deaths per day
  ungroup() %>%
  mutate(deaths_per_cap = deaths/population,
         cumulative_deaths_per_cap = cumulative_deaths/population) #per-capita

glimpse(nyt)

## When does mortality rate exceed 3 deaths per 10 million -> start of
## epidemiological timeline for our model
threshold_day_nyt <- nyt %>%
  group_by(state) %>%
  summarize(threshold_day = date[min(which(cumulative_deaths_per_cap >= 0.3/1e6))])

## if a state hasn't reached this threshold day yet, don't include it
## in the model
keep_states_nyt <- threshold_day_nyt %>%
  filter(!is.na(threshold_day)) %>%
  pull(state)

nyt <- nyt %>%
  filter(state %in% keep_states_nyt)

## use the threshold_day variable to get the time counter, then remove it
nyt = nyt %>% merge(threshold_day_nyt)

nyt = nyt %>%
  mutate(days_since_thresh = as.numeric(ymd(date) - ymd(threshold_day))) %>%
  select(-threshold_day) %>%
  filter(deaths >= 0, days_since_thresh >= 0)

glimpse(nyt)


###############################################################################
                                        #               JHU data              #
###############################################################################

## Data from Johns Hopkins U. -- https://github.com/CSSEGISandData/COVID-19
## Note that these data contain *cumulative deaths*
jhu_raw <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

glimpse(jhu_raw)

## Make this data "longer", and create YYYY-MM-DD dates
jhu <- jhu_raw %>%
  pivot_longer(cols = ends_with("20"),
               names_to = "date_mdy",
               values_to = "cumulative_deaths") %>%
  mutate(date_ymd = mdy(date_mdy) %>% ymd())

glimpse(jhu)

## Select columns
jhu <- jhu %>%
  select(date = date_ymd, #Select certain columns
         county = Admin2,
         state = Province_State,
         fips = FIPS,
         cumulative_deaths,
         Population) %>%
  filter(state %in% state_abbr$Name) %>% #Only US states + DC
  group_by(state, date) %>%              #Aggregate by state
  summarize(cumulative_deaths = sum(cumulative_deaths),
            population = sum(Population)) %>%
  ungroup() %>%
  group_by(state) %>%
  mutate(deaths = diff(c(0,cumulative_deaths))) %>% #Daily deaths
  mutate(deaths_per_cap = deaths/population,        #Per-capita deaths
         cumulative_deaths_per_cap = cumulative_deaths/population)


# Threshold date as defined above
threshold_day_jhu <- jhu %>%
  group_by(state) %>%
  summarize(threshold_day = date[min(which(cumulative_deaths_per_cap >= 0.3/1e6))])

keep_states_jhu <- threshold_day_jhu %>%
  filter(!is.na(threshold_day)) %>%
  pull(state)

jhu <- jhu %>%
  filter(state %in% keep_states_jhu)

# use the threshold_day variable to get the time counter, then remove it
jhu <- jhu %>% merge(threshold_day_jhu)

## Only data for after the threshold
jhu <- jhu %>%
  mutate(days_since_thresh = as.numeric(ymd(date) - ymd(threshold_day))) %>%
  select(-threshold_day) %>%
  filter(deaths >= 0, days_since_thresh >= 0) %>%
  select(state, date, cumulative_deaths, population, deaths, deaths_per_cap,
         cumulative_deaths_per_cap, days_since_thresh)

## Glimpse at formatting
glimpse(jhu %>% filter(cumulative_deaths >= 1))

glimpse(nyt %>% filter(cumulative_deaths >= 1))

###############################################################################
                                        #      Compare data for one state     #
###############################################################################

## Stack data sources
data_both <- rbind(
  jhu %>% mutate(Source = "JHU"),
  nyt %>% mutate(Source = "NYT")
)

## Choose a state
mystate <- "New York"

data_both_mystate <- data_both %>%
  filter(state == mystate) %>%
  arrange(date, Source)

tail(data_both_mystate, 4)

## Plot daily incident deaths
state_daily <- data_both_mystate %>%
  ggplot() +
  geom_point(aes(date, deaths, col = Source), alpha = 0.5, size = 3) +
  scale_color_manual(values = c("darkorange", "dodgerblue3")) +
  theme_minimal_grid() +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") + 
  labs(title = sprintf("%s", mystate),
       y = "Daily deaths",
       caption = sprintf("This version: %s", today()))

state_daily

## Plot cumulative deaths
state_cumulative <- data_both_mystate %>%
  ggplot() +
  geom_point(aes(date, cumulative_deaths, col = Source), alpha = 0.5, size = 3) +
  scale_color_manual(values = c("darkorange", "dodgerblue3")) +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d") + 
  theme_minimal_grid() + 
  labs(title = sprintf("%s", mystate),
       y = "Cumulative deaths",
       caption = sprintf("This version: %s", today()))

state_cumulative


## Stack daily and cumulative
state_grob <- arrangeGrob(state_daily, state_cumulative, ncol = 1)

grid.arrange(state_grob)

ggsave(sprintf("figures/%s-%s.pdf", today(), mystate), state_grob,
       width = 8, height = 8)

