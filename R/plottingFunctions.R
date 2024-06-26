library(pacehrh)
library(plotly)
library(treemapify)
library(mgcv)

# ------------------Fertility Plot --------------------
get_fertility_rates_time_series_plot <- function(rv) {
  StartYear <-  rv$start_year 
  EndYear <-  rv$end_year 
  
  age20_39 <- c("AnnualBirthRate20_24", "AnnualBirthRate25_29", "AnnualBirthRate30_34", "AnnualBirthRate35_39")
  rates_sim <- rv$fertilityrates %>% 
    filter(Year >= StartYear & Year <= EndYear) %>% 
    filter(Label %in% age20_39)
  plot <- ggplot(rates_sim, aes(x = Year, y = Rate, color = Label, group = Year)) +
    theme_bw() +
    geom_boxplot() +
    theme(legend.position = "none", axis.text.x = element_text(angle=-90, vjust = .5, hjust=1)) +
    facet_grid(Label ~ test_name)
  ggplotly(plot)
}


#--------------------Population plot------------------

get_population_plot <- function(rv) {
  StartYear <-  rv$start_year 
  EndYear <-  rv$end_year 
  
  pop_sim <- rv$popsummary %>%
    group_by(test_name, Year, Gender, Age) %>%
    dplyr::summarize(Population=mean(Population)) %>% 
    filter(Year == StartYear | Year == EndYear) %>% 
    group_by(test_name, Year) %>% 
    mutate(totalpop = sum(Population)) %>% 
    group_by(test_name) %>% 
    mutate(startpop = round(min(totalpop),0), endpop = round(max(totalpop),0)) %>% 
    mutate(Scenario_label = paste(test_name, 
                                  format(startpop, big.mark = ","),
                                  "Start Pop",
                                  format(endpop, big.mark = ","),
                                  "End Pop",
                                  sep=" "))
  
  plot <- ggplot()+
    theme_bw()+
    geom_point(data = pop_sim, aes(x=Age, y=Population, color=Gender, shape=as.factor(Year)), position = "jitter")+
    facet_wrap(~Scenario_label) +
    labs(color = "Gender", shape = "Year")
  ggplotly(plot)
  
}



# -----------------Slide 4 plot---------------------
get_slide_4_plot <- function(rv, plotly=TRUE){
 
  StartYear <-  rv$start_year + 1
  EndYear <-  rv$end_year 
  
  temp_clin <- rv$Mean_ClinCat %>%
    filter(Year >= StartYear & Year <= EndYear) %>% 
    mutate(Category = case_when(
      ClinicalOrNon != "Clinical" ~ ClinicalOrNon,
      ClinicalOrNon == "Clinical" ~ paste("Clinical -", ClinicalCat))) %>%
    mutate(Alpha = case_when(
      ClinicalOrNon == "Clinical" ~ 0.3,
      ClinicalOrNon != "Clinical" ~ 1)) %>%
    mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep=""))
  temp_clin$Category <- factor(temp_clin$Category,ordered=TRUE,levels=unique(temp_clin$Category))
  
  temp_total <- rv$Mean_Total %>%
    filter(Year >= StartYear & Year <= EndYear) %>% 
    mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep=""))
  
  ylabel <- "Hours per Week for Catchment Pop"
  maxyval <- max(rv$Mean_Total$CI95/rv$Mean_Total$WeeksPerYr)*1.05
  
  plot <- ggplot()+
    geom_bar(data = temp_clin, aes(x=Year,y=MeanHrs/WeeksPerYr,fill=Category),stat="identity",alpha=.9)+
    geom_line(data = temp_total, aes(x=Year,y=MeanHrs/WeeksPerYr),linewidth=1.2)+
    geom_point(data = temp_total, aes(x=Year,y=MeanHrs/WeeksPerYr))+
    geom_errorbar(data =temp_total, aes(x=Year,ymin=CI05/WeeksPerYr, ymax=CI95/WeeksPerYr), colour="black", width=.3)+
    ylim(0,maxyval)+
    theme_bw()+
    theme(axis.text.x = element_text(angle=-90, vjust = .5, hjust=1), legend.title=element_blank(), strip.text = element_text(size=12,margin=margin(1,1,1,1,"cm")))+
    labs(y=ylabel,x="")+
    scale_fill_viridis_d()+
    facet_wrap(~Scenario_label,labeller=labeller(Scenario_label=label_wrap_gen(40)))
  
  if(plotly){
    ggplotly(plot)
  }
  else{
    plot
  }
  
}

