USE integrated_business;

-- ============================================================
-- PART 18 - MANAGEMENT EXCEPTION SYSTEM
-- ============================================================
-- Automated Exception Report using SQL VIEW
--
-- Rules:
-- 1. Sales < 70% Target              -> High
-- 2. Outstanding > 180 Days          -> Critical
-- 3. Stockout + High Demand          -> Critical
-- 4. Supplier SLA < 80%              -> High
-- 5. Return Rate > 15%               -> High
-- 6. Attendance < 85%                -> Medium
-- 7. Complaint SLA Breach            -> High
-- 8. Negative Product Profit         -> Critical
--
-- Output:
-- Issue
-- Department
-- Entity_ID
-- Entity_Name
-- Value
-- Threshold
-- Priority
-- Recommended_Action
-- ============================================================


-- ============================================================
-- STEP 1: DROP OLD VIEW
-- ============================================================

DROP VIEW IF EXISTS vw_management_exception_report;


-- ============================================================
-- STEP 2: CREATE AUTOMATED MANAGEMENT EXCEPTION VIEW
-- ============================================================

CREATE VIEW vw_management_exception_report AS


-- ============================================================
-- EXCEPTION 1
-- SALES < 70% TARGET
-- Priority: HIGH
-- ============================================================

SELECT
    'Sales Below 70% Target' AS Issue,

    COALESCE(
        e.Department,
        'Sales'
    ) AS Department,

    t.Employee_ID AS Entity_ID,

    COALESCE(
        e.Employee_Name,
        'Unmapped Employee'
    ) AS Entity_Name,

    ROUND(
        COALESCE(s.Actual_Sales, 0)
        * 100.0
        / NULLIF(t.Sales_Target, 0),
        2
    ) AS Value,

    '>= 70% Target Achievement'
        AS Threshold,

    'High' AS Priority,

    'Review employee sales pipeline, customer coverage and recovery plan.'
        AS Recommended_Action

FROM
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Target_Month,
            '%Y-%m'
        ) AS Target_Month,

        SUM(Sales_Target)
            AS Sales_Target

    FROM sales_targets

    GROUP BY
        Employee_ID,
        DATE_FORMAT(
            Target_Month,
            '%Y-%m'
        )
) t

LEFT JOIN
(
    SELECT
        Employee_ID,

        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        ) AS Sales_Month,

        SUM(Sales_Value)
            AS Actual_Sales

    FROM sales_transactions

    GROUP BY
        Employee_ID,
        DATE_FORMAT(
            Sales_Date,
            '%Y-%m'
        )
) s

    ON t.Employee_ID = s.Employee_ID

    AND t.Target_Month = s.Sales_Month

LEFT JOIN employee_master e
    ON t.Employee_ID = e.Employee_ID

WHERE
    COALESCE(
        s.Actual_Sales,
        0
    ) * 100.0
    / NULLIF(
        t.Sales_Target,
        0
    ) < 70


UNION ALL


-- ============================================================
-- EXCEPTION 2
-- OUTSTANDING > 180 DAYS
-- Priority: CRITICAL
-- ============================================================

SELECT
    'Outstanding Receivable > 180 Days'
        AS Issue,

    'Finance'
        AS Department,

    COALESCE(
        o.Customer_ID,
        i.Invoice_ID
    ) AS Entity_ID,

    COALESCE(
        c.Customer_Name,
        CONCAT(
            'Invoice ',
            i.Invoice_ID
        )
    ) AS Entity_Name,

    ROUND(
        GREATEST(
            i.Invoice_Amount
            -
            COALESCE(
                p.Paid_Amount,
                0
            ),
            0
        ),
        2
    ) AS Value,

    '> 180 Days Outstanding'
        AS Threshold,

    'Critical'
        AS Priority,

    'Escalate collection immediately and review customer credit exposure.'
        AS Recommended_Action

FROM invoice_data i

LEFT JOIN
(
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN LOWER(
                    TRIM(
                        Payment_Status
                    )
                ) = 'success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data

    GROUP BY Invoice_ID

) p
    ON i.Invoice_ID = p.Invoice_ID

LEFT JOIN order_transactions o
    ON i.Order_ID = o.Order_ID

LEFT JOIN customer_master c
    ON o.Customer_ID = c.Customer_ID

WHERE

    GREATEST(
        i.Invoice_Amount
        -
        COALESCE(
            p.Paid_Amount,
            0
        ),
        0
    ) > 0

    AND DATEDIFF(
        CURDATE(),
        i.Due_Date
    ) > 180


UNION ALL


-- ============================================================
-- EXCEPTION 3
-- STOCKOUT + HIGH DEMAND
-- Priority: CRITICAL
-- ============================================================

