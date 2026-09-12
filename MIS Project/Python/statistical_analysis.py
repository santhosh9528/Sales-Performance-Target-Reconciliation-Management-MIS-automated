# ============================================================
# PART 16 - STATISTICAL ANALYSIS
# ============================================================

import os
import pandas as pd
import numpy as np
from scipy import stats
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt
import seaborn as sns


# ============================================================
# PATHS
# ============================================================

base_path = r"C:\Users\Hooooo\Documents\Excel\MIS Project\02_Cleaned_Data"

output_path = r"C:\Users\Hooooo\Documents\Excel\MIS Project\Python\Statistics"

os.makedirs(output_path, exist_ok=True)


# ============================================================
# LOAD DATA
# ============================================================

sales = pd.read_csv(
    os.path.join(base_path, "Sales_Clean.csv")
)

complaints = pd.read_csv(
    os.path.join(base_path, "Customer_Complaints_Clean.csv")
)

customers = pd.read_csv(
    os.path.join(base_path, "Customer_Clean.csv")
)


print("\n========================================")
print("PART 16 - STATISTICAL ANALYSIS")
print("========================================")

print("Sales Rows:", len(sales))
print("Complaint Rows:", len(complaints))
print("Customer Rows:", len(customers))


# ============================================================
# 1. MEAN, MEDIAN, STANDARD DEVIATION
# ============================================================

columns = [
    "Sales_Value",
    "Profit",
    "Quantity",
    "Unit_Price",
    "Discount_Pct"
]

statistics_summary = pd.DataFrame({
    "Mean": sales[columns].mean(),
    "Median": sales[columns].median(),
    "Standard_Deviation": sales[columns].std()
})


print("\n========================================")
print("MEAN, MEDIAN & STANDARD DEVIATION")
print("========================================")

print(
    statistics_summary.round(2)
)


statistics_summary.to_csv(
    os.path.join(
        output_path,
        "descriptive_statistics.csv"
    )
)


# ============================================================
# 2. CORRELATION ANALYSIS
# ============================================================

correlation_columns = [
    "Quantity",
    "Unit_Price",
    "Discount_Pct",
    "Sales_Value",
    "Product_Cost",
    "Profit"
]


correlation_matrix = (
    sales[
        correlation_columns
    ].corr()
)


print("\n========================================")
print("CORRELATION ANALYSIS")
print("========================================")

print(
    correlation_matrix.round(3)
)


correlation_matrix.to_csv(
    os.path.join(
        output_path,
        "correlation_matrix.csv"
    )
)


# ============================================================
# CORRELATION HEATMAP
# ============================================================

plt.figure(figsize=(10, 7))

sns.heatmap(
    correlation_matrix,
    annot=True,
    fmt=".2f",
    cmap="coolwarm"
)

