#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Name: waterLevel organization
# Coder: C. Nathan Jones
# Date: 6/18/2020
# Purpose: Create script to gather/organize waterLevel data 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#1.0 Setup Worskspace-----------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#clear environment
remove(list=ls())

#load relevant packages
library(patchwork)
library(lubridate)
library(tidyverse)

#Define working dir
data_dir<-"C:/Users/cnjones7/Box Sync/My Folders/Research Projects/SWI/PT_Data/"
output_dir<-"C:/Users/cnjones7/Box Sync/My Folders/Research Projects/SWI/Processed_Data/"

#Set system time zone 
Sys.setenv(TZ="America/New_York")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#2.0 Download data--------------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#DEfine waterLevel files
files<-list.files(data_dir, full.names = TRUE, recursive = TRUE)
files<-files[str_detect(files, "waterLevel")]

#Download data
df<-lapply(files,read_csv) %>% 
  bind_rows() %>% 
  drop_na() 

#Make into wide format!
output<-df %>% 
  pivot_wider(names_from = Site_Name, 
              values_from = waterDepth) %>% 
  rename(Timestamp_GMT = Timestamp)

#Export to output dir
write_csv(output, paste0(output_dir, "waterLevel.csv"))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#3.0 Plot for funzies-----------------------------------------------------------
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#Plot mean water level
ts<-df %>% 
  mutate(day = date(Timestamp)) %>% 
  group_by(day) %>% 
  summarise(median = median(waterDepth, na.rm=T), 
            lwr    = quantile(waterDepth, 0.05, na.rm = T),
            upr    = quantile(waterDepth, 0.95, na.rm = T)) %>%
  drop_na() %>% 
  ggplot() + 
    geom_ribbon(aes(x=day, ymin=lwr, ymax=upr), alpha=0.3) + 
    geom_line(aes(x=day, y=median))+
    theme_bw() +
      xlab("Date") + ylab("Water Level [m]")
  
#Plot by site
bp<-df %>% 
  #Remove ditch wells
  filter(!str_detect(Site_Name,'-D')) %>% 
  #Create site and date cols for grouping
  mutate(
    site = substr(Site_Name, 1,2),
    day = date(Timestamp)) %>% 
  #Group by site and day
  group_by(site, day) %>% 
  summarise(waterLevel = mean(waterDepth, na.rm=T)) %>% 
  #Plot
  ggplot() + 
    geom_violin(aes(x = site, y = waterLevel)) +
    theme_bw() +
      xlab("Site") + ylab("Mean Daily Water Level [m]")

#patchwork plot
png(paste0(output_dir,"hydro.png"), width = 7, height = 9, units="in", res=300)
ts + bp + plot_layout(ncol=1)
dev.off()
