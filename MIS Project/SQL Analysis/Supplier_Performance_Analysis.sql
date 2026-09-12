USE integrated_business;

-- ============================================================
-- PART 11 - SUPPLIER PERFORMANCE ANALYSIS
-- ============================================================
-- Metrics:
-- 1. Purchase Value
-- 2. Average Delivery Time
-- 3. On-Time Delivery %
-- 4. Rejection Rate %
-- 5. Price Variation %
-- 6. Quality Score
-- 7. Supplier Performance Score
-- 8. Supplier Classification
-- 9. Top 10 Suppliers for Review
-- ============================================================


-- ============================================================
-- RESULT 1: OVERALL SUPPLIER KPI SUMMARY
-- ============================================================

SELECT
    COUNT(DISTINCT s.Supplier_ID) AS Total_Suppliers,

    COUNT(DISTINCT p.Purchase_ID) AS Total_Purchases,

    ROUND(
        SUM(p.Purchase_Value),
        2
    ) AS Total_Purchase_Value,

    SUM(p.Quantity) AS Total_Purchased_Qty,

    SUM(p.Rejected_Qty) AS Total_Rejected_Qty,

    ROUND(
        SUM(p.Rejected_Qty) * 100.0 /
        NULLIF(SUM(p.Quantity), 0),
        2
    ) AS Overall_Rejection_Rate_Pct,

    ROUND(
        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Purchase_Date
            )
        ),
        2
    ) AS Avg_Delivery_Time_Days,

    ROUND(
        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN p.Actual_Delivery_Date IS NOT NULL
                         AND p.Promised_Delivery_Date IS NOT NULL
                    THEN 1
                    ELSE 0
                END
            ),
            0
        ),
        2
    ) AS Overall_On_Time_Delivery_Pct,

    ROUND(
        AVG(s.Quality_Score),
        2
    ) AS Avg_Supplier_Quality_Score

FROM supplier_master s

LEFT JOIN purchase_data p
    ON s.Supplier_ID = p.Supplier_ID;


-- ============================================================
-- RESULT 2: SUPPLIER PERFORMANCE DETAIL
-- ============================================================

WITH Supplier_Performance AS (
    SELECT
        s.Supplier_ID,
        s.Supplier_Name,
        s.City,
        s.State,
        s.Lead_Time_Days,
        s.Quality_Score,

        COUNT(p.Purchase_ID)
            AS Purchase_Count,

        COALESCE(
            SUM(p.Quantity),
            0
        ) AS Purchased_Qty,

        COALESCE(
            SUM(p.Rejected_Qty),
            0
        ) AS Rejected_Qty,

        COALESCE(
            SUM(p.Purchase_Value),
            0
        ) AS Purchase_Value,

        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Purchase_Date
            )
        ) AS Avg_Delivery_Time,

        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ) AS Avg_Delivery_Delay,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) AS On_Time_Deliveries,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date IS NOT NULL
                     AND p.Promised_Delivery_Date IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS Completed_Deliveries

    FROM supplier_master s

    LEFT JOIN purchase_data p
        ON s.Supplier_ID = p.Supplier_ID

    GROUP BY
        s.Supplier_ID,
        s.Supplier_Name,
        s.City,
        s.State,
        s.Lead_Time_Days,
        s.Quality_Score
)

SELECT
    Supplier_ID,
    Supplier_Name,
    City,
    State,
    Lead_Time_Days,

    Purchase_Count,
    Purchased_Qty,
    Rejected_Qty,

    ROUND(
        Purchase_Value,
        2
    ) AS Purchase_Value,

    ROUND(
        Avg_Delivery_Time,
        2
    ) AS Avg_Delivery_Time_Days,

    ROUND(
        Avg_Delivery_Delay,
        2
    ) AS Avg_Delivery_Delay_Days,

    ROUND(
        On_Time_Deliveries * 100.0 /
        NULLIF(Completed_Deliveries, 0),
        2
    ) AS On_Time_Delivery_Pct,

    ROUND(
        Rejected_Qty * 100.0 /
        NULLIF(Purchased_Qty, 0),
        2
    ) AS Rejection_Rate_Pct,

    Quality_Score

