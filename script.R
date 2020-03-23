# графік: https://texty.org.ua/media/images/dynamix_bobrudis.width-1600.jpg
library(dplyr)
library(tidyr)
library(ggplot2)

Sys.setlocale("LC_TIME", "Ukrainian")

original_cases = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv")  
original_deaths = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv") 
  
deaths = gather(original_deaths, "date", "amount", starts_with("X")) %>% 
  mutate(date = sub("X", "", date)) %>% 
  mutate(date = as.Date(date, "%m.%d.%y")) %>% 
  group_by(Country.Region, date) %>% 
  mutate(deaths = sum(amount)) %>% 
  ungroup() %>% 
  select(Country.Region, date, deaths) %>% 
  unique()

cases = gather(original_cases, "date", "amount", starts_with("X")) %>% 
  mutate(date = sub("X", "", date)) %>% 
  mutate(date = as.Date(date, "%m.%d.%y")) %>% 
  group_by(Country.Region, date) %>% 
  mutate(cases = sum(amount)) %>% 
  ungroup() %>% 
  select(Country.Region, date, cases) %>% 
  unique()

data = merge(cases, deaths,  by=c("date", "Country.Region")) %>% 
  filter(deaths > 0) %>% 
  group_by(Country.Region) %>% 
  arrange(Country.Region, date) %>% 
  mutate(counter=row_number()) %>% 
  mutate(place = Country.Region)

# перелік країн, які цікаві
target_countries = c("Austria", "Belgium", "Poland", "United Kingdom", 
                     "Belgium", "Croatia", "Czechia", "Denmark", "France", 
                     "Germany", "Greece", "Italy", "Spain", "Romania", 
                     "Sweden", "Switzerland", "US", "Netherlands", "Israel", 
                     "Russia", "Ukraine")

end_date = max(data$date)

filtered = data %>%  
  filter(Country.Region %in% target_countries)
  
options(scipen=10000)

# сірими лініями поки всі країни без фільтру по цікавим
ggplot(filtered, aes(y = cases, x = counter)) + 
  geom_line(data = transform(filtered, Country.Region = NULL), mapping = aes(group = place), colour = "#696969", size=0.2)+
  geom_line(aes(group = Country.Region), size=1, colour = "#cf1e25")+
  scale_size_manual(values = c(0.2, 1))+
  facet_wrap(~ Country.Region) +
  scale_y_continuous(trans='log10')+
  labs(title = paste("COVID-19. Станом на", format(end_date, "%d-%b-%Y")),
       subtitle = "Кількість випадків по днях, починаючи з 100 пацієнта",
       caption = "Дані: https://github.com/CSSEGISandData/COVID-19/", 
       x = "", y = "") +
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold"))



