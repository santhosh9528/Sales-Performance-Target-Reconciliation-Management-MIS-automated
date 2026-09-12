-- ============================================================
-- INTEGRATED BUSINESS PERFORMANCE, MIS & DATA ANALYTICS PROJECT
-- CLEANED DATA IMPORT SCRIPT
-- ============================================================

USE integrated_business;

SET FOREIGN_KEY_CHECKS = 0;


-- ============================================================
-- 1. REGION MASTER
-- Source: Region_Clean.csv
-- Expected Rows: 8
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Region_Clean.csv'
INTO TABLE region_master
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 2. SUPPLIER MASTER
-- Source: Supplier_Clean.csv
-- Expected Rows: 49
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Supplier_Clean.csv'
INTO TABLE supplier_master
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 3. EMPLOYEE MASTER
-- Source: Employee_Clean.csv
-- Expected Rows: 117
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Employee_Clean.csv'
INTO TABLE employee_master
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 4. CUSTOMER MASTER
-- Source: Customer_Clean.csv
-- Expected Rows: 597
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Customer_Clean.csv'
INTO TABLE customer_master
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 5. PRODUCT MASTER
-- Source: Product_Clean.csv
-- Expected Rows: 144
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Product_Clean.csv'
INTO TABLE product_master
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 6. SALES TARGETS
-- Source: Sales_Targets_Clean.csv
-- Expected Rows: 319
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Sales_Targets_Clean.csv'
INTO TABLE sales_targets
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 7. ORDER TRANSACTIONS
-- Source: Order_Clean.csv
-- Expected Rows: 2,990
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Order_Clean.csv'
INTO TABLE order_transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 8. SALES TRANSACTIONS
-- Source: Sales_Clean.csv
-- Expected Rows: 3,958
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Sales_Clean.csv'
INTO TABLE sales_transactions
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 9. INVOICE DATA
-- Source: Invoice_Clean.csv
-- Expected Rows: 2,747
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Invoice_Clean.csv'
INTO TABLE invoice_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 10. PAYMENT DATA
-- Source: Payment_Clean.csv
-- Expected Rows: 2,595
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Payment_Clean.csv'
INTO TABLE payment_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 11. PURCHASE DATA
-- Source: Purchase_Clean.csv
-- Expected Rows: 1,452
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Purchase_Clean.csv'
INTO TABLE purchase_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 12. INVENTORY DATA
-- Source: Inventory_Clean.csv
-- Expected Rows: 761
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Inventory_Clean.csv'
INTO TABLE inventory_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 13. RETURNS DATA
-- Source: Returns_Clean.csv
-- Expected Rows: 442
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Returns_Clean.csv'
INTO TABLE returns_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 14. ATTENDANCE DATA
-- Source: Attendance_Clean.csv
-- Expected Rows: 6,598
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Attendance_Clean.csv'
INTO TABLE attendance_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- ============================================================
-- 15. CUSTOMER COMPLAINTS
-- Source: Customer_Complaints_Clean.csv
-- Expected Rows: 688
--
-- Customer_Rating contains blank values.
-- Blank ratings are converted to NULL during import.
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Customer_Complaints_Clean.csv'
INTO TABLE customer_complaints
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Complaint_ID,
    Complaint_Date,
    Customer_ID,
    Product_ID,
    Employee_ID,
    Region_ID,
    Complaint_Type,
    Priority,
    Status,
    SLA_Hours,
    Resolution_Hours,
    @Customer_Rating
)
SET Customer_Rating =
    NULLIF(TRIM(BOTH '\r' FROM @Customer_Rating), '');


-- ============================================================
-- 16. MARKETING CAMPAIGN DATA
-- Source: Marketing_Campaign_Clean.csv
-- Expected Rows: 177
-- ============================================================

LOAD DATA LOCAL INFILE
'C:/Users/Hooooo/Documents/Excel/MIS Project/02_Cleaned_Data/Marketing_Campaign_Clean.csv'
INTO TABLE marketing_campaign_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- DATA IMPORT VALIDATION
-- ============================================================

SELECT 'Employee' AS Table_Name, COUNT(*) AS Row_Count
FROM employee_master

UNION ALL
SELECT 'Customer', COUNT(*)
FROM customer_master

UNION ALL
SELECT 'Product', COUNT(*)
FROM product_master

UNION ALL
SELECT 'Region', COUNT(*)
FROM region_master

UNION ALL
SELECT 'Sales Transactions', COUNT(*)
FROM sales_transactions

UNION ALL
SELECT 'Sales Targets', COUNT(*)
FROM sales_targets

UNION ALL
SELECT 'Orders', COUNT(*)
FROM order_transactions

UNION ALL
SELECT 'Invoice', COUNT(*)
FROM invoice_data

UNION ALL
SELECT 'Payment', COUNT(*)
FROM payment_data

UNION ALL
SELECT 'Purchase', COUNT(*)
FROM purchase_data

UNION ALL
SELECT 'Inventory', COUNT(*)
FROM inventory_data

UNION ALL
SELECT 'Supplier', COUNT(*)
FROM supplier_master

UNION ALL
SELECT 'Returns', COUNT(*)
FROM returns_data

UNION ALL
SELECT 'Attendance', COUNT(*)
FROM attendance_data

UNION ALL
SELECT 'Customer Complaints', COUNT(*)
FROM customer_complaints

UNION ALL
SELECT 'Marketing Campaign', COUNT(*)
FROM marketing_campaign_data;


-- ============================================================
-- CUSTOMER RATING NULL VALIDATION
-- Expected:
-- Total_Rows = 688
-- Blank_Ratings = 152
-- ============================================================

SELECT
    COUNT(*) AS Total_Rows,
    SUM(Customer_Rating IS NULL) AS Blank_Ratings
FROM customer_complaints;


-- ============================================================
-- TOTAL CLEAN RECORD VALIDATION
-- Expected Total = 23,642
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM employee_master) +
    (SELECT COUNT(*) FROM customer_master) +
    (SELECT COUNT(*) FROM product_master) +
    (SELECT COUNT(*) FROM region_master) +
    (SELECT COUNT(*) FROM sales_transactions) +
    (SELECT COUNT(*) FROM sales_targets) +
    (SELECT COUNT(*) FROM order_transactions) +
    (SELECT COUNT(*) FROM invoice_data) +
    (SELECT COUNT(*) FROM payment_data) +
    (SELECT COUNT(*) FROM purchase_data) +
    (SELECT COUNT(*) FROM inventory_data) +
    (SELECT COUNT(*) FROM supplier_master) +
    (SELECT COUNT(*) FROM returns_data) +
    (SELECT COUNT(*) FROM attendance_data) +
    (SELECT COUNT(*) FROM customer_complaints) +
    (SELECT COUNT(*) FROM marketing_campaign_data)
    AS Total_Clean_Records;


-- ============================================================
-- EXPECTED FINAL VALIDATION
-- ============================================================
--
-- Employee              =   117
-- Customer              =   597
-- Product               =   144
-- Region                =     8
-- Sales Transactions    = 3,958
-- Sales Targets         =   319
-- Orders                = 2,990
-- Invoice               = 2,747
-- Payment               = 2,595
-- Purchase              = 1,452
-- Inventory             =   761
-- Supplier              =    49
-- Returns               =   442
-- Attendance            = 6,598
-- Customer Complaints   =   688
-- Marketing Campaign    =   177
--
-- TOTAL CLEAN RECORDS   = 23,642
--
-- Customer Rating NULLs = 152
--
-- ============================================================
-- END OF CLEANED DATA IMPORT SCRIPT
-- ============================================================