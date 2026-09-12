# ============================================================
# INTEGRATED BUSINESS PERFORMANCE, MIS & DATA ANALYTICS
# PART 15 - PYTHON DATA ANALYTICS
#
# Libraries:
# Pandas
# NumPy
# Matplotlib
# Seaborn
# ============================================================


# ============================================================
# 1. IMPORT LIBRARIES
# ============================================================

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns


# ============================================================
# 2. FILE PATHS
# ============================================================

base_path = r"C:\Users\Hooooo\Documents\Excel\MIS Project\02_Cleaned_Data"

output_path = r"C:\Users\Hooooo\Documents\Excel\MIS Project\Python\Visualizations"

os.makedirs(output_path, exist_ok=True)


# ============================================================
# 3. LOAD DATASETS
# ============================================================

sales = pd.read_csv(
    os.path.join(base_path, "Sales_Clean.csv")
)

customers = pd.read_csv(
    os.path.join(base_path, "Customer_Clean.csv")
)

products = pd.read_csv(
    os.path.join(base_path, "Product_Clean.csv")
)

returns = pd.read_csv(
    os.path.join(base_path, "Returns_Clean.csv")
)

regions = pd.read_csv(
    os.path.join(base_path, "Region_Clean.csv")
)


print("\n========================================")
print("DATASET ROW COUNTS")
print("========================================")

print("Sales Rows:", len(sales))
print("Customer Rows:", len(customers))
print("Product Rows:", len(products))
print("Return Rows:", len(returns))
print("Region Rows:", len(regions))


# ============================================================
# 4. DATA CLEANING & VALIDATION
# ============================================================

print("\n========================================")
print("DATA CLEANING & VALIDATION")
print("========================================")


print("\nMissing Values:")

print(
    "Sales:",
    sales.isnull().sum().sum()
)

print(
    "Customers:",
    customers.isnull().sum().sum()
)

print(
    "Products:",
    products.isnull().sum().sum()
)

print(
    "Returns:",
    returns.isnull().sum().sum()
)


print("\nDuplicate Rows:")

print(
    "Sales:",
    sales.duplicated().sum()
)

print(
    "Customers:",
    customers.duplicated().sum()
)

print(
    "Products:",
    products.duplicated().sum()
)

print(
    "Returns:",
    returns.duplicated().sum()
)


# Remove duplicate rows

sales = sales.drop_duplicates()

customers = customers.drop_duplicates()

products = products.drop_duplicates()

returns = returns.drop_duplicates()

regions = regions.drop_duplicates()


# Convert dates

sales["Sales_Date"] = pd.to_datetime(
    sales["Sales_Date"]
)

customers["Join_Date"] = pd.to_datetime(
    customers["Join_Date"]
)

returns["Return_Date"] = pd.to_datetime(
    returns["Return_Date"]
)


print("\nCleaned Shapes:")

print("Sales:", sales.shape)
print("Customers:", customers.shape)
print("Products:", products.shape)
print("Returns:", returns.shape)


# ============================================================
# 5. EXPLORATORY DATA ANALYSIS - EDA
# ============================================================

print("\n========================================")
print("EXPLORATORY DATA ANALYSIS")
print("========================================")


numeric_columns = [
    "Quantity",
    "Unit_Price",
    "Discount_Pct",
    "Gross_Revenue",
    "Discount_Value",
    "Sales_Value",
    "Product_Cost",
    "Profit"
]

print(
    sales[numeric_columns].describe()
)


# ============================================================
# 6. BUSINESS KPI ANALYSIS
# ============================================================

total_sales = sales["Sales_Value"].sum()

total_profit = sales["Profit"].sum()

total_quantity = sales["Quantity"].sum()

total_transactions = sales["Transaction_ID"].nunique()

average_sales = sales["Sales_Value"].mean()

profit_margin = (
    total_profit / total_sales
) * 100


