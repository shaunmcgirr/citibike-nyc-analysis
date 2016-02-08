# This script reproduces Shaun McGirr's analysis of the citibike NYC data, 6-7 February 2016
# Dependencies: packages loaded below, and some kind of 

# Program structure
# 1. Obtain data from https://www.citibikenyc.com/system-data
# 2. Make it ready for analysis
# 3. Explore visually to refine business questions
# 4. Analyse to answer business questions
# 5. Produce automated report

####################
# 0. Preliminaries #
####################

library(XML)        #install.packages('XML')
library(httr)       #install.packages('httr')
library(downloader) #install.packages('downloader')
library(readr)      #install.packages('readr')
library(lubridate)  #install.packages('lubridate')
library(zoo)        #install.packages('zoo')
library(ggplot2)    #install.packages('ggplot2')
library(dplyr)      #install.packages('dplyr')
library(ggmap)      #install.packages("ggmap")
library(Cairo)      #install.packages('Cairo')
library(tidyr)      #install.packages('tidyr')
library(knitr)      #install.packages('knitr')

options(digits = 15) # So display of lat/lon isn't truncated

##################
# 1. Obtain data #
##################

# Download citibike-nyc system data (zipped CSVs); only need to run this once
source("code_grooming/download_citibike_data.R")

######################
# 2. Make data ready #
######################

# Load the unzipped CSVs in to R, run some data quality checks and make format useful
source("code_grooming/assemble_citibike_data.R")
source("code_analysis/subset_citibike_data.R")

#######################
# 3. Explore visually #
#######################

# Visualise
source("code_analysis/visualise_citibike_data.R")

#######################
# 4. Further analysis #
#######################

#

#####################
# 5. Compile report #
#####################

knit('citibike-nyc-analysis-report.rnw', encoding='UTF-8') 
system('pdflatex citibike-nyc-analysis-report.tex')
