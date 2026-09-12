-- =========================================================
-- INTEGRATED BUSINESS PERFORMANCE & MIS ANALYTICS PROJECT
-- DATABASE AND TABLE CREATION
-- =========================================================

CREATE DATABASE IF NOT EXISTS integrated_business;

USE integrated_business;


-- =========================================================
-- 1. REGION MASTER
-- =========================================================

CREATE TABLE region_master (
    Region_ID VARCHAR(10) PRIMARY KEY,
    Zone VARCHAR(50),
    City VARCHAR(100),
    State VARCHAR(100),
    Region_Name VARCHAR(100),
    Status VARCHAR(30)
);


-- =========================================================
-- 2. SUPPLIER MASTER
-- =========================================================

CREATE TABLE supplier_master (
    Supplier_ID VARCHAR(10) PRIMARY KEY,
    Supplier_Name VARCHAR(150),
    Region_ID VARCHAR(10),
    City VARCHAR(100),
    State VARCHAR(100),
    Lead_Time_Days INT,
    Quality_Score DECIMAL(10,2),
    Payment_Terms_Days INT,
    Status VARCHAR(30)
);


-- =========================================================
-- 3. EMPLOYEE MASTER
-- =========================================================

CREATE TABLE employee_master (
    Employee_ID VARCHAR(10) PRIMARY KEY,
    Employee_Name VARCHAR(150),
    Department VARCHAR(100),
    Designation VARCHAR(100),
    Region_ID VARCHAR(10),
    City VARCHAR(100),
    Date_of_Joining DATE,
    Monthly_Salary DECIMAL(15,2),
    Manager_ID VARCHAR(10),
    Email VARCHAR(150),
    Status VARCHAR(30)
);


-- =========================================================
-- 4. CUSTOMER MASTER
-- =========================================================

CREATE TABLE customer_master (
    Customer_ID VARCHAR(10) PRIMARY KEY,
    Customer_Name VARCHAR(150),
    Segment VARCHAR(100),
    Region_ID VARCHAR(10),
    City VARCHAR(100),
    State VARCHAR(100),
    Join_Date DATE,
    Credit_Limit DECIMAL(15,2),
    Credit_Terms_Days INT,
    Status VARCHAR(30),
    Email VARCHAR(150)
);


-- =========================================================
-- 5. PRODUCT MASTER
-- =========================================================

CREATE TABLE product_master (
    Product_ID VARCHAR(10) PRIMARY KEY,
    Product_Name VARCHAR(150),
    Category VARCHAR(100),
    Subcategory VARCHAR(100),
    Supplier_ID VARCHAR(10),
    Unit_Cost DECIMAL(15,2),
    Selling_Price DECIMAL(15,2),
    Reorder_Level INT,
    Status VARCHAR(30)
);


-- =========================================================
-- 6. SALES TARGETS
-- =========================================================

CREATE TABLE sales_targets (
    Target_ID VARCHAR(30) PRIMARY KEY,
    Employee_ID VARCHAR(10),
    Region_ID VARCHAR(10),
    Target_Month DATE,
    Sales_Target DECIMAL(15,2)
);


-- =========================================================
-- 7. ORDER TRANSACTIONS
-- =========================================================

CREATE TABLE order_transactions (
    Order_ID VARCHAR(20) PRIMARY KEY,
    Order_Date DATE,
    Customer_ID VARCHAR(10),
    Employee_ID VARCHAR(10),
    Region_ID VARCHAR(10),
    Order_Status VARCHAR(50),
    Order_Channel VARCHAR(50)
);


-- =========================================================
-- 8. SALES TRANSACTIONS
-- =========================================================

CREATE TABLE sales_transactions (
    Transaction_ID VARCHAR(20) PRIMARY KEY,
    Sales_Date DATE,
    Order_ID VARCHAR(20),
    Customer_ID VARCHAR(10),
    Product_ID VARCHAR(10),
    Employee_ID VARCHAR(10),
    Region_ID VARCHAR(10),
    Quantity INT,
    Unit_Price DECIMAL(15,2),
    Discount_Pct DECIMAL(10,4),
    Gross_Revenue DECIMAL(15,2),
    Discount_Value DECIMAL(15,2),
    Sales_Value DECIMAL(15,2),
    Product_Cost DECIMAL(15,2),
    Profit DECIMAL(15,2)
);


