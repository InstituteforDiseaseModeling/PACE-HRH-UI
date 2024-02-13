library(readxl)
library(plyr)
library(dplyr)
library(tidyr)
library(ggplot2)

# Specify the path to model inputs Excel file
input_file <- "config/model_inputs_demo.xlsx"

# Validation plot 1: population pyramid
sheet_name <- "TotalPop"

# Import the specified sheet from the Excel file
totalpop <- read_excel(input_file, sheet = sheet_name)
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




