# графік: https://texty.org.ua/media/images/dynamix_bobrudis.width-1600.jpg
library('ggplot2')
library('dplyr')
library(tidyr)
library(scales)

original_cases = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv")  

setwd("/home/yevheniia/R/2020/covid-19")
countries_translated = read.csv("countries_translated.csv")

cases = gather(original_cases, "date", "amount", starts_with("X")) %>% 
  mutate(date = sub("X", "", date)) %>% 
  mutate(date = as.Date(date, "%m.%d.%y")) %>% 
  group_by(Country.Region, date) %>% 
  mutate(cases = sum(amount)) %>% 
  ungroup() %>% 
  select(Country.Region, date, cases) %>% 
  unique()

data = cases %>% 
  filter(cases > 100) %>% 
  group_by(Country.Region) %>% 
  arrange(Country.Region, date) %>% 
  mutate(counter=row_number()) %>% 
  ungroup() %>% 
  group_by(Country.Region) %>% 
  filter(cases > 1000) %>% 
  ungroup()

from_100_to_1000 =  data %>% 
  group_by(Country.Region) %>% 
  summarize(from_100_to_1000 = min(counter)) 
  
from_100_to_1000 = left_join(from_100_to_1000, countries_translated, by="Country.Region")

# сірими лініями поки всі країни без фільтру по цікавим
ggplot(from_100_to_1000, aes(y = from_100_to_1000, x = reorder(country_uk, -from_100_to_1000))) + 
  geom_bar(stat="identity", width = 0.8)+
  # geom_text(aes(label = from_100_to_1000), position = position_dodge(width = 1), vjust = 0, size = 4) + 
  labs(title = "В Японії — 30, в Китаї і Туреччині — 4",
       subtitle = "Скільки днів знадобилось коронавірусу, \nщоб сягнути 1000 випадків після 100",
       caption = "Дані: https://github.com/CSSEGISandData/COVID-19/", 
       x = '', y = '')+
  coord_flip()+
  theme_minimal() +
  theme(legend.position="none",
        text = element_text(size=13),
        panel.grid.major.y = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.subtitle = element_text(size=14),
        strip.text = element_text()
  )

