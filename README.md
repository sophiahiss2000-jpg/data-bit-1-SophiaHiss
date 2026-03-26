# data-bit-1-SophiaHiss
Data Bit 1 – Securitization of Migration in Algeria

# Inside Algeria’s Migration Crackdown

This data journalism piece investigates Algeria’s migration control practices through newly compiled data from official military reports.

# Data Bit 1 – Migration in Algeria

This project explores migration control practices in Algeria using scraped data from official military reports.

🔗 **Read the full interactive article:**  
👉 https://rawcdn.githack.com/sophiahiss2000-jpg/data-bit-1-SophiaHiss/main/index.html

## 🔍 About the project

While Algeria remains a “black box” in migration governance, this project reconstructs patterns of enforcement by scraping and analyzing weekly operational reports published by the Algerian Ministry of Defence.

The dataset provides a rare longitudinal perspective on migration-related arrests between 2015 and 2025 and shows that repressive migration policies are on the rise since 2023.

## 📊 Data & Methods

- Sources:
  - Algerian Ministry of Defence operational reports (primary)
  - External news reporting (secondary dataset)
- Methods:
  - Web scraping in R (`rvest`, `tidyverse`)
  - Manual data collection from news sources
  - Data cleaning and aggregation
- Sample: 100+ reports (2015–2025)  
- Processing: extraction, cleaning, aggregation  

The full code and datasets are available in this repository to ensure transparency and reproducibility.

## 📁 Repository structure

├── index.html # Final rendered article
├── DataBit1_SophiaHiss.qmd # Quarto source file
├── styles.css # Custom styling
├── data/
│ ├── mdn_reports.csv # Scraped military data
│ └── external_reports.csv # Supplementary dataset (news sources)
├── code/
│ └── scraping_analysis.R # R script (scraping + cleaning + plotting)
├── figures/
   ├── InGuezzam.png
   └── Arrests-aggregated-2015-2025.png # Visualizations used in the article


## ⚠️ Notes on data

Official figures are not independently verifiable and should be interpreted with caution. They are used here to identify patterns rather than exact migration flows.

## 👩‍💻 Author

Sophia Hiss  
Master’s student in International Affairs (Berlin)  
Focus: migration, securitization, North Africa

