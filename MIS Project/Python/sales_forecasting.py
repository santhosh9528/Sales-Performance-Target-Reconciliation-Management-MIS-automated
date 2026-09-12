import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt

# ============================================================
# PART 17 - SALES FORECASTING
# ============================================================

# Project path
project_path = r"C:\Users\Hooooo\Documents\Excel\MIS Project"

sales_file = os.path.join(
    project_path,
    "02_Cleaned_Data",
    "Sales_Clean.csv"
)

target_file = os.path.join(
    project_path,
    "02_Cleaned_Data",
    "Sales_Targets_Clean.csv"
)

output_folder = os.path.join(
    project_path,
    "Python",
    "Forecasting"
)

os.makedirs(output_folder, exist_ok=True)

# ============================================================
# 1. LOAD DATA
# ============================================================

sales = pd.read_csv(sales_file)
targets = pd.read_csv(target_file)

print("\nPART 17 - SALES FORECASTING")
print("=" * 60)

print("Sales rows:", len(sales))
print("Target rows:", len(targets))

# ============================================================
# 2. DATE CONVERSION
# ============================================================

sales["Sales_Date"] = pd.to_datetime(
    sales["Sales_Date"],
    errors="coerce"
)

targets["Target_Month"] = pd.to_datetime(
    targets["Target_Month"],
    errors="coerce"
)

# Remove invalid dates if any
sales = sales.dropna(subset=["Sales_Date"])
targets = targets.dropna(subset=["Target_Month"])

# ============================================================
# 3. MONTHLY SALES SUMMARY
# ============================================================

sales["Month"] = (
    sales["Sales_Date"]
    .dt.to_period("M")
    .dt.to_timestamp()
)

monthly = (
    sales.groupby("Month")
    .agg(
        Actual_Revenue=("Sales_Value", "sum"),
        Actual_Orders=("Order_ID", "nunique"),
        Actual_Quantity=("Quantity", "sum")
    )
    .reset_index()
    .sort_values("Month")
)

monthly["Previous_Month_Revenue"] = (
    monthly["Actual_Revenue"].shift(1)
)

monthly["MoM_Growth_Pct"] = (
    (
        monthly["Actual_Revenue"]
        - monthly["Previous_Month_Revenue"]
    )
    /
    monthly["Previous_Month_Revenue"]
    * 100
)

# Previous 3 completed months average
monthly["Moving_Average_3M"] = (
    monthly["Actual_Revenue"]
    .shift(1)
    .rolling(window=3)
    .mean()
)

# ============================================================
# 4. DISPLAY MONTHLY SALES WITHOUT DATETIME ROUND WARNING
# ============================================================

display_monthly = monthly.copy()

numeric_cols = display_monthly.select_dtypes(
    include="number"
).columns

for col in numeric_cols:
    display_monthly[col] = (
        display_monthly[col].round(2)
    )

print("\nMONTHLY SALES")
print(
    display_monthly.to_string(
        index=False
    )
)

# ============================================================
# 5. MONTHLY TARGET SUMMARY
# ============================================================

targets["Month"] = (
    targets["Target_Month"]
    .dt.to_period("M")
    .dt.to_timestamp()
)

monthly_target = (
    targets.groupby("Month")
    .agg(
        Target=("Sales_Target", "sum")
    )
    .reset_index()
    .sort_values("Month")
)

monthly = monthly.merge(
    monthly_target,
    on="Month",
    how="left"
)

monthly["Target_Achievement_Pct"] = (
    monthly["Actual_Revenue"]
    /
    monthly["Target"]
    * 100
)

monthly["Target_Gap"] = (
    monthly["Actual_Revenue"]
    - monthly["Target"]
)

# ============================================================
# 6. LINEAR TREND FORECAST MODEL
# ============================================================
# x = month number
# y = monthly revenue

x = np.arange(
    len(monthly),
    dtype=float
)

revenue_values = (
    monthly["Actual_Revenue"]
    .astype(float)
    .to_numpy()
)

revenue_slope, revenue_intercept = (
    np.polyfit(
        x,
        revenue_values,
        1
    )
)

order_values = (
    monthly["Actual_Orders"]
    .astype(float)
    .to_numpy()
)

order_slope, order_intercept = (
    np.polyfit(
        x,
        order_values,
        1
    )
)

# ============================================================
# 7. CREATE NEXT 3 MONTHS
# ============================================================

last_month = monthly["Month"].max()

future_months = pd.date_range(
    start=last_month + pd.offsets.MonthBegin(1),
    periods=3,
    freq="MS"
)

future_x = np.arange(
    len(monthly),
    len(monthly) + 3,
    dtype=float
)

# ============================================================
# 8. FORECAST REVENUE
# ============================================================

forecast_revenue = (
    revenue_intercept
    + revenue_slope * future_x
)

forecast_revenue = np.maximum(
    forecast_revenue,
    0
)

# ============================================================
# 9. FORECAST ORDERS
# ============================================================

forecast_orders = (
    order_intercept
    + order_slope * future_x
)

