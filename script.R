# графік: https://texty.org.ua/media/images/dynamix_bobrudis.width-1600.jpg
library(dplyr)
library(tidyr)
library(ggplot2)

Sys.setlocale("LC_TIME", "Ukrainian")

original = read.csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv")  

# перелік країн, які цікаві
target_countries = c("Austria", "Belgium", "Poland", "United Kingdom", 
                     "Belgium", "Croatia", "Czechia", "Denmark", "France", 
                     "Germany", "Greece", "Italy", "Spain", "Romania", 
                     "Sweden", "Switzerland", "US", "Netherlands", "Israel", 
                     "Russia")

data = gather(original, "date", "amount", starts_with("X")) %>% 
  mutate(date = sub("X", "", date)) %>% 
  mutate(date = as.Date(date, "%m.%d.%y")) 

end_date = max(data$date)

data = data %>% 
  filter(amount >= 100) %>% 
  group_by(Country.Region, date) %>% 
  mutate(total = sum(amount)) %>% 
  ungroup() %>% 
  select(Country.Region, date, total) %>% 
  unique() %>% 
  group_by(Country.Region) %>% 
  arrange(Country.Region, date) %>% 
  #беремо за перший день найпершу наявну дату і далі кожен наступний день
  mutate(counter=row_number()) %>% 
  mutate(place = Country.Region)

filtered = data %>% 
  filter(Country.Region %in% target_countries)
  
# сірими лініями поки всі країни без фільтру по цікавим
ggplot(filtered, aes(y = total, x = counter)) + 
  geom_line(data = transform(data, Country.Region = NULL), mapping = aes(group = place), colour = "#696969", size=0.2)+
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



