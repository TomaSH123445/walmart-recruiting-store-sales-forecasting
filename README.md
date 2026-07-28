# Walmart Store Sales Forecasting & Retail Analytics in Snowflake

A end-to-end analytics portfolio project combining **Snowflake SQL**, **Python**, and optional **forecasting** to analyze Walmart store and department sales using the [Kaggle Walmart Recruiting dataset](https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting).

---

## Project Overview

This project demonstrates a production-style analytics workflow:

1. Ingest Kaggle CSV files into Snowflake **RAW** tables
2. Clean and standardize data in **STAGING**
3. Build business-ready **MARTS** (facts and dimensions)
4. Expose **REPORTING** views for dashboards and SQL demos
5. Explore data and optional forecasts in **Jupyter notebooks**
6. Present insights in a **Streamlit** app

The repository is structured for learning and portfolio review — SQL scripts are numbered and documented, and raw data is never committed to Git.

---



## Business Problem

Retail leaders need accurate weekly sales forecasts at the store and department level to plan inventory, staffing, and promotions. External factors — holidays, weather, fuel prices, markdowns, and regional economics — all influence demand.

This project answers: *How do sales vary across stores and departments, what drives weekly changes, and can we forecast future demand using historical patterns and features?*

See [business_questions.md](business_questions.md) for the full list of analytical questions.

---



## Dataset


| File           | Description                                     | Grain               |
| -------------- | ----------------------------------------------- | ------------------- |
| `train.csv`    | Historical sales                                | Store + Dept + Date |
| `test.csv`     | Holdout period (no sales)                       | Store + Dept + Date |
| `features.csv` | Temperature, fuel, markdowns, CPI, unemployment | Store + Date        |
| `stores.csv`   | Store type and size                             | Store               |


Full column definitions: [data_dictionary.md](data_dictionary.md)

> **Note:** Download the dataset from Kaggle locally. CSV files are excluded via `.gitignore`.

---



## Tools Used


| Category        | Tools                                              |
| --------------- | -------------------------------------------------- |
| Data warehouse  | Snowflake                                          |
| SQL             | Snowflake SQL (window functions, views, COPY INTO) |
| Python          | pandas, NumPy, Matplotlib, Seaborn                 |
| Connectivity    | snowflake-connector-python                         |
| Notebooks       | Jupyter                                            |
| Forecasting     | scikit-learn, statsmodels (optional)               |
| Dashboard       | Streamlit                                          |
| Version control | Git / GitHub                                       |


---



## Architecture

```
Kaggle CSVs  →  RAW  →  STAGING  →  MARTS  →  REPORTING
                  ↑                                    ↓
            (03_load_data)              (Streamlit / BI / SQL demos)
                                                  ↑
                                          Python notebooks (EDA, DQ, ML)
```

Detailed design: [docs/architecture.md](docs/architecture.md)

---



## Snowflake Layers


| Schema        | Purpose                             | Key Objects                                                                            |
| ------------- | ----------------------------------- | -------------------------------------------------------------------------------------- |
| **RAW**       | Landing zone — mirror CSV structure | `TRAIN`, `TEST`, `FEATURES`, `STORES`                                                  |
| **STAGING**   | Cleaned, typed, deduplicated        | `STG_TRAIN`, `STG_TEST`, `STG_FEATURES`, `STG_STORES`                                  |
| **MARTS**     | Star-schema facts and dimensions    | `FACT_SALES`, `DIM_STORE`, `FACT_STORE_FEATURES`, `FACT_STORE_WEEKLY_SALES`            |
| **REPORTING** | Business views for consumption      | `VW_SALES_SUMMARY`, `VW_HOLIDAY_IMPACT`, `VW_TOP_DEPARTMENTS`, `VW_STORE_WEEK_METRICS` |


Warehouse: `WALMART_WH` (XSMALL, auto-suspend 60s)

### Layer overview

- **RAW** — Minimal transformation landing zone. Tables mirror Kaggle CSV column order and structure so every downstream result can be traced to source files.
- **STAGING** — Standardized snake_case columns, deduplication on natural keys, and audit timestamps. NULL values for missing markdowns or economic indicators are preserved (not imputed to zero).
- **MARTS** — Business-ready star schema: `DIM_STORE` plus fact tables at department and store-week grains, with features joined for analysis and forecasting.
- **REPORTING** — Thin views on top of marts for dashboards, Streamlit, and portfolio SQL demos. No heavy transformation logic lives here.

---



## Run order

Execute the SQL scripts in Snowflake in this exact order:

1. `sql/01_create_database.sql` — database, schemas, warehouse
2. `sql/02_create_raw_tables.sql` — RAW table DDL
3. Upload all four source CSV files to `@RAW.CSV_STAGE` (PUT or Snowflake UI)
4. `sql/03_load_data.sql` — COPY INTO raw tables
5. `sql/08_data_quality_checks.sql` — **Section A** (RAW checks)
6. `sql/04_create_staging.sql` — staging transformations
7. `sql/05_create_marts.sql` — facts and dimensions
8. `sql/08_data_quality_checks.sql` — **Sections B & C** (STAGING and MARTS checks)
9. `sql/06_window_functions.sql` — analytical window function examples
10. `sql/07_reporting_views.sql` — reporting views