FROM Supplier_Performance

ORDER BY
    Purchase_Value DESC;


-- ============================================================
-- RESULT 3: SUPPLIER PRICE VARIATION ANALYSIS
-- Compare actual purchase Unit_Cost with Product Master Unit_Cost
-- ============================================================

WITH Price_Analysis AS (
    SELECT
        p.Supplier_ID,

        COUNT(*) AS Purchase_Lines,

        AVG(p.Unit_Cost)
            AS Avg_Purchase_Unit_Cost,

        AVG(pm.Unit_Cost)
            AS Standard_Unit_Cost,

        AVG(
            CASE
                WHEN pm.Unit_Cost > 0
                THEN
                    (
                        p.Unit_Cost - pm.Unit_Cost
                    ) * 100.0 / pm.Unit_Cost
            END
        ) AS Avg_Price_Variation_Pct

    FROM purchase_data p

    INNER JOIN product_master pm
        ON p.Product_ID = pm.Product_ID

    GROUP BY
        p.Supplier_ID
)

SELECT
    pa.Supplier_ID,

    s.Supplier_Name,

    pa.Purchase_Lines,

    ROUND(
        pa.Avg_Purchase_Unit_Cost,
        2
    ) AS Avg_Purchase_Unit_Cost,

    ROUND(
        pa.Standard_Unit_Cost,
        2
    ) AS Avg_Standard_Unit_Cost,

    ROUND(
        pa.Avg_Price_Variation_Pct,
        2
    ) AS Avg_Price_Variation_Pct,

    CASE
        WHEN pa.Avg_Price_Variation_Pct > 10
            THEN 'High Cost'

        WHEN pa.Avg_Price_Variation_Pct > 0
            THEN 'Above Standard Cost'

        WHEN pa.Avg_Price_Variation_Pct < 0
            THEN 'Below Standard Cost'

        ELSE 'At Standard Cost'
    END AS Price_Status

FROM Price_Analysis pa

LEFT JOIN supplier_master s
    ON pa.Supplier_ID = s.Supplier_ID

ORDER BY
    pa.Avg_Price_Variation_Pct DESC;


-- ============================================================
-- RESULT 4: SUPPLIER SCORE
-- ============================================================
-- Scoring Model (100 points):
--
-- On-Time Delivery = 30 points
-- Quality Score    = 25 points
-- Rejection Rate   = 20 points
-- Delivery Delay   = 15 points
-- Price Variation  = 10 points
--
-- Higher score = Better supplier
-- ============================================================

WITH Supplier_Base AS (
    SELECT
        s.Supplier_ID,
        s.Supplier_Name,
        s.City,
        s.State,
        s.Lead_Time_Days,
        s.Quality_Score,

        COUNT(p.Purchase_ID)
            AS Purchase_Count,

        COALESCE(
            SUM(p.Purchase_Value),
            0
        ) AS Purchase_Value,

        COALESCE(
            SUM(p.Quantity),
            0
        ) AS Purchased_Qty,

        COALESCE(
            SUM(p.Rejected_Qty),
            0
        ) AS Rejected_Qty,

        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ) AS Avg_Delivery_Delay,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) AS On_Time_Deliveries,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date IS NOT NULL
                     AND p.Promised_Delivery_Date IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS Completed_Deliveries

    FROM supplier_master s

    LEFT JOIN purchase_data p
        ON s.Supplier_ID = p.Supplier_ID

    GROUP BY
        s.Supplier_ID,
        s.Supplier_Name,
        s.City,
        s.State,
        s.Lead_Time_Days,
        s.Quality_Score
),

