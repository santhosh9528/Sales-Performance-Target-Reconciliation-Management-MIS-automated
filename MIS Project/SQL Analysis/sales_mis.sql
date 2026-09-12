USE integrated_business;

-- ============================================================
-- PART 4 - SALES MIS & EMPLOYEE PERFORMANCE
-- ============================================================


-- ============================================================
-- 1. DAILY SALES MIS
-- ============================================================

WITH Daily_Sales AS
(
    SELECT
        Sales_Date,
        SUM(Sales_Value) AS Total_Sales,
        COUNT(DISTINCT Transaction_ID) AS Number_of_Orders,
        SUM(Quantity) AS Quantity_Sold,
        SUM(Profit) AS Total_Profit
    FROM sales_transactions
    GROUP BY Sales_Date
),

Daily_Returns AS
(
    SELECT
        Return_Date,
        SUM(Return_Value) AS Return_Value
    FROM returns_data
    GROUP BY Return_Date
),

Daily_Final AS
(
    SELECT
        d.Sales_Date,
        d.Total_Sales,
        d.Number_of_Orders,
        d.Quantity_Sold,
        d.Total_Profit,

        COALESCE(r.Return_Value,0) AS Return_Value,

        d.Total_Sales -
        COALESCE(r.Return_Value,0) AS Net_Sales,

        d.Total_Sales /
        NULLIF(d.Number_of_Orders,0)
        AS Average_Order_Value,

        LAG(d.Total_Sales)
        OVER(ORDER BY d.Sales_Date)
        AS Previous_Day_Sales

    FROM Daily_Sales d

    LEFT JOIN Daily_Returns r
        ON d.Sales_Date = r.Return_Date
)

SELECT
    Sales_Date,

    ROUND(Total_Sales,2)
        AS Total_Sales,

    Number_of_Orders,

    ROUND(
        Average_Order_Value,
        2
    ) AS Average_Order_Value,

    Quantity_Sold,

    ROUND(
        Return_Value,
        2
    ) AS Return_Value,

    ROUND(
        Net_Sales,
        2
    ) AS Net_Sales,

    ROUND(
        (
            Total_Sales -
            Previous_Day_Sales
        )
        /
        NULLIF(
            Previous_Day_Sales,
            0
        ) * 100,
        2
    ) AS Sales_Growth_Percentage

FROM Daily_Final

ORDER BY Sales_Date;


-- ============================================================
-- 2. MONTHLY SALES MIS
-- ============================================================

WITH Monthly_Sales AS
(
    SELECT
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Total_Sales,

        COUNT(DISTINCT Transaction_ID)
            AS Number_of_Orders,

        SUM(Quantity)
            AS Quantity_Sold,

        SUM(Profit)
            AS Total_Profit

    FROM sales_transactions

    GROUP BY
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
),

Monthly_Returns AS
(
    SELECT
        DATE_FORMAT(
            Return_Date,
            '%Y-%m'
        ) AS Return_Month,

        SUM(Return_Value)
            AS Return_Value

    FROM returns_data

    GROUP BY
        DATE_FORMAT(
            Return_Date,
            '%Y-%m'
        )
),

Monthly_Final AS
(
    SELECT
        m.Sales_Month,
        m.Total_Sales,
        m.Number_of_Orders,
        m.Quantity_Sold,
        m.Total_Profit,

        COALESCE(
            r.Return_Value,
            0
        ) AS Return_Value,

        m.Total_Sales -
        COALESCE(
            r.Return_Value,
            0
        ) AS Net_Sales,

        m.Total_Sales /
        NULLIF(
            m.Number_of_Orders,
            0
        ) AS Average_Order_Value,

        LAG(m.Total_Sales)
        OVER(
            ORDER BY m.Sales_Month
        ) AS Previous_Month_Sales

    FROM Monthly_Sales m

    LEFT JOIN Monthly_Returns r
        ON m.Sales_Month =
           r.Return_Month
)

SELECT
    Sales_Month,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    Number_of_Orders,

    ROUND(
        Average_Order_Value,
        2
    ) AS Average_Order_Value,

    Quantity_Sold,

    ROUND(
        Return_Value,
        2
    ) AS Return_Value,

    ROUND(
        Net_Sales,
        2
    ) AS Net_Sales,

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
    ) AS Sales_Growth_Percentage

FROM Monthly_Final

ORDER BY Sales_Month;


-- ============================================================
-- 3. MONTHLY TARGET ACHIEVEMENT MIS
-- ============================================================

WITH Monthly_Target AS
(
    SELECT
        DATE_FORMAT(
            Target_Month,
            '%Y-%m'
        ) AS Target_Month,

        SUM(Sales_Target)
            AS Sales_Target

    FROM sales_targets

    GROUP BY
        DATE_FORMAT(
            Target_Month,
            '%Y-%m'
        )
),

