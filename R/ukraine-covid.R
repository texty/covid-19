# Хороший датасет поки відсутній, юзаємо оці два ресурси

# data source: https://public.tableau.com/profile/publicviz#!/vizhome/monitor_15841091301660/sheet0
# https://github.com/quazerro/COVID-19_ukr (Остап)

library("dplyr")
library("tidyr")
library('xlsx')
library("readxl")

setwd('/home/yevheniia/git/2020_YEAR/covid-19/data/source-data/ukraine/')
# датасет з Табло
data1 = read.csv("Загальне_data.csv", stringsAsFactors = F) %>% 
  rename(recovered = Кількість.випадків.одужання.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  rename(confirmed = Кількість.осіб..діагноз.COVID.19.яких.підтвердився.протягом.звітного.періоду) %>% 
  rename(suspected = Кількість.осіб.із.підозрою.на.зараження.коронавірусом.SARS.CoV.2..2019.nCoV...випадки.яких.зафіксовано.протягом.звітного.період) %>% 
  rename(deaths = Кількість.смертельних.випадків.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  rename(date=Звітна.дата) %>% 
  rename(hospital_id = Код.ЄДРПОУ.закладу.охорони.здоров.я) %>% 
  rename(region = `Область`) %>% 
  select(-кількість.лікарень, -max.date) %>% 
  mutate(date = as.Date(date, format="%m/%d/%Y"))

# датасет з координатами лікарень
data2 = read.csv("Карта_data.csv", stringsAsFactors = F, colClasses=c("Код.ЄДРПОУ.закладу.охорони.здоров.я"="character")) %>% 
  rename(recovered = Кількість.випадків.одужання.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  rename(confirmed = Кількість.осіб.із.підтвердженим.діагнозом.COVID.19..спричиненим.коронавірусом.SARS.CoV.2..2019.nCoV...які.перебувають.на.лікува) %>% 
  rename(waiting = Кількість.осіб.з.підозрою.на.зараження.коронавірусом.SARS.CoV.2..2019.nCoV...випадки.яких.очікують.лабораторного.підтвердження) %>% 
  rename(deaths = Кількість.смертельних.випадків.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  rename(lat = Latitude..generated.) %>% 
  rename(lon = Longitude..generated.) %>% 
  rename(address = `Адреса`) %>% 
  rename(hospital_id = Код.ЄДРПОУ.закладу.охорони.здоров.я) %>% 
  rename(hospital_name = Назва.закладу.охорони.здоров.я) %>% 
  select(hospital_id, hospital_name, lat, lon, address)

# координати областей для самоізольованих
selfizo_coords = read.csv("selfizo.csv", stringsAsFactors = F)

h1 = data1 %>%  select(hospital_id) %>% unique()
h2 = data2 %>%  select(hospital_id) %>% unique()

# перелік лікарень (унікальні значення)
hospitals = data2 %>% 
  select(hospital_id, hospital_name, lat, lon, address) %>% 
  filter(hospital_id != "самоізоляція") %>%  
  unique() %>% 
  mutate(hospital_id = as.character(hospital_id))

# остання дата в датасеті
max_date = max(data1$date)

# кількість по регіонам
get_data_by_region = function(df){
  data = df %>%
    select(region, suspected, confirmed, deaths) %>% 
    group_by(region) %>%
    mutate(suspected = sum(suspected)) %>%
    mutate(confirmed = sum(confirmed)) %>%
    mutate(deaths = sum(deaths)) %>%
    ungroup() %>% 
    unique()
  return(data)
}

# кількість по датах
get_data_by_date = function(df){
  data = df %>%
    select(date, confirmed) %>% 
    group_by(date) %>% 
    summarise(confirmed = sum(confirmed)) %>% 
    mutate(comsum = cumsum(confirmed)) %>% 
    unique()
  return(data)
}

split_dataset = function(df, var){
  selfizolation = df %>%
    filter(hospital_id == "самоізоляція") %>%
    left_join(selfizo_coords, by = "region") %>%
    filter(!!(as.name(var)) > 0)

  if(NROW(selfizolation) > 0){
    selfizolation = selfizolation %>%
      group_by(date, hospital_id, region, lat, lon) %>%
      expand(!!var := seq(1:!!(as.name(var)))) %>%
      ungroup() %>%
      mutate(!!(as.name(var)) := 1) %>%
      mutate(hospital_name = "") %>%
      select(date, hospital_id, hospital_name, region, lat, lon, !!var)
  }
  
  data = df %>% 
    select(date, hospital_id, !!var, region) %>%
    filter(hospital_id != "самоізоляція") %>% 
    left_join(hospitals, by="hospital_id") %>% 
    filter(!!(as.name(var)) > 0) %>% 
    group_by(date, hospital_id, hospital_name, region, lat, lon, !!(as.name(var))) %>% 
    expand(!!var := seq(1:!!(as.name(var)))) %>% 
    ungroup() %>% 
    mutate(!!(as.name(var)) := 1)
  
  if(NROW(selfizolation) > 0){
    data = data %>%  bind_rows(selfizolation) 
  } else {
    data = data
  }
  return(data)
}

confirmed = split_dataset(data1, "confirmed")
suspected = split_dataset(data1, "suspected")
deaths = split_dataset(data1, "deaths")
by_region = get_data_by_region(data1)
by_date = get_data_by_date(data1)

setwd("/home/yevheniia/git/2020_YEAR/covid-19/data/ukraine/")
write.csv(by_date, "cases_by_date.csv", row.names = F)
write.csv(by_region, "cases_by_region.csv", row.names = F)
write.csv(confirmed, "confirmed_cases.csv", row.names = F)
write.csv(suspected, "suspected_cases.csv", row.names = F)
write.csv(deaths, "death_cases.csv", row.names = F)




xlsx_ <- read_excel("monitoring_v4_2020-04-04.xlsx", sheet=1, col_names = TRUE,col_types=NULL, na="") %>% 
  rename(date =`Звітна дата`) %>% 
  rename(region = `Область`) %>% 
  rename(district = `Район`) %>% 
  rename(address = `Адреса`) %>% 
  rename(type = `Тип`) %>% 
  rename(suspected = `Кількість осіб із підозрою на зараження коронавірусом SARS-CoV-2 (2019-nCoV), випадки яких зафіксовано протягом звітного періоду`) %>% 
  rename(confirmed = `Кількість осіб, діагноз COVID-19 яких підтвердився протягом звітного періоду`) %>% 
  rename(deaths = `Кількість смертельних випадків серед осіб із підтвердженим діагнозом COVID-19 протягом звітного періоду`) %>% 
  rename(hospitalized = `Кількість осіб із підтвердженим діагнозом COVID-19, спричиненим коронавірусом SARS-CoV-2 (2019-nCoV), які перебувають на лікуванні у закладі`) %>% 
  rename(waiting = `Кількість осіб з підозрою на зараження коронавірусом SARS-CoV-2 (2019-nCoV), випадки яких очікують лабораторного підтвердження`) %>% 
  rename(recovered = `Кількість випадків одужання серед осіб із підтвердженим діагнозом COVID-19 протягом звітного періоду`) %>% 
  rename(hospital_id = `Код ЄДРПОУ закладу охорони здоров'я`) %>% 
  rename(beds = `Кількість ліжкомісць, пристосованих для госпіталізації осіб з підозрою на зараження коронавірусом SARS-CoV-2 (2019-nCoV)`) %>% 
  rename(ventilators =`Кількість апаратів штучної вентиляції легень у закладі охорони здоров'я`) %>% 
  rename(hospital_name =`Назва закладу охорони здоров'я`) %>% 
  select(date, region, district, hospital_id, hospital_name, address, suspected, confirmed, deaths) %>% 
  mutate(date = as.Date(date, format="%Y-%m-%d"))





# Після того, як НСЗУ опублікувала дані на гітхаб, Табло перестали використовувати, нижче старий код, для якого вантажили дані з Табло
#################################################################################### 
# дані з ТАБЛО https://public.tableau.com/profile/publicviz?!/vizhome/monitor_15841091301660/sheet0&fbclid=IwAR0VJF5WxBpx90ilcvCWi98wLxdfwtf-ag7-Rucq5tUhq4Gv3_T6P4_NoUg#!/vizhome/monitor_15841091301660/sheet0

# selfizo_coords = read.csv("selfizo.csv", stringsAsFactors = F) %>% 
#   rename(total_area = region) %>% 
#   rename(lng = lon)
# 
# # colClasses=c("edrpou_hosp"="character")
# setwd('/home/yevheniia/Desktop/')
# 
# # датасет з Табло
# data1 = read.csv("Загальне_data.csv", stringsAsFactors = F, colClasses=c("edrpou_hosp"="character")) %>% 
#   select(-Лікарень, -max.date) %>% 
#   mutate(zvit_date = as.Date(zvit_date, format="%m/%d/%Y"))
# 
# # датасет з координатами лікарень
# data2 = read.csv("Карта_data.csv", stringsAsFactors = F, colClasses=c("edrpou_hosp"="character")) %>% 
#   select(edrpou_hosp, legal_entity_name_hosp, lat, lng)
# 
# hospitals = data2 %>% 
#   select(edrpou_hosp, legal_entity_name_hosp, lat, lng) %>% 
#   filter(edrpou_hosp != "") %>%  
#   unique() %>% 
#   mutate(edrpou_hosp = as.character(edrpou_hosp))
# 
# max_date = max(data1$zvit_date)
# 
# # кількість по регіонам
# get_data_by_region = function(df){
#   data = df %>%
#     select(total_area, new_susp, new_confirm, new_death) %>% 
#     group_by(total_area) %>%
#     mutate(new_susp = sum(new_susp)) %>%
#     mutate(new_confirm = sum(new_confirm)) %>%
#     mutate(new_death = sum(new_death)) %>%
#     ungroup() %>% 
#     unique()
#   return(data)
# }
# 
# # кількість по датах
# get_data_by_date = function(df){
#   data = df %>%
#     select(zvit_date, new_confirm) %>% 
#     group_by(zvit_date) %>% 
#     summarise(new_confirm = sum(new_confirm)) %>% 
#     mutate(comsum = cumsum(new_confirm)) %>% 
#     unique()
#   return(data)
# }
# 
# split_dataset = function(df, var){
#   selfizolation = df %>%
#     filter(edrpou_hosp == "Самоізоляція") %>%
#     left_join(selfizo_coords, by = "total_area") %>%
#     filter(!!(as.name(var)) > 0) %>% 
#     select(edrpou_hosp, !!var, total_area, zvit_date, lat, lng) %>% 
#     uncount(!!(as.name(var))) %>% 
#     mutate(!!(as.name(var)) := 1) %>%
#     mutate(legal_entity_name_hosp = "") %>%
#     select(zvit_date, edrpou_hosp, legal_entity_name_hosp, total_area, lat, lng, !!var)
#   
#   data = df %>% 
#     select(zvit_date, edrpou_hosp, !!var, total_area) %>%
#     filter(edrpou_hosp != "Самоізоляція") %>% 
#     left_join(hospitals, by="edrpou_hosp") %>% 
#     filter(!!(as.name(var)) > 0) %>% 
#     uncount(!!(as.name(var))) %>% 
#     mutate(!!(as.name(var)) := 1) %>% 
#     select(zvit_date, edrpou_hosp, legal_entity_name_hosp, total_area, lat, lng, !!var)
#   
#   data = data %>%  bind_rows(selfizolation) 
#   
#   return(data)
# }
# 
# confirmed = split_dataset(data1, "new_confirm")
# suspected = split_dataset(data1, "new_susp")
# deaths = split_dataset(data1, "new_death")
# by_region = get_data_by_region(data1)
# by_date = get_data_by_date(data1)
# 



#######################################################
# рахуємо час подвоєння по регіонах (напевно це перед тим як малювати на js графіки подвоєння, я їх тут перевіряла, хз для чого цей код)
########################################################
regions_dubble = data1 %>%
  select(date, new_confirm, region) %>% 
  group_by(date, region) %>% 
  summarise(confirmed = sum(confirmed)) %>% 
  ungroup() %>% 
  unique() %>% 
  group_by(region) %>% 
  mutate(cs = cumsum(confirmed)) %>%  
  ungroup() %>% 
  filter(cs > 0)

regions_dubble = split(regions_dubble, regions_dubble$region)

for(i in 1:length(regions_dubble)){
  mindate = min(regions_dubble[[i]]$date)
  mincase = min(regions_dubble[[i]]$cs)
  regions_dubble[[i]] = regions_dubble[[i]] %>% 
    mutate(index = row_number()) %>% 
    mutate(lg = log(2) * index/ log(cs/mincase))
}

new = do.call(rbind, regions_dubble) %>% 
  filter(lg != "Inf") %>% 
  mutate(lg = round(lg, digits=1)) %>% 
  select(-confirmed)

write.csv(new, "regions_dubble.csv", row.names = F)

library("ggplot2")
ggplot(new, aes(y = lg, x = date)) + 
  geom_line(size=1, colour = "#cf1e25")+
  scale_size_manual(values = c(0.2, 1))+
  scale_x_date(limits = as.Date(c("2020-04-01","2020-04-16"))) +
  facet_wrap(.~region) 

theme_minimal() +
  theme(legend.position="none",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold")
  )