SELECT
    'Stockout + High Demand'
        AS Issue,

    'Inventory'
        AS Department,

    inv.Product_ID
        AS Entity_ID,

    COALESCE(
        pm.Product_Name,
        'Unmapped Product'
    ) AS Entity_Name,

    ROUND(
        COALESCE(
            demand.Sales_Qty,
            0
        ),
        2
    ) AS Value,

    'High Demand + Stockout'
        AS Threshold,

    'Critical'
        AS Priority,

    'Replenish stock immediately and review reorder level and safety stock.'
        AS Recommended_Action

FROM
(
    SELECT
        i.Product_ID,

        SUM(
            i.Closing_Stock
        ) AS Closing_Stock,

        SUM(
            i.Stockout_Days
        ) AS Stockout_Days

    FROM inventory_data i

    INNER JOIN
    (
        SELECT
            Product_ID,
            MAX(Snapshot_Date)
                AS Latest_Snapshot_Date

        FROM inventory_data

        GROUP BY Product_ID

    ) latest

        ON i.Product_ID =
           latest.Product_ID

        AND i.Snapshot_Date =
            latest.Latest_Snapshot_Date

    GROUP BY
        i.Product_ID

) inv

LEFT JOIN
(
    SELECT
        Product_ID,

        SUM(Quantity)
            AS Sales_Qty

    FROM sales_transactions

    GROUP BY Product_ID

) demand
    ON inv.Product_ID =
       demand.Product_ID

LEFT JOIN product_master pm
    ON inv.Product_ID =
       pm.Product_ID

WHERE

    (
        inv.Closing_Stock <= 0
        OR inv.Stockout_Days > 0
    )

    AND COALESCE(
        demand.Sales_Qty,
        0
    ) >
    (
        SELECT
            AVG(Product_Sales_Qty)

        FROM
        (
            SELECT
                Product_ID,

                SUM(Quantity)
                    AS Product_Sales_Qty

            FROM sales_transactions

            GROUP BY Product_ID

        ) avg_demand
    )


UNION ALL


-- ============================================================
-- EXCEPTION 4
-- SUPPLIER SLA < 80%
-- Priority: HIGH
-- ============================================================

SELECT
    'Supplier SLA Below 80%'
        AS Issue,

    'Procurement'
        AS Department,

    p.Supplier_ID
        AS Entity_ID,

    COALESCE(
        s.Supplier_Name,
        'Unmapped Supplier'
    ) AS Entity_Name,

    ROUND(
        SUM(
            CASE
                WHEN
                    p.Actual_Delivery_Date
                    <=
                    p.Promised_Delivery_Date
                THEN 1
                ELSE 0
            END
        )
        * 100.0
        /
        NULLIF(
            COUNT(*),
            0
        ),
        2
    ) AS Value,

    '>= 80% On-Time Delivery'
        AS Threshold,

    'High'
        AS Priority,

    'Review supplier delivery performance and initiate SLA improvement plan.'
        AS Recommended_Action

FROM purchase_data p

LEFT JOIN supplier_master s
    ON p.Supplier_ID =
       s.Supplier_ID

WHERE
    p.Promised_Delivery_Date
        IS NOT NULL

    AND p.Actual_Delivery_Date
        IS NOT NULL

GROUP BY
    p.Supplier_ID,
    s.Supplier_Name

HAVING

    SUM(
        CASE
            WHEN
                p.Actual_Delivery_Date
                <=
                p.Promised_Delivery_Date
            THEN 1
            ELSE 0
        END
    )
    * 100.0
    /
    NULLIF(
        COUNT(*),
        0
    ) < 80


UNION ALL


-- ============================================================
-- EXCEPTION 5
-- RETURN RATE > 15%
-- Priority: HIGH
-- ============================================================

SELECT
    'Product Return Rate Above 15%'
        AS Issue,

    'Sales / Quality'
        AS Department,

    sales.Product_ID
        AS Entity_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Entity_Name,

    ROUND(
        COALESCE(
            ret.Return_Qty,
            0
        )
        * 100.0
        /
        NULLIF(
            sales.Sales_Qty,
            0
        ),
        2
    ) AS Value,

    '<= 15% Return Rate'
        AS Threshold,

    'High'
        AS Priority,

    'Investigate product quality, fulfilment accuracy and return root causes.'
        AS Recommended_Action

FROM
(
    SELECT
        Product_ID,

        SUM(Quantity)
            AS Sales_Qty

    FROM sales_transactions

    GROUP BY Product_ID

) sales