print("\n========================================")
print("BUSINESS KPIs")
print("========================================")

print(
    "Total Transactions:",
    total_transactions
)

print(
    "Total Quantity:",
    total_quantity
)

print(
    "Total Sales:",
    round(total_sales, 2)
)

print(
    "Total Profit:",
    round(total_profit, 2)
)

print(
    "Average Sales:",
    round(average_sales, 2)
)

print(
    "Profit Margin %:",
    round(profit_margin, 2)
)


# ============================================================
# 7. OUTLIER DETECTION - IQR METHOD
# ============================================================

Q1 = sales["Sales_Value"].quantile(0.25)

Q3 = sales["Sales_Value"].quantile(0.75)

IQR = Q3 - Q1

lower_bound = Q1 - (1.5 * IQR)

upper_bound = Q3 + (1.5 * IQR)


outliers = sales[
    (sales["Sales_Value"] < lower_bound)
    |
    (sales["Sales_Value"] > upper_bound)
].copy()


print("\n========================================")
print("OUTLIER DETECTION")
print("========================================")

print("Q1:", round(Q1, 2))

print("Q3:", round(Q3, 2))

print("IQR:", round(IQR, 2))

print(
    "Lower Bound:",
    round(lower_bound, 2)
)

print(
    "Upper Bound:",
    round(upper_bound, 2)
)

print(
    "Total Outliers:",
    len(outliers)
)


# Save outlier data

