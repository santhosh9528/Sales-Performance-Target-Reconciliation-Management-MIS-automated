USE integrated_business;

-- ============================================================
-- PART 6 - CUSTOMER ANALYTICS & SEGMENTATION
-- ============================================================


-- ============================================================
-- 1. CUSTOMER KPI SUMMARY
-- Active = purchase within last 90 days of dataset max date
-- Inactive = no purchase in last 90 days / never purchased
-- New = first purchase occurred in latest available month
-- Repeat = more than 1 distinct order
-- ============================================================

WITH Max_Date AS (
    SELECT MAX(Sales_Date) AS Max_Sales_Date
    FROM sales_transactions
),

Customer_Stats AS (
    SELECT
        c.Customer_ID,
        MIN(s.Sales_Date) AS First_Purchase,
        MAX(s.Sales_Date) AS Last_Purchase,
        COUNT(DISTINCT s.Order_ID) AS Order_Count,
        COALESCE(SUM(s.Sales_Value), 0) AS Revenue
    FROM customer_master c
    LEFT JOIN sales_transactions s
        ON c.Customer_ID = s.Customer_ID
    GROUP BY c.Customer_ID
)

SELECT
    COUNT(*) AS Total_Customers,

    SUM(
        CASE
            WHEN DATE_FORMAT(First_Purchase,'%Y-%m') =
                 DATE_FORMAT(md.Max_Sales_Date,'%Y-%m')
            THEN 1 ELSE 0
        END
    ) AS New_Customers,

    SUM(
        CASE WHEN Order_Count > 1
        THEN 1 ELSE 0 END
    ) AS Repeat_Customers,

    SUM(
        CASE
            WHEN Last_Purchase >= DATE_SUB(md.Max_Sales_Date, INTERVAL 90 DAY)
            THEN 1 ELSE 0
        END
    ) AS Active_Customers,

    SUM(
        CASE
            WHEN Last_Purchase < DATE_SUB(md.Max_Sales_Date, INTERVAL 90 DAY)
                 OR Last_Purchase IS NULL
            THEN 1 ELSE 0
        END
    ) AS Inactive_Customers,

    ROUND(
        AVG(CASE WHEN Revenue > 0 THEN Revenue END),
        2
    ) AS Average_Customer_Spend

FROM Customer_Stats
CROSS JOIN Max_Date md;


-- ============================================================
-- 2. CUSTOMER LEVEL ANALYSIS
-- Revenue, AOV, Frequency, Recency
-- ============================================================

WITH Max_Date AS (
    SELECT MAX(Sales_Date) AS Max_Sales_Date
    FROM sales_transactions
)

SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Segment,
    c.City,
    c.Status,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0),
        2
    ) AS Total_Revenue,

    COUNT(DISTINCT s.Order_ID)
        AS Purchase_Frequency,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0)
        /
        NULLIF(COUNT(DISTINCT s.Order_ID),0),
        2
    ) AS Average_Order_Value,

    MIN(s.Sales_Date)
        AS First_Purchase_Date,

    MAX(s.Sales_Date)
        AS Last_Purchase_Date,

    DATEDIFF(
        md.Max_Sales_Date,
        MAX(s.Sales_Date)
    ) AS Recency_Days

FROM customer_master c

LEFT JOIN sales_transactions s
    ON c.Customer_ID = s.Customer_ID

CROSS JOIN Max_Date md

GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Segment,
    c.City,
    c.Status,
    md.Max_Sales_Date

ORDER BY Total_Revenue DESC;


-- ============================================================
-- 3. OVERALL AOV + PURCHASE FREQUENCY
-- ============================================================

SELECT
    ROUND(
        SUM(Sales_Value)
        /
        NULLIF(COUNT(DISTINCT Order_ID),0),
        2
    ) AS Overall_Average_Order_Value,

    COUNT(DISTINCT Customer_ID)
        AS Purchasing_Customers,

    COUNT(DISTINCT Order_ID)
        AS Total_Orders,

    ROUND(
        COUNT(DISTINCT Order_ID)
        /
        NULLIF(COUNT(DISTINCT Customer_ID),0),
        2
    ) AS Average_Purchase_Frequency

FROM sales_transactions;


-- ============================================================
-- 4. CUSTOMER SEGMENTATION
--
-- Rules:
-- Inactive = Recency > 180 days / no purchase
-- At Risk  = Recency 91-180 days
-- VIP      = Revenue >= 90th percentile threshold
-- High Value = Revenue >= 75th percentile threshold
-- Regular  = Revenue >= median
-- Low Value = Revenue < median
-- ============================================================

WITH Max_Date AS (
    SELECT MAX(Sales_Date) AS Max_Sales_Date
    FROM sales_transactions
),

