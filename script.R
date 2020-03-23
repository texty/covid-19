# графік: https://texty.org.ua/media/images/dynamix_bobrudis.width-1600.jpg
library(dplyr)
library(tidyr)
library(ggplot2)

Sys.setlocale("LC_TIME", "Ukrainian")

original_cases = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv")  
original_deaths = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Deaths.csv") 
setwd("/home/yevheniia/R/2020/covid-19")
countries_translated = read.csv("countries_translated.csv")

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
target_countries = c("Ukraine", "Austria", "Bulgaria", "Canada", "China", "France", "Germany", 
                     "Iran", "Israel", "Italy", "Korea, South", "Turkey", "Moldova", "Poland", 
                     "Portugal", "Russia", "Spain", "Sweden", "United Kingdom", "US")

end_date = max(data$date)

countries = data %>% 
  filter(date == end_date)  %>% 
  select(2,3)

filtered = data %>%  
  filter(Country.Region %in% target_countries) 

filtered = left_join(filtered, countries_translated, by="Country.Region")

options(scipen=10000)

# сірими лініями поки всі країни без фільтру по цікавим
ggplot(filtered, aes(y = cases, x = counter)) + 
  geom_line(data = transform(filtered, country_uk = NULL), mapping = aes(group = place), colour = "#696969", size=0.2)+
  geom_line(aes(group = country_uk), size=1, colour = "#cf1e25")+
  scale_size_manual(values = c(0.2, 1))+
  facet_wrap(.~country_uk) +
  scale_y_continuous(trans='log10')+
  labs(title = paste("COVID-19. Кількість захворювань по днях, починаючи з першої смерті.", format(end_date, '%d-%m-%Y')),
       subtitle = "Зверніть увагу, графік для України значно нижче за інші країни, через те, що перша смерть була зафіксована, \nколи хворих було визначено дуже мало. Ймовірно, це пов'язано з відсутністю тестування. Можна припустити, \nщо на момент першої смерті в Україні хворих було значно більше",
       caption = "Дані: https://github.com/CSSEGISandData/COVID-19/", 
       x = "", 
       y = "") +
  # geom_rect(data = subset(filtered, Country.Region == "Ukraine"), aes(fill = "red"), xmin = 0, xmax = 100000, ymin = 0,ymax = 60, alpha = 0.01)+
  theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold")
  )



