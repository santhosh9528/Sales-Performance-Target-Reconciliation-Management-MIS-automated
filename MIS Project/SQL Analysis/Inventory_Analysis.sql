Inventory_Analysis.sqlUSE integrated_business;

-- ============================================================
-- PART 10 - INVENTORY ANALYSIS
-- ============================================================
-- Main Metrics:
-- Opening Stock
-- Purchases
-- Sales
-- Returns
-- Closing Stock
-- Stock Value
-- Inventory Turnover
-- Days Inventory
-- Stockout Rate
--
-- Classification:
-- Fast Moving
-- Medium Moving
-- Slow Moving
-- Dead Stock
-- Overstocked
-- Critical Stock
-- ============================================================


-- ============================================================
-- RESULT 1: OVERALL INVENTORY KPI SUMMARY
-- ============================================================

WITH Inventory_Summary AS (
    SELECT
        SUM(Opening_Stock) AS Total_Opening_Stock,
        SUM(Purchases_Qty) AS Total_Purchases_Qty,
        SUM(Sales_Qty) AS Total_Sales_Qty,
        SUM(Returns_Qty) AS Total_Returns_Qty,
        SUM(Closing_Stock) AS Total_Closing_Stock,
        SUM(Stock_Value) AS Total_Stock_Value,
        SUM(Stockout_Days) AS Total_Stockout_Days,

        AVG(
            (Opening_Stock + Closing_Stock) / 2.0
        ) AS Avg_Inventory_Per_Row

    FROM inventory_data
)

SELECT
    Total_Opening_Stock,
    Total_Purchases_Qty,
    Total_Sales_Qty,
    Total_Returns_Qty,
    Total_Closing_Stock,

    ROUND(
        Total_Stock_Value,
        2
    ) AS Total_Stock_Value,

    Total_Stockout_Days,

    ROUND(
        Total_Sales_Qty /
        NULLIF(Avg_Inventory_Per_Row, 0),
        2
    ) AS Inventory_Turnover_Ratio,

    ROUND(
        365 /
        NULLIF(
            Total_Sales_Qty /
            NULLIF(Avg_Inventory_Per_Row, 0),
            0
        ),
        2
    ) AS Days_Inventory

FROM Inventory_Summary;


-- ============================================================
-- RESULT 2: PRODUCT LEVEL INVENTORY PERFORMANCE
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        i.Product_ID,

        SUM(i.Opening_Stock)
            AS Opening_Stock,

        SUM(i.Purchases_Qty)
            AS Purchases_Qty,

        SUM(i.Sales_Qty)
            AS Sales_Qty,

        SUM(i.Returns_Qty)
            AS Returns_Qty,

        SUM(i.Closing_Stock)
            AS Closing_Stock,

        SUM(i.Stock_Value)
            AS Stock_Value,

        SUM(i.Stockout_Days)
            AS Stockout_Days,

        AVG(
            (i.Opening_Stock + i.Closing_Stock) / 2.0
        ) AS Average_Inventory,

        MIN(i.Snapshot_Date)
            AS First_Snapshot_Date,

        MAX(i.Snapshot_Date)
            AS Last_Snapshot_Date,

        COUNT(DISTINCT i.Warehouse_ID)
            AS Warehouse_Count

    FROM inventory_data i

    GROUP BY i.Product_ID
)

SELECT
    pi.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    pi.Opening_Stock,
    pi.Purchases_Qty,
    pi.Sales_Qty,
    pi.Returns_Qty,
    pi.Closing_Stock,

    ROUND(
        pi.Stock_Value,
        2
    ) AS Stock_Value,

    pi.Stockout_Days,

    ROUND(
        pi.Sales_Qty /
        NULLIF(pi.Average_Inventory, 0),
        2
    ) AS Inventory_Turnover,

    ROUND(
        365 /
        NULLIF(
            pi.Sales_Qty /
            NULLIF(pi.Average_Inventory, 0),
            0
        ),
        2
    ) AS Days_Inventory,

    p.Reorder_Level,

    s.Lead_Time_Days

FROM Product_Inventory pi

LEFT JOIN product_master p
    ON pi.Product_ID = p.Product_ID

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

ORDER BY
    pi.Stock_Value DESC;


-- ============================================================
-- RESULT 3: STOCK MOVEMENT CLASSIFICATION
-- ============================================================
-- Fast Moving   : Turnover >= 6
-- Medium Moving : Turnover >= 3 and < 6
-- Slow Moving   : Turnover > 0 and < 3
-- Dead Stock    : Sales Qty = 0
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value,

        AVG(
            (Opening_Stock + Closing_Stock) / 2.0
        ) AS Average_Inventory

    FROM inventory_data

    GROUP BY Product_ID
),