Monthly_Sales AS
(
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
)

SELECT
    t.Target_Month,

    ROUND(
        t.Sales_Target,
        2
    ) AS Sales_Target,

    ROUND(
        COALESCE(
            s.Total_Sales,
            0
        ),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(
            s.Total_Sales,
            0
        )
        /
        NULLIF(
            t.Sales_Target,
            0
        ) * 100,
        2
    ) AS Target_Achievement_Percentage,

    ROUND(
        COALESCE(
            s.Total_Sales,
            0
        )
        -
        t.Sales_Target,
        2
    ) AS Sales_Gap

FROM Monthly_Target t

LEFT JOIN Monthly_Sales s
    ON t.Target_Month =
       s.Sales_Month

ORDER BY t.Target_Month;


-- ============================================================
-- 4. EMPLOYEE PERFORMANCE BASE
-- ============================================================

WITH Employee_Sales AS
(
    SELECT
        Employee_ID,

        COUNT(DISTINCT Transaction_ID)
            AS Order_Count,

        SUM(Sales_Value)
            AS Total_Sales,

        SUM(Quantity)
            AS Quantity_Sold

    FROM sales_transactions

    GROUP BY Employee_ID
),

Employee_Target AS
(
    SELECT
        Employee_ID,

        SUM(Sales_Target)
            AS Sales_Target

    FROM sales_targets

    GROUP BY Employee_ID
),

Employee_Return AS
(
    SELECT
        s.Employee_ID,

        SUM(r.Return_Value)
            AS Return_Value

    FROM returns_data r

    INNER JOIN sales_transactions s
        ON r.Transaction_ID =
           s.Transaction_ID

    GROUP BY s.Employee_ID
)

SELECT
    es.Employee_ID,

    e.Employee_Name,

    ROUND(
        es.Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(
            et.Sales_Target,
            0
        ),
        2
    ) AS Sales_Target,

    ROUND(
        es.Total_Sales /
        NULLIF(
            et.Sales_Target,
            0
        ) * 100,
        2
    ) AS Target_Achievement_Percentage,

    es.Order_Count,

    ROUND(
        es.Total_Sales /
        NULLIF(
            es.Order_Count,
            0
        ),
        2
    ) AS Average_Order_Value,

    es.Quantity_Sold,

    ROUND(
        COALESCE(
            er.Return_Value,
            0
        ),
        2
    ) AS Return_Value,

    ROUND(
        es.Total_Sales -
        COALESCE(
            er.Return_Value,
            0
        ),
        2
    ) AS Net_Sales

FROM Employee_Sales es

LEFT JOIN employee_master e
    ON es.Employee_ID =
       e.Employee_ID

LEFT JOIN Employee_Target et
    ON es.Employee_ID =
       et.Employee_ID

LEFT JOIN Employee_Return er
    ON es.Employee_ID =
       er.Employee_ID

ORDER BY Total_Sales DESC;


-- ============================================================
-- 5. EMPLOYEE MONTHLY SALES GROWTH
-- ============================================================

WITH Employee_Monthly AS
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Monthly_Sales

    FROM sales_transactions

    GROUP BY
        Employee_ID,
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
),

