setwd("C:/Users/Chetan Bhat/Dropbox/2. Data Science/Data Sciences/Kaggle/4. [15-10-2017] EDA - US Mass Shootings")

# of shootings by year
#1. Line chart of number of shootings by year and total fatalities (check box for fatality type)

#2. Heat map copy paste

#3. Average number of fatalies per shooting. Either line or bar

#4.1 Pie chart of total shootings by race by decade. split into 6 or 7 charts
#4.2 Pie chart of total fatalies by race by decade. split into 6 or 7 charts
#4.3 Pie chart of average fatalies per shooting by race by decade. split into 6 or 7 charts

#5a. Word cloud of title
#5b. Word cloud by description

#6. Drop down by region

#7. Deadliest states by # of shootings, # of fatalities

#8. Plot lat-long on map with bubbles being fatalities size

library(dplyr)
library(lubridate)
library(ggplot2)
library(ggthemes)
library(scales)
library(reshape2)
library(shiny)
library(shinydashboard)

## Load data and do basic data cleaning and prep
data <- read.csv("./Mass Shootings Dataset Ver 3.csv", stringsAsFactors = FALSE) # Note: This is a slightly cleaned up version.
# (Imputed missing states, lat longs. Original data can be found in Kaggle)
reg_state_map <- read.csv("./US Region-State Mapping.csv", stringsAsFactors = FALSE)

# Extract state from location
data$Location_stringlen <- apply(data, 2, nchar)[,c("Location")]
data$state <- substr(data$Location, regexpr(",", data$Location) + 2, data$Location_stringlen)

# Map states to 5 major US regions (this mapping can be found online)
data$region <- reg_state_map$Region[match(data$state, reg_state_map$State)]

# Standardizing gender and race strings
data$race_clean <- ifelse(grepl("White|white", data$Race), "White",
                          ifelse(grepl("Black|black", data$Race), "Black",
                                 ifelse(grepl("Asian|asian|asia", data$Race), "Asian",
                                        ifelse(grepl("Latin", data$Race), "Latino", "Unknown"))))

data$gender_clean <- ifelse(grepl("M|Male", data$Gender), "Male",
                          ifelse(grepl("F|Female", data$Gender), "Female",
                                 ifelse(grepl("M/F|Male/Female", data$Gender), "Both", "Unknown")))


# Making dates in date datatype and extracting month and year
data$Date <- as.Date(data$Date, format = "%m/%d/%Y")
data$year <- as.Date(paste0(year(data$Date),"-01-01"),format="%Y-%m-%d")
data$month <- as.factor(month(data$Date))

## Plots
#1. Plot of # number of shootings by year and total victims (check box for fatality type)
shootings <- melt(data[,c("year", "Fatalities", "Injured", "Total.victims")], id = c("year"))

# ui  

ui <- dashboardPage(
  title = "US Mass Shooting EDA",
  skin = "black",
  
  dashboardHeader(
    
    title = "US Mass Shooting EDA",
    titleWidth = 250,
    disable = F
  ),
  
  dashboardSidebar(
    width = 250,
    disable = F,
    
    sidebarMenu(
      id = "tabs",
      menuItem("Charts", tabName = "C", badgeLabel = "NEW", badgeColor = "red", icon = icon("inr")),
      hr()
    )
    
  ),
    
    dashboardBody(
      
      fluidRow(
        column(6,plotOutput("plotgraph1", height = 300))
        #column(6,plotOutput("plotgraph2", height = 300))
      )
    )
  )

server <- function(input, output) {
  output$plotgraph1 <- renderPlot({
    
    ggplot(data = shootings %>% 
             group_by(year, variable) %>% 
             summarize(n_shootings = length(year),
                       fatalities = sum(value)),
           aes(x=year, y=n_shootings)) + 
      geom_bar(data = shootings %>% 
                 filter(variable == "Total.victims") %>%
                 group_by(year, variable) %>% 
                 summarize(n_shootings = length(year),
                           fatalities = sum(value)),
               aes(x=year, y=fatalities, fill = variable), stat="identity") + 
      geom_line(size=1.5,colour="black") +
      theme_minimal() + scale_fill_gdocs() +
    scale_x_date(breaks=pretty_breaks(n=20)) +
      scale_color_colorblind()
    
  })
}

## 5. Final EXECUTION ---- 
shinyApp(ui, server)