Movement_Data AS (
    SELECT
        Product_ID,
        Sales_Qty,
        Closing_Stock,
        Stock_Value,

        Sales_Qty /
        NULLIF(Average_Inventory, 0)
            AS Inventory_Turnover

    FROM Product_Inventory
)

SELECT
    md.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    md.Sales_Qty,
    md.Closing_Stock,

    ROUND(
        md.Stock_Value,
        2
    ) AS Stock_Value,

    ROUND(
        md.Inventory_Turnover,
        2
    ) AS Inventory_Turnover,

    CASE
        WHEN md.Sales_Qty = 0
            THEN 'Dead Stock'

        WHEN md.Inventory_Turnover >= 6
            THEN 'Fast Moving'

        WHEN md.Inventory_Turnover >= 3
            THEN 'Medium Moving'

        ELSE 'Slow Moving'
    END AS Movement_Category

FROM Movement_Data md

LEFT JOIN product_master p
    ON md.Product_ID = p.Product_ID

ORDER BY
    CASE
        WHEN md.Sales_Qty = 0 THEN 4
        WHEN md.Inventory_Turnover >= 6 THEN 1
        WHEN md.Inventory_Turnover >= 3 THEN 2
        ELSE 3
    END,
    md.Inventory_Turnover DESC;


-- ============================================================
-- RESULT 4: MOVEMENT CATEGORY SUMMARY
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value,

        AVG(
            (Opening_Stock + Closing_Stock) / 2.0
        ) AS Average_Inventory

    FROM inventory_data

    GROUP BY Product_ID
),

Movement_Data AS (
    SELECT
        Product_ID,
        Sales_Qty,
        Closing_Stock,
        Stock_Value,

        Sales_Qty /
        NULLIF(Average_Inventory, 0)
            AS Inventory_Turnover

    FROM Product_Inventory
),

Classification AS (
    SELECT
        Product_ID,
        Sales_Qty,
        Closing_Stock,
        Stock_Value,

        CASE
            WHEN Sales_Qty = 0
                THEN 'Dead Stock'

            WHEN Inventory_Turnover >= 6
                THEN 'Fast Moving'

            WHEN Inventory_Turnover >= 3
                THEN 'Medium Moving'

            ELSE 'Slow Moving'
        END AS Movement_Category

    FROM Movement_Data
)

SELECT
    Movement_Category,

    COUNT(*) AS Product_Count,

    SUM(Sales_Qty)
        AS Total_Sales_Qty,

    SUM(Closing_Stock)
        AS Closing_Stock,

    ROUND(
        SUM(Stock_Value),
        2
    ) AS Stock_Value

FROM Classification

GROUP BY Movement_Category

ORDER BY
    CASE Movement_Category
        WHEN 'Fast Moving' THEN 1
        WHEN 'Medium Moving' THEN 2
        WHEN 'Slow Moving' THEN 3
        WHEN 'Dead Stock' THEN 4
        ELSE 5
    END;


-- ============================================================
-- RESULT 5: STOCKOUT ANALYSIS
-- Stockout Rate considers:
-- Stockout Days /
-- (Calendar Days × Number of Warehouses)
-- ============================================================

WITH Stockout_Data AS (
    SELECT
        Product_ID,

        SUM(Stockout_Days)
            AS Total_Stockout_Days,

        MIN(Snapshot_Date)
            AS First_Date,

        MAX(Snapshot_Date)
            AS Last_Date,

        COUNT(DISTINCT Warehouse_ID)
            AS Warehouse_Count

    FROM inventory_data

    GROUP BY Product_ID
)

SELECT
    sd.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    sd.Total_Stockout_Days,

    sd.Warehouse_Count,

    DATEDIFF(
        sd.Last_Date,
        sd.First_Date
    ) + 1 AS Observation_Days,

    ROUND(
        LEAST(
            100,
            sd.Total_Stockout_Days * 100.0
            /
            NULLIF(
                (
                    DATEDIFF(
                        sd.Last_Date,
                        sd.First_Date
                    ) + 1
                ) * sd.Warehouse_Count,
                0
            )
        ),
        2
    ) AS Stockout_Rate_Percentage

FROM Stockout_Data sd

LEFT JOIN product_master p
    ON sd.Product_ID = p.Product_ID

WHERE sd.Total_Stockout_Days > 0

ORDER BY
    Stockout_Rate_Percentage DESC,
    sd.Total_Stockout_Days DESC;


-- ============================================================
-- RESULT 6: CRITICAL STOCK
-- High Demand + Low Stock + Long Supplier Lead Time
-- High Demand = Above average sales quantity
-- Low Stock = Closing Stock <= Reorder Level
-- Long Lead = Above average supplier lead time
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value

    FROM inventory_data

    GROUP BY Product_ID
),

