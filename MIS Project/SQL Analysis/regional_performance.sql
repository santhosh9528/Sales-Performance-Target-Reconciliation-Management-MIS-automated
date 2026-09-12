USE integrated_business;

-- ============================================================
-- PART 5 - REGIONAL PERFORMANCE ANALYSIS
-- ============================================================


-- ============================================================
-- 1. OVERALL REGIONAL PERFORMANCE
-- ============================================================

WITH Region_Sales AS
(
    SELECT
        Region_ID,
        SUM(Sales_Value) AS Actual_Sales,
        SUM(Profit) AS Profit,
        COUNT(DISTINCT Transaction_ID) AS Orders,
        SUM(Quantity) AS Quantity_Sold
    FROM sales_transactions
    GROUP BY Region_ID
),

Region_Target AS
(
    SELECT
        Region_ID,
        SUM(Sales_Target) AS Sales_Target
    FROM sales_targets
    GROUP BY Region_ID
),

Company_Total AS
(
    SELECT
        SUM(Sales_Value) AS Company_Sales
    FROM sales_transactions
)

SELECT
    rs.Region_ID,
    r.Region_Name,

    ROUND(rs.Actual_Sales,2)
        AS Actual_Sales,

    ROUND(
        COALESCE(rt.Sales_Target,0),
        2
    ) AS Sales_Target,

    ROUND(
        rs.Actual_Sales /
        NULLIF(rt.Sales_Target,0) * 100,
        2
    ) AS Target_Achievement_Percentage,

    ROUND(
        rs.Actual_Sales -
        COALESCE(rt.Sales_Target,0),
        2
    ) AS Sales_Gap,

    ROUND(rs.Profit,2)
        AS Profit,

    ROUND(
        rs.Profit /
        NULLIF(rs.Actual_Sales,0) * 100,
        2
    ) AS Profit_Margin_Percentage,

    rs.Orders,

    rs.Quantity_Sold,

    ROUND(
        rs.Actual_Sales /
        NULLIF(ct.Company_Sales,0) * 100,
        2
    ) AS Revenue_Contribution_Percentage

FROM Region_Sales rs

LEFT JOIN region_master r
    ON rs.Region_ID = r.Region_ID

LEFT JOIN Region_Target rt
    ON rs.Region_ID = rt.Region_ID

CROSS JOIN Company_Total ct

ORDER BY Actual_Sales DESC;


-- ============================================================
-- 2. MONTHLY REGIONAL SALES
-- ============================================================

SELECT
    Region_ID,

    DATE_FORMAT(
        Sales_Date,
        '%Y-%m'
    ) AS Sales_Month,

    ROUND(
        SUM(Sales_Value),
        2
    ) AS Monthly_Sales,

    ROUND(
        SUM(Profit),
        2
    ) AS Monthly_Profit

FROM sales_transactions

GROUP BY
    Region_ID,
    DATE_FORMAT(Sales_Date,'%Y-%m')

ORDER BY
    Region_ID,
    Sales_Month;


-- ============================================================
-- 3. CURRENT MONTH VS PREVIOUS MONTH
-- ============================================================

WITH Monthly_Region AS
(
    SELECT
        Region_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Monthly_Sales

    FROM sales_transactions

    GROUP BY
        Region_ID,
        DATE_FORMAT(Sales_Date,'%Y-%m')
),

Growth_Calc AS
(
    SELECT
        Region_ID,
        Sales_Month,
        Monthly_Sales,

        LAG(Monthly_Sales)
        OVER(
            PARTITION BY Region_ID
            ORDER BY Sales_Month
        ) AS Previous_Month_Sales,

        ROW_NUMBER()
        OVER(
            PARTITION BY Region_ID
            ORDER BY Sales_Month DESC
        ) AS rn

    FROM Monthly_Region
)

SELECT
    g.Region_ID,
    r.Region_Name,

    g.Sales_Month,

    ROUND(
        g.Monthly_Sales,
        2
    ) AS Current_Month_Sales,

    ROUND(
        g.Previous_Month_Sales,
        2
    ) AS Previous_Month_Sales,

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

FROM Growth_Calc g

LEFT JOIN region_master r
    ON g.Region_ID = r.Region_ID

WHERE g.rn = 1

