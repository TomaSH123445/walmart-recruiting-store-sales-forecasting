# Architecture

## Overview

This project follows a **medallion-style layering** pattern in Snowflake, adapted for a portfolio analytics workflow.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Kaggle CSV Files                          │
│  train.csv | test.csv | features.csv | stores.csv               │
└────────────────────────────┬────────────────────────────────────┘
                             │ PUT + COPY INTO / Python load
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  RAW SCHEMA                                                      │
│  Mirror source files — minimal transformation                    │
│  Tables: TRAIN, TEST, FEATURES, STORES                          │
└────────────────────────────┬────────────────────────────────────┘
                             │ Clean, cast, dedupe
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  STAGING SCHEMA                                                  │
│  Analysis-ready tables with consistent naming                    │
│  Tables: STG_TRAIN, STG_TEST, STG_FEATURES, STG_STORES          │
└────────────────────────────┬────────────────────────────────────┘
                             │ Join, aggregate, enrich
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  MARTS SCHEMA                                                    │
│  Star schema — facts + dimensions                                │
│  Tables: FACT_SALES, DIM_STORE, FACT_STORE_FEATURES             │
└────────────────────────────┬────────────────────────────────────┘
                             │ Simplify for consumers
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  REPORTING SCHEMA                                                │
│  Views for BI, Streamlit, portfolio SQL demos                    │
│  Views: VW_SALES_SUMMARY, VW_HOLIDAY_IMPACT, ...                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Snowflake Objects

| Object | Name | Notes |
|--------|------|-------|
| Database | `WALMART_SALES` | Single database for all layers |
| Warehouse | `WALMART_WH` | XSMALL, AUTO_SUSPEND = 60 |
| Stage | `RAW.CSV_STAGE` | Internal stage for CSV uploads |

---

## Data Grain Reference

| Table | Grain | Key Columns |
|-------|-------|-------------|
| TRAIN / STG_TRAIN / FACT_SALES | Store + Dept + Date | Store, Dept, Date |
| FEATURES / STG_FEATURES | Store + Date | Store, Date |
| STORES / DIM_STORE | Store | Store |

---

## Consumption Paths

1. **SQL analysts** — query `REPORTING` views or `MARTS` tables directly
2. **Python notebooks** — Snowflake connector or local CSV for EDA
3. **Streamlit app** — reads from `REPORTING` views via connector
4. **Forecasting** — features from marts exported to notebook or scored in Snowflake

---

## TODO

- [ ] Add entity-relationship diagram (Mermaid or image)
- [ ] Document refresh strategy (full reload vs incremental)
- [ ] Add role-based access pattern (ANALYST vs LOADER)