Customer_Base AS (
    SELECT
        c.Customer_ID,
        c.Customer_Name,

        COALESCE(SUM(s.Sales_Value),0)
            AS Total_Revenue,

        COUNT(DISTINCT s.Order_ID)
            AS Purchase_Frequency,

        MAX(s.Sales_Date)
            AS Last_Purchase,

        DATEDIFF(
            md.Max_Sales_Date,
            MAX(s.Sales_Date)
        ) AS Recency_Days

    FROM customer_master c

    LEFT JOIN sales_transactions s
        ON c.Customer_ID = s.Customer_ID

    CROSS JOIN Max_Date md

    GROUP BY
        c.Customer_ID,
        c.Customer_Name,
        md.Max_Sales_Date
),

Ranked AS (
    SELECT
        *,

        PERCENT_RANK()
        OVER(
            ORDER BY Total_Revenue
        ) AS Revenue_Percentile

    FROM Customer_Base
),

Segmented AS (
    SELECT
        *,

        CASE
            WHEN Last_Purchase IS NULL
                 OR Recency_Days > 180
                THEN 'Inactive'

            WHEN Recency_Days BETWEEN 91 AND 180
                THEN 'At Risk'

            WHEN Revenue_Percentile >= 0.90
                THEN 'VIP'

            WHEN Revenue_Percentile >= 0.75
                THEN 'High Value'

            WHEN Revenue_Percentile >= 0.50
                THEN 'Regular'

            ELSE 'Low Value'
        END AS Customer_Segment

    FROM Ranked
)

SELECT
    Customer_ID,
    Customer_Name,

    ROUND(Total_Revenue,2)
        AS Total_Revenue,

    Purchase_Frequency,

    Recency_Days,

    Customer_Segment

FROM Segmented

ORDER BY Total_Revenue DESC;


-- ============================================================
-- 5. CUSTOMER SEGMENT SUMMARY
-- ============================================================

WITH Max_Date AS (
    SELECT MAX(Sales_Date) AS Max_Sales_Date
    FROM sales_transactions
),

Customer_Base AS (
    SELECT
        c.Customer_ID,

        COALESCE(SUM(s.Sales_Value),0)
            AS Total_Revenue,

        COUNT(DISTINCT s.Order_ID)
            AS Purchase_Frequency,

        MAX(s.Sales_Date)
            AS Last_Purchase,

        DATEDIFF(
            md.Max_Sales_Date,
            MAX(s.Sales_Date)
        ) AS Recency_Days

    FROM customer_master c

    LEFT JOIN sales_transactions s
        ON c.Customer_ID = s.Customer_ID

    CROSS JOIN Max_Date md

    GROUP BY
        c.Customer_ID,
        md.Max_Sales_Date
),

Ranked AS (
    SELECT
        *,
        PERCENT_RANK()
        OVER(ORDER BY Total_Revenue)
            AS Revenue_Percentile
    FROM Customer_Base
),

Segmented AS (
    SELECT
        *,

        CASE
            WHEN Last_Purchase IS NULL
                 OR Recency_Days > 180
                THEN 'Inactive'

            WHEN Recency_Days BETWEEN 91 AND 180
                THEN 'At Risk'

            WHEN Revenue_Percentile >= 0.90
                THEN 'VIP'

            WHEN Revenue_Percentile >= 0.75
                THEN 'High Value'

            WHEN Revenue_Percentile >= 0.50
                THEN 'Regular'

            ELSE 'Low Value'
        END AS Customer_Segment

    FROM Ranked
)

SELECT
    Customer_Segment,

    COUNT(*) AS Customer_Count,

    ROUND(
        SUM(Total_Revenue),
        2
    ) AS Segment_Revenue,

    ROUND(
        AVG(Total_Revenue),
        2
    ) AS Average_Customer_Revenue,

    ROUND(
        AVG(Purchase_Frequency),
        2
    ) AS Average_Purchase_Frequency,

    ROUND(
        AVG(Recency_Days),
        2
    ) AS Average_Recency_Days

FROM Segmented

GROUP BY Customer_Segment

ORDER BY Segment_Revenue DESC;


-- ============================================================
-- 6. TOP 10 CUSTOMERS BY REVENUE
-- ============================================================

SELECT
    s.Customer_ID,
    c.Customer_Name,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Revenue,

    COUNT(DISTINCT s.Order_ID)
        AS Order_Count,

    ROUND(
        SUM(s.Sales_Value)
        /
        NULLIF(COUNT(DISTINCT s.Order_ID),0),
        2
    ) AS Average_Order_Value

FROM sales_transactions s

LEFT JOIN customer_master c
    ON s.Customer_ID = c.Customer_ID

GROUP BY
    s.Customer_ID,
    c.Customer_Name

ORDER BY Total_Revenue DESC

LIMIT 10;


-- ============================================================
-- 7. HIGH REVENUE + LOW PURCHASE FREQUENCY
--
-- High Revenue = Above average customer revenue
-- Low Frequency = Below average customer order frequency
-- ============================================================

