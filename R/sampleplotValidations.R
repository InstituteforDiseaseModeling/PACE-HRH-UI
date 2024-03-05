library(readxl)
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)

get_population_pyramid_plot <- function(rv){
  
  totalpop <- rv$pop_input
  totalpop$age.num = as.numeric(gsub("<", "", totalpop$Age))
  totalpop <- totalpop %>% 
    dplyr::mutate(popLabel = case_when(age.num <= 4 ~ "0-4",
                                       age.num > 4 & age.num <= 9 ~ "5-9",
                                       age.num > 9 & age.num <= 14 ~ "10-14",
                                       age.num > 14 & age.num <= 19 ~ "15-19",
                                       age.num > 19 & age.num <= 24 ~ "20-24",
                                       age.num > 24 & age.num <= 29 ~ "25-29",
                                       age.num > 29 & age.num <= 34 ~ "30-34",
                                       age.num > 34 & age.num <= 39 ~ "35-39",
                                       age.num > 39 & age.num <= 44 ~ "40-44",
                                       age.num > 44 & age.num <= 49 ~ "45-49",
                                       age.num > 49 & age.num <= 54 ~ "50-54",
                                       age.num > 54 & age.num <= 59 ~ "55-59",
                                       age.num > 59 & age.num <= 64 ~ "60-64",
                                       age.num > 64 & age.num <= 69 ~ "65-69",
                                       age.num > 69 & age.num <= 74 ~ "70-74",
                                       age.num > 74 & age.num <= 79 ~ "75-79",
                                       age.num > 79 & age.num <= 84 ~ "80-84",
                                       age.num > 84 & age.num <= 89 ~ "85-89",
                                       age.num > 89 & age.num <= 94 ~ "90-94",
                                       age.num > 94 & age.num <= 99 ~ "95-99",
                                       age.num > 99 ~ "100+"))
  pop_by_group <-  totalpop %>% 
    group_by(popLabel) %>% 
    dplyr::summarise(Male = sum(Male), Female = sum(Female)) %>% 
    pivot_longer(cols = c("Male", "Female"), names_to = "Gender", values_to = "pop_sum") %>% 
    dplyr::mutate(totalpop = sum(pop_sum),
                  pct_pop = pop_sum/totalpop,
                  pct_plot = pct_pop*((Gender=="Female") - (Gender=="Male")))
  
  pop_by_group$popLabel = factor(pop_by_group$popLabel, levels = c("0-4",
                                                                   "5-9",
                                                                   "10-14",
                                                                   "15-19",
                                                                   "20-24",
                                                                   "25-29",
                                                                   "30-34",
                                                                   "35-39",
                                                                   "40-44",
                                                                   "45-49",
                                                                   "50-54",
                                                                   "55-59",
                                                                   "60-64",
                                                                   "65-69",
                                                                   "70-74",
                                                                   "75-79",
                                                                   "80-84",
                                                                   "85-89",
                                                                   "90-94",
                                                                   "95-99",
                                                                   "100+"))
  ymin = min(pop_by_group$pct_plot) - 0.05
  ymax = max(pop_by_group$pct_plot + 0.05)
  
  ggplot() +
    geom_bar(data = pop_by_group, aes(x = popLabel, y = pct_plot, fill = Gender), stat = "identity") +
    geom_text(data = pop_by_group[pop_by_group$Gender=="Female",], aes(x = popLabel, label = paste0(abs(round(pct_plot*100,0)), "%"), y = pct_plot), color = "grey50", hjust = -0.5) +
    geom_text(data = pop_by_group[pop_by_group$Gender=="Male",], aes(x = popLabel, label = paste0(abs(round(pct_plot*100,0)), "%"), y = pct_plot), color = "grey50", hjust = 1.5) +
    ylim(ymin, ymax) +
    coord_flip() + 
    theme_minimal() +
    theme(axis.text.x = element_blank()) +
    labs(y = "percentage of total population", x = "Population age group")
  
  
}

# Validation plot 2: fertility rates
get_fertility_rates_plot <- function(rv){
  
  popvalues <- rv$pop_values
  popvalues$SexLabel[popvalues$Sex=="F"] <- "Female"
  popvalues$SexLabel[popvalues$Sex=="M"] <- "Male"
  
  second_y_scalefactor <-  1000
  fertilityrates <- popvalues %>% 
    filter(Type == "Fertility") %>% 
    dplyr::mutate(ageband = paste0(SexLabel, ",\n", " Ages ", BandStart, "-", BandEnd)) %>% 
    dplyr::mutate(delta = ChangeRate - 1,
                  births_per_thousand = InitValue*second_y_scalefactor) 
  
  ggplot() +
    geom_point(data = fertilityrates, aes(x = ageband, y = births_per_thousand), shape = 8, size = 3) +
    geom_text(data = fertilityrates, aes(x = ageband, y = births_per_thousand, label = paste0(births_per_thousand, " births")), vjust = -1) +
    geom_bar(data = fertilityrates, aes(x = ageband, y = delta*second_y_scalefactor), stat = "identity") +
    geom_text(data = fertilityrates, aes(x = ageband, y = delta*second_y_scalefactor, label = paste0(round((delta*100),1), "%")), vjust = 1.5) +
    scale_x_discrete(guide = guide_axis(position = "top")) +
    scale_y_continuous(name = paste0("Number of births per ", second_y_scalefactor, " people in the age group"), 
                       sec.axis = sec_axis(~./second_y_scalefactor, name = "year-on-year rate of change on fertility rates, by the age group")) +
    theme_bw() +
    theme(axis.title.y.left = element_text(vjust = 2), 
          axis.title.y.right = element_text(vjust = 2)) +
    labs(x = NULL, title = "Fertility rates and annual change in fertility rates, by age groups")
  
  
}


