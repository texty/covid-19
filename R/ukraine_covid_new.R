# перейшли з Табло на дані НСЗУ з гітхабу
library("dplyr")
library("tidyr")
library("ggplot2")

getwd()
nszy = read.csv("https://raw.githubusercontent.com/VasiaPiven/covid19_ua/master/covid19_by_area_type_hosp_dynamics.csv", stringsAsFactors = F) %>% 
  mutate(zvit_date = as.Date(zvit_date, format="%Y-%m-%d"))

setwd('/home/yevheniia/git/2020_YEAR/covid-19/data/source-data/ukraine/')
selfizo_coords = read.csv("selfizo.csv", stringsAsFactors = F) %>% 
  rename(priority_hosp_area = region) %>% 
  rename(legal_entity_lng = lon) %>% 
  rename(legal_entity_lat = lat)

split_dataset = function(df, var){
  selfizolation = df %>%
    filter(edrpou_hosp == "Самоізоляція") %>%
    select(-legal_entity_lat, -legal_entity_lng) %>% 
    left_join(selfizo_coords, by = "priority_hosp_area") %>%
    filter(!!(as.name(var)) > 0) %>% 
    select(edrpou_hosp, !!var, priority_hosp_area, zvit_date, legal_entity_lat, legal_entity_lng) %>% 
    uncount(!!(as.name(var))) %>% 
    mutate(!!(as.name(var)) := 1) %>%
    mutate(legal_entity_name_hosp = "") %>%
    mutate(legal_entity_lat = as.numeric(legal_entity_lat)) %>% 
    mutate(legal_entity_lng = as.numeric(legal_entity_lng)) %>% 
    select(zvit_date, edrpou_hosp, legal_entity_name_hosp, priority_hosp_area, legal_entity_lat, legal_entity_lng, !!var)
  
  data = df %>% 
    filter(edrpou_hosp != "Самоізоляція") %>% 
    filter(!!(as.name(var)) > 0) %>% 
    uncount(!!(as.name(var))) %>% 
    mutate(!!(as.name(var)) := 1) %>% 
    mutate(legal_entity_lat = as.numeric(legal_entity_lat)) %>% 
    mutate(legal_entity_lng = as.numeric(legal_entity_lng)) %>% 
    select(zvit_date, edrpou_hosp, legal_entity_name_hosp, priority_hosp_area, legal_entity_lat, legal_entity_lng, !!var)
  
  data = data %>%  bind_rows(selfizolation) 
  
  return(data)
}

# кількість по регіонам

get_data_by_region = function(df){
  is_medical = nszy %>% 
    filter(new_confirm > 0) %>% 
    filter(is_medical_worker == "Так") %>% 
    group_by(priority_hosp_area) %>% 
    summarize(is_medical = sum(new_confirm))
  
  data = df %>%
    select(priority_hosp_area, new_susp, new_confirm, new_death) %>% 
    group_by(priority_hosp_area) %>%
    mutate(new_susp = sum(new_susp)) %>%
    mutate(new_confirm = sum(new_confirm)) %>%
    mutate(new_death = sum(new_death)) %>%
    ungroup() %>% 
    unique() %>% 
    left_join(is_medical, by = "priority_hosp_area") %>% 
    mutate(med_percent = is_medical/(new_confirm/100))
  
  data[is.na(data)] <- 0
  
  return(data)
}

# кількість по датах
get_data_by_date = function(df){
  data = df %>%
    select(zvit_date, new_confirm) %>% 
    group_by(zvit_date) %>% 
    summarise(new_confirm = sum(new_confirm)) %>% 
    mutate(comsum = cumsum(new_confirm)) %>% 
    unique()
  return(data)
}

is_medical_by_date = function(){
  is_medical = nszy %>% 
    filter(new_confirm > 0) %>% 
    filter(is_medical_worker == "Так") %>% 
    select(zvit_date, new_confirm, is_medical_worker, priority_hosp_area) %>% 
    group_by(zvit_date, priority_hosp_area) %>% 
    mutate(is_medical = sum(new_confirm)) %>%
    ungroup() %>% 
    select(-new_confirm) %>% 
    unique() %>% 
    select(-is_medical_worker)

  
  total = nszy %>% 
    filter(new_confirm > 0) %>% 
    select(zvit_date, new_confirm, priority_hosp_area) %>% 
    group_by(zvit_date, priority_hosp_area) %>% 
    mutate(new_confirm = sum(new_confirm)) %>%
    ungroup() %>% 
    unique() %>% 
    left_join(is_medical, by=c("zvit_date", "priority_hosp_area")) %>% 
    mutate(is_medical = ifelse(is.na(is_medical), 0, is_medical)) %>% 
    group_by(priority_hosp_area) %>% 
    arrange(zvit_date) %>% 
    mutate(confirm_cumsum = cumsum(new_confirm)) %>% 
    mutate(medical_comsum = cumsum(is_medical)) %>% 
    mutate(medical_percent = medical_comsum/(confirm_cumsum/100)) %>% 
    mutate(medical_total = sum(is_medical)) %>% 
    mutate(confirm_total = sum(new_confirm)) %>% 
    mutate(percent_total = medical_total/(confirm_total/100)) %>% 
    # select(zvit_date, priority_hosp_area, new_confirm, is_medical, confirm_cumsum, medical_comsum, medical_percent)
    select(zvit_date, priority_hosp_area, is_medical, medical_comsum, medical_percent, medical_total, percent_total)
  
  
  return(total)
}

medical = is_medical_by_date()
confirmed = split_dataset(nszy, "new_confirm")
suspected = split_dataset(nszy, "new_susp")
deaths = split_dataset(nszy, "new_death")
by_region = get_data_by_region(nszy)
by_date = get_data_by_date(nszy)


setwd("/home/yevheniia/git/2020_YEAR/covid-19/data/ukraine/")
write.csv(by_date, "cases_by_date.csv", row.names = F)
write.csv(by_region, "cases_by_region.csv", row.names = F)
write.csv(confirmed, "confirmed_cases.csv", row.names = F)
write.csv(suspected, "suspected_cases.csv", row.names = F)
write.csv(deaths, "death_cases.csv", row.names = F)
write.csv(medical, "medical.csv", row.names = F)

# отут є дані по к-ті лікарів в лікарнях і медперсоналу, а також ШВЛ та інше забезпечення: https://covid19.gov.ua/vidkryti-dani
# data = read.csv("https://covid19.gov.ua/csv/data.csv")

  

