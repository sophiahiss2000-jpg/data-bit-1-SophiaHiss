# set working directory 
setwd("C:/Users/Sophia Hiss/Desktop/Sophia Daten/AA Uni/Master/MIA/courses/Spring26/Data Journalism/R")
getwd()


library(rvest)
library(xml2)
library(dplyr)
library(purrr)
library(stringr)
library(tibble)
library(gt)
library(readr)
library(lubridate)
library(ggplot2)
library(scales)
install.packages("plotly")
library(plotly)

archive_url <- "https://www.mdn.dz/site_principal/sommaire/archives/archives_actualites_ar.php"
archive_page <- read_html(archive_url)

# step 1: get monthly archive links
month_nodes <- archive_page %>%
  html_elements("div.div_archives a")

archive_links <- tibble(
  month = html_text2(month_nodes),
  href  = html_attr(month_nodes, "href")
) %>%
  filter(!is.na(href), href != "") %>%
  mutate(href = url_absolute(href, archive_url)) %>%
  distinct()

# from each monthly page, collect links with "lutte" in href
# if no lutte link is found, return one row with NA

scrape_lutte_links <- function(url) {
  message("Trying: ", url)
  Sys.sleep(1)
  
  tryCatch({
    page <- read_html(url)
    
    section_node <- page %>% html_element("section#contentSection")
    
    if (length(section_node) == 0) {
      return(tibble(
        source_page = url,
        link_text = NA_character_,
        href = NA_character_,
        match_type = NA_character_,
        error = "contentSection not found"
      ))
    }
    
    nodes <- section_node %>%
      html_elements("div.clearfix.single_content a")
    
    results <- tibble(
      source_page = url,
      link_text = html_text2(nodes),
      href = html_attr(nodes, "href")
    ) %>%
      filter(!is.na(href), href != "") %>%
      mutate(href_lower = str_to_lower(href)) %>%
      filter(str_detect(href_lower, "lutte")) %>%
      mutate(
        match_type = "lutte",
        href = url_absolute(href, url)
      ) %>%
      select(source_page, link_text, href, match_type) %>%
      distinct()
    
    if (nrow(results) == 0) {
      return(tibble(
        source_page = url,
        link_text = NA_character_,
        href = NA_character_,
        match_type = NA_character_,
        error = NA_character_
      ))
    }
    
    results %>%
      mutate(error = NA_character_)
    
  }, error = function(e) {
    tibble(
      source_page = url,
      link_text = NA_character_,
      href = NA_character_,
      match_type = NA_character_,
      error = conditionMessage(e)
    )
  })
}

lutte_links_df <- map_dfr(archive_links$href, scrape_lutte_links)

lutte_links_df %>% print(n = 100, width = Inf)
lutte_links_clean <- lutte_links_df %>%
  filter(!is.na(href)) %>%
  filter(link_text != "More...") %>%
  distinct(href, .keep_all = TRUE)

lutte_links_clean %>% print(n = 150, width = Inf)

#extract migration arrest numbers

extract_immigration_numbers <- function(url) {
  message("Scraping: ", url)
  Sys.sleep(1)
  
  tryCatch({
    page <- read_html(url)
    
    rows <- page %>% html_elements("table tbody tr")
    
    if (length(rows) < 2) {
      return(tibble(
        url = url,
        maritime = NA_real_,
        border = NA_real_,
        error = "fewer than 2 table rows"
      ))
    }
    
    # select last two rows of tbody
    last_two_rows <- tail(rows, 2)
    
    # last td-cell of every row= target value
    values <- map_chr(last_two_rows, ~ {
      tds <- html_elements(.x, "td")
      if (length(tds) == 0) return(NA_character_)
      html_text2(tds[[length(tds)]])
    })
    
    values <- values %>%
      str_extract("\\d+[\\d.,]*") %>%
      str_remove_all("\\.") %>%   # if seperate by a dot
      str_remove_all(",") %>%     # if seperate by comma
      as.numeric()
    
    tibble(
      url = url,
      maritime = values[1],
      border = values[2],
      error = NA_character_
    )
    
  }, error = function(e) {
    tibble(
      url = url,
      maritime = NA_real_,
      border = NA_real_,
      error = conditionMessage(e)
    )
  })
}

