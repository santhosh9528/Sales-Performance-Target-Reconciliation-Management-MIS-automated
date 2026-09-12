-- ============================================================
-- INTEGRATED BUSINESS PERFORMANCE, MIS & DATA ANALYTICS
-- SQL BUSINESS ANALYSIS
-- File Name: analysis.sql
-- Database: integrated_business
-- ============================================================

USE integrated_business;


-- ============================================================
-- 1. OVERALL SALES PERFORMANCE
-- ============================================================

SELECT
    COUNT(*) AS Total_Transactions,
    SUM(Quantity) AS Total_Quantity,
    ROUND(SUM(Sales_Value), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        (SUM(Profit) / NULLIF(SUM(Sales_Value), 0)) * 100,
        2
    ) AS Profit_Margin_Percentage
FROM sales_transactions;


-- Average Sales Per Transaction

SELECT
    ROUND(AVG(Sales_Value), 2) AS Average_Sales_Per_Transaction
FROM sales_transactions;


-- Highest and Lowest Sales Value

SELECT
    MAX(Sales_Value) AS Highest_Sales_Value,
    MIN(Sales_Value) AS Lowest_Sales_Value
FROM sales_transactions;


-- Highest and Lowest Profit

SELECT
    MAX(Profit) AS Highest_Profit,
    MIN(Profit) AS Lowest_Profit
FROM sales_transactions;



-- ============================================================
-- 2. REGION-WISE SALES PERFORMANCE
-- ============================================================

SELECT
    r.Region_ID,
    r.Region_Name,
    r.Zone,

    COUNT(s.Transaction_ID) AS Total_Transactions,

    COALESCE(SUM(s.Quantity), 0) AS Total_Quantity,

    ROUND(
        COALESCE(SUM(s.Sales_Value), 0),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(SUM(s.Profit), 0),
        2
    ) AS Total_Profit,

    ROUND(
        COALESCE(
            SUM(s.Profit) /
            NULLIF(SUM(s.Sales_Value), 0) * 100,
            0
        ),
        2
    ) AS Profit_Margin_Percentage

FROM region_master r

LEFT JOIN sales_transactions s
    ON r.Region_ID = s.Region_ID

GROUP BY
    r.Region_ID,
    r.Region_Name,
    r.Zone

ORDER BY Total_Sales DESC;