Growth AS
(
    SELECT
        Employee_ID,
        Sales_Month,
        Monthly_Sales,

        LAG(Monthly_Sales)
        OVER(
            PARTITION BY Employee_ID
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales

    FROM Employee_Monthly
)

SELECT
    Employee_ID,
    Sales_Month,

    ROUND(
        Monthly_Sales,
        2
    ) AS Monthly_Sales,

    ROUND(
        Previous_Month_Sales,
        2
    ) AS Previous_Month_Sales,

    ROUND(
        (
            Monthly_Sales -
            Previous_Month_Sales
        )
        /
        NULLIF(
            Previous_Month_Sales,
            0
        ) * 100,
        2
    ) AS Revenue_Growth_Percentage

FROM Growth

ORDER BY
    Employee_ID,
    Sales_Month;


-- ============================================================
-- 6. EMPLOYEE OVERALL RANKING
-- ============================================================

WITH Employee_Performance AS
(
    SELECT
        s.Employee_ID,
        e.Employee_Name,

        SUM(s.Sales_Value)
            AS Total_Sales,

        COUNT(DISTINCT s.Transaction_ID)
            AS Order_Count,

        SUM(s.Sales_Value) /
        NULLIF(
            COUNT(DISTINCT s.Transaction_ID),
            0
        ) AS Average_Order_Value

    FROM sales_transactions s

    LEFT JOIN employee_master e
        ON s.Employee_ID =
           e.Employee_ID

    GROUP BY
        s.Employee_ID,
        e.Employee_Name
)

SELECT
    Employee_ID,
    Employee_Name,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    Order_Count,

    ROUND(
        Average_Order_Value,
        2
    ) AS Average_Order_Value,

    RANK()
    OVER(
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank,

    RANK()
    OVER(
        ORDER BY Order_Count DESC
    ) AS Order_Rank,

    RANK()
    OVER(
        ORDER BY Average_Order_Value DESC
    ) AS AOV_Rank

FROM Employee_Performance

ORDER BY Sales_Rank;


-- ============================================================
-- 7. TOP 10 EMPLOYEES
-- ============================================================

SELECT
    s.Employee_ID,
    e.Employee_Name,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Sales,

    COUNT(DISTINCT s.Transaction_ID)
        AS Order_Count,

    ROUND(
        SUM(s.Sales_Value) /
        NULLIF(
            COUNT(DISTINCT s.Transaction_ID),
            0
        ),
        2
    ) AS Average_Order_Value

FROM sales_transactions s

LEFT JOIN employee_master e
    ON s.Employee_ID =
       e.Employee_ID

GROUP BY
    s.Employee_ID,
    e.Employee_Name

ORDER BY Total_Sales DESC

LIMIT 10;


-- ============================================================
-- 8. BOTTOM 10 EMPLOYEES
-- ============================================================

SELECT
    s.Employee_ID,
    e.Employee_Name,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Sales,

    COUNT(DISTINCT s.Transaction_ID)
        AS Order_Count,

    ROUND(
        SUM(s.Sales_Value) /
        NULLIF(
            COUNT(DISTINCT s.Transaction_ID),
            0
        ),
        2
    ) AS Average_Order_Value

FROM sales_transactions s

LEFT JOIN employee_master e
    ON s.Employee_ID =
       e.Employee_ID

GROUP BY
    s.Employee_ID,
    e.Employee_Name

ORDER BY Total_Sales ASC

LIMIT 10;


-- ============================================================
-- 9. EMPLOYEES BELOW 70% TARGET
-- ============================================================

WITH Sales_Total AS
(
    SELECT
        Employee_ID,
        SUM(Sales_Value)
            AS Total_Sales

    FROM sales_transactions

    GROUP BY Employee_ID
),

Target_Total AS
(
    SELECT
        Employee_ID,
        SUM(Sales_Target)
            AS Sales_Target

    FROM sales_targets

    GROUP BY Employee_ID
)

SELECT
    s.Employee_ID,
    e.Employee_Name,

    ROUND(
        s.Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        t.Sales_Target,
        2
    ) AS Sales_Target,

    ROUND(
        s.Total_Sales /
        NULLIF(
            t.Sales_Target,
            0
        ) * 100,
        2
    ) AS Achievement_Percentage

FROM Sales_Total s

INNER JOIN Target_Total t
    ON s.Employee_ID =
       t.Employee_ID

LEFT JOIN employee_master e
    ON s.Employee_ID =
       e.Employee_ID

WHERE
    (
        s.Total_Sales /
        NULLIF(
            t.Sales_Target,
            0
        )
    ) * 100 < 70

ORDER BY Achievement_Percentage ASC;


-- ============================================================
-- 10. EMPLOYEES WITH DECLINING SALES
--
-- Compares each employee's latest available month
-- with their immediately previous sales month.
-- ============================================================

WITH Employee_Monthly AS
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Monthly_Sales

    FROM sales_transactions

    GROUP BY
        Employee_ID,
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
),

Employee_Growth AS
(
    SELECT
        Employee_ID,
        Sales_Month,
        Monthly_Sales,

        LAG(Monthly_Sales)
        OVER(
            PARTITION BY Employee_ID
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales,

        ROW_NUMBER()
        OVER(
            PARTITION BY Employee_ID
            ORDER BY Sales_Month DESC
        ) AS rn

    FROM Employee_Monthly
)

SELECT
    g.Employee_ID,
    e.Employee_Name,
    g.Sales_Month,

    ROUND(
        g.Monthly_Sales,
        2
    ) AS Current_Sales,

    ROUND(
        g.Previous_Month_Sales,
        2
    ) AS Previous_Sales,

    ROUND(
        (
            g.Monthly_Sales -
            g.Previous_Month_Sales
        )
        /
        NULLIF(
            g.Previous_Month_Sales,
            0
        ) * 100,
        2
    ) AS Growth_Percentage

FROM Employee_Growth g

LEFT JOIN employee_master e
    ON g.Employee_ID =
       e.Employee_ID

WHERE g.rn = 1
  AND g.Monthly_Sales <
      g.Previous_Month_Sales

ORDER BY Growth_Percentage ASC;


-- ============================================================
-- 11. EMPLOYEE RETURN ANALYSIS
-- ============================================================

WITH Employee_Returns AS
(
    SELECT
        s.Employee_ID,

        SUM(r.Return_Value)
            AS Return_Value,

        COUNT(DISTINCT r.Return_ID)
            AS Return_Count

    FROM returns_data r

    INNER JOIN sales_transactions s
        ON r.Transaction_ID =
           s.Transaction_ID

    GROUP BY s.Employee_ID
),

Employee_Sales AS
(
    SELECT
        Employee_ID,

        SUM(Sales_Value)
            AS Total_Sales

    FROM sales_transactions

    GROUP BY Employee_ID
)

SELECT
    es.Employee_ID,
    e.Employee_Name,

    ROUND(
        es.Total_Sales,
        2
    ) AS Total_Sales,

    COALESCE(
        er.Return_Count,
        0
    ) AS Return_Count,

    ROUND(
        COALESCE(
            er.Return_Value,
            0
        ),
        2
    ) AS Return_Value,

    ROUND(
        COALESCE(
            er.Return_Value,
            0
        )
        /
        NULLIF(
            es.Total_Sales,
            0
        ) * 100,
        2
    ) AS Return_Rate_Percentage

FROM Employee_Sales es

LEFT JOIN Employee_Returns er
    ON es.Employee_ID =
       er.Employee_ID

LEFT JOIN employee_master e
    ON es.Employee_ID =
       e.Employee_ID

ORDER BY Return_Rate_Percentage DESC;


-- ============================================================
-- 12. UNUSUALLY HIGH RETURNS
--
-- Employees whose return rate is greater than:
-- Average Return Rate + 1 Standard Deviation
-- ============================================================

WITH Employee_Base AS
(
    SELECT
        s.Employee_ID,

        SUM(s.Sales_Value)
            AS Total_Sales,

        COALESCE(
            SUM(r.Return_Value),
            0
        ) AS Return_Value

    FROM sales_transactions s

    LEFT JOIN returns_data r
        ON s.Transaction_ID =
           r.Transaction_ID

    GROUP BY s.Employee_ID
),

Return_Rates AS
(
    SELECT
        Employee_ID,
        Total_Sales,
        Return_Value,

        Return_Value /
        NULLIF(
            Total_Sales,
            0
        ) * 100 AS Return_Rate

    FROM Employee_Base
),

Threshold AS
(
    SELECT
        AVG(Return_Rate)
            AS Avg_Return_Rate,

        STDDEV_POP(Return_Rate)
            AS Std_Return_Rate

    FROM Return_Rates
)

SELECT
    rr.Employee_ID,
    e.Employee_Name,

    ROUND(
        rr.Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        rr.Return_Value,
        2
    ) AS Return_Value,

    ROUND(
        rr.Return_Rate,
        2
    ) AS Return_Rate_Percentage,

    ROUND(
        t.Avg_Return_Rate +
        t.Std_Return_Rate,
        2
    ) AS High_Return_Threshold

FROM Return_Rates rr

CROSS JOIN Threshold t

LEFT JOIN employee_master e
    ON rr.Employee_ID =
       e.Employee_ID

WHERE
    rr.Return_Rate >
    (
        t.Avg_Return_Rate +
        t.Std_Return_Rate
    )

ORDER BY
    rr.Return_Rate DESC;


-- ============================================================
-- 13. FINAL SALES MIS SUMMARY
-- ============================================================

SELECT
    ROUND(
        SUM(Sales_Value),
        2
    ) AS Total_Sales,

    COUNT(DISTINCT Transaction_ID)
        AS Number_of_Orders,

    ROUND(
        SUM(Sales_Value) /
        NULLIF(
            COUNT(DISTINCT Transaction_ID),
            0
        ),
        2
    ) AS Average_Order_Value,

    SUM(Quantity)
        AS Quantity_Sold,

    ROUND(
        SUM(Profit),
        2
    ) AS Total_Profit,

    ROUND(
        SUM(Profit) /
        NULLIF(
            SUM(Sales_Value),
            0
        ) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions;


-- ============================================================
-- PART 4 STATUS
-- ============================================================

/*

SALES MIS
---------
Daily Sales MIS              - Completed
Monthly Sales MIS            - Completed
Total Sales                   - Completed
Sales Target                  - Completed
Target Achievement %          - Completed
Sales Gap                     - Completed
Sales Growth %                - Completed
Number of Orders              - Completed
Average Order Value           - Completed
Quantity Sold                 - Completed
Return Value                  - Completed
Net Sales                     - Completed


EMPLOYEE PERFORMANCE
--------------------
Sales Ranking                 - Completed
Target Achievement            - Completed
Order Count                   - Completed
Revenue Growth                - Completed
Average Order Value           - Completed

Top 10 Performers             - Completed
Bottom 10 Performers          - Completed
Below 70% Target              - Completed
Declining Sales               - Completed
Unusually High Returns        - Completed

*/