# Sales Performance, Target Reconciliation & Management MIS

## 📌 Project Overview

This project is an end-to-end **Sales Performance, Target Reconciliation, and Management MIS Reporting System** designed to provide management with a clear view of daily and monthly business performance.

The organization operates across multiple regions, sales teams, customers, and product categories. Management identified inconsistencies between **sales targets, actual sales, orders, returns, and finance collections**.

The objective of this project is to validate the data, reconcile business transactions, identify exceptions, automate the reporting workflow, and provide management with actionable insights through an interactive **Power BI Management Dashboard**.

---

## 🎯 Business Problem

Management needs to understand:

- Whether sales teams are achieving their targets
- Which employees and regions are underperforming
- Whether orders, sales, returns, and collections reconcile correctly
- Where revenue leakage is occurring
- Which products are contributing to declining performance
- How returns are affecting revenue
- Which exceptions require immediate management attention

The project provides an automated MIS framework to answer these questions.

---

## 📂 Datasets

The project uses the following business datasets:

- Employee Master
- Customer Master
- Product Master
- Region Master
- Daily Sales
- Monthly Targets
- Orders
- Collections
- Returns
- Attendance

---

## 🛠️ Tools & Technologies

The following tools and technologies were used:

- **Microsoft Excel**
- **Power Query**
- **SQL**
- **Python**
- **Power BI**
- **DAX**

These tools were used for data cleaning, validation, reconciliation, automation, analysis, reporting, and dashboard development.

---

# 🔄 Project Workflow

## 1. Data Validation

The first stage focuses on identifying and correcting data-quality issues.

Validation checks include:

- Duplicate employees
- Duplicate customers
- Missing employee IDs
- Invalid product IDs
- Invalid region codes
- Duplicate transactions
- Incorrect dates
- Negative sales values
- Invalid target values

A separate **Data Quality Report** was created to document the identified issues.

---

## 2. Sales MIS

The Sales MIS provides management with important performance metrics.

### KPIs

- Daily Sales
- Month-to-Date Sales
- Year-to-Date Sales
- Monthly Target
- Achievement %
- Sales Gap
- Growth %
- Average Order Value

These metrics help management compare actual sales performance against business targets.

---

## 3. Employee Performance Analysis

Employee performance is evaluated using:

- Total Sales
- Target Achievement %
- Number of Orders
- Average Order Value
- Sales Growth

Employees are analyzed to identify:

- Top 10 Performers
- Bottom 10 Performers
- Employees Below 70% Target
- Employees with Declining Performance

This helps management identify employees who may require additional attention or support.

---

## 4. Regional Performance Analysis

Regional performance is evaluated using:

- Region Target
- Actual Sales
- Achievement %
- Previous Month Sales
- Growth %
- Sales Contribution

This analysis helps identify high-performing and underperforming regions.

---

## 5. Sales Reconciliation

A reconciliation process is implemented across the complete sales cycle:

```text
Orders
   ↓
Sales
   ↓
Returns
   ↓
Net Sales
   ↓
Collections
```

The reconciliation process identifies inconsistencies between operational and financial records.

Examples include:

- Orders without sales records
- Sales without collections
- Sales and collection mismatches
- Return-related discrepancies
- Missing transactions

---

## 6. Exception Reporting

An automated **Exception Report** identifies records that require management attention.

The report includes:

- Employees Below Target
- Regions Below Target
- Unusually High Returns
- Missing Transactions
- Duplicate Transactions
- Sales Without Collections
- Orders Without Sales Records

This helps management focus on exceptions instead of manually reviewing every transaction.

---

## 7. MIS Automation

The reporting workflow is designed so that new daily data can be processed without manually rebuilding the entire report.

Automation uses:

- Excel Power Query
- SQL
- Python

### Automated Workflow

```text
New Daily Data
      ↓
Data Validation
      ↓
Data Cleaning
      ↓
SQL / Python Processing
      ↓
Reconciliation
      ↓
Exception Detection
      ↓
MIS Refresh
      ↓
Power BI Dashboard
```

This reduces repetitive manual reporting work and improves reporting consistency.

---

# 📊 Power BI Management Dashboard

The Power BI Management MIS contains multiple analytical dashboard pages designed to provide management with a consolidated view of:

- Sales
- Targets
- Customers
- Products
- Finance
- Inventory
- Business Exceptions

---

## 📌 Executive Overview

The **Executive Overview** provides a high-level summary of overall business performance and key management KPIs.

It allows management to quickly monitor the overall status of the business.

![Executive Overview](MIS%20Project/Dashboard%20Image/Executive%20Overview.png)

---

## 💰 Sales MIS Dashboard

The **Sales MIS Dashboard** focuses on sales performance and target achievement.

The dashboard provides analysis of:

- Sales
- Monthly Targets
- Achievement %
- Sales Gap
- Growth
- Sales Performance

![Sales MIS Dashboard](MIS%20Project/Dashboard%20Image/Sales%20Mis.png)

---

## 👥 Customer Analytics Dashboard

The **Customer Analytics Dashboard** provides insights into customer-level performance and purchasing behavior.

It helps analyze customer contribution and identify important customer trends.

