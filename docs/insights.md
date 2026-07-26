# Insights

Document key findings here as you complete analysis. Link each insight to the SQL script or notebook that produced it.

---

## Template

### Insight title

**Question:** (from business_questions.md)  
**Finding:** One-sentence summary  
**Evidence:** Query, chart, or metric  
**Business implication:** What a retail analyst would do with this  

---

## Draft Insights (TODO)

### Holiday lift

**Question:** How much do sales increase during holiday weeks?  
**Finding:** *TBD*  
**Evidence:** `REPORTING.VW_HOLIDAY_IMPACT` or EDA notebook  
**Business implication:** Adjust staffing and inventory before holiday weeks  

---

### Store type performance

**Question:** How do sales vary by store type (A/B/C)?  
**Finding:** *TBD*  
**Evidence:** `REPORTING.VW_SALES_SUMMARY`  
**Business implication:** Tailor assortment by store format  

---

### Markdown effectiveness

**Question:** Do markdowns lift sales?  
**Finding:** *TBD*  
**Evidence:** Feature correlation analysis in `01_eda.ipynb`  
**Business implication:** Optimize promotional calendar  

---

## Metrics Log

| Metric | Value | Date computed | Source |
|--------|-------|---------------|--------|
| Total training rows | TBD | — | RAW.TRAIN |
| Holiday avg sales lift | TBD | — | VW_HOLIDAY_IMPACT |
| Forecast MAPE (baseline) | TBD | — | 02_forecasting.ipynb |
