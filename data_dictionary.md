# Data Dictionary

Source: [Kaggle — Walmart Recruiting: Store Sales Forecasting](https://www.kaggle.com/c/walmart-recruiting-store-sales-forecasting)

All dates are weekly (Friday-based reporting weeks). `IsHoliday` flags weeks that contain a major US holiday.

---

## train.csv

Historical sales used for model training and analytics.

| Column        | Type    | Description                                      |
|---------------|---------|--------------------------------------------------|
| Store         | INTEGER | Store identifier                                 |
| Dept          | INTEGER | Department identifier within the store           |
| Date          | DATE    | End of the reporting week                        |
| Weekly_Sales  | FLOAT   | Total sales for the store–department in the week |
| IsHoliday     | BOOLEAN | Whether the week contains a holiday              |

---

## test.csv

Holdout period for forecasting evaluation (no sales values provided).

| Column    | Type    | Description                             |
|-----------|---------|-----------------------------------------|
| Store     | INTEGER | Store identifier                        |
| Dept      | INTEGER | Department identifier within the store  |
| Date      | DATE    | End of the reporting week               |
| IsHoliday | BOOLEAN | Whether the week contains a holiday     |

---

## features.csv

Store-level external features by week (same `Store` + `Date` grain as aggregated sales).

| Column       | Type    | Description                                      |
|--------------|---------|--------------------------------------------------|
| Store        | INTEGER | Store identifier                                 |
| Date         | DATE    | End of the reporting week                        |
| Temperature  | FLOAT   | Average temperature for the week (°F)            |
| Fuel_Price   | FLOAT   | Regional fuel price for the week                 |
| MarkDown1    | FLOAT   | Promotional markdown amount 1 (nullable)         |
| MarkDown2    | FLOAT   | Promotional markdown amount 2 (nullable)         |
| MarkDown3    | FLOAT   | Promotional markdown amount 3 (nullable)         |
| MarkDown4    | FLOAT   | Promotional markdown amount 4 (nullable)         |
| MarkDown5    | FLOAT   | Promotional markdown amount 5 (nullable)         |
| CPI          | FLOAT   | Consumer Price Index (regional, nullable)        |
| Unemployment | FLOAT   | Regional unemployment rate (nullable)            |
| IsHoliday    | BOOLEAN | Whether the week contains a holiday              |

---

## stores.csv

Static store attributes (one row per store).

| Column | Type    | Description                                      |
|--------|---------|--------------------------------------------------|
| Store  | INTEGER | Store identifier                                 |
| Type   | VARCHAR | Store format: `A` (large), `B` (medium), `C` (small) |
| Size   | INTEGER | Store size in square feet                        |

---

## Entity Relationships

```
stores (1) ──< (many) features   [Store]
stores (1) ──< (many) train      [Store]
stores (1) ──< (many) test       [Store]

train / test grain: Store + Dept + Date
features grain:     Store + Date
stores grain:       Store
```
