
## Snippet of code for reading in RI data from their governor's office...

###############################################################################
                                        #             Rhode Island            #
###############################################################################

ri <- read.csv("../data/2020-04-19-rhode-island.csv",
               header = TRUE, stringsAsFactors = FALSE)

glimpse(ri)

ri <- ri %>%
  mutate(Date = dmy(paste0(Date, "-2020")))

glimpse(ri)

ri <- ri %>%
  filter(Date >= Date[head(which(New.deaths > 0), 1)])

data_ri <- data_both %>%
  filter(state == "Rhode Island") %>%
  select(date, deaths, Source) %>%
  rbind(data.frame(
    date = ri$Date, deaths = ri$New.deaths, Source = "RI_gov"
  ))
 


data_ri %>%
  ggplot() +
  geom_hline(yintercept = 0) +
  ## geom_line(aes(date, deaths, col = Source), alpha = 0.5, lty = "dotted") +
  geom_jitter(aes(date, deaths, col = Source), alpha = 0.5, size = 3, width = 0.4) +
  ## facet_wrap(~Source) + 
  scale_color_manual(values = c("darkorange", "dodgerblue", "grey30")) +
  scale_x_date(date_breaks = "1 week", date_labels = "%b %d", date_minor_breaks = "1 day") +
  labs(title = "Rhode Island",
       x = "date", y = "Daily deaths") +
  theme_minimal(base_size = 16) 

data_ri %>%
  pivot_wider(names_from = Source, values_from = deaths, values_fill = list(deaths = 0)) %>%
  arrange(date) %>%
  mutate(RI_gov = ifelse(date <= max(ri$Date), RI_gov, NA)) %>% 
  readr::write_csv("~/Desktop/ri.csv")