plt.title(
    "Correlation Analysis"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "01_correlation_heatmap.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 3. 95% CONFIDENCE INTERVAL - SALES VALUE
# ============================================================

sales_mean = sales["Sales_Value"].mean()

sales_sem = stats.sem(
    sales["Sales_Value"]
)


sales_ci = stats.t.interval(
    confidence=0.95,
    df=len(sales["Sales_Value"]) - 1,
    loc=sales_mean,
    scale=sales_sem
)


print("\n========================================")
print("95% CONFIDENCE INTERVAL")
print("========================================")

print(
    "Mean Sales Value:",
    round(sales_mean, 2)
)

print(
    "95% CI Lower:",
    round(sales_ci[0], 2)
)

print(
    "95% CI Upper:",
    round(sales_ci[1], 2)
)


# ============================================================
# 4. HYPOTHESIS TEST 1
#
# Does higher discount significantly reduce profit margin?
# ============================================================

sales["Profit_Margin"] = np.where(
    sales["Sales_Value"] != 0,
    (
        sales["Profit"]
        /
        sales["Sales_Value"]
    ) * 100,
    np.nan
)


hyp1_data = sales[
    [
        "Discount_Pct",
        "Profit_Margin"
    ]
].dropna()


# Pearson correlation

corr_discount_profit, p_discount_profit = (
    stats.pearsonr(
        hyp1_data["Discount_Pct"],
        hyp1_data["Profit_Margin"]
    )
)


alpha = 0.05


print("\n========================================")
print("HYPOTHESIS TEST 1")
print("========================================")

print(
    "Question: Does a higher discount significantly reduce profit margin?"
)

print(
    "H0: Higher discount does not significantly reduce profit margin."
)

print(
    "H1: Higher discount significantly reduces profit margin."
)

print(
    "Significance Level:",
    alpha
)

print(
    "Test: Pearson Correlation"
)

print(
    "Test Statistic (r):",
    round(corr_discount_profit, 4)
)

print(
    "P-Value:",
    p_discount_profit
)


if (
    p_discount_profit < alpha
    and corr_discount_profit < 0
):
    hyp1_conclusion = (
        "Reject H0 - Higher discount significantly reduces profit margin."
    )
else:
    hyp1_conclusion = (
        "Fail to Reject H0 - There is insufficient evidence that "
        "higher discount significantly reduces profit margin."
    )


print(
    "Conclusion:",
    hyp1_conclusion
)


# ============================================================
# HYPOTHESIS TEST 1 VISUALIZATION
# ============================================================

plt.figure(figsize=(10, 6))

sns.regplot(
    data=hyp1_data,
    x="Discount_Pct",
    y="Profit_Margin",
    scatter_kws={
        "alpha": 0.25
    }
)

plt.title(
    "Discount Percentage vs Profit Margin"
)

plt.xlabel(
    "Discount Percentage"
)

plt.ylabel(
    "Profit Margin (%)"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "02_discount_vs_profit_margin.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 5. HYPOTHESIS TEST 2
#
# Does customer complaint frequency significantly
# affect customer spending?
# ============================================================

customer_spending = (
    sales
    .groupby("Customer_ID")
    .agg(
        Total_Spending=(
            "Sales_Value",
            "sum"
        )
    )
    .reset_index()
)


complaint_frequency = (
    complaints
    .groupby("Customer_ID")
    .agg(
        Complaint_Frequency=(
            "Complaint_ID",
            "count"
        )
    )
    .reset_index()
)


customer_test = (
    customer_spending
    .merge(
        complaint_frequency,
        on="Customer_ID",
        how="left"
    )
)


customer_test[
    "Complaint_Frequency"
] = (
    customer_test[
        "Complaint_Frequency"
    ].fillna(0)
)


corr_complaint_spending, p_complaint_spending = (
    stats.pearsonr(
        customer_test[
            "Complaint_Frequency"
        ],
        customer_test[
            "Total_Spending"
        ]
    )
)


print("\n========================================")
print("HYPOTHESIS TEST 2")
print("========================================")

print(
    "Question: Does customer complaint frequency significantly affect customer spending?"
)

print(
    "H0: Customer complaint frequency does not significantly affect customer spending."
)

print(
    "H1: Customer complaint frequency significantly affects customer spending."
)

print(
    "Significance Level:",
    alpha
)

print(
    "Test: Pearson Correlation"
)

print(
    "Test Statistic (r):",
    round(corr_complaint_spending, 4)
)

print(
    "P-Value:",
    p_complaint_spending
)


if p_complaint_spending < alpha:
    hyp2_conclusion = (
        "Reject H0 - Customer complaint frequency has a statistically "
        "significant relationship with customer spending."
    )
else:
    hyp2_conclusion = (
        "Fail to Reject H0 - Customer complaint frequency does not have "
        "a statistically significant relationship with customer spending."
    )


print(
    "Conclusion:",
    hyp2_conclusion
)


# ============================================================
# HYPOTHESIS TEST 2 VISUALIZATION
# ============================================================

plt.figure(figsize=(10, 6))

sns.regplot(
    data=customer_test,
    x="Complaint_Frequency",
    y="Total_Spending",
    scatter_kws={
        "alpha": 0.4
    }
)

plt.title(
    "Complaint Frequency vs Customer Spending"
)

plt.xlabel(
    "Complaint Frequency"
)

plt.ylabel(
    "Total Customer Spending"
)

plt.tight_layout()

plt.savefig(
    os.path.join(
        output_path,
        "03_complaints_vs_spending.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 6. REGRESSION ANALYSIS
#
# Predict Profit using Sales Value
# ============================================================

X = sales[
    ["Sales_Value"]
]

y = sales[
    "Profit"
]


model = LinearRegression()

model.fit(
    X,
    y
)


predicted_profit = model.predict(
    X
)


slope = model.coef_[0]

intercept = model.intercept_

r_squared = model.score(
    X,
    y
)


print("\n========================================")
print("REGRESSION ANALYSIS")
print("========================================")

print(
    "Dependent Variable: Profit"
)

print(
    "Independent Variable: Sales Value"
)

print(
    "Slope:",
    round(slope, 4)
)

print(
    "Intercept:",
    round(intercept, 2)
)

print(
    "R-Squared:",
    round(r_squared, 4)
)

print(
    "Regression Equation:"
)

print(
    f"Predicted Profit = {round(intercept, 2)} + "
    f"({round(slope, 4)} × Sales Value)"
)


# ============================================================
# REGRESSION VISUALIZATION
# ============================================================

plt.figure(figsize=(10, 6))

sns.regplot(
    data=sales,
    x="Sales_Value",
    y="Profit",
    scatter_kws={
        "alpha": 0.3
    }
)

plt.title(
    "Linear Regression - Sales Value vs Profit"
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
        "04_sales_profit_regression.png"
    ),
    dpi=300
)

plt.close()


# ============================================================
# 7. SAVE HYPOTHESIS TEST RESULTS
# ============================================================

hypothesis_results = pd.DataFrame({

    "Test": [
        "Discount vs Profit Margin",
        "Complaint Frequency vs Spending"
    ],

    "H0": [
        "Higher discount does not significantly reduce profit margin",
        "Complaint frequency does not significantly affect customer spending"
    ],

    "H1": [
        "Higher discount significantly reduces profit margin",
        "Complaint frequency significantly affects customer spending"
    ],

    "Significance_Level": [
        alpha,
        alpha
    ],

    "Test_Statistic": [
        corr_discount_profit,
        corr_complaint_spending
    ],

    "P_Value": [
        p_discount_profit,
        p_complaint_spending
    ],

    "Conclusion": [
        hyp1_conclusion,
        hyp2_conclusion
    ]
})


hypothesis_results.to_csv(
    os.path.join(
        output_path,
        "hypothesis_test_results.csv"
    ),
    index=False
)


# ============================================================
# 8. SAVE CUSTOMER STATISTICAL DATA
# ============================================================

customer_test.to_csv(
    os.path.join(
        output_path,
        "customer_complaint_spending_analysis.csv"
    ),
    index=False
)


# ============================================================
# 9. CREATE TEXT REPORT
# ============================================================

report_file = os.path.join(
    output_path,
    "Statistical_Analysis_Report.txt"
)


with open(
    report_file,
    "w",
    encoding="utf-8"
) as report:

    report.write(
        "PART 16 - STATISTICAL ANALYSIS\n"
    )

    report.write(
        "========================================\n\n"
    )

    report.write(
        "DESCRIPTIVE STATISTICS\n"
    )

    report.write(
        "----------------------------------------\n"
    )

    report.write(
        statistics_summary.round(2).to_string()
    )

    report.write(
        "\n\n"
    )


    report.write(
        "95% CONFIDENCE INTERVAL - SALES VALUE\n"
    )

    report.write(
        "----------------------------------------\n"
    )

    report.write(
        f"Mean Sales Value: {sales_mean:.2f}\n"
    )

    report.write(
        f"Lower Bound: {sales_ci[0]:.2f}\n"
    )

    report.write(
        f"Upper Bound: {sales_ci[1]:.2f}\n\n"
    )


    report.write(
        "HYPOTHESIS TEST 1\n"
    )

    report.write(
        "----------------------------------------\n"
    )

    report.write(
        "Does a higher discount significantly reduce profit margin?\n\n"
    )

    report.write(
        "H0: Higher discount does not significantly reduce profit margin.\n"
    )

    report.write(
        "H1: Higher discount significantly reduces profit margin.\n"
    )

    report.write(
        f"Significance Level: {alpha}\n"
    )

    report.write(
        f"Test Statistic (r): {corr_discount_profit:.4f}\n"
    )

    report.write(
        f"P-Value: {p_discount_profit:.6f}\n"
    )

    report.write(
        f"Conclusion: {hyp1_conclusion}\n"
    )

    report.write(
        "Business Interpretation: A statistically significant negative "
        "relationship indicates that increasing discounts is associated "
        "with lower profit margins. Management should monitor discount "
        "levels to protect profitability.\n\n"
    )


    report.write(
        "HYPOTHESIS TEST 2\n"
    )

    report.write(
        "----------------------------------------\n"
    )

    report.write(
        "Does customer complaint frequency significantly affect customer spending?\n\n"
    )

    report.write(
        "H0: Customer complaint frequency does not significantly affect customer spending.\n"
    )

    report.write(
        "H1: Customer complaint frequency significantly affects customer spending.\n"
    )

    report.write(
        f"Significance Level: {alpha}\n"
    )

    report.write(
        f"Test Statistic (r): {corr_complaint_spending:.4f}\n"
    )

    report.write(
        f"P-Value: {p_complaint_spending:.6f}\n"
    )

    report.write(
        f"Conclusion: {hyp2_conclusion}\n"
    )

    if p_complaint_spending < alpha:

        report.write(
            "Business Interpretation: Complaint frequency has a statistically "
            "significant relationship with customer spending. Management "
            "should consider complaint behavior when evaluating customer "
            "value and retention strategies.\n\n"
        )

    else:

        report.write(
            "Business Interpretation: The analysis does not provide sufficient "
            "statistical evidence that complaint frequency is related to "
            "customer spending. Other customer behavior factors may have "
            "a stronger relationship with spending.\n\n"
        )


    report.write(
        "REGRESSION ANALYSIS\n"
    )

    report.write(
        "----------------------------------------\n"
    )

    report.write(
        "Dependent Variable: Profit\n"
    )

    report.write(
        "Independent Variable: Sales Value\n"
    )

    report.write(
        f"Slope: {slope:.4f}\n"
    )

    report.write(
        f"Intercept: {intercept:.2f}\n"
    )

    report.write(
        f"R-Squared: {r_squared:.4f}\n"
    )

    report.write(
        f"Equation: Predicted Profit = {intercept:.2f} + "
        f"({slope:.4f} x Sales Value)\n"
    )


# ============================================================
# FINAL STATUS
# ============================================================

print("\n========================================")
print("PART 16 COMPLETED")
print("========================================")

print("Mean                      : Completed")
print("Median                    : Completed")
print("Standard Deviation        : Completed")
print("Correlation               : Completed")
print("Confidence Interval       : Completed")
print("Hypothesis Test 1         : Completed")
print("Hypothesis Test 2         : Completed")
print("Regression                : Completed")

print(
    "\nResults saved in:"
)

print(
    output_path
)