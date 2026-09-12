USE integrated_business;

-- ============================================================
-- PART 13 - CUSTOMER COMPLAINTS & SLA ANALYSIS
-- ============================================================
-- Covers:
-- Total Complaints
-- Open / Closed / Pending
-- Average Resolution Time
-- SLA Compliance %
-- SLA Breach %
-- Average Rating
-- Complaint Type Analysis
-- Priority Analysis
-- High Complaint Employees
-- High Complaint Products
-- High Complaint Regions
-- Repeat Complaint Customers
-- Relationship Exceptions
-- ============================================================


-- ============================================================
-- RESULT 1: OVERALL COMPLAINT KPI SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS Total_Complaints,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'open'
            THEN 1 ELSE 0
        END
    ) AS Open_Complaints,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'closed'
            THEN 1 ELSE 0
        END
    ) AS Closed_Complaints,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'pending'
            THEN 1 ELSE 0
        END
    ) AS Pending_Complaints,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Customer_Rating,

    SUM(
        CASE
            WHEN Resolution_Hours IS NOT NULL
                 AND SLA_Hours IS NOT NULL
                 AND Resolution_Hours <= SLA_Hours
            THEN 1
            ELSE 0
        END
    ) AS SLA_Met_Complaints,

    SUM(
        CASE
            WHEN Resolution_Hours IS NOT NULL
                 AND SLA_Hours IS NOT NULL
                 AND Resolution_Hours > SLA_Hours
            THEN 1
            ELSE 0
        END
    ) AS SLA_Breached_Complaints,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours IS NOT NULL
                     AND SLA_Hours IS NOT NULL
                     AND Resolution_Hours <= SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN Resolution_Hours IS NOT NULL
                         AND SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Compliance_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours IS NOT NULL
                     AND SLA_Hours IS NOT NULL
                     AND Resolution_Hours > SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN Resolution_Hours IS NOT NULL
                         AND SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Breach_Pct

FROM customer_complaints;


-- ============================================================
-- RESULT 2: COMPLAINT STATUS SUMMARY
-- ============================================================

SELECT
    COALESCE(Status, 'Unknown') AS Complaint_Status,

    COUNT(*) AS Complaint_Count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Complaint_Pct,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints

GROUP BY Status

ORDER BY Complaint_Count DESC;


-- ============================================================
-- RESULT 3: COMPLAINT TYPE ANALYSIS
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
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours > SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN Resolution_Hours IS NOT NULL
                         AND SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Breach_Pct,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints

GROUP BY Complaint_Type

ORDER BY Total_Complaints DESC;


-- ============================================================
-- RESULT 4: PRIORITY-WISE COMPLAINT PERFORMANCE
-- ============================================================