Price_Data AS (
    SELECT
        p.Supplier_ID,

        AVG(
            CASE
                WHEN pm.Unit_Cost > 0
                THEN
                    ABS(
                        (
                            p.Unit_Cost - pm.Unit_Cost
                        ) * 100.0 / pm.Unit_Cost
                    )
            END
        ) AS Price_Variation_Pct

    FROM purchase_data p

    INNER JOIN product_master pm
        ON p.Product_ID = pm.Product_ID

    GROUP BY
        p.Supplier_ID
),

Metrics AS (
    SELECT
        sb.*,

        ROUND(
            sb.On_Time_Deliveries * 100.0 /
            NULLIF(sb.Completed_Deliveries, 0),
            2
        ) AS On_Time_Pct,

        ROUND(
            sb.Rejected_Qty * 100.0 /
            NULLIF(sb.Purchased_Qty, 0),
            2
        ) AS Rejection_Rate,

        COALESCE(
            pd.Price_Variation_Pct,
            0
        ) AS Price_Variation

    FROM Supplier_Base sb

    LEFT JOIN Price_Data pd
        ON sb.Supplier_ID = pd.Supplier_ID
),

Scored AS (
    SELECT
        *,

        -- On-Time Delivery: maximum 30
        LEAST(
            30,
            GREATEST(
                0,
                COALESCE(On_Time_Pct, 0) * 0.30
            )
        ) AS On_Time_Score,

        -- Quality: score out of 5 converted to 25
        LEAST(
            25,
            GREATEST(
                0,
                COALESCE(Quality_Score, 0) * 5
            )
        ) AS Quality_Score_Points,

        -- Rejection: lower is better
        LEAST(
            20,
            GREATEST(
                0,
                20 - COALESCE(Rejection_Rate, 0) * 2
            )
        ) AS Rejection_Score,

        -- Delay: lower is better
        LEAST(
            15,
            GREATEST(
                0,
                15 -
                GREATEST(
                    COALESCE(Avg_Delivery_Delay, 0),
                    0
                ) * 2
            )
        ) AS Delivery_Score,

        -- Price variation: lower absolute variation is better
        LEAST(
            10,
            GREATEST(
                0,
                10 - COALESCE(Price_Variation, 0)
            )
        ) AS Price_Score

    FROM Metrics
),

Final_Score AS (
    SELECT
        *,

        On_Time_Score
        + Quality_Score_Points
        + Rejection_Score
        + Delivery_Score
        + Price_Score
            AS Supplier_Score

    FROM Scored
)

SELECT
    Supplier_ID,
    Supplier_Name,

    Purchase_Count,

    ROUND(
        Purchase_Value,
        2
    ) AS Purchase_Value,

    ROUND(
        On_Time_Pct,
        2
    ) AS On_Time_Delivery_Pct,

    ROUND(
        Rejection_Rate,
        2
    ) AS Rejection_Rate_Pct,

    ROUND(
        Avg_Delivery_Delay,
        2
    ) AS Avg_Delivery_Delay_Days,

    ROUND(
        Price_Variation,
        2
    ) AS Price_Variation_Pct,

    Quality_Score,

    ROUND(
        Supplier_Score,
        2
    ) AS Supplier_Score,

    CASE
        WHEN Supplier_Score >= 85
            THEN 'Excellent'

        WHEN Supplier_Score >= 70
            THEN 'Good'

        WHEN Supplier_Score >= 55
            THEN 'Average'

        WHEN Supplier_Score >= 40
            THEN 'Poor'

        ELSE 'Critical'
    END AS Supplier_Category

FROM Final_Score

ORDER BY
    Supplier_Score DESC;


-- ============================================================
-- RESULT 5: SUPPLIER CATEGORY SUMMARY
-- ============================================================