# -----------------by ServiceCat bar plot---------------------
byServiceCat_plot <- function(rv, plotly=TRUE){

  StartYear <-  rv$start_year + 1 
  EndYear <-  rv$end_year 
  
  ServiceCat_Clinical <- rv$Mean_ServiceCat %>%
    subset(ClinicalOrNon=="Clinical") %>%
    filter(Year >= StartYear & Year <= EndYear) %>% 
    dplyr::mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep="")) %>%
    group_by(Scenario_label, Year) %>%
    dplyr::mutate(TotalHrs=sum(MeanHrs)) 
  
  temp_TotClin <- rv$Stats_TotClin %>% 
    filter(Year >= StartYear & Year <= EndYear) %>% 
    dplyr::mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep=""))
  
  ymax <- max(temp_TotClin$CI95/temp_TotClin$WeeksPerYr)*1.05
  
  plot <- ggplot() +
    theme_bw()+
    geom_bar(data=ServiceCat_Clinical,aes(x=Year,y=MeanHrs/WeeksPerYr,fill=ServiceCat),stat="identity",alpha=.9)+
    geom_line(data=temp_TotClin,aes(x=Year,y=CI50/WeeksPerYr),linewidth=1.2)+
    geom_point(data=temp_TotClin,aes(x=Year,y=CI50/WeeksPerYr))+
    geom_errorbar(data=temp_TotClin,aes(x=Year,ymin=CI05/WeeksPerYr, ymax=CI95/WeeksPerYr), colour="black", width=.3)+
    ylim(0, ymax) +
    facet_wrap(~Scenario_label,labeller=labeller(Scenario_label=label_wrap_gen(40))) +
    theme(axis.text.x = element_text(angle=-90, vjust = .5, hjust=1))+
    theme(legend.position = c(0.02, 1), legend.justification = c(0.02, 1), legend.key.size=unit(0.3, 'cm'), legend.direction="vertical", legend.background = element_rect(fill = 'transparent'))+
    theme(axis.text.x = element_text(angle=-90, vjust = .5, hjust=1), legend.title=element_blank(), strip.text = element_text(size=12,margin=margin(1,1,1,1,"cm")))+
    scale_fill_brewer(palette = "BrBG", direction = -1)+
    labs(x="", y="Hours per Week for Catchment Pop")
  
  if(plotly){
    ggplotly(plot)
  } else{
    plot
  }
  
}

byCadreRoles_plot <-  function(rv, plotly=TRUE){

  StartYear <-  rv$start_year + 1 
  EndYear <-  rv$end_year 
  
  Cadre_labelled <- rv$Mean_Alloc %>% 
    filter(CI50!=0 ) %>% 
    group_by(test_name, Year) %>% 
    dplyr::mutate(sum_CI50 = sum(CI50), sum_CI05 = sum(CI05), sum_CI95 = sum(CI95)) 
  
  plot <-  ggplot(data=Cadre_labelled)+
    geom_bar(aes(x=Year,y=CI50/WeeksPerYr,fill=RoleDescription),stat="identity",alpha=.9)+
    geom_line(aes(x=Year,y=sum_CI50/WeeksPerYr),linewidth=1.2)+
    geom_point(aes(x=Year,y=sum_CI50/WeeksPerYr))+
    geom_errorbar(aes(x=Year,ymin=sum_CI05/WeeksPerYr, ymax=sum_CI95/WeeksPerYr), colour="black", width=.3)+
    theme_bw()+
    scale_x_continuous(breaks =  c(2021,2025, 2030, 2035))+
    theme(legend.title=element_blank(),legend.position = c(0.02, 0.99), legend.justification = c(0.02, 0.99), 
          legend.key.size=unit(0.3, 'cm'), legend.direction="vertical", legend.background = element_rect(fill = 'transparent'))+
    scale_fill_brewer(palette = "Paired", direction = -1)+
    facet_wrap(~test_name)+
    labs(x="Year", y="Hours per Week per 5,000 Pop", fill = "Cadre")
  print(plot)
  
  
  if(plotly){
    ggplotly(plot)
  } else{
    plot
  }
  
}


