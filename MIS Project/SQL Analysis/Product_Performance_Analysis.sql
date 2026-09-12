USE integrated_business;

-- ============================================================
-- PART 7 - PRODUCT PERFORMANCE & PROFITABILITY ANALYSIS
-- ============================================================


-- ============================================================
-- 1. PRODUCT LEVEL PERFORMANCE
-- Gross Revenue - Discount - Return Value - Product Cost = Net Profit
-- ============================================================

WITH Product_Returns AS
(
    SELECT
        Product_ID,
        SUM(Return_Value) AS Return_Value
    FROM returns_data
    GROUP BY Product_ID
),

Product_Stock AS
(
    SELECT
        Product_ID,
        SUM(Closing_Stock) AS Closing_Stock
    FROM inventory_data
    GROUP BY Product_ID
)

SELECT
    s.Product_ID,
    p.Product_Name,
    p.Category,

    ROUND(SUM(s.Gross_Revenue),2)
        AS Gross_Revenue,

    ROUND(SUM(s.Discount_Value),2)
        AS Discount_Value,

    ROUND(
        COALESCE(pr.Return_Value,0),
        2
    ) AS Return_Value,

    ROUND(SUM(s.Product_Cost),2)
        AS Product_Cost,

    ROUND(
        SUM(s.Gross_Revenue)
        - SUM(s.Discount_Value)
        - COALESCE(pr.Return_Value,0)
        - SUM(s.Product_Cost),
        2
    ) AS Net_Profit,

    ROUND(
        (
            SUM(s.Gross_Revenue)
            - SUM(s.Discount_Value)
            - COALESCE(pr.Return_Value,0)
            - SUM(s.Product_Cost)
        )
        /
        NULLIF(SUM(s.Sales_Value),0) * 100,
        2
    ) AS Profit_Margin_Percentage,

    SUM(s.Quantity)
        AS Units_Sold,

    ROUND(
        COALESCE(pr.Return_Value,0)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100,
        2
    ) AS Return_Rate_Percentage,

    ROUND(
        SUM(s.Discount_Value)
        /
        NULLIF(SUM(s.Gross_Revenue),0) * 100,
        2
    ) AS Discount_Percentage,

    COALESCE(ps.Closing_Stock,0)
        AS Closing_Stock

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

LEFT JOIN Product_Returns pr
    ON s.Product_ID = pr.Product_ID

LEFT JOIN Product_Stock ps
    ON s.Product_ID = ps.Product_ID

GROUP BY
    s.Product_ID,
    p.Product_Name,
    p.Category,
    pr.Return_Value,
    ps.Closing_Stock

ORDER BY Gross_Revenue DESC;


-- ============================================================
-- 2. CATEGORY PERFORMANCE
-- ============================================================

SELECT
    p.Category,

    ROUND(SUM(s.Gross_Revenue),2)
        AS Gross_Revenue,

    ROUND(SUM(s.Discount_Value),2)
        AS Discount_Value,

    ROUND(SUM(s.Sales_Value),2)
        AS Sales_Value,

    ROUND(SUM(s.Product_Cost),2)
        AS Product_Cost,

    ROUND(SUM(s.Profit),2)
        AS Profit,

    ROUND(
        SUM(s.Profit)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100,
        2
    ) AS Profit_Margin_Percentage,

    SUM(s.Quantity)
        AS Units_Sold

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY p.Category

ORDER BY Sales_Value DESC;


-- ============================================================
-- 3. TOP 10 BEST SELLING PRODUCTS
-- ============================================================

SELECT
    s.Product_ID,
    p.Product_Name,
    p.Category,

    SUM(s.Quantity)
        AS Units_Sold,

    ROUND(SUM(s.Sales_Value),2)
        AS Revenue

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY
    s.Product_ID,
    p.Product_Name,
    p.Category

ORDER BY Units_Sold DESC

LIMIT 10;


-- ============================================================
-- 4. TOP 10 MOST PROFITABLE PRODUCTS
-- ============================================================