-- ============================================================
-- 3. TOP 10 CUSTOMERS BY SALES
-- ============================================================

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Segment,

    COUNT(s.Transaction_ID) AS Total_Transactions,

    SUM(s.Quantity) AS Total_Quantity,

    ROUND(SUM(s.Sales_Value), 2) AS Total_Sales,

    ROUND(SUM(s.Profit), 2) AS Total_Profit,

    ROUND(
        SUM(s.Profit) /
        NULLIF(SUM(s.Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM customer_master c

JOIN sales_transactions s
    ON c.Customer_ID = s.Customer_ID

GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Segment

ORDER BY Total_Sales DESC

LIMIT 10;



-- ============================================================
-- 4. TOP 10 PRODUCTS BY SALES
-- ============================================================

SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory,

    COUNT(s.Transaction_ID) AS Total_Transactions,

    SUM(s.Quantity) AS Total_Quantity,

    ROUND(SUM(s.Sales_Value), 2) AS Total_Sales,

    ROUND(SUM(s.Profit), 2) AS Total_Profit,

    ROUND(
        SUM(s.Profit) /
        NULLIF(SUM(s.Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM product_master p

JOIN sales_transactions s
    ON p.Product_ID = s.Product_ID

GROUP BY
    p.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory

ORDER BY Total_Sales DESC

LIMIT 10;



-- ============================================================
-- 5. CATEGORY-WISE SALES PERFORMANCE
-- ============================================================

SELECT
    p.Category,

    COUNT(s.Transaction_ID) AS Total_Transactions,

    SUM(s.Quantity) AS Total_Quantity,

    ROUND(SUM(s.Sales_Value), 2) AS Total_Sales,

    ROUND(SUM(s.Profit), 2) AS Total_Profit,

    ROUND(
        SUM(s.Profit) /
        NULLIF(SUM(s.Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions s

JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY p.Category

ORDER BY Total_Sales DESC;



-- ============================================================
-- 6. MONTHLY SALES TREND
-- ============================================================

SELECT
    DATE_FORMAT(Sales_Date, '%Y-%m') AS Sales_Month,

    COUNT(*) AS Total_Transactions,

    SUM(Quantity) AS Total_Quantity,

    ROUND(SUM(Sales_Value), 2) AS Total_Sales,

    ROUND(SUM(Profit), 2) AS Total_Profit,

    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions

GROUP BY
    DATE_FORMAT(Sales_Date, '%Y-%m')

ORDER BY Sales_Month;



-- ============================================================
-- 7. MONTH-ON-MONTH SALES GROWTH
-- ============================================================

WITH Monthly_Sales AS
(
    SELECT
        DATE_FORMAT(Sales_Date, '%Y-%m') AS Sales_Month,
        SUM(Sales_Value) AS Total_Sales

    FROM sales_transactions

    GROUP BY
        DATE_FORMAT(Sales_Date, '%Y-%m')
),

Monthly_Growth AS
(
    SELECT
        Sales_Month,
        Total_Sales,

        LAG(Total_Sales) OVER (
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales

    FROM Monthly_Sales
)

SELECT
    Sales_Month,

    ROUND(Total_Sales, 2) AS Total_Sales,

    ROUND(
        Previous_Month_Sales,
        2
    ) AS Previous_Month_Sales,

    ROUND(
        (
            (Total_Sales - Previous_Month_Sales) /
            NULLIF(Previous_Month_Sales, 0)
        ) * 100,
        2
    ) AS MoM_Growth_Percentage

FROM Monthly_Growth

ORDER BY Sales_Month;



-- ============================================================
-- 8. SALES TARGET VS ACHIEVEMENT
-- ============================================================

WITH Monthly_Employee_Sales AS
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value) AS Actual_Sales

    FROM sales_transactions

    GROUP BY
        Employee_ID,
        DATE_FORMAT(Sales_Date, '%Y-%m')
)

SELECT
    st.Employee_ID,

    e.Employee_Name,

    DATE_FORMAT(
        st.Target_Month,
        '%Y-%m'
    ) AS Target_Month,

    ROUND(st.Sales_Target, 2)
        AS Sales_Target,

    ROUND(
        COALESCE(ms.Actual_Sales, 0),
        2
    ) AS Actual_Sales,

    ROUND(
        COALESCE(ms.Actual_Sales, 0) /
        NULLIF(st.Sales_Target, 0) * 100,
        2
    ) AS Achievement_Percentage,

    CASE
        WHEN COALESCE(ms.Actual_Sales, 0)
             >= st.Sales_Target
        THEN 'Achieved'
        ELSE 'Not Achieved'
    END AS Target_Status

FROM sales_targets st

LEFT JOIN employee_master e
    ON st.Employee_ID = e.Employee_ID

LEFT JOIN Monthly_Employee_Sales ms
    ON st.Employee_ID = ms.Employee_ID
    AND DATE_FORMAT(st.Target_Month, '%Y-%m')
        = ms.Sales_Month

ORDER BY Achievement_Percentage DESC;



-- ============================================================
-- 9. TARGET ACHIEVEMENT SUMMARY
-- ============================================================

WITH Monthly_Employee_Sales AS
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value) AS Actual_Sales

    FROM sales_transactions

    GROUP BY
        Employee_ID,
        DATE_FORMAT(Sales_Date, '%Y-%m')
),

Target_Result AS
(
    SELECT
        st.Target_ID,

        CASE
            WHEN COALESCE(ms.Actual_Sales, 0)
                 >= st.Sales_Target
            THEN 'Achieved'
            ELSE 'Not Achieved'
        END AS Target_Status

    FROM sales_targets st

    LEFT JOIN Monthly_Employee_Sales ms
        ON st.Employee_ID = ms.Employee_ID
        AND DATE_FORMAT(st.Target_Month, '%Y-%m')
            = ms.Sales_Month
)

SELECT
    Target_Status,

    COUNT(*) AS Total_Targets,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Percentage

FROM Target_Result

GROUP BY Target_Status

ORDER BY Total_Targets DESC;



-- ============================================================
-- 10. ORDER STATUS ANALYSIS
-- ============================================================

SELECT
    Order_Status,

    COUNT(*) AS Total_Orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Order_Percentage

FROM order_transactions

GROUP BY Order_Status

ORDER BY Total_Orders DESC;



-- ============================================================
-- 11. ORDER CHANNEL ANALYSIS
-- ============================================================

SELECT
    Order_Channel,

    COUNT(*) AS Total_Orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Order_Percentage

FROM order_transactions

GROUP BY Order_Channel

ORDER BY Total_Orders DESC;



-- ============================================================
-- 12. INVOICE STATUS ANALYSIS
-- ============================================================

SELECT
    Invoice_Status,

    COUNT(*) AS Total_Invoices,

    ROUND(
        SUM(Invoice_Amount),
        2
    ) AS Total_Invoice_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Invoice_Percentage

FROM invoice_data

GROUP BY Invoice_Status

ORDER BY Total_Invoices DESC;



-- ============================================================
-- 13. PAYMENT STATUS ANALYSIS
-- ============================================================

SELECT
    Payment_Status,

    COUNT(*) AS Total_Payments,

    ROUND(
        SUM(Payment_Amount),
        2
    ) AS Total_Payment_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Payment_Percentage

FROM payment_data

GROUP BY Payment_Status

ORDER BY Total_Payments DESC;



-- ============================================================
-- 14. OUTSTANDING RECEIVABLES ANALYSIS
-- Only successful payments are considered.
-- Overpayments are capped at invoice amount.
-- ============================================================

WITH Payment_Summary AS
(
    SELECT
        Invoice_ID,
        SUM(Payment_Amount) AS Total_Paid

    FROM payment_data

    WHERE Payment_Status = 'Success'

    GROUP BY Invoice_ID
)

SELECT
    ROUND(
        SUM(i.Invoice_Amount),
        2
    ) AS Total_Invoice_Amount,

    ROUND(
        SUM(
            LEAST(
                COALESCE(p.Total_Paid, 0),
                i.Invoice_Amount
            )
        ),
        2
    ) AS Total_Amount_Received,

    ROUND(
        SUM(
            GREATEST(
                i.Invoice_Amount -
                COALESCE(p.Total_Paid, 0),
                0
            )
        ),
        2
    ) AS Total_Outstanding_Amount

FROM invoice_data i

LEFT JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID;



-- ============================================================
-- 15. RETURN REASON ANALYSIS
-- ============================================================

SELECT
    Return_Reason,

    COUNT(*) AS Total_Returns,

    SUM(Return_Qty)
        AS Total_Return_Quantity,

    ROUND(
        SUM(Return_Value),
        2
    ) AS Total_Return_Value,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Return_Percentage

FROM returns_data

GROUP BY Return_Reason

ORDER BY Total_Returns DESC;



-- ============================================================
-- 16. INVENTORY STOCK RISK ANALYSIS
-- ============================================================

SELECT
    COUNT(*) AS Total_Inventory_Records,

    SUM(
        CASE
            WHEN i.Closing_Stock <= p.Reorder_Level
            THEN 1
            ELSE 0
        END
    ) AS Low_Stock_Records,

    SUM(
        CASE
            WHEN i.Stockout_Days > 0
            THEN 1
            ELSE 0
        END
    ) AS Stockout_Records,

    ROUND(
        SUM(i.Stock_Value),
        2
    ) AS Total_Stock_Value

FROM inventory_data i

JOIN product_master p
    ON i.Product_ID = p.Product_ID;



-- ============================================================
-- 17. SUPPLIER PERFORMANCE ANALYSIS
-- ============================================================

SELECT
    s.Supplier_ID,

    s.Supplier_Name,

    COUNT(p.Purchase_ID)
        AS Total_Purchases,

    ROUND(
        SUM(p.Purchase_Value),
        2
    ) AS Total_Purchase_Value,

    ROUND(
        AVG(s.Quality_Score),
        2
    ) AS Quality_Score,

    ROUND(
        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ),
        2
    ) AS Average_Delivery_Delay_Days,

    SUM(p.Rejected_Qty)
        AS Total_Rejected_Quantity

FROM supplier_master s

JOIN purchase_data p
    ON s.Supplier_ID = p.Supplier_ID

GROUP BY
    s.Supplier_ID,
    s.Supplier_Name

ORDER BY Total_Purchase_Value DESC;



-- ============================================================
-- 18. TOP 10 EMPLOYEE SALES PERFORMANCE
-- ============================================================

SELECT
    e.Employee_ID,

    e.Employee_Name,

    e.Department,

    e.Designation,

    COUNT(s.Transaction_ID)
        AS Total_Transactions,

    SUM(s.Quantity)
        AS Units_Sold,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Sales,

    ROUND(
        SUM(s.Profit),
        2
    ) AS Total_Profit,

    ROUND(
        SUM(s.Profit) /
        NULLIF(SUM(s.Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM employee_master e

JOIN sales_transactions s
    ON e.Employee_ID = s.Employee_ID

GROUP BY
    e.Employee_ID,
    e.Employee_Name,
    e.Department,
    e.Designation

ORDER BY Total_Sales DESC

LIMIT 10;



-- ============================================================
-- 19. CUSTOMER COMPLAINT & SLA ANALYSIS
-- ============================================================

SELECT
    Complaint_Type,

    COUNT(*) AS Total_Complaints,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN Resolution_Hours > SLA_Hours
            THEN 1
            ELSE 0
        END
    ) AS SLA_Breached_Complaints,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours > SLA_Hours
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS SLA_Breach_Percentage,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Average_Customer_Rating

FROM customer_complaints

GROUP BY Complaint_Type

ORDER BY Total_Complaints DESC;



-- ============================================================
-- 20. MARKETING CAMPAIGN ROI ANALYSIS
-- ============================================================

SELECT
    Channel,

    COUNT(*) AS Total_Campaigns,

    ROUND(
        SUM(Campaign_Spend),
        2
    ) AS Total_Spend,

    SUM(Leads)
        AS Total_Leads,

    SUM(Conversions)
        AS Total_Conversions,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(Conversions) * 100.0 /
        NULLIF(SUM(Leads), 0),
        2
    ) AS Conversion_Rate_Percentage,

    ROUND(
        (
            (SUM(Revenue) - SUM(Campaign_Spend)) /
            NULLIF(SUM(Campaign_Spend), 0)
        ) * 100,
        2
    ) AS ROI_Percentage

FROM marketing_campaign_data

GROUP BY Channel

ORDER BY ROI_Percentage DESC;



-- ============================================================
-- 21. EMPLOYEE ATTENDANCE ANALYSIS
-- ============================================================

SELECT
    Attendance_Status,

    COUNT(*) AS Total_Records,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Percentage,

    ROUND(
        AVG(Working_Hours),
        2
    ) AS Avg_Working_Hours,

    ROUND(
        AVG(Late_Minutes),
        2
    ) AS Avg_Late_Minutes

FROM attendance_data

GROUP BY Attendance_Status

ORDER BY Total_Records DESC;


-- ============================================================
-- END OF SQL BUSINESS ANALYSIS
-- ============================================================


USE integrated_business;

-- ============================================================
-- PART 3 - SQL DATABASE
-- ADDITIONAL / ADVANCED SQL ANALYSIS
-- ============================================================


-- ============================================================
-- 22. DAILY SALES ANALYSIS
-- ============================================================

SELECT
    Sales_Date,
    COUNT(DISTINCT Transaction_ID) AS Total_Transactions,
    SUM(Quantity) AS Quantity_Sold,
    ROUND(SUM(Sales_Value), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        (SUM(Profit) / NULLIF(SUM(Sales_Value), 0)) * 100,
        2
    ) AS Profit_Margin_Percentage
FROM sales_transactions
GROUP BY Sales_Date
ORDER BY Sales_Date;


-- ============================================================
-- 23. MONTHLY SALES ANALYSIS
-- ============================================================

SELECT
    DATE_FORMAT(Sales_Date, '%Y-%m') AS Sales_Month,
    COUNT(DISTINCT Transaction_ID) AS Total_Transactions,
    SUM(Quantity) AS Quantity_Sold,
    ROUND(SUM(Sales_Value), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage
FROM sales_transactions
GROUP BY DATE_FORMAT(Sales_Date, '%Y-%m')
ORDER BY Sales_Month;


-- ============================================================
-- 24. MTD SALES
--
-- Dataset ends in Aug-2026.
-- MAX(Sales_Date) is used instead of CURRENT_DATE so the
-- analysis remains valid for the historical project dataset.
-- ============================================================

SELECT
    DATE_FORMAT(MAX(Sales_Date), '%Y-%m') AS MTD_Month,

    COUNT(DISTINCT Transaction_ID)
        AS MTD_Transactions,

    SUM(Quantity)
        AS MTD_Quantity,

    ROUND(
        SUM(Sales_Value),
        2
    ) AS MTD_Sales,

    ROUND(
        SUM(Profit),
        2
    ) AS MTD_Profit

FROM sales_transactions

WHERE YEAR(Sales_Date) = (
    SELECT YEAR(MAX(Sales_Date))
    FROM sales_transactions
)

AND MONTH(Sales_Date) = (
    SELECT MONTH(MAX(Sales_Date))
    FROM sales_transactions
);


-- ============================================================
-- 25. YTD SALES
-- ============================================================

SELECT
    YEAR(MAX(Sales_Date)) AS YTD_Year,

    COUNT(DISTINCT Transaction_ID)
        AS YTD_Transactions,

    SUM(Quantity)
        AS YTD_Quantity,

    ROUND(
        SUM(Sales_Value),
        2
    ) AS YTD_Sales,

    ROUND(
        SUM(Profit),
        2
    ) AS YTD_Profit,

    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales_Value), 0) * 100,
        2
    ) AS YTD_Profit_Margin

FROM sales_transactions

WHERE YEAR(Sales_Date) = (
    SELECT YEAR(MAX(Sales_Date))
    FROM sales_transactions
);


-- ============================================================
-- 26. GROUP BY + HAVING
-- HIGH REVENUE CUSTOMERS
-- ============================================================

SELECT
    s.Customer_ID,
    c.Customer_Name,

    COUNT(DISTINCT s.Transaction_ID)
        AS Total_Transactions,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(s.Profit),
        2
    ) AS Total_Profit

FROM sales_transactions s

LEFT JOIN customer_master c
    ON s.Customer_ID = c.Customer_ID

GROUP BY
    s.Customer_ID,
    c.Customer_Name

HAVING SUM(s.Sales_Value) > 1000000

ORDER BY Total_Revenue DESC;


-- ============================================================
-- 27. SUBQUERY
-- CUSTOMERS ABOVE AVERAGE CUSTOMER REVENUE
-- ============================================================

SELECT
    Customer_ID,
    ROUND(
        SUM(Sales_Value),
        2
    ) AS Customer_Revenue

FROM sales_transactions

GROUP BY Customer_ID

HAVING SUM(Sales_Value) > (

    SELECT AVG(Customer_Total)

    FROM (

        SELECT
            Customer_ID,
            SUM(Sales_Value)
                AS Customer_Total

        FROM sales_transactions

        GROUP BY Customer_ID

    ) AS Customer_Summary

)

ORDER BY Customer_Revenue DESC;


-- ============================================================
-- 28. CTE
-- MONTHLY SALES & PROFIT ANALYSIS
-- ============================================================

WITH Monthly_Performance AS (

    SELECT
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Total_Sales,

        SUM(Profit)
            AS Total_Profit

    FROM sales_transactions

    GROUP BY
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
)

SELECT
    Sales_Month,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        Total_Profit,
        2
    ) AS Total_Profit,

    ROUND(
        Total_Profit /
        NULLIF(Total_Sales, 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM Monthly_Performance

ORDER BY Sales_Month;


-- ============================================================
-- 29. WINDOW FUNCTION
-- MONTH-ON-MONTH SALES GROWTH
-- ============================================================

WITH Monthly_Sales AS (

    SELECT
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Total_Sales

    FROM sales_transactions

    GROUP BY
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
),

Previous_Month AS (

    SELECT
        Sales_Month,
        Total_Sales,

        LAG(Total_Sales)
        OVER (
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales

    FROM Monthly_Sales
)

SELECT
    Sales_Month,

    ROUND(
        Total_Sales,
        2
    ) AS Current_Month_Sales,

    ROUND(
        Previous_Month_Sales,
        2
    ) AS Previous_Month_Sales,

    ROUND(
        (
            Total_Sales -
            Previous_Month_Sales
        )
        /
        NULLIF(
            Previous_Month_Sales,
            0
        ) * 100,
        2
    ) AS Growth_Percentage

FROM Previous_Month

ORDER BY Sales_Month;


-- ============================================================
-- 30. WINDOW FUNCTION
-- PRODUCT REVENUE RANKING
-- ============================================================

WITH Product_Performance AS (

    SELECT
        s.Product_ID,
        p.Product_Name,
        p.Category,

        SUM(s.Sales_Value)
            AS Total_Revenue,

        SUM(s.Profit)
            AS Total_Profit

    FROM sales_transactions s

    LEFT JOIN product_master p
        ON s.Product_ID = p.Product_ID

    GROUP BY
        s.Product_ID,
        p.Product_Name,
        p.Category
)

SELECT
    Product_ID,
    Product_Name,
    Category,

    ROUND(
        Total_Revenue,
        2
    ) AS Total_Revenue,

    ROUND(
        Total_Profit,
        2
    ) AS Total_Profit,

    RANK() OVER (
        ORDER BY Total_Revenue DESC
    ) AS Revenue_Rank,

    RANK() OVER (
        ORDER BY Total_Profit DESC
    ) AS Profit_Rank

FROM Product_Performance

ORDER BY Revenue_Rank;


-- ============================================================
-- 31. WINDOW FUNCTION
-- EMPLOYEE SALES RANKING
-- ============================================================

WITH Employee_Performance AS (

    SELECT
        s.Employee_ID,
        e.Employee_Name,
        e.Department,

        COUNT(DISTINCT s.Transaction_ID)
            AS Transactions,

        SUM(s.Sales_Value)
            AS Total_Sales,

        SUM(s.Profit)
            AS Total_Profit

    FROM sales_transactions s

    LEFT JOIN employee_master e
        ON s.Employee_ID = e.Employee_ID

    GROUP BY
        s.Employee_ID,
        e.Employee_Name,
        e.Department
)

SELECT
    Employee_ID,
    Employee_Name,
    Department,
    Transactions,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        Total_Profit,
        2
    ) AS Total_Profit,

    DENSE_RANK() OVER (
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank

FROM Employee_Performance

ORDER BY Sales_Rank;


-- ============================================================
-- 32. CASE WHEN
-- CUSTOMER VALUE CLASSIFICATION
-- ============================================================

WITH Customer_Revenue AS (

    SELECT
        Customer_ID,

        SUM(Sales_Value)
            AS Total_Revenue

    FROM sales_transactions

    GROUP BY Customer_ID
)

SELECT
    Customer_ID,

    ROUND(
        Total_Revenue,
        2
    ) AS Total_Revenue,

    CASE

        WHEN Total_Revenue >= 1500000
            THEN 'High Value'

        WHEN Total_Revenue >= 750000
            THEN 'Medium Value'

        ELSE 'Low Value'

    END AS Customer_Value_Category

FROM Customer_Revenue

ORDER BY Total_Revenue DESC;


-- ============================================================
-- 33. VIEW
-- MONTHLY SALES SUMMARY
-- ============================================================

DROP VIEW IF EXISTS vw_monthly_sales_summary;

CREATE VIEW vw_monthly_sales_summary AS

SELECT
    DATE_FORMAT(
        Sales_Date,
        '%Y-%m'
    ) AS Sales_Month,

    COUNT(DISTINCT Transaction_ID)
        AS Total_Transactions,

    SUM(Quantity)
        AS Total_Quantity,

    ROUND(
        SUM(Sales_Value),
        2
    ) AS Total_Sales,

    ROUND(
        SUM(Profit),
        2
    ) AS Total_Profit,

    ROUND(
        SUM(Profit) /
        NULLIF(SUM(Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions

GROUP BY
    DATE_FORMAT(
        Sales_Date,
        '%Y-%m'
    );


-- Test View

SELECT *
FROM vw_monthly_sales_summary
ORDER BY Sales_Month;


-- ============================================================
-- 34. VIEW
-- CUSTOMER REVENUE SUMMARY
-- ============================================================

DROP VIEW IF EXISTS vw_customer_revenue;

CREATE VIEW vw_customer_revenue AS

SELECT
    s.Customer_ID,
    c.Customer_Name,
    c.Segment,
    c.Region_ID,

    COUNT(DISTINCT s.Transaction_ID)
        AS Total_Transactions,

    SUM(s.Quantity)
        AS Total_Quantity,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(s.Profit),
        2
    ) AS Total_Profit

FROM sales_transactions s

LEFT JOIN customer_master c
    ON s.Customer_ID = c.Customer_ID

GROUP BY
    s.Customer_ID,
    c.Customer_Name,
    c.Segment,
    c.Region_ID;


-- Test View

SELECT *
FROM vw_customer_revenue
ORDER BY Total_Revenue DESC;


-- ============================================================
-- 35. VIEW
-- PRODUCT PERFORMANCE
-- ============================================================

DROP VIEW IF EXISTS vw_product_performance;

CREATE VIEW vw_product_performance AS

SELECT
    s.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory,

    SUM(s.Quantity)
        AS Units_Sold,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Revenue,

    ROUND(
        SUM(s.Product_Cost),
        2
    ) AS Product_Cost,

    ROUND(
        SUM(s.Profit),
        2
    ) AS Profit,

    ROUND(
        SUM(s.Profit) /
        NULLIF(SUM(s.Sales_Value), 0) * 100,
        2
    ) AS Profit_Margin

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY
    s.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory;


-- Test View

SELECT *
FROM vw_product_performance
ORDER BY Revenue DESC;


-- ============================================================
-- 36. INDEXES
-- ============================================================
-- MySQL does not support CREATE INDEX IF NOT EXISTS.
-- Run SHOW INDEX first. The CREATE INDEX statements below
-- should be run once only.

SHOW INDEX FROM sales_transactions;
SHOW INDEX FROM order_transactions;
SHOW INDEX FROM invoice_data;
SHOW INDEX FROM payment_data;


-- ============================================================
-- CREATE ANALYTICAL INDEXES
-- Run these CREATE INDEX commands only once.
-- If the index already exists, do not run it again.
-- ============================================================

CREATE INDEX idx_sales_date
ON sales_transactions (Sales_Date);

CREATE INDEX idx_sales_customer
ON sales_transactions (Customer_ID);

CREATE INDEX idx_sales_product
ON sales_transactions (Product_ID);

CREATE INDEX idx_sales_employee
ON sales_transactions (Employee_ID);

CREATE INDEX idx_sales_region
ON sales_transactions (Region_ID);

CREATE INDEX idx_order_customer
ON order_transactions (Customer_ID);

CREATE INDEX idx_invoice_order
ON invoice_data (Order_ID);

CREATE INDEX idx_payment_invoice
ON payment_data (Invoice_ID);


-- ============================================================
-- 37. VERIFY VIEWS
-- ============================================================

SHOW FULL TABLES
WHERE Table_type = 'VIEW';


-- ============================================================
-- 38. VERIFY CREATED INDEXES
-- ============================================================

SHOW INDEX
FROM sales_transactions;

SHOW INDEX
FROM order_transactions;

SHOW INDEX
FROM invoice_data;

SHOW INDEX
FROM payment_data;


-- ============================================================
-- PART 3 SQL REQUIREMENT STATUS
-- ============================================================

/*

SQL DATABASE REQUIREMENTS COVERED:

Daily Sales             - Completed
Monthly Sales           - Completed
MTD Sales               - Completed
YTD Sales               - Completed
Target Achievement      - Completed in earlier analysis
Customer Revenue        - Completed
Product Revenue         - Completed
Product Profitability   - Completed
Regional Performance    - Completed
Employee Performance    - Completed
Returns                 - Completed
Collections             - Completed
Outstanding Payments    - Completed
Inventory               - Completed
Supplier Performance    - Completed

SQL TECHNIQUES:

JOIN                    - Used
GROUP BY                - Used
HAVING                  - Used
CASE WHEN               - Used
Subqueries              - Used
CTEs                    - Used
Window Functions        - Used
Views                   - Used
Indexes                 - Used

*/