outliers.to_csv(
    os.path.join(
        output_path,
        "sales_outliers.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 1
# SALES VALUE OUTLIER BOX PLOT
# ============================================================

plt.figure(figsize=(10, 5))

sns.boxplot(
    x=sales["Sales_Value"]
)

plt.title(
    "Sales Value Outlier Detection"
)

plt.xlabel(
    "Sales Value"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "01_sales_outlier_boxplot.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 8. CORRELATION ANALYSIS
# ============================================================

correlation_columns = [
    "Quantity",
    "Unit_Price",
    "Discount_Pct",
    "Gross_Revenue",
    "Discount_Value",
    "Sales_Value",
    "Product_Cost",
    "Profit"
]

correlation_matrix = sales[
    correlation_columns
].corr()


print("\n========================================")
print("CORRELATION MATRIX")
print("========================================")

print(
    correlation_matrix.round(2)
)


# ============================================================
# VISUALIZATION 2
# CORRELATION HEATMAP
# ============================================================

plt.figure(
    figsize=(11, 8)
)

sns.heatmap(
    correlation_matrix,
    annot=True,
    fmt=".2f",
    cmap="coolwarm"
)

plt.title(
    "Sales Correlation Heatmap"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "02_correlation_heatmap.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 9. SALES TREND ANALYSIS
# ============================================================

sales["Sales_Month"] = (
    sales["Sales_Date"]
    .dt.to_period("M")
)


monthly_sales = (
    sales
    .groupby("Sales_Month")
    .agg(
        Total_Sales=("Sales_Value", "sum"),
        Total_Profit=("Profit", "sum"),
        Quantity=("Quantity", "sum")
    )
    .reset_index()
)


monthly_sales["Sales_Month"] = (
    monthly_sales[
        "Sales_Month"
    ].astype(str)
)


print("\n========================================")
print("MONTHLY SALES TREND")
print("========================================")

print(
    monthly_sales.round(2)
)


# Save summary

monthly_sales.to_csv(
    os.path.join(
        output_path,
        "monthly_sales_summary.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 3
# MONTHLY SALES TREND
# ============================================================

plt.figure(
    figsize=(13, 6)
)

sns.lineplot(
    data=monthly_sales,
    x="Sales_Month",
    y="Total_Sales",
    marker="o"
)

plt.title(
    "Monthly Sales Trend"
)

plt.xlabel(
    "Month"
)

plt.ylabel(
    "Total Sales"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "03_monthly_sales_trend.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# VISUALIZATION 4
# MONTHLY PROFIT TREND
# ============================================================

plt.figure(
    figsize=(13, 6)
)

sns.lineplot(
    data=monthly_sales,
    x="Sales_Month",
    y="Total_Profit",
    marker="o"
)

plt.title(
    "Monthly Profit Trend"
)

plt.xlabel(
    "Month"
)

plt.ylabel(
    "Total Profit"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "04_monthly_profit_trend.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 10. PRODUCT ANALYSIS
# ============================================================

sales_product = sales.merge(
    products[
        [
            "Product_ID",
            "Product_Name",
            "Category",
            "Subcategory"
        ]
    ],
    on="Product_ID",
    how="left"
)


category_analysis = (
    sales_product
    .groupby("Category")
    .agg(
        Total_Sales=("Sales_Value", "sum"),
        Total_Profit=("Profit", "sum"),
        Quantity_Sold=("Quantity", "sum")
    )
    .reset_index()
)


category_analysis = (
    category_analysis
    .sort_values(
        "Total_Sales",
        ascending=False
    )
)


print("\n========================================")
print("CATEGORY ANALYSIS")
print("========================================")

print(
    category_analysis.round(2)
)


category_analysis.to_csv(
    os.path.join(
        output_path,
        "category_analysis.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 5
# SALES BY PRODUCT CATEGORY
# ============================================================

plt.figure(
    figsize=(11, 6)
)

sns.barplot(
    data=category_analysis,
    x="Category",
    y="Total_Sales"
)

plt.title(
    "Sales by Product Category"
)

plt.xlabel(
    "Product Category"
)

plt.ylabel(
    "Total Sales"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "05_sales_by_category.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# VISUALIZATION 6
# PROFIT BY PRODUCT CATEGORY
# ============================================================

profit_category = (
    category_analysis
    .sort_values(
        "Total_Profit",
        ascending=False
    )
)


plt.figure(
    figsize=(11, 6)
)

sns.barplot(
    data=profit_category,
    x="Category",
    y="Total_Profit"
)

plt.title(
    "Profit by Product Category"
)

plt.xlabel(
    "Product Category"
)

plt.ylabel(
    "Total Profit"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "06_profit_by_category.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 11. TOP PRODUCT ANALYSIS
# ============================================================

product_performance = (
    sales_product
    .groupby(
        [
            "Product_ID",
            "Product_Name"
        ]
    )
    .agg(
        Total_Sales=("Sales_Value", "sum"),
        Total_Profit=("Profit", "sum"),
        Quantity_Sold=("Quantity", "sum")
    )
    .reset_index()
)


top_products = (
    product_performance
    .sort_values(
        "Total_Sales",
        ascending=False
    )
    .head(10)
)


print("\n========================================")
print("TOP 10 PRODUCTS")
print("========================================")

print(
    top_products.round(2)
)


top_products.to_csv(
    os.path.join(
        output_path,
        "top_10_products.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 7
# TOP 10 PRODUCTS BY SALES
# ============================================================

plt.figure(
    figsize=(12, 7)
)

sns.barplot(
    data=top_products,
    y="Product_Name",
    x="Total_Sales"
)

plt.title(
    "Top 10 Products by Sales"
)

plt.xlabel(
    "Total Sales"
)

plt.ylabel(
    "Product"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "07_top_10_products.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 12. CUSTOMER ANALYSIS
# ============================================================

customer_analysis = (
    sales
    .groupby("Customer_ID")
    .agg(
        Transactions=(
            "Transaction_ID",
            "nunique"
        ),
        Total_Quantity=(
            "Quantity",
            "sum"
        ),
        Total_Sales=(
            "Sales_Value",
            "sum"
        ),
        Total_Profit=(
            "Profit",
            "sum"
        ),
        Average_Transaction_Value=(
            "Sales_Value",
            "mean"
        )
    )
    .reset_index()
)


customer_analysis = customer_analysis.merge(
    customers[
        [
            "Customer_ID",
            "Customer_Name",
            "Segment"
        ]
    ],
    on="Customer_ID",
    how="left"
)


# ============================================================
# 13. CUSTOMER SEGMENTATION
# ============================================================

sales_median = (
    customer_analysis[
        "Total_Sales"
    ].median()
)

sales_q75 = (
    customer_analysis[
        "Total_Sales"
    ].quantile(0.75)
)

transaction_median = (
    customer_analysis[
        "Transactions"
    ].median()
)


conditions = [

    (
        customer_analysis["Total_Sales"]
        >= sales_q75
    )
    &
    (
        customer_analysis["Transactions"]
        >= transaction_median
    ),

    (
        customer_analysis["Total_Sales"]
        >= sales_median
    )
]


choices = [
    "High Value",
    "Medium Value"
]


customer_analysis[
    "Customer_Value_Segment"
] = np.select(
    conditions,
    choices,
    default="Low Value"
)


print("\n========================================")
print("CUSTOMER SEGMENTATION")
print("========================================")

print(
    customer_analysis[
        "Customer_Value_Segment"
    ].value_counts()
)


customer_analysis.to_csv(
    os.path.join(
        output_path,
        "customer_segmentation.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 8
# CUSTOMER SEGMENT DISTRIBUTION
# ============================================================

segment_counts = (
    customer_analysis[
        "Customer_Value_Segment"
    ]
    .value_counts()
    .reset_index()
)

segment_counts.columns = [
    "Customer_Segment",
    "Customer_Count"
]


plt.figure(
    figsize=(8, 5)
)

sns.barplot(
    data=segment_counts,
    x="Customer_Segment",
    y="Customer_Count"
)

plt.title(
    "Customer Value Segmentation"
)

plt.xlabel(
    "Customer Segment"
)

plt.ylabel(
    "Number of Customers"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "08_customer_segmentation.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 14. TOP 10 CUSTOMER ANALYSIS
# ============================================================

top_customers = (
    customer_analysis
    .sort_values(
        "Total_Sales",
        ascending=False
    )
    .head(10)
)


print("\n========================================")
print("TOP 10 CUSTOMERS")
print("========================================")

print(
    top_customers[
        [
            "Customer_ID",
            "Customer_Name",
            "Total_Sales",
            "Total_Profit"
        ]
    ].round(2)
)


top_customers.to_csv(
    os.path.join(
        output_path,
        "top_10_customers.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 9
# TOP 10 CUSTOMERS BY SALES
# ============================================================

plt.figure(
    figsize=(12, 7)
)

sns.barplot(
    data=top_customers,
    y="Customer_Name",
    x="Total_Sales"
)

plt.title(
    "Top 10 Customers by Sales"
)

plt.xlabel(
    "Total Sales"
)

plt.ylabel(
    "Customer"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "09_top_10_customers.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 15. RETURN ANALYSIS
# ============================================================

return_analysis = (
    returns
    .groupby("Return_Reason")
    .agg(
        Total_Returns=("Return_ID", "count"),
        Return_Quantity=("Return_Qty", "sum"),
        Return_Value=("Return_Value", "sum")
    )
    .reset_index()
)


return_analysis = (
    return_analysis
    .sort_values(
        "Total_Returns",
        ascending=False
    )
)


print("\n========================================")
print("RETURN ANALYSIS")
print("========================================")

print(
    return_analysis.round(2)
)


return_analysis.to_csv(
    os.path.join(
        output_path,
        "return_analysis.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 10
# RETURNS BY REASON
# ============================================================

plt.figure(
    figsize=(10, 6)
)

sns.barplot(
    data=return_analysis,
    x="Return_Reason",
    y="Total_Returns"
)

plt.title(
    "Returns by Reason"
)

plt.xlabel(
    "Return Reason"
)

plt.ylabel(
    "Number of Returns"
)

plt.xticks(
    rotation=45
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "10_returns_by_reason.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 16. REVENUE ANALYSIS BY REGION
# ============================================================

regional_sales = (
    sales
    .groupby("Region_ID")
    .agg(
        Total_Sales=("Sales_Value", "sum"),
        Total_Profit=("Profit", "sum"),
        Transactions=("Transaction_ID", "count")
    )
    .reset_index()
)


regional_sales = regional_sales.merge(
    regions[
        [
            "Region_ID",
            "Region_Name",
            "Zone"
        ]
    ],
    on="Region_ID",
    how="left"
)


regional_sales = (
    regional_sales
    .sort_values(
        "Total_Sales",
        ascending=False
    )
)


print("\n========================================")
print("REGIONAL REVENUE ANALYSIS")
print("========================================")

print(
    regional_sales.round(2)
)


regional_sales.to_csv(
    os.path.join(
        output_path,
        "regional_revenue_analysis.csv"
    ),
    index=False
)


# ============================================================
# VISUALIZATION 11
# REVENUE BY REGION
# ============================================================

plt.figure(
    figsize=(11, 6)
)

sns.barplot(
    data=regional_sales,
    y="Region_Name",
    x="Total_Sales"
)

plt.title(
    "Revenue by Region"
)

plt.xlabel(
    "Total Sales Revenue"
)

plt.ylabel(
    "Region"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "11_revenue_by_region.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 17. SALES VS PROFIT ANALYSIS
# ============================================================

print("\n========================================")
print("SALES VS PROFIT CORRELATION")
print("========================================")

sales_profit_corr = (
    sales[
        [
            "Sales_Value",
            "Profit"
        ]
    ]
    .corr()
    .iloc[0, 1]
)

print(
    "Sales vs Profit Correlation:",
    round(sales_profit_corr, 4)
)


# ============================================================
# VISUALIZATION 12
# SALES VALUE VS PROFIT SCATTER PLOT
# ============================================================

plt.figure(
    figsize=(10, 6)
)

sns.scatterplot(
    data=sales,
    x="Sales_Value",
    y="Profit",
    alpha=0.6
)

plt.title(
    "Sales Value vs Profit"
)

plt.xlabel(
    "Sales Value"
)

plt.ylabel(
    "Profit"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "12_sales_vs_profit.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 18. REVENUE ANALYSIS SUMMARY
# ============================================================

gross_revenue = (
    sales["Gross_Revenue"].sum()
)

discount_value = (
    sales["Discount_Value"].sum()
)

net_sales = (
    sales["Sales_Value"].sum()
)

product_cost = (
    sales["Product_Cost"].sum()
)


print("\n========================================")
print("REVENUE ANALYSIS")
print("========================================")

print(
    "Gross Revenue:",
    round(gross_revenue, 2)
)

print(
    "Total Discount:",
    round(discount_value, 2)
)

print(
    "Net Sales Revenue:",
    round(net_sales, 2)
)

print(
    "Product Cost:",
    round(product_cost, 2)
)

print(
    "Total Profit:",
    round(total_profit, 2)
)

print(
    "Profit Margin %:",
    round(profit_margin, 2)
)


# ============================================================
# 19. FINAL ANALYSIS SUMMARY
# ============================================================

print("\n========================================")
print("PYTHON ANALYSIS COMPLETED")
print("========================================")

print("Data Cleaning              : Completed")
print("Exploratory Data Analysis  : Completed")
print("Outlier Detection          : Completed")
print("Correlation Analysis       : Completed")
print("Customer Segmentation      : Completed")
print("Product Analysis           : Completed")
print("Sales Trend Analysis       : Completed")
print("Return Analysis            : Completed")
print("Revenue Analysis           : Completed")
print("Visualizations Created     : 12")

print(
    "\nVisualization Folder:"
)

print(
    output_path
)

print(
    "\nPart 15 Python Data Analytics Successfully Completed."
)