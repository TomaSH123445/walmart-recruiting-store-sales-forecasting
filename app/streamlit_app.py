import pandas as pd
import streamlit as st
import snowflake.connector

st.set_page_config(
    page_title="Walmart Sales Analytics",
    page_icon="📊",
    layout="wide",
)

st.title("Walmart Store Sales Forecasting and Retail Analytics")

@st.cache_resource
def get_connection():
    return snowflake.connector.connect(
        user=st.secrets["snowflake"]["user"],
        password=st.secrets["snowflake"]["password"],
        account=st.secrets["snowflake"]["account"],
        warehouse="WALMART_WH",
        database="WALMART_SALES",
        schema="REPORTING",
    )


@st.cache_data(ttl=300)
def run_query(query: str) -> pd.DataFrame:
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(query)
        return cur.fetch_pandas_all()
    finally:
        cur.close()


def format_currency(value: float) -> str:
    abs_value = abs(value)
    if abs_value >= 1_000_000_000:
        return f"${value / 1_000_000_000:.2f}B"
    if abs_value >= 1_000_000:
        return f"${value / 1_000_000:.2f}M"
    return f"${value:,.0f}"


sales_summary_query = """
SELECT
    sales_month,
    store_type,
    store_count,
    total_sales,
    avg_department_sales,
    sales_records
FROM REPORTING.VW_SALES_SUMMARY
ORDER BY sales_month, store_type
"""

holiday_query = """
SELECT
    is_holiday,
    week_count,
    total_sales,
    avg_department_sales
FROM REPORTING.VW_HOLIDAY_IMPACT
ORDER BY is_holiday
"""

top_departments_query = """
SELECT
    store,
    dept,
    total_sales,
    department_rank
FROM REPORTING.VW_TOP_DEPARTMENTS
WHERE department_rank <= 10
ORDER BY store, department_rank, dept
"""

store_week_query = """
SELECT
    store,
    sales_date,
    store_type,
    store_size,
    is_holiday,
    total_weekly_sales,
    avg_department_weekly_sales,
    active_departments,
    temperature,
    fuel_price,
    cpi,
    unemployment
FROM REPORTING.VW_STORE_WEEK_METRICS
ORDER BY sales_date, store
"""

sales_summary_df = run_query(sales_summary_query)
holiday_df = run_query(holiday_query)
top_departments_df = run_query(top_departments_query)
store_week_df = run_query(store_week_query)

for df in [sales_summary_df, store_week_df]:
    if "SALES_MONTH" in df.columns:
        df["SALES_MONTH"] = pd.to_datetime(df["SALES_MONTH"])
    if "SALES_DATE" in df.columns:
        df["SALES_DATE"] = pd.to_datetime(df["SALES_DATE"])

st.sidebar.header("Filters")
store_type_options = ["All"] + sorted(store_week_df["STORE_TYPE"].dropna().unique().tolist())
selected_store_type = st.sidebar.selectbox("Store Type", store_type_options)

filtered_store_week = store_week_df.copy()
filtered_sales_summary = sales_summary_df.copy()
filtered_top_departments = top_departments_df.copy()

if selected_store_type != "All":
    filtered_store_week = filtered_store_week[filtered_store_week["STORE_TYPE"] == selected_store_type]
    filtered_sales_summary = filtered_sales_summary[filtered_sales_summary["STORE_TYPE"] == selected_store_type]
    valid_stores = filtered_store_week["STORE"].dropna().unique().tolist()
    filtered_top_departments = filtered_top_departments[filtered_top_departments["STORE"].isin(valid_stores)]

store_options = ["All"] + sorted(
    filtered_store_week["STORE"].dropna().astype(str).unique().tolist(),
    key=lambda x: int(x)
)
selected_store = st.sidebar.selectbox("Store", store_options)

if selected_store != "All":
    store_value = int(selected_store)
    filtered_store_week = filtered_store_week[filtered_store_week["STORE"] == store_value]
    filtered_top_departments = filtered_top_departments[filtered_top_departments["STORE"] == store_value]

min_date = filtered_store_week["SALES_DATE"].min().date()
max_date = filtered_store_week["SALES_DATE"].max().date()
selected_dates = st.sidebar.date_input(
    "Date Range",
    value=(min_date, max_date),
    min_value=min_date,
    max_value=max_date,
)