SELECT
    s.Product_ID,
    p.Product_Name,
    p.Category,

    ROUND(SUM(s.Sales_Value),2)
        AS Revenue,

    ROUND(SUM(s.Profit),2)
        AS Profit,

    ROUND(
        SUM(s.Profit)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY
    s.Product_ID,
    p.Product_Name,
    p.Category

ORDER BY Profit DESC

LIMIT 10;


-- ============================================================
-- 5. LOSS MAKING PRODUCTS
-- ============================================================

SELECT
    s.Product_ID,
    p.Product_Name,
    p.Category,

    ROUND(SUM(s.Sales_Value),2)
        AS Revenue,

    ROUND(SUM(s.Profit),2)
        AS Profit,

    ROUND(
        SUM(s.Profit)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100,
        2
    ) AS Profit_Margin_Percentage

FROM sales_transactions s

LEFT JOIN product_master p
    ON s.Product_ID = p.Product_ID

GROUP BY
    s.Product_ID,
    p.Product_Name,
    p.Category

HAVING SUM(s.Profit) < 0

ORDER BY Profit ASC;


-- ============================================================
-- 6. HIGH RETURN PRODUCTS
-- Threshold = Above Average Return Rate
-- ============================================================

WITH Product_Performance AS
(
    SELECT
        s.Product_ID,
        p.Product_Name,

        SUM(s.Sales_Value)
            AS Revenue,

        COALESCE(
            SUM(r.Return_Value),
            0
        ) AS Return_Value

    FROM sales_transactions s

    LEFT JOIN product_master p
        ON s.Product_ID = p.Product_ID

    LEFT JOIN returns_data r
        ON s.Transaction_ID = r.Transaction_ID

    GROUP BY
        s.Product_ID,
        p.Product_Name
),

Rates AS
(
    SELECT
        *,

        Return_Value
        /
        NULLIF(Revenue,0) * 100
            AS Return_Rate

    FROM Product_Performance
),

Benchmark AS
(
    SELECT
        AVG(Return_Rate)
            AS Avg_Return_Rate
    FROM Rates
)

SELECT
    r.Product_ID,
    r.Product_Name,

    ROUND(r.Revenue,2)
        AS Revenue,

    ROUND(r.Return_Value,2)
        AS Return_Value,

    ROUND(r.Return_Rate,2)
        AS Return_Rate_Percentage,

    ROUND(b.Avg_Return_Rate,2)
        AS Average_Return_Rate

FROM Rates r

CROSS JOIN Benchmark b

WHERE r.Return_Rate > b.Avg_Return_Rate

ORDER BY r.Return_Rate DESC;


-- ============================================================
-- 7. HIGH DISCOUNT PRODUCTS
-- Threshold = Above Average Discount %
-- ============================================================

WITH Product_Discount AS
(
    SELECT
        s.Product_ID,
        p.Product_Name,

        SUM(s.Gross_Revenue)
            AS Gross_Revenue,

        SUM(s.Discount_Value)
            AS Discount_Value,

        SUM(s.Discount_Value)
        /
        NULLIF(SUM(s.Gross_Revenue),0) * 100
            AS Discount_Percentage

    FROM sales_transactions s

    LEFT JOIN product_master p
        ON s.Product_ID = p.Product_ID

    GROUP BY
        s.Product_ID,
        p.Product_Name
),

Benchmark AS
(
    SELECT
        AVG(Discount_Percentage)
            AS Avg_Discount
    FROM Product_Discount
)

SELECT
    pd.Product_ID,
    pd.Product_Name,

    ROUND(pd.Gross_Revenue,2)
        AS Gross_Revenue,

    ROUND(pd.Discount_Value,2)
        AS Discount_Value,

    ROUND(pd.Discount_Percentage,2)
        AS Discount_Percentage,

    ROUND(b.Avg_Discount,2)
        AS Average_Discount_Percentage

FROM Product_Discount pd

CROSS JOIN Benchmark b

WHERE pd.Discount_Percentage > b.Avg_Discount

ORDER BY pd.Discount_Percentage DESC;


-- ============================================================
-- 8. LOW MARGIN PRODUCTS
-- Threshold = Below Average Product Margin
-- ============================================================

WITH Product_Margin AS
(
    SELECT
        s.Product_ID,
        p.Product_Name,

        SUM(s.Sales_Value)
            AS Revenue,

        SUM(s.Profit)
            AS Profit,

        SUM(s.Profit)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100
            AS Profit_Margin

    FROM sales_transactions s

    LEFT JOIN product_master p
        ON s.Product_ID = p.Product_ID

    GROUP BY
        s.Product_ID,
        p.Product_Name
),

Benchmark AS
(
    SELECT
        AVG(Profit_Margin)
            AS Avg_Margin
    FROM Product_Margin
)

SELECT
    pm.Product_ID,
    pm.Product_Name,

    ROUND(pm.Revenue,2)
        AS Revenue,

    ROUND(pm.Profit,2)
        AS Profit,

    ROUND(pm.Profit_Margin,2)
        AS Profit_Margin_Percentage,

    ROUND(b.Avg_Margin,2)
        AS Average_Margin

FROM Product_Margin pm

CROSS JOIN Benchmark b

WHERE pm.Profit_Margin < b.Avg_Margin

ORDER BY pm.Profit_Margin ASC;


-- ============================================================
-- 9. SLOW MOVING PRODUCTS
-- Low unit sales + stock available
-- ============================================================

WITH Product_Sales AS
(
    SELECT
        Product_ID,
        SUM(Quantity) AS Units_Sold
    FROM sales_transactions
    GROUP BY Product_ID
),

Average_Sales AS
(
    SELECT
        AVG(Units_Sold) AS Avg_Units_Sold
    FROM Product_Sales
),

Stock_Data AS
(
    SELECT
        Product_ID,
        SUM(Closing_Stock) AS Closing_Stock
    FROM inventory_data
    GROUP BY Product_ID
)

SELECT
    ps.Product_ID,
    p.Product_Name,

    ps.Units_Sold,

    COALESCE(sd.Closing_Stock,0)
        AS Closing_Stock,

    ROUND(a.Avg_Units_Sold,2)
        AS Average_Units_Sold

FROM Product_Sales ps

LEFT JOIN product_master p
    ON ps.Product_ID = p.Product_ID

LEFT JOIN Stock_Data sd
    ON ps.Product_ID = sd.Product_ID

CROSS JOIN Average_Sales a

WHERE ps.Units_Sold < a.Avg_Units_Sold
  AND COALESCE(sd.Closing_Stock,0) > 0

ORDER BY ps.Units_Sold ASC;


-- ============================================================
-- 10. DEAD STOCK PRODUCTS
-- No sales + stock available
-- ============================================================

WITH Stock_Data AS
(
    SELECT
        Product_ID,
        SUM(Closing_Stock) AS Closing_Stock
    FROM inventory_data
    GROUP BY Product_ID
)

SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,

    COALESCE(sd.Closing_Stock,0)
        AS Closing_Stock

FROM product_master p

LEFT JOIN Stock_Data sd
    ON p.Product_ID = sd.Product_ID

LEFT JOIN sales_transactions s
    ON p.Product_ID = s.Product_ID

WHERE s.Product_ID IS NULL
  AND COALESCE(sd.Closing_Stock,0) > 0

ORDER BY Closing_Stock DESC;


-- ============================================================
-- 11. HIGH REVENUE + LOW PROFIT PRODUCTS
-- High Revenue = Above average revenue
-- Low Profit = Below average profit
-- ============================================================

WITH Product_Performance AS
(
    SELECT
        s.Product_ID,
        p.Product_Name,

        SUM(s.Sales_Value)
            AS Revenue,

        SUM(s.Profit)
            AS Profit

    FROM sales_transactions s

    LEFT JOIN product_master p
        ON s.Product_ID = p.Product_ID

    GROUP BY
        s.Product_ID,
        p.Product_Name
),

Benchmark AS
(
    SELECT
        AVG(Revenue) AS Avg_Revenue,
        AVG(Profit) AS Avg_Profit
    FROM Product_Performance
)

SELECT
    pp.Product_ID,
    pp.Product_Name,

    ROUND(pp.Revenue,2)
        AS Revenue,

    ROUND(pp.Profit,2)
        AS Profit,

    ROUND(
        pp.Profit
        /
        NULLIF(pp.Revenue,0) * 100,
        2
    ) AS Profit_Margin_Percentage,

    ROUND(b.Avg_Revenue,2)
        AS Average_Revenue,

    ROUND(b.Avg_Profit,2)
        AS Average_Profit

FROM Product_Performance pp

CROSS JOIN Benchmark b

WHERE pp.Revenue > b.Avg_Revenue
  AND pp.Profit < b.Avg_Profit

ORDER BY pp.Revenue DESC;


-- ============================================================
-- 12. PRODUCT PERFORMANCE RANKING
-- ============================================================

WITH Product_Performance AS
(
    SELECT
        s.Product_ID,
        p.Product_Name,
        p.Category,

        SUM(s.Sales_Value)
            AS Revenue,

        SUM(s.Profit)
            AS Profit,

        SUM(s.Quantity)
            AS Units_Sold,

        SUM(s.Profit)
        /
        NULLIF(SUM(s.Sales_Value),0) * 100
            AS Profit_Margin

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

    ROUND(Revenue,2)
        AS Revenue,

    ROUND(Profit,2)
        AS Profit,

    Units_Sold,

    ROUND(Profit_Margin,2)
        AS Profit_Margin_Percentage,

    RANK()
    OVER(ORDER BY Revenue DESC)
        AS Revenue_Rank,

    RANK()
    OVER(ORDER BY Profit DESC)
        AS Profit_Rank,

    RANK()
    OVER(ORDER BY Units_Sold DESC)
        AS Units_Rank

FROM Product_Performance

ORDER BY Revenue_Rank;


-- ============================================================
-- PART 7 COMPLETE
-- ============================================================