forecast_orders = np.maximum(
    forecast_orders,
    0
)

forecast_orders = np.round(
    forecast_orders
).astype(int)

# ============================================================
# 10. CREATE FORECAST DATAFRAME
# ============================================================

forecast = pd.DataFrame(
    {
        "Month": future_months,
        "Forecast_Revenue": forecast_revenue,
        "Forecast_Orders": forecast_orders
    }
)

# ============================================================
# 11. RECURSIVE 3-MONTH MOVING AVERAGE
# ============================================================

revenue_history = list(
    monthly["Actual_Revenue"].astype(float)
)

forecast_ma = []

for revenue in forecast["Forecast_Revenue"]:

    moving_average = np.mean(
        revenue_history[-3:]
    )

    forecast_ma.append(
        moving_average
    )

    revenue_history.append(
        revenue
    )

forecast["Moving_Average_3M"] = (
    forecast_ma
)

# ============================================================
# 12. PREVIOUS MONTH REVENUE
# ============================================================

previous_month_revenue = []

previous_revenue = float(
    monthly["Actual_Revenue"].iloc[-1]
)

for revenue in forecast["Forecast_Revenue"]:

    previous_month_revenue.append(
        previous_revenue
    )

    previous_revenue = revenue

forecast["Previous_Month_Revenue"] = (
    previous_month_revenue
)

# ============================================================
# 13. FORECAST GROWTH %
# ============================================================

forecast["Forecast_Growth_Pct"] = (
    (
        forecast["Forecast_Revenue"]
        - forecast["Previous_Month_Revenue"]
    )
    /
    forecast["Previous_Month_Revenue"]
    * 100
)

# ============================================================
# 14. EXPECTED TARGET
# ============================================================
# Future targets are not available.
# Use latest 3 available monthly targets as planning baseline.

latest_target_values = (
    monthly_target
    .dropna(subset=["Target"])
    .sort_values("Month")
    .tail(3)
)

if len(latest_target_values) > 0:

    planning_target = (
        latest_target_values["Target"]
        .mean()
    )

else:

    planning_target = np.nan

forecast["Expected_Target"] = (
    planning_target
)

# ============================================================
# 15. EXPECTED TARGET ACHIEVEMENT %
# ============================================================

forecast[
    "Expected_Target_Achievement_Pct"
] = (
    forecast["Forecast_Revenue"]
    /
    forecast["Expected_Target"]
    * 100
)

forecast["Expected_Target_Gap"] = (
    forecast["Forecast_Revenue"]
    - forecast["Expected_Target"]
)

# ============================================================
# 16. TARGET LIKELIHOOD
# ============================================================

def target_likelihood(
    achievement_pct
):

    if pd.isna(achievement_pct):
        return "Target Not Available"

    elif achievement_pct >= 100:
        return "High"

    elif achievement_pct >= 90:
        return "Moderate"

    else:
        return "Low"


forecast["Target_Likelihood"] = (
    forecast[
        "Expected_Target_Achievement_Pct"
    ].apply(target_likelihood)
)

# ============================================================
# 17. FINAL FORECAST TABLE
# ============================================================

forecast = forecast[
    [
        "Month",
        "Previous_Month_Revenue",
        "Moving_Average_3M",
        "Forecast_Revenue",
        "Forecast_Growth_Pct",
        "Forecast_Orders",
        "Expected_Target",
        "Expected_Target_Achievement_Pct",
        "Expected_Target_Gap",
        "Target_Likelihood"
    ]
]

# Round numeric columns
forecast_numeric_cols = [
    "Previous_Month_Revenue",
    "Moving_Average_3M",
    "Forecast_Revenue",
    "Forecast_Growth_Pct",
    "Expected_Target",
    "Expected_Target_Achievement_Pct",
    "Expected_Target_Gap"
]

for col in forecast_numeric_cols:
    forecast[col] = (
        forecast[col].round(2)
    )

# ============================================================
# 18. PRINT FORECAST
# ============================================================

print("\n" + "=" * 60)
print("NEXT 3 MONTH SALES FORECAST")
print("=" * 60)

print(
    forecast.to_string(
        index=False
    )
)

# ============================================================
# 19. MODEL INFORMATION
# ============================================================

print("\nFORECAST MODEL")
print("-" * 60)

print(
    "Revenue monthly trend:",
    round(
        revenue_slope,
        2
    )
)

print(
    "Order monthly trend:",
    round(
        order_slope,
        2
    )
)

print(
    "Planning Target:",
    round(
        planning_target,
        2
    )
)

# ============================================================
# 20. FORECAST SUMMARY
# ============================================================

avg_forecast_revenue = (
    forecast["Forecast_Revenue"].mean()
)

avg_forecast_orders = (
    forecast["Forecast_Orders"].mean()
)

avg_target_achievement = (
    forecast[
        "Expected_Target_Achievement_Pct"
    ].mean()
)

print("\nFORECAST SUMMARY")
print("-" * 60)

print(
    "Average Forecast Revenue:",
    round(
        avg_forecast_revenue,
        2
    )
)

