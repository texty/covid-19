# Хороший датасет поки відсутній, юзаємо оці два ресурси

# data source: https://public.tableau.com/profile/publicviz#!/vizhome/monitor_15841091301660/sheet0
# https://github.com/quazerro/COVID-19_ukr (Остап)

library("dplyr")
library("tidyr")
library('xlsx')
library("readxl")

setwd('/home/yevheniia/git/2020_YEAR/covid-19/data/source-data/ukraine/')
xlsx_ <- read_excel("monitoring_v4_2020-04-03.xlsx", sheet=1, col_names = TRUE,col_types=NULL, na="") %>% 
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
data2 = read.csv("Карта_data.csv", stringsAsFactors = F) %>% 
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

# перелік лікарень (унікальні значення)
hospitals = data2 %>% 
  select(hospital_id, hospital_name, lat, lon, address) %>% 
  filter(hospital_id != "самоізоляція") %>%  
  unique()

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

confirmed = split_dataset(xlsx_, "confirmed")
suspected = split_dataset(xlsx_, "suspected")
deaths = split_dataset(xlsx_, "deaths")
by_region = get_data_by_region(xlsx_)
by_date = get_data_by_date(xlsx_)

setwd("/home/yevheniia/git/2020_YEAR/covid-19/data/ukraine/")
write.csv(by_date, "cases_by_date.csv", row.names = F)
write.csv(by_region, "cases_by_region.csv", row.names = F)
write.csv(confirmed, "confirmed_cases.csv", row.names = F)
write.csv(suspected, "suspected_cases.csv", row.names = F)
write.csv(deaths, "death_cases.csv", row.names = F)