![Customer Analytics Dashboard](MIS%20Project/Dashboard%20Image/Customer%20Analytics.png)

---

## 📦 Product Analytics Dashboard

The **Product Analytics Dashboard** focuses on product-level business performance.

It helps management identify:

- Product Sales Performance
- High-Performing Products
- Low-Performing Products
- Product Contribution
- Product Trends

![Product Analytics Dashboard](MIS%20Project/Dashboard%20Image/Product%20Analytics.png)

---

## 💳 Finance Analysis Dashboard

The **Finance Analysis Dashboard** provides insights into financial and collection performance.

It supports analysis of:

- Sales
- Collections
- Returns
- Net Sales
- Financial Reconciliation
- Collection Performance

![Finance Analysis Dashboard](MIS%20Project/Dashboard%20Image/Finance%20Analysis.png)

---

## 📦 Inventory Analysis Dashboard

The **Inventory Analysis Dashboard** provides insights into inventory and stock-related performance.

It helps management monitor inventory conditions and identify stock-related issues.

![Inventory Analysis Dashboard](MIS%20Project/Dashboard%20Image/Inventory%20Analysis.png)

---

## 🚨 Management Exception Dashboard

The **Management Exception Dashboard** highlights business records and performance issues that require management attention.

Examples include:

- Employees below target
- Regions below target
- High returns
- Missing transactions
- Duplicate transactions
- Sales without collections
- Orders without corresponding sales records
- Reconciliation exceptions

![Management Exception Dashboard](MIS%20Project/Dashboard%20Image/Management%20Exception.png)

---

## 📄 Complete Dashboard PDF

A PDF containing the dashboard pages is also included in the project.

```text
MIS Project/Dashboard Image/Dashboards.pdf
```

---

# ❓ Management Questions

The project is designed to answer the following key management questions:

1. Which region is underperforming?
2. Which employees require management attention?
3. Why is achievement below target?
4. Which products are driving the decline?
5. Where are reconciliation issues occurring?
6. How much revenue is affected by returns?
7. What should management do next month?

---

# 📋 Project Deliverables

The completed project includes:

- Cleaned Datasets
- Data Quality Report
- SQL Queries
- Power Query Transformations
- Sales MIS Calculations
- Employee Performance Analysis
- Region Analysis
- Reconciliation Checks
- Exception Report
- Python + SQL Automation
- Automated MIS Refresh Workflow
- Power BI Management Dashboard
- Dashboard PDF
- Management Summary
- Answers to Final Management Questions

---

# 💡 Business Value

The MIS system provides management with a centralized reporting framework to:

- Monitor sales performance against targets
- Identify underperforming employees
- Identify underperforming regions
- Detect transaction discrepancies
- Monitor returns
- Monitor collections
- Identify reconciliation issues
- Monitor inventory performance
- Identify business exceptions
- Reduce repetitive manual reporting
- Improve management decision-making

---

# 📁 Project Structure

```text
Repository/
│
├── MIS Project/
│   │
│   ├── 02_Cleaned_Data/
│   │
│   ├── DQ report/
│   │
│   ├── Dashboard Image/
│   │   ├── Customer Analytics.png
│   │   ├── Dashboards.pdf
│   │   ├── Executive Overview.png
│   │   ├── Finance Analysis.png
│   │   ├── Inventory Analysis.png
│   │   ├── Product Analytics.png
│   │   ├── Sales Mis.png
│   │   └── Management Exception.png
│   │
│   ├── Dax Query/
│   ├── Excel_MIS/
│   ├── Exception_Report/
│   ├── Executive_Report/
│   ├── Power Bi/
│   ├── Python Analysis/
│   └── SQL/
│
└── README.md
```

---

# 🚀 Key Skills Demonstrated

This project demonstrates practical experience in:

- Data Cleaning
- Data Validation
- Data Quality Analysis
- SQL Querying
- Python Automation
- Excel Power Query
- DAX
- Sales Analytics
- Target vs Actual Analysis
- Employee Performance Analysis
- Regional Performance Analysis
- Customer Analytics
- Product Analytics
- Financial Reconciliation
- Inventory Analysis
- Exception Reporting
- MIS Reporting
- Power BI Dashboard Development
- Business Analysis
- Management Reporting
- Data-Driven Decision Making

---

# 🎯 Project Goal

The goal of this project is to demonstrate an end-to-end **Management Information System (MIS) and Data Analytics workflow**.

The project combines:

**Data Validation → Data Cleaning → Sales Analysis → Target Reconciliation → Exception Detection → Automation → Power BI Reporting → Management Insights**

This provides management with a structured and automated approach to monitoring business performance.

---

# 📝 Conclusion

This project demonstrates how multiple data analytics technologies can be combined to build an end-to-end **Sales Performance and Management MIS solution**.

By integrating **Excel, Power Query, SQL, Python, DAX, and Power BI**, the project supports data validation, reconciliation, automation, performance monitoring, exception reporting, and management decision-making.

---

## 👤 Author

**Santhosh Kumar M.**

### Data Analytics Skills

**Excel | SQL | Python | Power Query | Power BI | DAX | Data Analysis | MIS Reporting | Data Visualization**