ORDER BY Growth_Percentage DESC;


-- ============================================================
-- 4. REGIONAL TARGET ACHIEVEMENT BY MONTH
-- ============================================================

WITH Monthly_Region_Sales AS
(
    SELECT
        Region_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Actual_Sales

    FROM sales_transactions

    GROUP BY
        Region_ID,
        DATE_FORMAT(Sales_Date,'%Y-%m')
),

Monthly_Region_Target AS
(
    SELECT
        Region_ID,

        DATE_FORMAT(
            Target_Month,
            '%Y-%m'
        ) AS Target_Month,

        SUM(Sales_Target)
            AS Sales_Target

    FROM sales_targets

    GROUP BY
        Region_ID,
        DATE_FORMAT(Target_Month,'%Y-%m')
)

SELECT
    t.Region_ID,
    r.Region_Name,
    t.Target_Month,

    ROUND(
        t.Sales_Target,
        2
    ) AS Sales_Target,

    ROUND(
        COALESCE(s.Actual_Sales,0),
        2
    ) AS Actual_Sales,

    ROUND(
        COALESCE(s.Actual_Sales,0)
        /
        NULLIF(t.Sales_Target,0) * 100,
        2
    ) AS Achievement_Percentage

FROM Monthly_Region_Target t

LEFT JOIN Monthly_Region_Sales s
    ON t.Region_ID = s.Region_ID
   AND t.Target_Month = s.Sales_Month

LEFT JOIN region_master r
    ON t.Region_ID = r.Region_ID

ORDER BY
    t.Target_Month,
    Actual_Sales DESC;


-- ============================================================
-- 5. REGIONAL RANKING
-- ============================================================

WITH Region_Performance AS
(
    SELECT
        s.Region_ID,
        r.Region_Name,

        SUM(s.Sales_Value)
            AS Total_Sales,

        SUM(s.Profit)
            AS Total_Profit,

        SUM(s.Profit)
        /
        NULLIF(
            SUM(s.Sales_Value),
            0
        ) * 100
            AS Profit_Margin

    FROM sales_transactions s

    LEFT JOIN region_master r
        ON s.Region_ID = r.Region_ID

    GROUP BY
        s.Region_ID,
        r.Region_Name
)

SELECT
    Region_ID,
    Region_Name,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        Total_Profit,
        2
    ) AS Total_Profit,

    ROUND(
        Profit_Margin,
        2
    ) AS Profit_Margin_Percentage,

    RANK()
    OVER(
        ORDER BY Total_Sales DESC
    ) AS Sales_Rank,

    RANK()
    OVER(
        ORDER BY Total_Profit DESC
    ) AS Profit_Rank,

    RANK()
    OVER(
        ORDER BY Profit_Margin DESC
    ) AS Margin_Rank

FROM Region_Performance

ORDER BY Sales_Rank;


-- ============================================================
-- 6. HIGHEST SALES BUT LOW PROFITABILITY
-- ============================================================

WITH Region_Performance AS
(
    SELECT
        s.Region_ID,
        r.Region_Name,

        SUM(s.Sales_Value)
            AS Total_Sales,

        SUM(s.Profit)
            AS Total_Profit,

        SUM(s.Profit)
        /
        NULLIF(
            SUM(s.Sales_Value),
            0
        ) * 100
            AS Profit_Margin

    FROM sales_transactions s

    LEFT JOIN region_master r
        ON s.Region_ID = r.Region_ID

    GROUP BY
        s.Region_ID,
        r.Region_Name
),

Ranked AS
(
    SELECT
        *,

        RANK()
        OVER(
            ORDER BY Total_Sales DESC
        ) AS Sales_Rank,

        RANK()
        OVER(
            ORDER BY Profit_Margin ASC
        ) AS Low_Margin_Rank

    FROM Region_Performance
)

SELECT
    Region_ID,
    Region_Name,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        Total_Profit,
        2
    ) AS Total_Profit,

    ROUND(
        Profit_Margin,
        2
    ) AS Profit_Margin_Percentage,

    Sales_Rank,
    Low_Margin_Rank

FROM Ranked

ORDER BY
    Sales_Rank,
    Low_Margin_Rank;