WITH Supplier_Base AS (
    SELECT
        s.Supplier_ID,
        s.Supplier_Name,
        s.Quality_Score,

        COALESCE(
            SUM(p.Purchase_Value),
            0
        ) AS Purchase_Value,

        COALESCE(
            SUM(p.Quantity),
            0
        ) AS Purchased_Qty,

        COALESCE(
            SUM(p.Rejected_Qty),
            0
        ) AS Rejected_Qty,

        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ) AS Avg_Delivery_Delay,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) AS On_Time_Deliveries,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date IS NOT NULL
                     AND p.Promised_Delivery_Date IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS Completed_Deliveries

    FROM supplier_master s

    LEFT JOIN purchase_data p
        ON s.Supplier_ID = p.Supplier_ID

    GROUP BY
        s.Supplier_ID,
        s.Supplier_Name,
        s.Quality_Score
),

Price_Data AS (
    SELECT
        p.Supplier_ID,

        AVG(
            CASE
                WHEN pm.Unit_Cost > 0
                THEN
                    ABS(
                        (
                            p.Unit_Cost - pm.Unit_Cost
                        ) * 100.0 /
                        pm.Unit_Cost
                    )
            END
        ) AS Price_Variation

    FROM purchase_data p

    INNER JOIN product_master pm
        ON p.Product_ID = pm.Product_ID

    GROUP BY
        p.Supplier_ID
),

Metrics AS (
    SELECT
        sb.*,

        COALESCE(
            sb.On_Time_Deliveries * 100.0 /
            NULLIF(sb.Completed_Deliveries, 0),
            0
        ) AS On_Time_Pct,

        COALESCE(
            sb.Rejected_Qty * 100.0 /
            NULLIF(sb.Purchased_Qty, 0),
            0
        ) AS Rejection_Rate,

        COALESCE(
            pd.Price_Variation,
            0
        ) AS Price_Variation

    FROM Supplier_Base sb

    LEFT JOIN Price_Data pd
        ON sb.Supplier_ID = pd.Supplier_ID
),

Scores AS (
    SELECT
        *,

        LEAST(
            30,
            GREATEST(
                0,
                On_Time_Pct * 0.30
            )
        )

        +

        LEAST(
            25,
            GREATEST(
                0,
                COALESCE(Quality_Score, 0) * 5
            )
        )

        +

        LEAST(
            20,
            GREATEST(
                0,
                20 - Rejection_Rate * 2
            )
        )

        +

        LEAST(
            15,
            GREATEST(
                0,
                15 -
                GREATEST(
                    COALESCE(Avg_Delivery_Delay, 0),
                    0
                ) * 2
            )
        )

        +

        LEAST(
            10,
            GREATEST(
                0,
                10 - Price_Variation
            )
        ) AS Supplier_Score

    FROM Metrics
),

Categories AS (
    SELECT
        *,

        CASE
            WHEN Supplier_Score >= 85
                THEN 'Excellent'

            WHEN Supplier_Score >= 70
                THEN 'Good'

            WHEN Supplier_Score >= 55
                THEN 'Average'

            WHEN Supplier_Score >= 40
                THEN 'Poor'

            ELSE 'Critical'
        END AS Supplier_Category

    FROM Scores
)

SELECT
    Supplier_Category,

    COUNT(*) AS Supplier_Count,

    ROUND(
        SUM(Purchase_Value),
        2
    ) AS Purchase_Value,

    ROUND(
        AVG(Supplier_Score),
        2
    ) AS Average_Supplier_Score,

    ROUND(
        AVG(On_Time_Pct),
        2
    ) AS Avg_On_Time_Delivery_Pct,

    ROUND(
        AVG(Rejection_Rate),
        2
    ) AS Avg_Rejection_Rate_Pct,

    ROUND(
        AVG(Quality_Score),
        2
    ) AS Avg_Quality_Score

FROM Categories

GROUP BY
    Supplier_Category

ORDER BY
    CASE Supplier_Category
        WHEN 'Excellent' THEN 1
        WHEN 'Good' THEN 2
        WHEN 'Average' THEN 3
        WHEN 'Poor' THEN 4
        WHEN 'Critical' THEN 5
        ELSE 6
    END;


-- ============================================================
-- RESULT 6: TOP 10 SUPPLIERS BY PURCHASE VALUE
-- ============================================================