print(
    "Average Forecast Orders:",
    round(
        avg_forecast_orders,
        2
    )
)

print(
    "Average Target Achievement %:",
    round(
        avg_target_achievement,
        2
    )
)

# ============================================================
# 21. SAVE MONTHLY SALES HISTORY
# ============================================================

monthly_output = monthly.copy()

monthly_output["Month"] = (
    monthly_output["Month"]
    .dt.strftime("%Y-%m")
)

monthly_output.to_csv(
    os.path.join(
        output_folder,
        "Monthly_Sales_History.csv"
    ),
    index=False
)

# ============================================================
# 22. SAVE FORECAST CSV
# ============================================================

forecast_output = forecast.copy()

forecast_output["Month"] = (
    forecast_output["Month"]
    .dt.strftime("%Y-%m")
)

forecast_output.to_csv(
    os.path.join(
        output_folder,
        "Sales_Forecast_Next_3_Months.csv"
    ),
    index=False
)

# ============================================================
# 23. SAVE FORECAST SUMMARY
# ============================================================

summary = pd.DataFrame(
    {
        "Metric": [
            "Revenue Monthly Trend",
            "Order Monthly Trend",
            "Planning Target",
            "Average Forecast Revenue",
            "Average Forecast Orders",
            "Average Target Achievement %"
        ],

        "Value": [
            revenue_slope,
            order_slope,
            planning_target,
            avg_forecast_revenue,
            avg_forecast_orders,
            avg_target_achievement
        ]
    }
)

summary["Value"] = (
    summary["Value"].round(2)
)

summary.to_csv(
    os.path.join(
        output_folder,
        "Forecast_Summary.csv"
    ),
    index=False
)

# ============================================================
# 24. ACTUAL VS FORECAST CHART
# ============================================================

plt.figure(
    figsize=(11, 6)
)

plt.plot(
    monthly["Month"],
    monthly["Actual_Revenue"],
    marker="o",
    label="Actual Revenue"
)

plt.plot(
    forecast["Month"],
    forecast["Forecast_Revenue"],
    marker="o",
    label="Forecast Revenue"
)

plt.xlabel("Month")
plt.ylabel("Revenue")

plt.title(
    "Actual Sales vs Next 3 Months Forecast"
)

plt.xticks(
    rotation=45
)

plt.legend()

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_folder,
        "Actual_vs_Forecast.png"
    ),
    dpi=300
)

plt.close()

# ============================================================
# 25. ACTUAL VS MOVING AVERAGE CHART
# ============================================================

plt.figure(
    figsize=(11, 6)
)

plt.plot(
    monthly["Month"],
    monthly["Actual_Revenue"],
    marker="o",
    label="Actual Revenue"
)

plt.plot(
    monthly["Month"],
    monthly["Moving_Average_3M"],
    marker="o",
    label="3-Month Moving Average"
)

plt.xlabel("Month")
plt.ylabel("Revenue")

plt.title(
    "Actual Revenue vs 3-Month Moving Average"
)

plt.xticks(
    rotation=45
)

plt.legend()

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_folder,
        "Actual_vs_Moving_Average.png"
    ),
    dpi=300
)

plt.close()

# ============================================================
# 26. FORECAST VS TARGET CHART
# ============================================================

plt.figure(
    figsize=(10, 6)
)

plt.plot(
    forecast["Month"],
    forecast["Forecast_Revenue"],
    marker="o",
    label="Forecast Revenue"
)

plt.plot(
    forecast["Month"],
    forecast["Expected_Target"],
    marker="o",
    label="Expected Target"
)

plt.xlabel("Month")
plt.ylabel("Revenue")

plt.title(
    "Forecast Revenue vs Expected Target"
)

plt.xticks(
    rotation=45
)

plt.legend()

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_folder,
        "Forecast_vs_Target.png"
    ),
    dpi=300
)

plt.close()

# ============================================================
# 27. FORECAST ORDERS CHART
# ============================================================

plt.figure(
    figsize=(10, 6)
)

plt.bar(
    forecast["Month"].dt.strftime("%Y-%m"),
    forecast["Forecast_Orders"]
)

plt.xlabel("Month")
plt.ylabel("Forecast Orders")

plt.title(
    "Next 3 Months Forecast Orders"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_folder,
        "Forecast_Orders.png"
    ),
    dpi=300
)

plt.close()

# ============================================================
# 28. FINAL MESSAGE
# ============================================================

print("\nFiles created successfully in:")
print(output_folder)

print("\nCreated files:")

print(
    "1. Monthly_Sales_History.csv"
)

print(
    "2. Sales_Forecast_Next_3_Months.csv"
)

print(
    "3. Forecast_Summary.csv"
)

print(
    "4. Actual_vs_Forecast.png"
)

print(
    "5. Actual_vs_Moving_Average.png"
)

print(
    "6. Forecast_vs_Target.png"
)

print(
    "7. Forecast_Orders.png"
)

print(
    "\nPART 17 FORECASTING COMPLETED"
)