# -----------------by ServiceCat tile plot---------------------
byServiceTile_plot <- function(rv, plotly=TRUE){

  StartYear <-  rv$start_year + 1
  EndYear <-  rv$end_year 
  
  temp_ServiceCat <- rv$Mean_ServiceCat %>% 
    filter(Year >= StartYear & Year <= EndYear) %>% 
    dplyr::mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep="")) %>%
    mutate(ServiceLabel = case_when(
      ServiceCat == "Family planning" ~ "Family planning",
      ServiceCat == "Immunization" ~ "Immunization",
      ServiceCat == "Overhead 1" | ServiceCat == "Overhead 2" ~ "Admin",
      ServiceCat == "Record keeping" ~ "Records",
      ServiceCat == "Nutrition" ~ "Nutrition",
      ServiceCat == "NCDs" ~ "NCD",
      ServiceCat == "Sick child" ~ "IMNCI",
      ServiceCat == "Disease surveillance for reportable diseases" ~ "Surveillance", 
      T ~ ServiceCat)) %>% 
    filter(ClinicalOrNon == "Clinical") %>%
    group_by(Year)
  
  # p <- ggplot(temp_ServiceCat,aes(area=MeanHrs,fill=ServiceLabel,label=ServiceLabel,subgroup=ServiceLabel))+
  #   geom_treemap()+geom_treemap_text(color="black",place="center",size=16)+
  #   geom_treemap_subgroup_border(color="black",size=2.5)+
  #   facet_wrap(~test_name) +
  #   theme_bw()+theme(legend.position = "none")+
  #   scale_fill_viridis_d()+
  #   theme(strip.text = element_text(size = 16))
  
  temp_ServiceCatTotal <- rv$Mean_ServiceCat %>%
    filter(ClinicalOrNon == "Clinical") %>%
    group_by(Year) %>%
    summarize(TotalValue = sum(MeanHrs,na.rm=TRUE)) 
  
  temp_ServiceCat$Denominator = temp_ServiceCatTotal$TotalValue[match(temp_ServiceCat$Year,temp_ServiceCatTotal$Year)]
  
  plot <- ggplot(temp_ServiceCat,aes(x=Year,y=MeanHrs/Denominator,fill=ServiceLabel))+
    geom_bar(stat="identity",position="fill")+
    theme_bw() + 
    scale_fill_viridis_d()+
    geom_text(aes(label=paste(round(MeanHrs/Denominator*100,0),sep="")), position = position_fill(vjust = 0.5))+
    facet_wrap(~Scenario_label,labeller=labeller(Scenario_label=label_wrap_gen(40))) +
    theme(axis.text.x = element_text(angle=-90, vjust = .5, hjust=1), legend.title=element_blank(), strip.text = element_text(size=12,margin=margin(1,1,1,1,"cm")))+
    xlab("")+ylab("% of workload by type")+
    labs(fill="Service")+
    scale_y_continuous(labels = scales::percent)
  
  if(plotly){
    ggplotly(plot)
  } else{
    plot
  }
  
}

