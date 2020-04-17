library("dplyr")
library("tidyr")
library('xlsx')
library("readxl")

setwd('/home/yevheniia/git/2020_YEAR/covid-19/data/source-data/ukraine/')
selfizo_coords = read.csv("selfizo.csv", stringsAsFactors = F)
# colClasses=c("edrpou_hosp"="character")
setwd('/home/yevheniia/Desktop/')
# датасет з Табло
data1 = read.csv("Загальне_data.csv", stringsAsFactors = F, colClasses=c("edrpou_hosp"="character")) %>% 
  rename(recovered = new_recover) %>% 
  rename(confirmed = new_confirm) %>% 
  rename(suspected = new_susp) %>% 
  rename(deaths = new_death) %>% 
  rename(date=zvit_date) %>% 
  rename(hospital_id = edrpou_hosp) %>% 
  rename(region = total_area) %>% 
  select(-Лікарень, -max.date) %>% 
  mutate(date = as.Date(date, format="%m/%d/%Y"))

# датасет з координатами лікарень
data2 = read.csv("Карта_data.csv", stringsAsFactors = F, colClasses=c("edrpou_hosp"="character")) %>% 
  # rename(recovered = Кількість.випадків.одужання.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  # rename(confirmed = Кількість.осіб.із.підтвердженим.діагнозом.COVID.19..спричиненим.коронавірусом.SARS.CoV.2..2019.nCoV...які.перебувають.на.лікува) %>% 
  # rename(waiting = Кількість.осіб.з.підозрою.на.зараження.коронавірусом.SARS.CoV.2..2019.nCoV...випадки.яких.очікують.лабораторного.підтвердження) %>% 
  # rename(deaths = Кількість.смертельних.випадків.серед.осіб.із.підтвердженим.діагнозом.COVID.19.протягом.звітного.періоду) %>% 
  rename(lat = lat) %>% 
  rename(lon = lng) %>% 
  # rename(address = addresses) %>% 
  rename(hospital_id = edrpou_hosp) %>% 
  rename(hospital_name = legal_entity_name_hosp) %>% 
  select(hospital_id, hospital_name, lat, lon)

hospitals = data2 %>% 
  select(hospital_id, hospital_name, lat, lon) %>% 
  filter(hospital_id != "") %>%  
  unique() %>% 
  mutate(hospital_id = as.character(hospital_id))


max_date = max(data1$date)

h1 = data1 %>%  filter(hospital_id != "Самоізоляція") %>% select(hospital_id) %>% unique()
h2 = data2 %>%  select(hospital_id) %>% unique()

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



# split_dataset = function(df, var){
#   selfizolation = df %>%
#     filter(hospital_id == "Самоізоляція") %>%
#     left_join(selfizo_coords, by = "region") %>%
#     filter(!!(as.name(var)) > 0)
#     
#   
#   if(NROW(selfizolation) > 0){
#     selfizolation = selfizolation %>%
#       group_by(date, hospital_id, region, lat, lon) %>%
#       expand(!!var := seq(1:!!(as.name(var)))) %>%
#       ungroup() %>%
#       mutate(!!(as.name(var)) := 1) %>%
#       mutate(hospital_name = "") %>%
#       select(date, hospital_id, hospital_name, region, lat, lon, !!var)
#   }
#   
#   data = df %>% 
#     select(date, hospital_id, !!var, region) %>%
#     filter(hospital_id != "Самоізоляція") %>% 
#     left_join(hospitals, by="hospital_id") %>% 
#     filter(!!(as.name(var)) > 0) %>% 
#     group_by(date, hospital_id, hospital_name, region, lat, lon, !!(as.name(var))) %>% 
#     expand(!!var := seq(1:!!(as.name(var)))) %>% 
#     ungroup() %>% 
#     mutate(!!(as.name(var)) := 1)
#   
#   if(NROW(selfizolation) > 0){
#     data = data %>%  bind_rows(selfizolation) 
#   } else {
#     data = data
#   }
#   return(data)
# }

split_dataset = function(df, var){
  selfizolation = df %>%
    filter(hospital_id == "Самоізоляція") %>%
    left_join(selfizo_coords, by = "region") %>%
    filter(!!(as.name(var)) > 0) %>% 
    select(hospital_id, !!var,region, date, lat, lon) %>% 
    uncount(!!(as.name(var))) %>% 
    mutate(!!(as.name(var)) := 1) %>%
    mutate(hospital_name = "") %>%
    select(date, hospital_id, hospital_name, region, lat, lon, !!var)
  
  data = df %>% 
    select(date, hospital_id, !!var, region) %>%
    filter(hospital_id != "Самоізоляція") %>% 
    left_join(hospitals, by="hospital_id") %>% 
    filter(!!(as.name(var)) > 0) %>% 
    uncount(!!(as.name(var))) %>% 
    mutate(!!(as.name(var)) := 1) %>% 
    select(date, hospital_id, hospital_name, region, lat, lon, !!var)
  
  data = data %>%  bind_rows(selfizolation) 
  
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

#######################################################
# рахуємо час подвоєння по регіонах
########################################################


regions_dubble = data1 %>%
  select(date, confirmed, region) %>% 
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
  
  
  #################################################################################### 