LEFT JOIN
(
    SELECT
        Product_ID,

        SUM(Return_Qty)
            AS Return_Qty

    FROM returns_data

    GROUP BY Product_ID

) ret

    ON sales.Product_ID =
       ret.Product_ID

LEFT JOIN product_master p

    ON sales.Product_ID =
       p.Product_ID

WHERE

    COALESCE(
        ret.Return_Qty,
        0
    )
    * 100.0
    /
    NULLIF(
        sales.Sales_Qty,
        0
    ) > 15


UNION ALL


-- ============================================================
-- EXCEPTION 6
-- ATTENDANCE < 85%
-- Priority: MEDIUM
-- ============================================================

SELECT
    'Employee Attendance Below 85%'
        AS Issue,

    COALESCE(
        e.Department,
        'HR'
    ) AS Department,

    a.Employee_ID
        AS Entity_ID,

    COALESCE(
        e.Employee_Name,
        'Unmapped Employee'
    ) AS Entity_Name,

    ROUND(
        SUM(
            CASE
                WHEN LOWER(
                    TRIM(
                        a.Attendance_Status
                    )
                ) = 'present'
                THEN 1
                ELSE 0
            END
        )
        * 100.0
        /
        NULLIF(
            COUNT(*),
            0
        ),
        2
    ) AS Value,

    '>= 85% Attendance'
        AS Threshold,

    'Medium'
        AS Priority,

    'Review absenteeism, leave pattern and employee attendance improvement plan.'
        AS Recommended_Action

FROM attendance_data a

LEFT JOIN employee_master e
    ON a.Employee_ID =
       e.Employee_ID

GROUP BY
    a.Employee_ID,
    e.Employee_Name,
    e.Department

HAVING

    SUM(
        CASE
            WHEN LOWER(
                TRIM(
                    a.Attendance_Status
                )
            ) = 'present'
            THEN 1
            ELSE 0
        END
    )
    * 100.0
    /
    NULLIF(
        COUNT(*),
        0
    ) < 85


UNION ALL


-- ============================================================
-- EXCEPTION 7
-- COMPLAINT SLA BREACH
-- Priority: HIGH
-- ============================================================

SELECT
    'Complaint SLA Breach'
        AS Issue,

    'Customer Support'
        AS Department,

    cc.Customer_ID
        AS Entity_ID,

    COALESCE(
        cm.Customer_Name,
        'Unmapped Customer'
    ) AS Entity_Name,

    ROUND(
        cc.Resolution_Hours
        -
        cc.SLA_Hours,
        2
    ) AS Value,

    CONCAT(
        'Resolution <= ',
        ROUND(
            cc.SLA_Hours,
            2
        ),
        ' Hours'
    ) AS Threshold,

    'High'
        AS Priority,

    CONCAT(
        'Escalate complaint ',
        cc.Complaint_ID,
        ' and investigate SLA breach root cause.'
    ) AS Recommended_Action

FROM customer_complaints cc

LEFT JOIN customer_master cm
    ON cc.Customer_ID =
       cm.Customer_ID

WHERE

    cc.Resolution_Hours
        IS NOT NULL

    AND cc.SLA_Hours
        IS NOT NULL

    AND cc.Resolution_Hours
        >
        cc.SLA_Hours


UNION ALL


-- ============================================================
-- EXCEPTION 8
-- NEGATIVE PRODUCT PROFIT
-- Priority: CRITICAL
-- ============================================================

SELECT
    'Negative Product Profit'
        AS Issue,

    'Sales / Product'
        AS Department,

    sales.Product_ID
        AS Entity_ID,

    COALESCE(
        p.Product_Name,
        'Unmapped Product'
    ) AS Entity_Name,

    ROUND(
        sales.Gross_Profit
        -
        COALESCE(
            ret.Return_Value,
            0
        ),
        2
    ) AS Value,

    '>= 0 Net Product Profit'
        AS Threshold,

    'Critical'
        AS Priority,

    'Review pricing, discount, product cost and return losses immediately.'
        AS Recommended_Action

FROM
(
    SELECT
        Product_ID,

        SUM(Profit)
            AS Gross_Profit

    FROM sales_transactions

    GROUP BY Product_ID

) sales

LEFT JOIN
(
    SELECT
        Product_ID,

        SUM(Return_Value)
            AS Return_Value

    FROM returns_data

    GROUP BY Product_ID

) ret

    ON sales.Product_ID =
       ret.Product_ID

LEFT JOIN product_master p

    ON sales.Product_ID =
       p.Product_ID

WHERE

    (
        sales.Gross_Profit
        -
        COALESCE(
            ret.Return_Value,
            0
        )
    ) < 0;


-- ============================================================
-- STEP 3: VIEW COMPLETE EXCEPTION REPORT
-- ============================================================