# -----------------service over time plot---------------------
serviceOverTime_plot <- function(rv, plotly=TRUE){

  StartYear <-  rv$start_year + 1
  EndYear <-  rv$end_year  
  
  ServiceCat_Clinical <- rv$Mean_ServiceCat %>%
    subset(ClinicalOrNon=="Clinical") %>%
    filter(Year >= StartYear & Year <= EndYear) %>% 
    dplyr::mutate(Scenario_label = paste(test_name, " - Starting Pop=", format(BaselinePop, big.mark = ",")," - Hrs Per Week=",HrsPerWeek," - Weeks Per Year=",WeeksPerYr,sep="")) %>%
    group_by(Scenario_label, ServiceCat) %>% 
    dplyr::mutate(MeanHrs_Start = dplyr::first(MeanHrs), RatioTo1 = MeanHrs/MeanHrs_Start) %>% 
    dplyr::mutate(RatioLabel = case_when(
      Year == max(Year) ~ paste(ServiceCat, round(RatioTo1,1), sep = ","))) 
  
  ServiceCat_Clinical$ServiceCat = as.factor(ServiceCat_Clinical$ServiceCat)
  
  plot <- ggplot(ServiceCat_Clinical,aes(x=Year,y=RatioTo1,group=ServiceCat,label=round(RatioTo1,2)) )+
    geom_line(aes(color=ServiceCat),size=1.1) +
    geom_hline(yintercept = 1,color="black") +
    theme_bw() +
    scale_color_discrete()+
    geom_text(data=subset(ServiceCat_Clinical,Year==max(ServiceCat_Clinical$Year))) +
    facet_wrap(~Scenario_label,labeller=labeller(Scenario_label=label_wrap_gen(40))) +
    theme(axis.text.x = element_text(angle=-90, vjust = .5, hjust=1), legend.title=element_blank(), strip.text = element_text(size=12,margin=margin(1,1,1,1,"cm")))+
    labs(x = "", y = "Ratio of Workload vs. Baseline Year")
  
  if(plotly){
    ggplotly(plot)
  } else{
    plot
  }
  
}


# -----------------seasonality plot---------------------
seasonality_plot <- function(rv, plotly=TRUE){
 
  StartYear <-  rv$start_year + 1
  EndYear <-  rv$end_year  
  
  Monthly_NonClinical <- rv$Mean_ClinCat %>% 
    subset(ClinicalOrNon != "Clinical") %>% 
    group_by(test_name, Year) %>% 
    dplyr::summarize(NonClinical_Monthly = sum(MeanHrs)/12)
  
  RatioToAvg_ByMonth <- rv$ByRun_ClinMonth %>% 
    subset(Year == EndYear) %>% 
    left_join(Monthly_NonClinical, by = c("test_name", "Year"))  %>% 
    dplyr::mutate(NonClinical_Monthly = replace_na(NonClinical_Monthly,0)) %>% 
    group_by(test_name, Trial_num, Year) %>% 
    dplyr::mutate(MeanMonthHrs = (mean(TotHrs)+NonClinical_Monthly), RatioToMean = (TotHrs+NonClinical_Monthly)/(MeanMonthHrs)) %>% 
    ungroup() %>% 
    group_by(test_name, Month) %>% 
    dplyr::summarize(RatioToMean_p05 = quantile(RatioToMean, 0.05),
                     RatioToMean_p25 = quantile(RatioToMean, 0.25),
                     RatioToMean_p50 = quantile(RatioToMean, 0.50),
                     RatioToMean_p75 = quantile(RatioToMean, 0.75),
                     RatioToMean_p95 = quantile(RatioToMean, 0.95))
  
  plot <- ggplot(data=RatioToAvg_ByMonth)+
    theme_bw()+
    geom_smooth(aes(x = Month, y=RatioToMean_p50), method ="loess",se=TRUE, fill = "#80B1D3", span=0.5, alpha = 0.25)+
    geom_hline(yintercept = 1, color = "blue", linetype="dashed")+
    scale_color_manual("#80B1D3")+
    scale_x_continuous(breaks =  seq(1, 12))+
    facet_wrap(~test_name)+
    labs(x = "Month", y="Ratio of workload for the month to annual average")
  
  if(plotly){
    ggplotly(plot)
  } else{
    plot
  }
  
}



get_pdf_report <- function(rv){
  # print to pdf
  current_datetime <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
  filename <- file.path(result_root, paste0("report_", current_datetime, ".pdf"))
  scenariocount = length(unique(rv$Mean_ServiceCat$test_name))
  pdf(file = filename, width = (scenariocount * 9.5), height = 8)
  p1 <- get_slide_4_plot(rv, plotly = FALSE)
  p2 <- byServiceCat_plot(rv, plotly = FALSE)
  p3 <- byServiceTile_plot(rv, plotly = FALSE)
  p4 <- serviceOverTime_plot(rv, plotly = FALSE)
  p5 <- seasonality_plot(rv, plotly = FALSE)
  print(p1)
  print(p2)
  print(p3)
  print(p4)
  print(p5)
  dev.off()
  return (filename)
}