-- ============================================================
-- 7. HIGHEST GROWTH BUT LOW TARGET ACHIEVEMENT
-- ============================================================

WITH Monthly_Sales AS
(
    SELECT
        Region_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Monthly_Sales

    FROM sales_transactions

    GROUP BY
        Region_ID,
        DATE_FORMAT(Sales_Date,'%Y-%m')
),

Growth_Data AS
(
    SELECT
        Region_ID,
        Sales_Month,
        Monthly_Sales,

        LAG(Monthly_Sales)
        OVER(
            PARTITION BY Region_ID
            ORDER BY Sales_Month
        ) AS Previous_Sales,

        ROW_NUMBER()
        OVER(
            PARTITION BY Region_ID
            ORDER BY Sales_Month DESC
        ) AS rn

    FROM Monthly_Sales
),

Latest_Growth AS
(
    SELECT
        Region_ID,
        Sales_Month,
        Monthly_Sales,
        Previous_Sales,

        (
            Monthly_Sales -
            Previous_Sales
        )
        /
        NULLIF(
            Previous_Sales,
            0
        ) * 100
            AS Growth_Percentage

    FROM Growth_Data

    WHERE rn = 1
),

Latest_Target AS
(
    SELECT
        st.Region_ID,

        SUM(st.Sales_Target)
            AS Sales_Target

    FROM sales_targets st

    WHERE DATE_FORMAT(
        st.Target_Month,
        '%Y-%m'
    ) = (
        SELECT
            DATE_FORMAT(
                MAX(Target_Month),
                '%Y-%m'
            )
        FROM sales_targets
    )

    GROUP BY st.Region_ID
)

SELECT
    lg.Region_ID,
    r.Region_Name,

    ROUND(
        lg.Monthly_Sales,
        2
    ) AS Current_Month_Sales,

    ROUND(
        lg.Previous_Sales,
        2
    ) AS Previous_Month_Sales,

    ROUND(
        lg.Growth_Percentage,
        2
    ) AS Growth_Percentage,

    ROUND(
        lt.Sales_Target,
        2
    ) AS Sales_Target,

    ROUND(
        lg.Monthly_Sales /
        NULLIF(
            lt.Sales_Target,
            0
        ) * 100,
        2
    ) AS Target_Achievement_Percentage,

    RANK()
    OVER(
        ORDER BY lg.Growth_Percentage DESC
    ) AS Growth_Rank,

    RANK()
    OVER(
        ORDER BY
        (
            lg.Monthly_Sales /
            NULLIF(
                lt.Sales_Target,
                0
            )
        ) ASC
    ) AS Low_Target_Achievement_Rank

FROM Latest_Growth lg

LEFT JOIN Latest_Target lt
    ON lg.Region_ID = lt.Region_ID

LEFT JOIN region_master r
    ON lg.Region_ID = r.Region_ID

ORDER BY Growth_Rank;


-- ============================================================
-- 8. FINAL REGIONAL SUMMARY
-- ============================================================

SELECT
    r.Region_ID,
    r.Region_Name,

    ROUND(
        COALESCE(
            SUM(s.Sales_Value),
            0
        ),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(
            SUM(s.Profit),
            0
        ),
        2
    ) AS Total_Profit,

    ROUND(
        COALESCE(
            SUM(s.Profit),
            0
        )
        /
        NULLIF(
            SUM(s.Sales_Value),
            0
        ) * 100,
        2
    ) AS Profit_Margin_Percentage,

    COUNT(
        DISTINCT s.Transaction_ID
    ) AS Orders

FROM region_master r

LEFT JOIN sales_transactions s
    ON r.Region_ID = s.Region_ID

GROUP BY
    r.Region_ID,
    r.Region_Name

ORDER BY Total_Sales DESC;


-- ============================================================
-- PART 5 STATUS
-- ============================================================

/*

Regional Sales Target                 - Completed
Actual Sales                          - Completed
Target Achievement %                  - Completed
Previous Month Sales                  - Completed
Current Month Sales                   - Completed
Growth %                              - Completed
Revenue Contribution %                - Completed
Profit                                - Completed
Profit Margin %                       - Completed
Regional Ranking                      - Completed

Highest Sales + Lowest Profitability  - Completed
Highest Growth + Low Target Achievement - Completed

*/