SELECT
    Issue,
    Department,
    Entity_ID,
    Entity_Name,
    Value,
    Threshold,
    Priority,
    Recommended_Action

FROM vw_management_exception_report

ORDER BY

    CASE Priority

        WHEN 'Critical'
            THEN 1

        WHEN 'High'
            THEN 2

        WHEN 'Medium'
            THEN 3

        ELSE 4

    END,

    Issue,
    Value DESC;


-- ============================================================
-- RESULT 2: EXCEPTION SUMMARY BY PRIORITY
-- ============================================================

SELECT
    Priority,

    COUNT(*) AS Exception_Count

FROM vw_management_exception_report

GROUP BY Priority

ORDER BY

    CASE Priority

        WHEN 'Critical'
            THEN 1

        WHEN 'High'
            THEN 2

        WHEN 'Medium'
            THEN 3

        ELSE 4

    END;


-- ============================================================
-- RESULT 3: EXCEPTION SUMMARY BY ISSUE
-- ============================================================

SELECT
    Issue,

    Priority,

    COUNT(*) AS Exception_Count,

    ROUND(
        AVG(Value),
        2
    ) AS Avg_Value,

    ROUND(
        MAX(Value),
        2
    ) AS Max_Value

FROM vw_management_exception_report

GROUP BY
    Issue,
    Priority

ORDER BY

    CASE Priority

        WHEN 'Critical'
            THEN 1

        WHEN 'High'
            THEN 2

        WHEN 'Medium'
            THEN 3

        ELSE 4

    END,

    Exception_Count DESC;


-- ============================================================
-- RESULT 4: CRITICAL EXCEPTIONS ONLY
-- ============================================================

SELECT
    Issue,
    Department,
    Entity_ID,
    Entity_Name,
    Value,
    Threshold,
    Recommended_Action

FROM vw_management_exception_report

WHERE Priority = 'Critical'

ORDER BY
    Issue,
    Value DESC;


-- ============================================================
-- RESULT 5: HIGH PRIORITY EXCEPTIONS ONLY
-- ============================================================

SELECT
    Issue,
    Department,
    Entity_ID,
    Entity_Name,
    Value,
    Threshold,
    Recommended_Action

FROM vw_management_exception_report

WHERE Priority = 'High'

ORDER BY
    Issue,
    Value DESC;


-- ============================================================
-- RESULT 6: MEDIUM PRIORITY EXCEPTIONS ONLY
-- ============================================================

SELECT
    Issue,
    Department,
    Entity_ID,
    Entity_Name,
    Value,
    Threshold,
    Recommended_Action

FROM vw_management_exception_report

WHERE Priority = 'Medium'

ORDER BY
    Issue,
    Value DESC;


-- ============================================================
-- RESULT 7: MANAGEMENT DASHBOARD SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS Total_Exceptions,

    SUM(
        CASE
            WHEN Priority = 'Critical'
            THEN 1
            ELSE 0
        END
    ) AS Critical_Exceptions,

    SUM(
        CASE
            WHEN Priority = 'High'
            THEN 1
            ELSE 0
        END
    ) AS High_Exceptions,

    SUM(
        CASE
            WHEN Priority = 'Medium'
            THEN 1
            ELSE 0
        END
    ) AS Medium_Exceptions,

    COUNT(
        DISTINCT Department
    ) AS Departments_Affected,

    COUNT(
        DISTINCT Entity_ID
    ) AS Entities_Affected

FROM vw_management_exception_report;


-- ============================================================
-- RESULT 8: VERIFY ALL REQUIRED RULES
-- ============================================================

SELECT
    'Sales < 70% Target'
        AS Required_Rule,

    COUNT(*) AS Flagged_Count

FROM vw_management_exception_report

WHERE Issue =
      'Sales Below 70% Target'


UNION ALL


SELECT
    'Outstanding > 180 Days',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Outstanding Receivable > 180 Days'


UNION ALL


SELECT
    'Stockout + High Demand',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Stockout + High Demand'


UNION ALL


SELECT
    'Supplier SLA < 80%',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Supplier SLA Below 80%'


UNION ALL


SELECT
    'Return Rate > 15%',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Product Return Rate Above 15%'


UNION ALL


SELECT
    'Attendance < 85%',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Employee Attendance Below 85%'


UNION ALL


SELECT
    'Complaint SLA Breach',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Complaint SLA Breach'


UNION ALL


SELECT
    'Negative Product Profit',

    COUNT(*)

FROM vw_management_exception_report

WHERE Issue =
      'Negative Product Profit';


-- ============================================================
-- PART 18 COMPLETE
-- ============================================================