WITH Customer_Performance AS (
    SELECT
        s.Customer_ID,
        c.Customer_Name,

        SUM(s.Sales_Value)
            AS Total_Revenue,

        COUNT(DISTINCT s.Order_ID)
            AS Purchase_Frequency

    FROM sales_transactions s

    LEFT JOIN customer_master c
        ON s.Customer_ID = c.Customer_ID

    GROUP BY
        s.Customer_ID,
        c.Customer_Name
),

Benchmarks AS (
    SELECT
        AVG(Total_Revenue)
            AS Avg_Revenue,

        AVG(Purchase_Frequency)
            AS Avg_Frequency

    FROM Customer_Performance
)

SELECT
    cp.Customer_ID,
    cp.Customer_Name,

    ROUND(cp.Total_Revenue,2)
        AS Total_Revenue,

    cp.Purchase_Frequency,

    ROUND(b.Avg_Revenue,2)
        AS Average_Revenue_Benchmark,

    ROUND(b.Avg_Frequency,2)
        AS Average_Frequency_Benchmark

FROM Customer_Performance cp

CROSS JOIN Benchmarks b

WHERE cp.Total_Revenue > b.Avg_Revenue
  AND cp.Purchase_Frequency < b.Avg_Frequency

ORDER BY cp.Total_Revenue DESC;


-- ============================================================
-- 8. HIGH PURCHASE FREQUENCY + LOW REVENUE
-- ============================================================

WITH Customer_Performance AS (
    SELECT
        s.Customer_ID,
        c.Customer_Name,

        SUM(s.Sales_Value)
            AS Total_Revenue,

        COUNT(DISTINCT s.Order_ID)
            AS Purchase_Frequency

    FROM sales_transactions s

    LEFT JOIN customer_master c
        ON s.Customer_ID = c.Customer_ID

    GROUP BY
        s.Customer_ID,
        c.Customer_Name
),

Benchmarks AS (
    SELECT
        AVG(Total_Revenue)
            AS Avg_Revenue,

        AVG(Purchase_Frequency)
            AS Avg_Frequency

    FROM Customer_Performance
)

SELECT
    cp.Customer_ID,
    cp.Customer_Name,

    ROUND(cp.Total_Revenue,2)
        AS Total_Revenue,

    cp.Purchase_Frequency,

    ROUND(b.Avg_Revenue,2)
        AS Average_Revenue_Benchmark,

    ROUND(b.Avg_Frequency,2)
        AS Average_Frequency_Benchmark

FROM Customer_Performance cp

CROSS JOIN Benchmarks b

WHERE cp.Total_Revenue < b.Avg_Revenue
  AND cp.Purchase_Frequency > b.Avg_Frequency

ORDER BY cp.Purchase_Frequency DESC,
         cp.Total_Revenue ASC;


-- ============================================================
-- 9. NEW VS REPEAT CUSTOMER REVENUE
-- ============================================================

WITH Customer_Data AS (
    SELECT
        Customer_ID,

        COUNT(DISTINCT Order_ID)
            AS Order_Count,

        SUM(Sales_Value)
            AS Revenue

    FROM sales_transactions

    GROUP BY Customer_ID
)

SELECT
    CASE
        WHEN Order_Count = 1
            THEN 'New / One-Time'
        ELSE 'Repeat'
    END AS Customer_Type,

    COUNT(*) AS Customer_Count,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        AVG(Revenue),
        2
    ) AS Average_Revenue

FROM Customer_Data

GROUP BY
    CASE
        WHEN Order_Count = 1
            THEN 'New / One-Time'
        ELSE 'Repeat'
    END;


-- ============================================================
-- 10. ACTIVE VS INACTIVE CUSTOMER REVENUE
-- ============================================================

WITH Max_Date AS (
    SELECT MAX(Sales_Date) AS Max_Sales_Date
    FROM sales_transactions
),

Customer_Data AS (
    SELECT
        c.Customer_ID,

        MAX(s.Sales_Date)
            AS Last_Purchase,

        COALESCE(
            SUM(s.Sales_Value),
            0
        ) AS Revenue

    FROM customer_master c

    LEFT JOIN sales_transactions s
        ON c.Customer_ID = s.Customer_ID

    GROUP BY c.Customer_ID
)

SELECT
    CASE
        WHEN Last_Purchase >=
             DATE_SUB(md.Max_Sales_Date, INTERVAL 90 DAY)
            THEN 'Active'
        ELSE 'Inactive'
    END AS Activity_Status,

    COUNT(*) AS Customer_Count,

    ROUND(
        SUM(Revenue),
        2
    ) AS Total_Revenue,

    ROUND(
        AVG(Revenue),
        2
    ) AS Average_Revenue

FROM Customer_Data

CROSS JOIN Max_Date md

GROUP BY Activity_Status;


-- ============================================================
-- PART 6 COMPLETE
-- ============================================================