if isinstance(selected_dates, tuple) and len(selected_dates) == 2:
    start_date, end_date = selected_dates
else:
    start_date, end_date = min_date, max_date

filtered_store_week = filtered_store_week[
    (filtered_store_week["SALES_DATE"].dt.date >= start_date)
    & (filtered_store_week["SALES_DATE"].dt.date <= end_date)
]

holiday_only = st.sidebar.checkbox("Holiday weeks only", value=False)
if holiday_only:
    filtered_store_week = filtered_store_week[filtered_store_week["IS_HOLIDAY"] == True]

if selected_store_type != "All":
    months = filtered_store_week["SALES_DATE"].dt.to_period("M").astype(str).unique().tolist()
    filtered_sales_summary = filtered_sales_summary[
        filtered_sales_summary["SALES_MONTH"].dt.to_period("M").astype(str).isin(months)
    ]
else:
    filtered_sales_summary = filtered_sales_summary[
        (filtered_sales_summary["SALES_MONTH"].dt.date >= start_date.replace(day=1))
        & (filtered_sales_summary["SALES_MONTH"].dt.date <= end_date)
    ]

if filtered_store_week.empty:
    st.warning("No data available for the selected filters.")
    st.stop()

total_sales_value = float(filtered_store_week["TOTAL_WEEKLY_SALES"].sum())
avg_weekly_sales_value = float(filtered_store_week["TOTAL_WEEKLY_SALES"].mean())
active_stores_value = int(filtered_store_week["STORE"].nunique())
avg_active_departments = float(filtered_store_week["ACTIVE_DEPARTMENTS"].mean())

holiday_sales = holiday_df.loc[holiday_df["IS_HOLIDAY"] == True, "AVG_DEPARTMENT_SALES"]
non_holiday_sales = holiday_df.loc[holiday_df["IS_HOLIDAY"] == False, "AVG_DEPARTMENT_SALES"]
if not holiday_sales.empty and not non_holiday_sales.empty and float(non_holiday_sales.iloc[0]) != 0:
    holiday_lift_pct = (
        (float(holiday_sales.iloc[0]) - float(non_holiday_sales.iloc[0]))
        / float(non_holiday_sales.iloc[0])
    ) * 100
else:
    holiday_lift_pct = 0.0

kpi1, kpi2, kpi3, kpi4, kpi5 = st.columns(5)
kpi1.metric("Total Sales", format_currency(total_sales_value))
kpi2.metric("Avg Weekly Sales", format_currency(avg_weekly_sales_value))
kpi3.metric("Holiday Lift %", f"{holiday_lift_pct:.2f}%")
kpi4.metric("Active Stores", f"{active_stores_value:,}")
kpi5.metric("Avg Active Departments", f"{avg_active_departments:.1f}")

st.markdown("### Sales Trends")
trend_col, type_col = st.columns(2)

with trend_col:
    trend_df = (
        filtered_store_week.groupby("SALES_DATE", as_index=False)["TOTAL_WEEKLY_SALES"]
        .sum()
        .sort_values("SALES_DATE")
        .set_index("SALES_DATE")
    )
    st.caption("Weekly sales trend")
    st.line_chart(trend_df)

with type_col:
    if not filtered_sales_summary.empty:
        sales_by_type = (
            filtered_sales_summary.groupby("STORE_TYPE", as_index=False)["TOTAL_SALES"]
            .sum()
            .sort_values("TOTAL_SALES", ascending=False)
            .set_index("STORE_TYPE")
        )
        st.caption("Total sales by store type")
        st.bar_chart(sales_by_type)

st.markdown("### Drivers & Comparison")
driver_col1, driver_col2 = st.columns(2)

with driver_col1:
    holiday_display = holiday_df.copy()
    holiday_display["WEEK_TYPE"] = holiday_display["IS_HOLIDAY"].map(
        {True: "Holiday", False: "Non-Holiday"}
    )
    holiday_display = holiday_display[["WEEK_TYPE", "TOTAL_SALES"]].set_index("WEEK_TYPE")
    st.caption("Holiday vs non-holiday sales")
    st.bar_chart(holiday_display)