Demand_Benchmark AS (
    SELECT
        AVG(Sales_Qty)
            AS Average_Sales_Qty

    FROM Product_Inventory
),

Lead_Time_Benchmark AS (
    SELECT
        AVG(Lead_Time_Days)
            AS Average_Lead_Time

    FROM supplier_master

    WHERE Lead_Time_Days IS NOT NULL
)

SELECT
    pi.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    pi.Sales_Qty,

    ROUND(
        db.Average_Sales_Qty,
        2
    ) AS Avg_Product_Sales_Qty,

    pi.Closing_Stock,

    p.Reorder_Level,

    s.Supplier_ID,

    s.Supplier_Name,

    s.Lead_Time_Days,

    ROUND(
        lb.Average_Lead_Time,
        2
    ) AS Avg_Lead_Time,

    ROUND(
        pi.Stock_Value,
        2
    ) AS Stock_Value,

    'Critical Stock'
        AS Inventory_Status

FROM Product_Inventory pi

INNER JOIN product_master p
    ON pi.Product_ID = p.Product_ID

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

CROSS JOIN Demand_Benchmark db

CROSS JOIN Lead_Time_Benchmark lb

WHERE pi.Sales_Qty >
      db.Average_Sales_Qty

  AND pi.Closing_Stock <=
      p.Reorder_Level

  AND s.Lead_Time_Days >
      lb.Average_Lead_Time

ORDER BY
    pi.Sales_Qty DESC,
    pi.Closing_Stock ASC,
    s.Lead_Time_Days DESC;


-- ============================================================
-- RESULT 7: OVERSTOCKED / EXCESS STOCK
-- Low Demand + High Closing Stock
-- Low Demand = Below average sales
-- Overstock = Closing stock > 3 × Reorder Level
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value

    FROM inventory_data

    GROUP BY Product_ID
),

Demand_Benchmark AS (
    SELECT
        AVG(Sales_Qty)
            AS Average_Sales_Qty

    FROM Product_Inventory
)

SELECT
    pi.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    pi.Sales_Qty,

    ROUND(
        db.Average_Sales_Qty,
        2
    ) AS Avg_Product_Sales_Qty,

    pi.Closing_Stock,

    p.Reorder_Level,

    ROUND(
        pi.Stock_Value,
        2
    ) AS Stock_Value,

    ROUND(
        pi.Closing_Stock /
        NULLIF(p.Reorder_Level, 0),
        2
    ) AS Stock_To_Reorder_Ratio,

    'Overstocked'
        AS Inventory_Status

FROM Product_Inventory pi

INNER JOIN product_master p
    ON pi.Product_ID = p.Product_ID

CROSS JOIN Demand_Benchmark db

WHERE pi.Sales_Qty <
      db.Average_Sales_Qty

  AND pi.Closing_Stock >
      (p.Reorder_Level * 3)

ORDER BY
    pi.Stock_Value DESC;


-- ============================================================
-- RESULT 8: DEAD STOCK PRODUCTS
-- No sales but inventory still available
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value

    FROM inventory_data

    GROUP BY Product_ID
)

SELECT
    pi.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    pi.Sales_Qty,
    pi.Closing_Stock,

    ROUND(
        pi.Stock_Value,
        2
    ) AS Stock_Value,

    p.Reorder_Level,

    'Dead Stock'
        AS Inventory_Status

FROM Product_Inventory pi

LEFT JOIN product_master p
    ON pi.Product_ID = p.Product_ID

WHERE pi.Sales_Qty = 0

  AND pi.Closing_Stock > 0

ORDER BY
    pi.Stock_Value DESC;


-- ============================================================
-- RESULT 9: WAREHOUSE PERFORMANCE SUMMARY
-- ============================================================

SELECT
    Warehouse_ID,

    COUNT(DISTINCT Product_ID)
        AS Product_Count,

    SUM(Opening_Stock)
        AS Opening_Stock,

    SUM(Purchases_Qty)
        AS Purchases_Qty,

    SUM(Sales_Qty)
        AS Sales_Qty,

    SUM(Returns_Qty)
        AS Returns_Qty,

    SUM(Closing_Stock)
        AS Closing_Stock,

    ROUND(
        SUM(Stock_Value),
        2
    ) AS Stock_Value,

    SUM(Stockout_Days)
        AS Stockout_Days

FROM inventory_data

GROUP BY Warehouse_ID

ORDER BY
    Stock_Value DESC;


-- ============================================================
-- RESULT 10: CATEGORY INVENTORY PERFORMANCE
-- ============================================================