SELECT
    p.Supplier_ID,

    COALESCE(
        s.Supplier_Name,
        'Unmapped Supplier'
    ) AS Supplier_Name,

    COUNT(p.Purchase_ID)
        AS Purchase_Count,

    SUM(p.Quantity)
        AS Purchased_Qty,

    ROUND(
        SUM(p.Purchase_Value),
        2
    ) AS Purchase_Value,

    ROUND(
        AVG(s.Quality_Score),
        2
    ) AS Quality_Score

FROM purchase_data p

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

GROUP BY
    p.Supplier_ID,
    s.Supplier_Name

ORDER BY
    Purchase_Value DESC

LIMIT 10;


-- ============================================================
-- RESULT 7: TOP 10 SUPPLIERS FOR MANAGEMENT REVIEW
-- ============================================================
-- Review priority:
-- Low on-time %
-- High rejection
-- Long delivery delay
-- High price variation
-- Low quality
-- ============================================================

WITH Supplier_Base AS (
    SELECT
        s.Supplier_ID,
        s.Supplier_Name,
        s.Quality_Score,

        COUNT(p.Purchase_ID)
            AS Purchase_Count,

        COALESCE(
            SUM(p.Purchase_Value),
            0
        ) AS Purchase_Value,

        COALESCE(
            SUM(p.Quantity),
            0
        ) AS Purchased_Qty,

        COALESCE(
            SUM(p.Rejected_Qty),
            0
        ) AS Rejected_Qty,

        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ) AS Avg_Delivery_Delay,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) AS On_Time_Deliveries,

        SUM(
            CASE
                WHEN p.Actual_Delivery_Date IS NOT NULL
                     AND p.Promised_Delivery_Date IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS Completed_Deliveries

    FROM supplier_master s

    LEFT JOIN purchase_data p
        ON s.Supplier_ID = p.Supplier_ID

    GROUP BY
        s.Supplier_ID,
        s.Supplier_Name,
        s.Quality_Score
),

Price_Data AS (
    SELECT
        p.Supplier_ID,

        AVG(
            CASE
                WHEN pm.Unit_Cost > 0
                THEN
                    ABS(
                        (
                            p.Unit_Cost - pm.Unit_Cost
                        ) * 100.0 /
                        pm.Unit_Cost
                    )
            END
        ) AS Price_Variation

    FROM purchase_data p

    INNER JOIN product_master pm
        ON p.Product_ID = pm.Product_ID

    GROUP BY
        p.Supplier_ID
),

Review_Data AS (
    SELECT
        sb.*,

        COALESCE(
            sb.On_Time_Deliveries * 100.0 /
            NULLIF(sb.Completed_Deliveries, 0),
            0
        ) AS On_Time_Pct,

        COALESCE(
            sb.Rejected_Qty * 100.0 /
            NULLIF(sb.Purchased_Qty, 0),
            0
        ) AS Rejection_Rate,

        COALESCE(
            pd.Price_Variation,
            0
        ) AS Price_Variation

    FROM Supplier_Base sb

    LEFT JOIN Price_Data pd
        ON sb.Supplier_ID = pd.Supplier_ID
)

SELECT
    Supplier_ID,
    Supplier_Name,

    Purchase_Count,

    ROUND(
        Purchase_Value,
        2
    ) AS Purchase_Value,

    ROUND(
        On_Time_Pct,
        2
    ) AS On_Time_Delivery_Pct,

    ROUND(
        Rejection_Rate,
        2
    ) AS Rejection_Rate_Pct,

    ROUND(
        Avg_Delivery_Delay,
        2
    ) AS Avg_Delivery_Delay_Days,

    ROUND(
        Price_Variation,
        2
    ) AS Price_Variation_Pct,

    Quality_Score,

    ROUND(
        (
            (100 - On_Time_Pct) * 0.30
            + Rejection_Rate * 0.20
            + GREATEST(
                COALESCE(Avg_Delivery_Delay, 0),
                0
              ) * 2
            + Price_Variation * 0.10
            + (5 - COALESCE(Quality_Score, 0)) * 5
        ),
        2
    ) AS Review_Risk_Score,

    CASE
        WHEN On_Time_Pct < 70
            THEN 'Low On-Time Delivery'

        WHEN Rejection_Rate > 5
            THEN 'High Rejection Rate'

        WHEN Avg_Delivery_Delay > 5
            THEN 'Delivery Delay'

        WHEN Price_Variation > 10
            THEN 'High Price Variation'

        WHEN Quality_Score < 3
            THEN 'Low Quality'

        ELSE 'General Performance Review'
    END AS Primary_Review_Reason

