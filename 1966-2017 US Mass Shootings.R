setwd("C:/Users/Chetan Bhat/Dropbox/2. Data Science/Data Sciences/Kaggle/4. [15-10-2017] EDA - US Mass Shootings")

# Data wrangling libraries
library(dplyr)
library(lubridate)
library(reshape2)
library(SnowballC)
library(tm)

# Mapping and plotting libraries
library(extrafont)
#font_import()
loadfonts(device="win")
library(ggplot2)
library(ggthemes)
library(scales)
library(wordcloud)
library(ggmap)
library(gtable)
library(grid)

## Load data and do basic data cleaning and prep
data <- read.csv("Mass Shootings Dataset Ver 3.csv", stringsAsFactors = FALSE) # Note: This is a slightly cleaned up version.
# (Imputed missing states, lat longs. Original data can be found in Kaggle)
colnames(data)[colnames(data) == "Total.victims"] <- "Total victims"
reg_state_map <- read.csv("US Region-State Mapping.csv", stringsAsFactors = FALSE)

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

# Add decade column
data$decade <- ifelse(data$year <= '1980-01-01', "1970s",
                      ifelse(data$year <= '1990-01-01', "1980s",
                             ifelse(data$year <= '2000-01-01', "1990s",
                                    ifelse(data$year <= '2010-01-01', "2000s",
                                           ifelse(data$year <= '2020-01-01', "2010s","2020s")))))


## Plots
#1. Plot of # number of shootings by year and total victims (check box for fatality type)
temp <- melt(data[,c("year", "Fatalities", "Injured", "Total victims")], id = c("year"))

ggplot(data = temp %>% 
               group_by(year, variable) %>% 
               summarize(n_shootings = length(year),
                         fatalities = sum(value)),
             aes(x=year, y=n_shootings)) + 
  geom_line(size=1,colour="black") +
  geom_point(shape=21,size=1, fill="black",stroke=1.5, color = "black") +
  theme_minimal() + scale_fill_gdocs() +
  scale_x_date(breaks=pretty_breaks(n=20)) +
  scale_color_colorblind() + 
  ggtitle("Total # shootings, 1966-2017") +
  ylab("Total # shootings") + theme(text = element_text(family="Palatino Linotype"),
      legend.key = element_blank())


ggplot() + 
  geom_bar(data = temp %>% 
             filter(variable == "Total victims") %>%
             group_by(year, variable) %>% 
             summarize(n_shootings = length(year),
                       fatalities = sum(value)),
           aes(x=year, y=fatalities, fill = variable), stat="identity") + 
  theme_minimal() + scale_fill_gdocs() +
  scale_x_date(breaks=pretty_breaks(n=20)) +
  scale_color_colorblind() + 
  ggtitle("Total victims, 1966-2017") +
  ylab("Total victims") +
theme(text = element_text(family="Palatino Linotype"),
      legend.key = element_blank(),
      legend.text = element_blank(),
      legend.title = element_blank())

#2. Number and type of casualties by year and month
temp <- melt(data[,c("year", "month", "Total victims", "Fatalities", "Injured")], id = c("year", "month"))

ggplot(data = temp, aes(x=month, y=year, color=variable)) + 
  geom_point(shape=15, size=6, alpha=.5) + facet_grid(.~variable, scales="free") +
  theme_minimal() + scale_colour_wsj() +
  scale_y_date(breaks=pretty_breaks(n=30)) +
  ggtitle("Grid view of Total Victims, Fatalities, and Injured by time") +
  theme(text = element_text(family = 'Palatino Linotype'))

#3. Average total victims, fatalities, # injured per shooting over the years
ggplot(data = temp %>% 
         group_by(year, variable) %>% 
         summarize(n_shootings = length(year),
                   fatalities = sum(value),
                   averages = fatalities/n_shootings),
       aes(x=year, y=averages, colour=variable)) + 
  geom_line(size=1) +
  ggtitle("Average victims, fatalities, injured per shooting incident") +
  ylab("Average per shooting incident") +
  theme_minimal() + 
  #theme_gdocs() +
  scale_fill_gdocs() +
  scale_x_date(breaks=pretty_breaks(n=20)) +
  scale_y_continuous(limits = c(0,30)) +
  scale_color_colorblind() +
  theme(text = element_text(family = 'Palatino Linotype'))

#4. Race based shootings analysis
#4a. Data prep
temp <- melt(data[,c("decade","race_clean","Total victims", "Fatalities", "Injured")], id = c("decade", "race_clean"))

temp <- temp %>%
  group_by(decade, race_clean, variable) %>%
  summarize(total_casualities = sum(value),
            total_shootings = length(decade),
            average_casualities = total_casualities/total_shootings)

temp_blank <- expand.grid(race_clean = c("Black", "White", "Unknown", "Latino", "Asian"),
                    decade = c("1970s", "1980s", "1990s", "2000s", "2010s"),
                    variable = c("Total victims", "Fatalities", "Injured"))

temp <- merge(x=temp_blank, y=temp, by = c("decade", "race_clean", "variable"), all.x=T, all.y=T)
temp[is.na(temp)] <- 0
temp <- temp %>%
  group_by(decade, variable) %>%
  mutate(perc_total_casualities = total_casualities / sum(total_casualities))

#4b Proportion of casualities by race, by decade
ggplot() +
  geom_bar(data = temp %>% filter(variable == "Total victims"),
           aes(x="", y=perc_total_casualities, fill = race_clean), stat="identity") +
  coord_polar("y", start = 0) + 
  ggtitle("Proportion of shooters by race, over the last 5 decades") +
  theme_minimal() + scale_fill_wsj() + xlab('') + ylab('') + facet_grid(.~decade) +
  theme(strip.text.x = element_text(size = 10)) +
  theme(text = element_text(family = 'Palatino Linotype')) +
  guides(fill=guide_legend(title="Race")) +
  theme(axis.text = element_blank())

#4c Average casualties by race, by decade
ggplot() +
  geom_bar(data = temp %>% filter(variable == "Total victims"),
           aes(x=race_clean, y=average_casualities, fill=decade), stat="identity", position = "dodge") + 
  theme_minimal() + scale_fill_wsj() +
  ggtitle("Average number of victims per shooting, by the race of the culprit") +
  theme(text = element_text(family = 'Palatino Linotype')) +
  ylab("average casualties per shooting") +
  xlab("race") 

#5 Plot of shootings latitude-longitude on US map
mapImage <- get_map(location = "united states",
                    source = "google",
                    maptype = "terrain",
                    # color = "bw",
                    zoom = 4)

ggmap(mapImage) + 
  geom_point(data = data, aes(x=Longitude, y=Latitude, colour = `Total victims`),size=3) +
  scale_color_gradientn(colours = rainbow(4)) +
  ggtitle("Shootings by United States Geography, 1966-2017") +
  theme(text = element_text(family = 'Palatino Linotype'))

#6. Word clouds
#a. Based on title
Corpus <- Corpus(VectorSource(data$Title))
Corpus <- Corpus(VectorSource(Corpus))
Corpus <- tm_map(Corpus, removePunctuation)
Corpus <- tm_map(Corpus, stripWhitespace)
Corpus <- tm_map(Corpus, removeWords, stopwords('english'))
Corpus <- tm_map(Corpus, removeWords, 'shooting')
wordcloud(Corpus,  scale=c(5,0.5), max.words = 200, use.r.layout=FALSE, 
          rot.per = 0.3, random.order = FALSE, colors=brewer.pal(8, 'Dark2'))