SELECT
    COALESCE(Priority, 'Unknown') AS Priority,

    COUNT(*) AS Total_Complaints,

    ROUND(
        AVG(SLA_Hours),
        2
    ) AS Avg_SLA_Hours,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN Resolution_Hours <= SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Met,

    SUM(
        CASE
            WHEN Resolution_Hours > SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breached,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours <= SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN Resolution_Hours IS NOT NULL
                         AND SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Compliance_Pct,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Rating

FROM customer_complaints

GROUP BY Priority

ORDER BY
    Total_Complaints DESC;


-- ============================================================
-- RESULT 5: EMPLOYEES WITH HIGH COMPLAINT VOLUME
-- ============================================================

SELECT
    c.Employee_ID,

    COALESCE(
        e.Employee_Name,
        'Unmapped Employee'
    ) AS Employee_Name,

    e.Department,
    e.Designation,

    COUNT(*) AS Complaint_Count,

    ROUND(
        AVG(c.Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN c.Resolution_Hours > c.SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        SUM(
            CASE
                WHEN c.Resolution_Hours > c.SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN c.Resolution_Hours IS NOT NULL
                         AND c.SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Breach_Pct,

    ROUND(
        AVG(c.Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints c

LEFT JOIN employee_master e
    ON c.Employee_ID = e.Employee_ID

GROUP BY
    c.Employee_ID,
    e.Employee_Name,
    e.Department,
    e.Designation

ORDER BY
    Complaint_Count DESC,
    SLA_Breach_Pct DESC

LIMIT 10;


-- ============================================================
-- RESULT 6: PRODUCTS WITH HIGH COMPLAINT VOLUME
-- ============================================================

SELECT
    c.Product_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Product_Name,

    p.Category,
    p.Subcategory,

    COUNT(*) AS Complaint_Count,

    ROUND(
        AVG(c.Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN c.Resolution_Hours > c.SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        AVG(c.Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints c

LEFT JOIN product_master p
    ON c.Product_ID = p.Product_ID

GROUP BY
    c.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory

ORDER BY
    Complaint_Count DESC,
    SLA_Breaches DESC

LIMIT 10;


-- ============================================================
-- RESULT 7: REGIONS WITH HIGH COMPLAINT VOLUME
-- ============================================================

SELECT
    c.Region_ID,

    COALESCE(
        r.Region_Name,
        'Unmapped Region'
    ) AS Region_Name,

    COUNT(*) AS Complaint_Count,

    ROUND(
        AVG(c.Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN c.Resolution_Hours > c.SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        SUM(
            CASE
                WHEN c.Resolution_Hours > c.SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN c.Resolution_Hours IS NOT NULL
                         AND c.SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Breach_Pct,

    ROUND(
        AVG(c.Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints c

LEFT JOIN region_master r
    ON c.Region_ID = r.Region_ID

GROUP BY
    c.Region_ID,
    r.Region_Name

ORDER BY
    Complaint_Count DESC;


-- ============================================================
-- RESULT 8: REPEAT COMPLAINT CUSTOMERS
-- ============================================================

SELECT
    c.Customer_ID,

    COALESCE(
        cu.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    COUNT(*) AS Complaint_Count,

    COUNT(DISTINCT c.Complaint_Type)
        AS Complaint_Type_Count,

    ROUND(
        AVG(c.Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    SUM(
        CASE
            WHEN c.Resolution_Hours > c.SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        AVG(c.Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints c

LEFT JOIN customer_master cu
    ON c.Customer_ID = cu.Customer_ID

GROUP BY
    c.Customer_ID,
    cu.Customer_Name

HAVING COUNT(*) > 1

ORDER BY
    Complaint_Count DESC,
    SLA_Breaches DESC;


-- ============================================================
-- RESULT 9: LOW RATING / CUSTOMER EXPERIENCE RISK
-- ============================================================

SELECT
    Complaint_ID,
    Complaint_Date,
    Customer_ID,
    Complaint_Type,
    Priority,
    Status,

    SLA_Hours,
    Resolution_Hours,

    ROUND(
        Resolution_Hours - SLA_Hours,
        2
    ) AS SLA_Delay_Hours,

    Customer_Rating,

    CASE
        WHEN Customer_Rating <= 2
             AND Resolution_Hours > SLA_Hours
            THEN 'Critical Customer Experience'

        WHEN Customer_Rating <= 2
            THEN 'Low Rating'

        WHEN Resolution_Hours > SLA_Hours
            THEN 'SLA Breach'

        ELSE 'Normal'
    END AS Experience_Risk

FROM customer_complaints

WHERE
    Customer_Rating <= 2

    OR Resolution_Hours > SLA_Hours

ORDER BY
    Customer_Rating ASC,
    SLA_Delay_Hours DESC;


-- ============================================================
-- RESULT 10: SLA BREACH DETAIL
-- ============================================================

SELECT
    Complaint_ID,
    Complaint_Date,
    Customer_ID,
    Employee_ID,
    Product_ID,
    Region_ID,
    Complaint_Type,
    Priority,
    Status,

    SLA_Hours,
    Resolution_Hours,

    ROUND(
        Resolution_Hours - SLA_Hours,
        2
    ) AS Breach_Hours,

    Customer_Rating

FROM customer_complaints

WHERE
    Resolution_Hours IS NOT NULL
    AND SLA_Hours IS NOT NULL
    AND Resolution_Hours > SLA_Hours

ORDER BY
    Breach_Hours DESC;


-- ============================================================
-- RESULT 11: MONTHLY COMPLAINT TREND
-- ============================================================

SELECT
    DATE_FORMAT(
        Complaint_Date,
        '%Y-%m'
    ) AS Complaint_Month,

    COUNT(*) AS Total_Complaints,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'closed'
            THEN 1 ELSE 0
        END
    ) AS Closed_Complaints,

    SUM(
        CASE
            WHEN Resolution_Hours > SLA_Hours
            THEN 1 ELSE 0
        END
    ) AS SLA_Breaches,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Customer_Rating

FROM customer_complaints

GROUP BY
    DATE_FORMAT(
        Complaint_Date,
        '%Y-%m'
    )

ORDER BY
    Complaint_Month;


-- ============================================================
-- RESULT 12: RELATIONSHIP / DATA QUALITY EXCEPTIONS
-- ============================================================

SELECT
    'Customer' AS Entity,
    c.Customer_ID AS Entity_ID,
    COUNT(*) AS Complaint_Count,
    'Customer not found in Customer Master'
        AS Exception_Reason

FROM customer_complaints c

LEFT JOIN customer_master cu
    ON c.Customer_ID = cu.Customer_ID

WHERE cu.Customer_ID IS NULL

GROUP BY c.Customer_ID


UNION ALL


SELECT
    'Employee',
    c.Employee_ID,
    COUNT(*),
    'Employee not found in Employee Master'

FROM customer_complaints c

LEFT JOIN employee_master e
    ON c.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL

GROUP BY c.Employee_ID


UNION ALL


SELECT
    'Product',
    c.Product_ID,
    COUNT(*),
    'Product not found in Product Master'

FROM customer_complaints c

LEFT JOIN product_master p
    ON c.Product_ID = p.Product_ID

WHERE p.Product_ID IS NULL

GROUP BY c.Product_ID


UNION ALL


SELECT
    'Region',
    c.Region_ID,
    COUNT(*),
    'Region not found in Region Master'

FROM customer_complaints c

LEFT JOIN region_master r
    ON c.Region_ID = r.Region_ID

WHERE r.Region_ID IS NULL

GROUP BY c.Region_ID;


-- ============================================================
-- RESULT 13: MANAGEMENT COMPLAINT SUMMARY
-- ============================================================

SELECT
    Complaint_Type,

    COUNT(*) AS Complaint_Count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Complaint_Share_Pct,

    ROUND(
        AVG(Resolution_Hours),
        2
    ) AS Avg_Resolution_Hours,

    ROUND(
        SUM(
            CASE
                WHEN Resolution_Hours > SLA_Hours
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(
            SUM(
                CASE
                    WHEN Resolution_Hours IS NOT NULL
                         AND SLA_Hours IS NOT NULL
                    THEN 1 ELSE 0
                END
            ),
            0
        ),
        2
    ) AS SLA_Breach_Pct,

    ROUND(
        AVG(Customer_Rating),
        2
    ) AS Avg_Rating,

    CASE
        WHEN
            SUM(
                CASE
                    WHEN Resolution_Hours > SLA_Hours
                    THEN 1 ELSE 0
                END
            ) * 100.0 /
            NULLIF(
                SUM(
                    CASE
                        WHEN Resolution_Hours IS NOT NULL
                             AND SLA_Hours IS NOT NULL
                        THEN 1 ELSE 0
                    END
                ),
                0
            ) >= 70
            THEN 'Critical'

        WHEN
            SUM(
                CASE
                    WHEN Resolution_Hours > SLA_Hours
                    THEN 1 ELSE 0
                END
            ) * 100.0 /
            NULLIF(
                SUM(
                    CASE
                        WHEN Resolution_Hours IS NOT NULL
                             AND SLA_Hours IS NOT NULL
                        THEN 1 ELSE 0
                    END
                ),
                0
            ) >= 60
            THEN 'High Risk'

        ELSE 'Monitor'
    END AS Management_Status

FROM customer_complaints

GROUP BY Complaint_Type

ORDER BY
    SLA_Breach_Pct DESC,
    Complaint_Count DESC;


-- ============================================================
-- PART 13 COMPLETE
-- ============================================================