#Now apply to all links

immigration_numbers_df <- map_dfr(lutte_links_clean$href, extract_immigration_numbers)

immigration_numbers_df %>% print(n = 200, width = Inf)

#Filter dates of report from all Links 
immigration_numbers_df <- immigration_numbers_df %>%
  mutate(
    date_raw = str_extract(url, "\\d{8}"),
    report_date = as.Date(date_raw, format = "%d%m%Y")
  )

#Save dataframe
write.csv(immigration_numbers_df, "immigration_numbers_VFD.csv", row.names = FALSE)

df <- read_csv("immigration_numbers_VFD.csv")

df %>%
  gt()


# aggregate immigration Arrests by month 

df_plot <- immigration_numbers_df %>%
  filter(!is.na(report_date), !is.na(border)) %>%
  mutate(month = floor_date(report_date, "month")) %>%
  group_by(month) %>%
  summarise(border = sum(border, na.rm = TRUE)) %>%
  arrange(month)

# Plot

Sys.setlocale("LC_TIME", "C")
ggplot(df_plot, aes(x = month, y = border)) +
  geom_line(color = "#C0392B", linewidth = 1.2) +
  geom_point(color = "#C0392B", size = 2) +
  geom_text(
    data = year_labels,
    aes(x = x, y = y, label = label),
    inherit.aes = FALSE,
    size = 4
  ) +
  scale_y_continuous(
    labels = scales::comma,
    expand = expansion(mult = c(0.12, 0.05))
  ) +
  scale_x_date(
    date_breaks = "1 month",
    date_labels = "%b"
  ) +
  coord_cartesian(clip = "off") +
  labs(
    title = "Reported monthly migrant arrests in Algeria",
    subtitle = "Monthly reported arrests, 2024–2025\nSource: Algerian Ministry of Defence (scraped)",
    y = "Reported arrests",
    x = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.title.y = element_text(margin = margin(r = 25)),
    axis.text = element_text(color = "black"),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1),
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(size = 11, color = "grey30"),
    plot.margin = margin(20, 20, 40, 20)
  )

# Aggregate immigration arrests per year

df <- read_csv("immigration_numbers_VFD.csv")
immigration_numbers_df <- df

df %>%
  gt()

# Aggreagate immigration arrests to years

df_immigration_year <- immigration_numbers_df %>%
  filter(!is.na(report_date), !is.na(border)) %>%
  mutate(year = year(report_date)) %>%
  group_by(year) %>%
  summarise(immigration_total = sum(border, na.rm = TRUE)) %>%
  arrange(year)

ggplot(df_immigration_year, aes(x = factor(year), y = immigration_total)) +
  geom_col() +
  labs(
    title = "Yearly immigration arrests (land borders)",
    x = "Year",
    y = "Number of arrests"
  ) +
  theme_minimal()

# Add earlier yearly updates to df_immigration_year
# earlier years + uncertainty columns

df_immigration_early <- tibble(
  year = c(2015,2016,2017,2018, 2019, 2020, 2021, 2022, 2023),
  immigration_total = c(2718,6103,8213,6834, 4465, 3085, 5839, 8750, 14814),
)

# add scraped years and keep same structure

df_immigration_2015til2025 <- bind_rows(
  df_immigration_early,
  df_immigration_year
) %>%
  arrange(year)

ggplot(df_immigration_2015til2025, aes(x = year, y = immigration_total)) +
  geom_col(fill = "#C0392B", alpha = 0.9, color = "white", width = 0.7) +
  scale_y_continuous(labels = scales::comma) +
  scale_x_continuous(
    breaks = df_immigration_2015til2025$year,
    labels = df_immigration_2015til2025$year
  ) +
  labs(
    title = "Algeria’s Migration Crackdown Is Persistent",
    subtitle = "Military reports show sustained arrests of migrants since 2015\nSource: Algerian Ministry of Defence (scraped) + External reporting",
    y = "Reported arrests",
    x = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text = element_text(color = "black"),
    plot.title = element_text(face = "bold", size = 16)
  )
