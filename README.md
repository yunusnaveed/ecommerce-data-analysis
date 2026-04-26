# E-Commerce Sales Intelligence Dashboard

An end-to-end data analytics project analyzing 100,000+ orders
from the Olist Brazilian E-Commerce dataset using Python,
PostgreSQL, and Power BI.

## Project Overview
This project covers the complete data analytics pipeline:
- Data cleaning and exploratory analysis in Python
- Business SQL queries and RFM segmentation in PostgreSQL
- Interactive 4-page Power BI dashboard

## Tools & Technologies
- Python (Pandas, NumPy, Matplotlib, Seaborn)
- PostgreSQL (CTEs, Window Functions, RFM Segmentation)
- Power BI (DAX, KPI Cards, Conditional Formatting)
- Jupyter Notebook

## Project Structure

    ecommerce-analysis/
    ├── data/
    │   ├── raw/                      ← original Kaggle CSV files
    │   └── processed/                ← cleaned CSV files output
    │       ├── master_cleaned.csv
    │       ├── monthly_revenue.csv
    │       ├── category_revenue.csv
    │       ├── state_performance.csv
    │       ├── delivery_analysis.csv
    │       └── rfm_segments.csv
    ├── notebooks/
    │   ├── 01_data_cleaning.ipynb    ← null handling, merging, preprocessing
    │   └── 02_eda.ipynb              ← visualizations and business insights
    ├── sql/
    │   ├── create_tables.sql         ← table setup and verification
    │   └── analysis_queries.sql      ← all 8 business queries + RFM
    ├── dashboard/
    │   ├── ecommerce_dashboard.pbix  ← Power BI source file
    │   └── ecommerce_dashboard_preview.pdf  ← PDF export for viewing
    ├── requirements.txt              ← Python dependencies
    └── README.md

## Dashboard Pages
1. **Sales Overview** — Revenue trends, KPIs, MoM growth, payment analysis
2. **Product Performance** — Top categories, pricing, review scores
3. **Customer & Delivery** — State performance, delivery speed analysis
4. **RFM Segments** — Customer segmentation and revenue contribution

## Key Business Insights
- Total revenue of R$ 15.4M across 96,000+ orders (2016-2018)
- Champions segment (16% of customers) drives 36% of total revenue
- Faster delivery strongly correlates with higher review scores
- São Paulo generates 38% of total revenue across all states
- Credit card used in 74% of all transactions
- Average delivery time of 12.5 days across all states

## SQL Highlights
- RFM segmentation using NTILE window functions and CTEs
- Month-on-month revenue growth using LAG function
- Delivery performance analysis with EXTRACT and EPOCH
- Multi-table JOINs across 6 related tables

## How to Run This Project

### 1. Clone the repository
    git clone https://github.com/yunusnaveed/ecommerce-data-analysis.git
    cd ecommerce-data-analysis

### 2. Install dependencies
    pip install -r requirements.txt

### 3. Download dataset
Download from Kaggle: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
Place all CSV files in data/raw/ folder

### 4. Run notebooks
Open Jupyter Notebook and run in order:
- 01_data_cleaning.ipynb
- 02_eda.ipynb

### 5. Run SQL queries
Connect to PostgreSQL and run:
- sql/create_tables.sql
- sql/analysis_queries.sql

### 6. View dashboard
Open dashboard/ecommerce_dashboard.pbix in Power BI Desktop
Or view dashboard/ecommerce_dashboard_preview.pdf directly

## Dataset
- Source: Olist Brazilian E-Commerce Dataset (Kaggle)
- Size: ~100,000 orders across 8 relational tables
- Period: 2016 to 2018
- Link: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Author
**Yunus Naveed**
- LinkedIn: https://www.linkedin.com/in/yunus-naveed
- GitHub: https://github.com/yunusnaveed
- Email: yunusnaveed04@gmail.com