> **Required source files:** `train.csv`, `test.csv`, `features.csv`, and `stores.csv` must all be present on the stage before running `03_load_data.sql`.

---



## SQL Analysis

Numbered scripts in `sql/` — run in order:


| Script                       | Description                                     |
| ---------------------------- | ----------------------------------------------- |
| `01_create_database.sql`     | Database, schemas, warehouse                    |
| `02_create_raw_tables.sql`   | RAW table DDL                                   |
| `03_load_data.sql`           | Stage + COPY INTO (active load statements)      |
| `04_create_staging.sql`      | Staging CTAS with deduplication                 |
| `05_create_marts.sql`        | Facts, dimensions, store-week rollup            |
| `06_window_functions.sql`    | Moving averages, WoW, ranking, holiday analysis |
| `07_reporting_views.sql`     | Dashboard-ready views                           |
| `08_data_quality_checks.sql` | RAW, STAGING, and MARTS validation queries      |


---



## Dashboard

The Streamlit dashboard connects to Snowflake reporting views and provides interactive exploration of sales performance.

### Dashboard features

- Sidebar filters for store type, store, date range, and holiday-only analysis.
- KPI cards for total sales, average weekly sales, holiday lift, active stores, and active departments.
- Weekly sales trend visualization.
- Sales comparison by store type.
- Holiday vs non-holiday comparison.
- Scatter plots for temperature vs sales and fuel price vs sales.
- Top departments by store table.
- Detailed store-week operational metrics.

**Overview**

Walmart Dashboard Overview

**Operational detail**

Walmart Dashboard Operational Detail

## Python EDA

Notebook: [notebooks/01_eda.ipynb](notebooks/01_eda_and_business_insights.ipynb)

Planned exploration:

- Sales distribution by store type and department
- Seasonality and holiday effects
- Missing values in markdown and economic features
- Correlation between temperature, fuel price, and sales

---



## Forecasting

Notebook: [notebooks/02_forecasting.ipynb](notebooks/02_forecasting_baseline.ipynb)

Optional baseline forecasting workflow:

- Feature engineering from marts or local CSVs
- Train/test split aligned with Kaggle `test.csv` dates
- Baseline models (e.g., seasonal naive, linear regression)
- Error metrics (MAE, MAPE)

---



## Data Quality Checks

- **SQL:** [sql/08_data_quality_checks.sql](sql/08_data_quality_checks.sql) — duplicates, orphans, nulls, outliers

---



## Key Insights

The analysis shows clear seasonal patterns in weekly sales, with stronger performance toward the end of the year and visible holiday-related spikes. Holiday weeks tend to outperform non-holiday weeks on average, but the effect is moderate rather than dramatic.

External variables such as temperature, fuel price, CPI, and unemployment show weak standalone relationships with weekly sales in the exploratory analysis. Markdown activity appears more informative, but the relationship is noisy and likely non-linear.

At the store and department level, sales behavior varies substantially, which means aggregate trends do not fully describe local performance. Some departments are stable, while others show sharp volatility and sudden drops or spikes.

The baseline forecasting models capture the overall trend reasonably well, but they struggle with abrupt changes and department-level volatility. This suggests that stronger forecasting performance will likely require richer lag features, rolling statistics, and holiday-aware time-series features.

Overall, the project shows that Walmart sales are shaped by a combination of seasonality, promotions, and local store-department dynamics rather than by a single external driver.

---



## Repository Structure

```
├── README.md
├── data_dictionary.md
├── business_questions.md
├── .gitignore
├── requirements.txt
├── sql/                    # Snowflake scripts (01–08)
├── notebooks/              # EDA, forecasting, data quality
├── docs/                   # Architecture, insights, AI workflow
└── app/
    └── streamlit_app.py    # Optional dashboard
```

---



## How to Run



### 1. Clone and set up Python

```bash
git clone <your-repo-url>
cd walmart-recruiting-store-sales-forecasting
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```



### 2. Download Kaggle data

Download `train.csv`, `test.csv`, `features.csv`, and `stores.csv` from Kaggle.  
Place them in a local folder (e.g., `data/`) — this folder is gitignored.

### 3. Snowflake setup

Follow the [Run order](#run-order) section above. All eight SQL scripts are implemented and ready to execute in Snowflake.

### 4. Run notebooks

```bash
jupyter notebook notebooks/
```



### 5. Launch Streamlit (optional)

```bash
streamlit run app/streamlit_app.py
```

---



## Next Steps

- [x] Implement full Snowflake ELT pipeline (RAW → STAGING → MARTS → REPORTING)
- [x] Run EDA notebook and document insights in `docs/insights.md`
- [x] Add baseline forecasting model in `02_forecasting.ipynb`
- [x] Connect Streamlit to Snowflake reporting views
- [x] Prepare chart screenshots for README and portfolio use
- [x] Embed screenshots directly in the GitHub README
- [ ] Add architecture diagram screenshot to README

---



## License & Attribution

Dataset: Walmart Recruiting — Store Sales Forecasting (Kaggle).  
This project is for educational and portfolio purposes.