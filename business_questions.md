# Business Questions

Analytical questions this project aims to answer using Snowflake SQL and Python.

---

## Sales Performance

1. Which stores and departments generate the highest weekly sales?
2. How do sales vary by store type (`A`, `B`, `C`) and store size?
3. What is the year-over-year and week-over-week sales growth by store?

## Seasonality & Holidays

4. How much do sales increase during holiday weeks compared to non-holiday weeks?
5. Which months and quarters show the strongest seasonal patterns?
6. Are certain store types more sensitive to holiday effects?

## External Factors

7. Does temperature correlate with weekly sales at the store level?
8. How do fuel price changes relate to sales trends?
9. Do markdown promotions (MarkDown1–5) lift sales in the weeks they are active?

## Forecasting & Planning

10. Can we forecast next-week department sales using historical patterns and features?
11. Which departments are hardest to forecast (highest error)?
12. How would inventory and staffing plans change if we used model-based forecasts?

## Data Quality

13. Are there missing or anomalous values in features (CPI, Unemployment, MarkDowns)?
14. Do all stores in `train` have matching rows in `stores` and `features`?
15. Are there duplicate Store + Dept + Date combinations in the training data?

---

## TODO

- [ ] Prioritize top 5 questions for the portfolio README "Key Insights" section
- [ ] Map each question to a SQL script or notebook section
- [ ] Document expected KPIs (e.g., MAPE for forecasting, % holiday lift)