FROM Review_Data

ORDER BY
    Review_Risk_Score DESC,
    Purchase_Value DESC

LIMIT 10;


-- ============================================================
-- RESULT 8: DELIVERY PERFORMANCE
-- ============================================================

SELECT
    p.Supplier_ID,

    COALESCE(
        s.Supplier_Name,
        'Unmapped Supplier'
    ) AS Supplier_Name,

    COUNT(p.Purchase_ID)
        AS Total_Deliveries,

    SUM(
        CASE
            WHEN p.Actual_Delivery_Date
                 <= p.Promised_Delivery_Date
            THEN 1
            ELSE 0
        END
    ) AS On_Time_Deliveries,

    SUM(
        CASE
            WHEN p.Actual_Delivery_Date
                 > p.Promised_Delivery_Date
            THEN 1
            ELSE 0
        END
    ) AS Late_Deliveries,

    ROUND(
        SUM(
            CASE
                WHEN p.Actual_Delivery_Date
                     <= p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(COUNT(p.Purchase_ID), 0),
        2
    ) AS On_Time_Delivery_Pct,

    ROUND(
        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Purchase_Date
            )
        ),
        2
    ) AS Avg_Total_Delivery_Days,

    ROUND(
        AVG(
            DATEDIFF(
                p.Actual_Delivery_Date,
                p.Promised_Delivery_Date
            )
        ),
        2
    ) AS Avg_Delivery_Delay_Days

FROM purchase_data p

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

GROUP BY
    p.Supplier_ID,
    s.Supplier_Name

ORDER BY
    On_Time_Delivery_Pct ASC,
    Avg_Delivery_Delay_Days DESC;


-- ============================================================
-- RESULT 9: REJECTION PERFORMANCE
-- ============================================================

SELECT
    p.Supplier_ID,

    COALESCE(
        s.Supplier_Name,
        'Unmapped Supplier'
    ) AS Supplier_Name,

    SUM(p.Quantity)
        AS Purchased_Qty,

    SUM(p.Rejected_Qty)
        AS Rejected_Qty,

    ROUND(
        SUM(p.Rejected_Qty) * 100.0 /
        NULLIF(SUM(p.Quantity), 0),
        2
    ) AS Rejection_Rate_Pct,

    ROUND(
        SUM(p.Purchase_Value),
        2
    ) AS Purchase_Value,

    s.Quality_Score

FROM purchase_data p

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

GROUP BY
    p.Supplier_ID,
    s.Supplier_Name,
    s.Quality_Score

ORDER BY
    Rejection_Rate_Pct DESC,
    Rejected_Qty DESC;


-- ============================================================
-- RESULT 10: SUPPLIER DATA / RELATIONSHIP EXCEPTIONS
-- ============================================================

SELECT
    p.Supplier_ID,

    COUNT(*) AS Purchase_Count,

    ROUND(
        SUM(p.Purchase_Value),
        2
    ) AS Purchase_Value,

    'Supplier not found in Supplier Master'
        AS Exception_Reason

FROM purchase_data p

LEFT JOIN supplier_master s
    ON p.Supplier_ID = s.Supplier_ID

WHERE s.Supplier_ID IS NULL

GROUP BY
    p.Supplier_ID

ORDER BY
    Purchase_Value DESC;


-- ============================================================
-- PART 11 COMPLETE
-- ============================================================