SELECT
    COALESCE(
        p.Category,
        'Unmapped'
    ) AS Category,

    COUNT(DISTINCT i.Product_ID)
        AS Product_Count,

    SUM(i.Opening_Stock)
        AS Opening_Stock,

    SUM(i.Purchases_Qty)
        AS Purchases_Qty,

    SUM(i.Sales_Qty)
        AS Sales_Qty,

    SUM(i.Returns_Qty)
        AS Returns_Qty,

    SUM(i.Closing_Stock)
        AS Closing_Stock,

    ROUND(
        SUM(i.Stock_Value),
        2
    ) AS Stock_Value,

    SUM(i.Stockout_Days)
        AS Stockout_Days

FROM inventory_data i

LEFT JOIN product_master p
    ON i.Product_ID = p.Product_ID

GROUP BY
    p.Category

ORDER BY
    Stock_Value DESC;


-- ============================================================
-- RESULT 11: INVENTORY FLOW VALIDATION
-- Expected Closing:
-- Opening + Purchases + Returns - Sales
-- ============================================================

SELECT
    Inventory_ID,
    Snapshot_Date,
    Product_ID,
    Warehouse_ID,

    Opening_Stock,
    Purchases_Qty,
    Sales_Qty,
    Returns_Qty,
    Closing_Stock,

    (
        Opening_Stock
        + Purchases_Qty
        + Returns_Qty
        - Sales_Qty
    ) AS Expected_Closing_Stock,

    Closing_Stock -
    (
        Opening_Stock
        + Purchases_Qty
        + Returns_Qty
        - Sales_Qty
    ) AS Stock_Difference,

    CASE
        WHEN Closing_Stock =
             (
                Opening_Stock
                + Purchases_Qty
                + Returns_Qty
                - Sales_Qty
             )
        THEN 'Matched'

        ELSE 'Mismatch'
    END AS Validation_Status

FROM inventory_data

WHERE Closing_Stock <>
      (
        Opening_Stock
        + Purchases_Qty
        + Returns_Qty
        - Sales_Qty
      )

ORDER BY
    ABS(
        Closing_Stock -
        (
            Opening_Stock
            + Purchases_Qty
            + Returns_Qty
            - Sales_Qty
        )
    ) DESC;


-- ============================================================
-- RESULT 12: INVENTORY MANAGEMENT STATUS SUMMARY
-- Critical / Overstocked / Dead / Normal
-- ============================================================

WITH Product_Inventory AS (
    SELECT
        Product_ID,

        SUM(Sales_Qty)
            AS Sales_Qty,

        SUM(Closing_Stock)
            AS Closing_Stock,

        SUM(Stock_Value)
            AS Stock_Value

    FROM inventory_data

    GROUP BY Product_ID
),

Demand_Benchmark AS (
    SELECT
        AVG(Sales_Qty)
            AS Average_Sales_Qty

    FROM Product_Inventory
),

Lead_Benchmark AS (
    SELECT
        AVG(Lead_Time_Days)
            AS Average_Lead_Time

    FROM supplier_master

    WHERE Lead_Time_Days IS NOT NULL
),

Inventory_Status_Data AS (
    SELECT
        pi.Product_ID,
        pi.Sales_Qty,
        pi.Closing_Stock,
        pi.Stock_Value,
        p.Reorder_Level,
        s.Lead_Time_Days,

        CASE
            WHEN pi.Sales_Qty = 0
                 AND pi.Closing_Stock > 0
                THEN 'Dead Stock'

            WHEN pi.Sales_Qty > db.Average_Sales_Qty
                 AND pi.Closing_Stock <= p.Reorder_Level
                 AND s.Lead_Time_Days > lb.Average_Lead_Time
                THEN 'Critical'

            WHEN pi.Sales_Qty < db.Average_Sales_Qty
                 AND pi.Closing_Stock >
                     (p.Reorder_Level * 3)
                THEN 'Overstocked'

            ELSE 'Normal'
        END AS Inventory_Status

    FROM Product_Inventory pi

    LEFT JOIN product_master p
        ON pi.Product_ID = p.Product_ID

    LEFT JOIN supplier_master s
        ON p.Supplier_ID = s.Supplier_ID

    CROSS JOIN Demand_Benchmark db

    CROSS JOIN Lead_Benchmark lb
)

SELECT
    Inventory_Status,

    COUNT(*) AS Product_Count,

    SUM(Sales_Qty)
        AS Sales_Qty,

    SUM(Closing_Stock)
        AS Closing_Stock,

    ROUND(
        SUM(Stock_Value),
        2
    ) AS Stock_Value

FROM Inventory_Status_Data

GROUP BY Inventory_Status

ORDER BY
    CASE Inventory_Status
        WHEN 'Critical' THEN 1
        WHEN 'Dead Stock' THEN 2
        WHEN 'Overstocked' THEN 3
        ELSE 4
    END;


-- ============================================================
-- PART 10 COMPLETE
-- ============================================================