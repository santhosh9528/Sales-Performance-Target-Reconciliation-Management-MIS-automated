# Sales Performance, Target Reconciliation & Management MIS

## Project Overview

This project is an end-to-end **Sales Performance, Target Reconciliation, and Management MIS Reporting System** designed to provide management with a clear view of daily and monthly business performance.

The organization operates across multiple regions, sales teams, customers, and product categories. Management identified inconsistencies between **sales targets, actual sales, orders, returns, and finance collections**.

The objective of this project is to validate the data, reconcile business transactions, identify exceptions, automate the reporting workflow, and provide management with actionable insights through an interactive Power BI dashboard.

---

## Business Problem

Management needs to understand:

- Whether sales teams are achieving their targets
- Which employees and regions are underperforming
- Whether order, sales, return, and collection records reconcile correctly
- Where revenue leakage is occurring
- Which products are contributing to declining performance
- How returns are affecting revenue
- Which exceptions require immediate management attention

The project provides an automated MIS framework to answer these questions.

---

## Datasets

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

## Tools & Technologies

- **Excel**
- **Power Query**
- **SQL**
- **Python**
- **Power BI**

These tools are used for data cleaning, validation, reconciliation, automation, analysis, reporting, and dashboard development.

---

# Project Workflow

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

A separate **Data Quality Report** is generated to document identified issues.

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

These metrics help management compare actual performance against business targets.

---

## 3. Employee Performance Analysis

Employee performance is evaluated using:

- Total Sales
- Target Achievement %
- Number of Orders
- Average Order Value
- Sales Growth

Employees are classified and ranked to identify:

- Top 10 Performers
- Bottom 10 Performers
- Employees Below 70% Target
- Employees with Declining Performance

This allows management to quickly identify employees who require support or performance intervention.

---

## 4. Regional Performance Analysis

Regional performance is evaluated using:

- Region Target
- Actual Sales
- Achievement %
- Previous Month Sales
- Growth %
- Sales Contribution

This analysis identifies high-performing and underperforming regions.

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

An automated Exception Report identifies records that require management attention.

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

The reporting workflow is designed so that new daily data can be processed without manually rebuilding the complete report.

Automation uses:

- Excel Power Query
- SQL
- Python

The workflow supports:

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

## 8. Management Dashboard

An interactive **Power BI Management Dashboard** provides a consolidated view of business performance.

### Dashboard Metrics

- Sales
- Target
- Achievement %
- Growth %
- Collections
- Returns
- Regional Performance
- Employee Ranking
- Exception Monitoring

The dashboard allows management to identify performance issues and investigate them using interactive visuals and filters.

---

# Management Questions

The project is designed to answer the following key business questions:

1. Which region is underperforming?
2. Which employees require management attention?
3. Why is achievement below target?
4. Which products are driving the decline?
5. Where are reconciliation issues occurring?
6. How much revenue is affected by returns?
7. What should management do next month?

---

# Project Deliverables

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
- Management Summary
- Answers to Final Management Questions

---

# Key Skills Demonstrated

This project demonstrates practical experience in:

- Data Cleaning
- Data Validation
- Data Quality Analysis
- SQL Querying
- Sales Analytics
- Target vs Actual Analysis
- Employee Performance Analysis
- Regional Performance Analysis
- Financial Reconciliation
- Exception Reporting
- MIS Reporting
- Power Query
- Python Automation
- Power BI Dashboard Development
- Business Analysis
- Management Reporting
- Data-Driven Decision Making

---

# Suggested Project Structure

```text
Sales_Performance_MIS/
│
├── Dataset/
│   ├── Employee_Master/
│   ├── Customer_Master/
│   ├── Product_Master/
│   ├── Region_Master/
│   ├── Daily_Sales/
│   ├── Monthly_Targets/
│   ├── Orders/
│   ├── Collections/
│   ├── Returns/
│   └── Attendance/
│
├── SQL/
│   └── SQL_Queries/
│
├── Python/
│   └── Automation_Scripts/
│
├── Power_Query/
│
├── PowerBI/
│   └── Management_Dashboard.pbix
│
├── Reports/
│   ├── Data_Quality_Report/
│   ├── Exception_Report/
│   └── Management_Summary/
│
└── README.md
```

---

## Business Value

The MIS system provides management with a centralized reporting framework to:

- Monitor sales performance against targets
- Identify underperforming employees and regions
- Detect transaction discrepancies
- Monitor returns and collections
- Identify business exceptions
- Reduce manual reporting effort
- Improve daily management decision-making

---

## Author

**Santhosh Kumar M.**

Data Analytics Skills:

**Excel | SQL | Python | Power Query | Power BI | Data Analysis | MIS Reporting**

---

## Project Goal

The goal of this project is to demonstrate an end-to-end **Management Information System (MIS) and Data Analytics workflow**, combining data validation, sales analysis, reconciliation, exception reporting, automation, and management dashboard development.