# Validation plot 3: mortality rates
get_mortality_rates_plot  <- function(rv){
  popvalues <- rv$pop_values
  popvalues$SexLabel[popvalues$Sex=="F"] <- "Female"
  popvalues$SexLabel[popvalues$Sex=="M"] <- "Male"
  second_y_scalefactor <-  10000
  mortalityrates <- popvalues %>% 
    filter(Type == "Mortality") %>% 
    dplyr::mutate(ageband = paste0(SexLabel, ",\n", "Ages ", BandStart, "-", BandEnd)) %>% 
    dplyr::mutate(delta = ChangeRate -1,
                  deaths_per_10k = InitValue*second_y_scalefactor)
  mortalityrates[mortalityrates$Sex=="F" & mortalityrates$BandStart==0,]$ageband = paste0("Female", ",\n", "infants") 
  mortalityrates[mortalityrates$Sex=="M" & mortalityrates$BandStart==0,]$ageband = paste0("Male", ",\n", "infants") 
  mortalityrates$ageband = factor(mortalityrates$ageband, levels = c(paste0("Female", ",\n", "infants"), 
                                                                     paste0("Male", ",\n", "infants"), 
                                                                     paste0("Female", ",\n", "Ages 1-4"), 
                                                                     paste0("Male", ",\n", "Ages 1-4"),
                                                                     paste0("Female", ",\n", "Ages 5-9"), 
                                                                     paste0("Male", ",\n", "Ages 5-9"),
                                                                     paste0("Female", ",\n", "Ages 10-14"), 
                                                                     paste0("Male", ",\n", "Ages 10-14"),
                                                                     paste0("Female", ",\n", "Ages 15-19"), 
                                                                     paste0("Male", ",\n", "Ages 15-19"),
                                                                     paste0("Female", ",\n", "Ages 20-34"), 
                                                                     paste0("Male", ",\n", "Ages 20-34"),
                                                                     paste0("Female", ",\n", "Ages 35-49"), 
                                                                     paste0("Male", ",\n", "Ages 35-49"),
                                                                     paste0("Female", ",\n", "Ages 50-59"), 
                                                                     paste0("Male", ",\n", "Ages 50-59"),
                                                                     paste0("Female", ",\n", "Ages 60-74"), 
                                                                     paste0("Male", ",\n", "Ages 60-74"),
                                                                     paste0("Female", ",\n", "Ages 75-100"), 
                                                                     paste0("Male", ",\n", "Ages 75-100")))
  
  ## choose y-limits for plot to display properly
  ymin = min(mortalityrates$delta)*second_y_scalefactor*1.05
  ymax = max(mortalityrates$deaths_per_10k)*1.05
  
  ggplot(data = mortalityrates) +
    geom_point(aes(x = ageband, y = deaths_per_10k), shape = 8, size = 3) +
    geom_text(aes(x = ageband, y = deaths_per_10k, label = paste0(round(deaths_per_10k), " deaths")), vjust = -1) +
    geom_bar(aes(x = ageband, y = delta*second_y_scalefactor), stat = "identity") +
    geom_text(aes(x = ageband, y = delta*second_y_scalefactor, label = paste0(round((delta*100),1), "%")), vjust = 1.5) +
    scale_x_discrete(guide = guide_axis(position = "top")) +
    scale_y_continuous(name = paste0("Number of deaths per ", second_y_scalefactor, " population base in the age group"),
                       limits = c(ymin, ymax),
                       sec.axis = sec_axis(~./second_y_scalefactor, name = "year-on-year rate of change on mortality rates, by age group")) +
    facet_wrap(~ SexLabel, scales = "free_x", ncol = 1) +
    theme_bw() +
    theme(axis.title.y.left = element_text(vjust = 3), axis.title.y.right = element_text(vjust = 3),
          plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "inches")) +
    labs(x = NULL, title = "Mortality rates and annual change in mortality rates, by age groups")

}

# Validation plot 4: seasonality curves
get_seasonality_validation_plot <- function(rv){
  totalpop <- rv$pop_input
  popvalues <- rv$pop_values
  seasonalitytable  <- rv$seasonality_input
  
  
  seasonalitytable$Month = factor(seasonalitytable$Month, 
                                  levels = c("Jan", "Feb", "Mar", "Apr", "May", "June",
                                             "July", "Aug", "Sept", "Oct", "Nov", "Dec"))
  seasonalitycurves <- seasonalitytable %>% 
    pivot_longer(cols = !Month, names_to = "CurveName", values_to = "Seasonality")
  
  ggplot(data = seasonalitycurves, aes(x = Month, y = Seasonality)) +
    geom_point() +
    ylim(0, NA) +
    facet_wrap(~CurveName, ncol = 1) +
    theme_bw() +
    labs(x = "Month", y = "Seasonality (monthly share of the yearly total)") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
          plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "inches")) 
  
}

get_pdf_report_validation <- function(rv){
  # print to pdf
  current_datetime <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  filename <- file.path(result_root, paste0("report_", current_datetime, ".pdf"))
  pdf(file = filename, width = 11, height = 8.5)
  p1 <- get_mortality_rates_plot(rv)
  p2 <- et_seasonality_validation_plot(rv)
  print(p1)
  print(p2)
  dev.off()
  return (filename)
}