with driver_col2:
    scatter_df = filtered_store_week[["FUEL_PRICE", "TOTAL_WEEKLY_SALES"]].dropna().copy()
    scatter_df = scatter_df.rename(
        columns={"FUEL_PRICE": "Fuel Price", "TOTAL_WEEKLY_SALES": "Weekly Sales"}
    )
    st.caption("Fuel price vs weekly sales")
    st.scatter_chart(scatter_df, x="Fuel Price", y="Weekly Sales")

st.markdown("### Operational Detail")
detail_col1, detail_col2 = st.columns([1, 1])

with detail_col1:
    temp_df = filtered_store_week[["TEMPERATURE", "TOTAL_WEEKLY_SALES"]].dropna().copy()
    temp_df = temp_df.rename(
        columns={"TEMPERATURE": "Temperature", "TOTAL_WEEKLY_SALES": "Weekly Sales"}
    )
    st.caption("Temperature vs weekly sales")
    st.scatter_chart(temp_df, x="Temperature", y="Weekly Sales")

with detail_col2:
    st.caption("Top departments by sales")
    top_dept_display = filtered_top_departments.copy()
    if not top_dept_display.empty:
        top_dept_display = top_dept_display.rename(
            columns={
                "STORE": "Store",
                "DEPT": "Department",
                "TOTAL_SALES": "Total Sales",
                "DEPARTMENT_RANK": "Rank",
            }
        )
        top_dept_display["Total Sales"] = top_dept_display["Total Sales"].map(
            lambda x: f"${x:,.0f}"
        )
        st.dataframe(top_dept_display, use_container_width=True, hide_index=True)
    else:
        st.info("No department data for the selected filters.")

st.markdown("### Store Week Metrics")
detail_df = filtered_store_week.copy().sort_values("SALES_DATE", ascending=False)
detail_df["WEEK_TYPE"] = detail_df["IS_HOLIDAY"].map({True: "Holiday", False: "Non-Holiday"})
detail_df = detail_df.rename(
    columns={
        "STORE": "Store",
        "SALES_DATE": "Sales Date",
        "STORE_TYPE": "Store Type",
        "STORE_SIZE": "Store Size",
        "TOTAL_WEEKLY_SALES": "Total Weekly Sales",
        "AVG_DEPARTMENT_WEEKLY_SALES": "Avg Department Weekly Sales",
        "ACTIVE_DEPARTMENTS": "Active Departments",
        "TEMPERATURE": "Temperature",
        "FUEL_PRICE": "Fuel Price",
        "CPI": "CPI",
        "UNEMPLOYMENT": "Unemployment",
    }
)
detail_df["Total Weekly Sales"] = detail_df["Total Weekly Sales"].map(lambda x: f"${x:,.0f}")
detail_df["Avg Department Weekly Sales"] = detail_df["Avg Department Weekly Sales"].map(
    lambda x: f"${x:,.0f}"
)
show_columns = [
    "Store",
    "Sales Date",
    "Store Type",
    "Store Size",
    "WEEK_TYPE",
    "Total Weekly Sales",
    "Avg Department Weekly Sales",
    "Active Departments",
    "Temperature",
    "Fuel Price",
    "CPI",
    "Unemployment",
]
st.dataframe(detail_df[show_columns].head(250), use_container_width=True, hide_index=True)

st.markdown("### Key Insights")
peak_week = filtered_store_week.loc[filtered_store_week["TOTAL_WEEKLY_SALES"].idxmax()]
lowest_week = filtered_store_week.loc[filtered_store_week["TOTAL_WEEKLY_SALES"].idxmin()]

st.markdown(
    f"""
- Holiday weeks show an average department sales lift of **{holiday_lift_pct:.2f}%** versus non-holiday weeks.
- Peak filtered week: Store **{int(peak_week['STORE'])}** on **{peak_week['SALES_DATE'].date()}** with **{format_currency(float(peak_week['TOTAL_WEEKLY_SALES']))}** in total weekly sales.
- Lowest filtered week: Store **{int(lowest_week['STORE'])}** on **{lowest_week['SALES_DATE'].date()}** with **{format_currency(float(lowest_week['TOTAL_WEEKLY_SALES']))}** in total weekly sales.
"""
)