-- =========================================================
-- 9. INVOICE DATA
-- =========================================================

CREATE TABLE invoice_data (
    Invoice_ID VARCHAR(20) PRIMARY KEY,
    Order_ID VARCHAR(20),
    Invoice_Date DATE,
    Due_Date DATE,
    Net_Amount DECIMAL(15,2),
    Tax_Amount DECIMAL(15,2),
    Invoice_Amount DECIMAL(15,2),
    Invoice_Status VARCHAR(50)
);


-- =========================================================
-- 10. PAYMENT DATA
-- =========================================================

CREATE TABLE payment_data (
    Payment_ID VARCHAR(20) PRIMARY KEY,
    Invoice_ID VARCHAR(20),
    Payment_Date DATE,
    Payment_Amount DECIMAL(15,2),
    Payment_Mode VARCHAR(50),
    Reference_No VARCHAR(100),
    Payment_Status VARCHAR(50)
);


-- =========================================================
-- 11. PURCHASE DATA
-- =========================================================

CREATE TABLE purchase_data (
    Purchase_ID VARCHAR(20) PRIMARY KEY,
    Purchase_Date DATE,
    Product_ID VARCHAR(10),
    Supplier_ID VARCHAR(10),
    Quantity INT,
    Unit_Cost DECIMAL(15,2),
    Purchase_Value DECIMAL(15,2),
    Promised_Delivery_Date DATE,
    Actual_Delivery_Date DATE,
    Rejected_Qty INT,
    Warehouse_ID VARCHAR(20)
);


-- =========================================================
-- 12. INVENTORY DATA
-- =========================================================

CREATE TABLE inventory_data (
    Inventory_ID VARCHAR(50) PRIMARY KEY,
    Snapshot_Date DATE,
    Product_ID VARCHAR(10),
    Warehouse_ID VARCHAR(20),
    Opening_Stock INT,
    Purchases_Qty INT,
    Sales_Qty INT,
    Returns_Qty INT,
    Closing_Stock INT,
    Stock_Value DECIMAL(15,2),
    Stockout_Days INT
);


-- =========================================================
-- 13. RETURNS DATA
-- =========================================================

CREATE TABLE returns_data (
    Return_ID VARCHAR(20) PRIMARY KEY,
    Return_Date DATE,
    Transaction_ID VARCHAR(20),
    Order_ID VARCHAR(20),
    Customer_ID VARCHAR(10),
    Product_ID VARCHAR(10),
    Return_Qty INT,
    Return_Value DECIMAL(15,2),
    Return_Reason VARCHAR(150),
    Return_Status VARCHAR(50)
);


-- =========================================================
-- 14. ATTENDANCE DATA
-- =========================================================

CREATE TABLE attendance_data (
    Attendance_ID VARCHAR(50) PRIMARY KEY,
    Employee_ID VARCHAR(10),
    Attendance_Date DATE,
    Attendance_Status VARCHAR(50),
    Check_In_Time TIME,
    Working_Hours DECIMAL(10,2),
    Late_Minutes INT
);


-- =========================================================
-- 15. CUSTOMER COMPLAINTS
-- =========================================================

CREATE TABLE customer_complaints (
    Complaint_ID VARCHAR(20) PRIMARY KEY,
    Complaint_Date DATE,
    Customer_ID VARCHAR(10),
    Product_ID VARCHAR(10),
    Employee_ID VARCHAR(10),
    Region_ID VARCHAR(10),
    Complaint_Type VARCHAR(100),
    Priority VARCHAR(50),
    Status VARCHAR(50),
    SLA_Hours DECIMAL(10,2),
    Resolution_Hours DECIMAL(10,2),
    Customer_Rating DECIMAL(10,2)
);


-- =========================================================
-- 16. MARKETING CAMPAIGN DATA
-- =========================================================

CREATE TABLE marketing_campaign_data (
    Campaign_ID VARCHAR(20) PRIMARY KEY,
    Campaign_Month DATE,
    Channel VARCHAR(100),
    Campaign_Spend DECIMAL(15,2),
    Leads INT,
    Conversions INT,
    Revenue DECIMAL(15,2),
    Region_ID VARCHAR(10),
    Campaign_Type VARCHAR(100)
);


-- =========================================================
-- CHECK ALL TABLES
-- =========================================================

SHOW TABLES;