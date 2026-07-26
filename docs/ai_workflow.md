# AI Workflow

How AI tools (e.g., Cursor, ChatGPT) were used in this portfolio project — transparency for recruiters and collaborators.

---

## Purpose

Documenting AI-assisted development shows you can leverage modern tools while understanding and owning the output.

---

## What AI Helped With

| Task | AI role | Human review |
|------|---------|--------------|
| Project scaffolding | Generated folder structure and SQL templates | Verified Snowflake syntax and column names |
| SQL comments & TODOs | Drafted explanatory comments | Will implement logic step-by-step |
| README structure | Portfolio-style outline | Will add real insights after analysis |
| Debugging | *TBD as project progresses* | — |

---

## What Was Done Manually (or will be)

- Running scripts in Snowflake and validating row counts
- Interpreting business results and writing insights
- Choosing forecasting approach and evaluating model error
- Final review of all SQL before sharing publicly

---

## Prompts Used (examples)

```
Create Snowflake RAW table DDL for Kaggle Walmart train.csv columns:
Store, Dept, Date, Weekly_Sales, IsHoliday
```

```
Write a Snowflake window function query for 4-week moving average
of weekly_sales partitioned by store and dept.
```

---

## Guidelines Followed

1. **Never commit raw Kaggle CSVs** — AI suggested `.gitignore` patterns
2. **No invented columns** — only documented Kaggle schema
3. **Learn from generated code** — comments explain *why*, not just *what*
4. **Verify in Snowflake** — templates are starting points, not final truth

---

## TODO

- [ ] Log significant AI-assisted debugging sessions
- [ ] Note any SQL patterns learned from AI suggestions
