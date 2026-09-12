USE integrated_business;

-- ============================================================
-- PART 12 - EMPLOYEE PRODUCTIVITY & HR ANALYTICS
-- ============================================================
-- Covers:
-- Headcount
-- Attendance
-- Leave
-- Late Coming
-- Working Hours
-- Attrition
-- Attendance %
-- Sales per Employee
-- Revenue per Employee
-- Productivity Score
-- Low Attendance + Low Performance
-- High Performance + High Sales + Low Attendance
-- ============================================================


-- ============================================================
-- RESULT 1: OVERALL HR KPI SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS Total_Employees,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'active'
            THEN 1 ELSE 0
        END
    ) AS Active_Employees,

    SUM(
        CASE
            WHEN LOWER(TRIM(Status)) = 'inactive'
            THEN 1 ELSE 0
        END
    ) AS Inactive_Employees,

    ROUND(
        SUM(
            CASE
                WHEN LOWER(TRIM(Status)) = 'inactive'
                THEN 1 ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Attrition_Rate_Pct,

    ROUND(
        AVG(Monthly_Salary),
        2
    ) AS Avg_Monthly_Salary

FROM employee_master;

-- ============================================================
-- RESULT 2: OVERALL ATTENDANCE KPI
-- ============================================================

SELECT
    COUNT(*) AS Total_Attendance_Records,

    SUM(
        CASE
            WHEN LOWER(TRIM(Attendance_Status)) = 'present'
            THEN 1 ELSE 0
        END
    ) AS Present_Days,

    SUM(
        CASE
            WHEN LOWER(TRIM(Attendance_Status)) = 'leave'
            THEN 1 ELSE 0
        END
    ) AS Leave_Days,

    SUM(
        CASE
            WHEN LOWER(TRIM(Attendance_Status)) = 'absent'
            THEN 1 ELSE 0
        END
    ) AS Absent_Days,

    ROUND(
        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) * 100.0 /
        NULLIF(COUNT(*),0),
        2
    ) AS Attendance_Pct,

    ROUND(
        AVG(Working_Hours),
        2
    ) AS Avg_Working_Hours,

    ROUND(
        AVG(Late_Minutes),
        2
    ) AS Avg_Late_Minutes

FROM attendance_data;


-- ============================================================
-- RESULT 3: EMPLOYEE ATTENDANCE PERFORMANCE
-- ============================================================

WITH Attendance_Summary AS (
    SELECT
        Employee_ID,

        COUNT(*) AS Total_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) AS Present_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'leave'
                THEN 1 ELSE 0
            END
        ) AS Leave_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'absent'
                THEN 1 ELSE 0
            END
        ) AS Absent_Days,

        SUM(
            CASE
                WHEN Late_Minutes > 0
                THEN 1 ELSE 0
            END
        ) AS Late_Days,

        AVG(Working_Hours) AS Avg_Working_Hours,

        AVG(Late_Minutes) AS Avg_Late_Minutes

    FROM attendance_data

    GROUP BY Employee_ID
)

SELECT
    e.Employee_ID,
    e.Employee_Name,
    e.Department,
    e.Designation,
    e.Region_ID,

    COALESCE(a.Total_Days,0) AS Total_Days,
    COALESCE(a.Present_Days,0) AS Present_Days,
    COALESCE(a.Leave_Days,0) AS Leave_Days,
    COALESCE(a.Absent_Days,0) AS Absent_Days,
    COALESCE(a.Late_Days,0) AS Late_Days,

    ROUND(
        COALESCE(a.Present_Days,0) * 100.0 /
        NULLIF(a.Total_Days,0),
        2
    ) AS Attendance_Pct,

    ROUND(
        a.Avg_Working_Hours,
        2
    ) AS Avg_Working_Hours,

    ROUND(
        a.Avg_Late_Minutes,
        2
    ) AS Avg_Late_Minutes

FROM employee_master e

LEFT JOIN Attendance_Summary a
    ON e.Employee_ID = a.Employee_ID

ORDER BY
    Attendance_Pct DESC;


-- ============================================================
-- RESULT 4: EMPLOYEE SALES PERFORMANCE
-- ============================================================

WITH Sales_Summary AS (
    SELECT
        Employee_ID,

        COUNT(DISTINCT Transaction_ID)
            AS Transaction_Count,

        COUNT(DISTINCT Order_ID)
            AS Order_Count,

        SUM(Quantity)
            AS Quantity_Sold,

        SUM(Sales_Value)
            AS Total_Sales,

        SUM(Profit)
            AS Total_Profit,

        AVG(Sales_Value)
            AS Avg_Order_Value

    FROM sales_transactions

    GROUP BY Employee_ID
)

SELECT
    e.Employee_ID,
    e.Employee_Name,
    e.Department,
    e.Designation,
    e.Region_ID,

    COALESCE(s.Transaction_Count,0)
        AS Transaction_Count,

    COALESCE(s.Order_Count,0)
        AS Order_Count,

    COALESCE(s.Quantity_Sold,0)
        AS Quantity_Sold,

    ROUND(
        COALESCE(s.Total_Sales,0),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(s.Total_Profit,0),
        2
    ) AS Total_Profit,

    ROUND(
        COALESCE(s.Avg_Order_Value,0),
        2
    ) AS Avg_Order_Value

FROM employee_master e

LEFT JOIN Sales_Summary s
    ON e.Employee_ID = s.Employee_ID

ORDER BY
    Total_Sales DESC;


-- ============================================================
-- RESULT 5: SALES PER EMPLOYEE / REVENUE PER EMPLOYEE
-- ============================================================

SELECT
    COUNT(DISTINCT e.Employee_ID)
        AS Employee_Count,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Revenue,

    ROUND(
        SUM(s.Sales_Value) /
        NULLIF(COUNT(DISTINCT e.Employee_ID),0),
        2
    ) AS Revenue_Per_Employee,

    ROUND(
        COUNT(DISTINCT s.Order_ID) /
        NULLIF(COUNT(DISTINCT e.Employee_ID),0),
        2
    ) AS Orders_Per_Employee,

    ROUND(
        SUM(s.Profit) /
        NULLIF(COUNT(DISTINCT e.Employee_ID),0),
        2
    ) AS Profit_Per_Employee

FROM employee_master e

LEFT JOIN sales_transactions s
    ON e.Employee_ID = s.Employee_ID;


-- ============================================================
-- RESULT 6: EMPLOYEE PRODUCTIVITY SCORE
-- ============================================================
-- Derived score:
-- Sales Score      = 50%
-- Attendance Score = 30%
-- Working Hours    = 10%
-- Punctuality      = 10%
-- ============================================================

WITH Attendance_Summary AS (
    SELECT
        Employee_ID,

        COUNT(*) AS Total_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) AS Present_Days,

        AVG(Working_Hours)
            AS Avg_Working_Hours,

        AVG(Late_Minutes)
            AS Avg_Late_Minutes

    FROM attendance_data
    GROUP BY Employee_ID
),

Sales_Summary AS (
    SELECT
        Employee_ID,

        SUM(Sales_Value)
            AS Total_Sales,

        COUNT(DISTINCT Order_ID)
            AS Order_Count

    FROM sales_transactions
    GROUP BY Employee_ID
),

Employee_Base AS (
    SELECT
        e.Employee_ID,
        e.Employee_Name,
        e.Department,
        e.Designation,
        e.Region_ID,
        e.Status,

        COALESCE(s.Total_Sales,0)
            AS Total_Sales,

        COALESCE(s.Order_Count,0)
            AS Order_Count,

        ROUND(
            COALESCE(a.Present_Days,0) * 100.0 /
            NULLIF(a.Total_Days,0),
            2
        ) AS Attendance_Pct,

        COALESCE(a.Avg_Working_Hours,0)
            AS Avg_Working_Hours,

        COALESCE(a.Avg_Late_Minutes,0)
            AS Avg_Late_Minutes

    FROM employee_master e

    LEFT JOIN Attendance_Summary a
        ON e.Employee_ID = a.Employee_ID

    LEFT JOIN Sales_Summary s
        ON e.Employee_ID = s.Employee_ID
),

Benchmarks AS (
    SELECT
        MAX(Total_Sales)
            AS Max_Sales,

        MAX(Avg_Working_Hours)
            AS Max_Working_Hours,

        MAX(Avg_Late_Minutes)
            AS Max_Late_Minutes

    FROM Employee_Base
),

Scored AS (
    SELECT
        eb.*,

        LEAST(
            50,
            COALESCE(
                eb.Total_Sales /
                NULLIF(b.Max_Sales,0) * 50,
                0
            )
        ) AS Sales_Score,

        LEAST(
            30,
            COALESCE(
                eb.Attendance_Pct / 100 * 30,
                0
            )
        ) AS Attendance_Score,

        LEAST(
            10,
            COALESCE(
                eb.Avg_Working_Hours /
                NULLIF(b.Max_Working_Hours,0) * 10,
                0
            )
        ) AS Working_Hours_Score,

        LEAST(
            10,
            GREATEST(
                0,
                10 -
                COALESCE(
                    eb.Avg_Late_Minutes /
                    NULLIF(b.Max_Late_Minutes,0) * 10,
                    0
                )
            )
        ) AS Punctuality_Score

    FROM Employee_Base eb
    CROSS JOIN Benchmarks b
)

SELECT
    Employee_ID,
    Employee_Name,
    Department,
    Designation,
    Region_ID,

    ROUND(
        Total_Sales,
        2
    ) AS Total_Sales,

    Order_Count,

    Attendance_Pct,

    ROUND(
        Avg_Working_Hours,
        2
    ) AS Avg_Working_Hours,

    ROUND(
        Avg_Late_Minutes,
        2
    ) AS Avg_Late_Minutes,

    ROUND(
        Sales_Score
        + Attendance_Score
        + Working_Hours_Score
        + Punctuality_Score,
        2
    ) AS Productivity_Score,

    CASE
        WHEN (
            Sales_Score
            + Attendance_Score
            + Working_Hours_Score
            + Punctuality_Score
        ) >= 80
            THEN 'High Performer'

        WHEN (
            Sales_Score
            + Attendance_Score
            + Working_Hours_Score
            + Punctuality_Score
        ) >= 60
            THEN 'Good Performer'

        WHEN (
            Sales_Score
            + Attendance_Score
            + Working_Hours_Score
            + Punctuality_Score
        ) >= 40
            THEN 'Average Performer'

        ELSE 'Low Performer'
    END AS Performance_Category

FROM Scored

ORDER BY
    Productivity_Score DESC;


-- ============================================================
-- RESULT 7: PERFORMANCE CATEGORY SUMMARY
-- ============================================================

WITH Attendance_Summary AS (
    SELECT
        Employee_ID,
        COUNT(*) AS Total_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) AS Present_Days,

        AVG(Working_Hours)
            AS Avg_Working_Hours,

        AVG(Late_Minutes)
            AS Avg_Late_Minutes

    FROM attendance_data
    GROUP BY Employee_ID
),

Sales_Summary AS (
    SELECT
        Employee_ID,
        SUM(Sales_Value)
            AS Total_Sales

    FROM sales_transactions
    GROUP BY Employee_ID
),

Employee_Base AS (
    SELECT
        e.Employee_ID,

        COALESCE(s.Total_Sales,0)
            AS Total_Sales,

        COALESCE(a.Present_Days,0) * 100.0 /
        NULLIF(a.Total_Days,0)
            AS Attendance_Pct,

        COALESCE(a.Avg_Working_Hours,0)
            AS Avg_Working_Hours,

        COALESCE(a.Avg_Late_Minutes,0)
            AS Avg_Late_Minutes

    FROM employee_master e

    LEFT JOIN Attendance_Summary a
        ON e.Employee_ID = a.Employee_ID

    LEFT JOIN Sales_Summary s
        ON e.Employee_ID = s.Employee_ID
),

Benchmarks AS (
    SELECT
        MAX(Total_Sales)
            AS Max_Sales,

        MAX(Avg_Working_Hours)
            AS Max_Working_Hours,

        MAX(Avg_Late_Minutes)
            AS Max_Late_Minutes

    FROM Employee_Base
),

Scores AS (
    SELECT
        eb.*,

        LEAST(
            50,
            COALESCE(
                eb.Total_Sales /
                NULLIF(b.Max_Sales,0) * 50,
                0
            )
        )

        +

        LEAST(
            30,
            COALESCE(
                eb.Attendance_Pct / 100 * 30,
                0
            )
        )

        +

        LEAST(
            10,
            COALESCE(
                eb.Avg_Working_Hours /
                NULLIF(b.Max_Working_Hours,0) * 10,
                0
            )
        )

        +

        LEAST(
            10,
            GREATEST(
                0,
                10 -
                COALESCE(
                    eb.Avg_Late_Minutes /
                    NULLIF(b.Max_Late_Minutes,0) * 10,
                    0
                )
            )
        ) AS Productivity_Score

    FROM Employee_Base eb
    CROSS JOIN Benchmarks b
),

Categories AS (
    SELECT
        *,

        CASE
            WHEN Productivity_Score >= 80
                THEN 'High Performer'

            WHEN Productivity_Score >= 60
                THEN 'Good Performer'

            WHEN Productivity_Score >= 40
                THEN 'Average Performer'

            ELSE 'Low Performer'
        END AS Performance_Category

    FROM Scores
)

SELECT
    Performance_Category,

    COUNT(*) AS Employee_Count,

    ROUND(
        AVG(Productivity_Score),
        2
    ) AS Avg_Productivity_Score,

    ROUND(
        AVG(Attendance_Pct),
        2
    ) AS Avg_Attendance_Pct,

    ROUND(
        SUM(Total_Sales),
        2
    ) AS Total_Sales

FROM Categories

GROUP BY
    Performance_Category

ORDER BY
    Avg_Productivity_Score DESC;


-- ============================================================
-- RESULT 8: LOW ATTENDANCE + LOW PERFORMANCE EMPLOYEES
-- ============================================================

WITH Attendance_Summary AS (
    SELECT
        Employee_ID,

        COUNT(*) AS Total_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) AS Present_Days

    FROM attendance_data
    GROUP BY Employee_ID
),

Sales_Summary AS (
    SELECT
        Employee_ID,
        SUM(Sales_Value) AS Total_Sales

    FROM sales_transactions
    GROUP BY Employee_ID
),

Employee_Data AS (
    SELECT
        e.Employee_ID,
        e.Employee_Name,
        e.Department,

        ROUND(
            COALESCE(a.Present_Days,0) * 100.0 /
            NULLIF(a.Total_Days,0),
            2
        ) AS Attendance_Pct,

        COALESCE(s.Total_Sales,0)
            AS Total_Sales

    FROM employee_master e

    LEFT JOIN Attendance_Summary a
        ON e.Employee_ID = a.Employee_ID

    LEFT JOIN Sales_Summary s
        ON e.Employee_ID = s.Employee_ID
),

Benchmark AS (
    SELECT
        AVG(Total_Sales)
            AS Avg_Employee_Sales

    FROM Employee_Data
)

SELECT
    ed.Employee_ID,
    ed.Employee_Name,
    ed.Department,
    ed.Attendance_Pct,

    ROUND(
        ed.Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        b.Avg_Employee_Sales,
        2
    ) AS Avg_Employee_Sales,

    'Low Attendance + Low Performance'
        AS Risk_Flag

FROM Employee_Data ed

CROSS JOIN Benchmark b

WHERE ed.Attendance_Pct < 75

AND ed.Total_Sales <
    b.Avg_Employee_Sales

ORDER BY
    ed.Attendance_Pct ASC,
    ed.Total_Sales ASC;


-- ============================================================
-- RESULT 9: HIGH SALES + HIGH PERFORMANCE + LOW ATTENDANCE
-- ============================================================

WITH Attendance_Summary AS (
    SELECT
        Employee_ID,

        COUNT(*) AS Total_Days,

        SUM(
            CASE
                WHEN LOWER(TRIM(Attendance_Status)) = 'present'
                THEN 1 ELSE 0
            END
        ) AS Present_Days

    FROM attendance_data
    GROUP BY Employee_ID
),

Sales_Summary AS (
    SELECT
        Employee_ID,
        SUM(Sales_Value) AS Total_Sales

    FROM sales_transactions
    GROUP BY Employee_ID
),

Employee_Data AS (
    SELECT
        e.Employee_ID,
        e.Employee_Name,
        e.Department,

        ROUND(
            COALESCE(a.Present_Days,0) * 100.0 /
            NULLIF(a.Total_Days,0),
            2
        ) AS Attendance_Pct,

        COALESCE(s.Total_Sales,0)
            AS Total_Sales

    FROM employee_master e

    LEFT JOIN Attendance_Summary a
        ON e.Employee_ID = a.Employee_ID

    LEFT JOIN Sales_Summary s
        ON e.Employee_ID = s.Employee_ID
),

Benchmark AS (
    SELECT
        AVG(Total_Sales)
            AS Avg_Employee_Sales

    FROM Employee_Data
)

SELECT
    ed.Employee_ID,
    ed.Employee_Name,
    ed.Department,
    ed.Attendance_Pct,

    ROUND(
        ed.Total_Sales,
        2
    ) AS Total_Sales,

    ROUND(
        b.Avg_Employee_Sales,
        2
    ) AS Avg_Employee_Sales,

    'High Sales despite Low Attendance'
        AS Performance_Flag

FROM Employee_Data ed

CROSS JOIN Benchmark b

WHERE ed.Attendance_Pct < 75

AND ed.Total_Sales >
    b.Avg_Employee_Sales

ORDER BY
    ed.Total_Sales DESC;


-- ============================================================
-- RESULT 10: TOP 10 EMPLOYEES BY SALES
-- ============================================================

SELECT
    s.Employee_ID,

    COALESCE(
        e.Employee_Name,
        'Unmapped Employee'
    ) AS Employee_Name,

    e.Department,
    e.Designation,

    COUNT(DISTINCT s.Order_ID)
        AS Order_Count,

    ROUND(
        SUM(s.Sales_Value),
        2
    ) AS Total_Sales,

    ROUND(
        SUM(s.Profit),
        2
    ) AS Total_Profit

FROM sales_transactions s

LEFT JOIN employee_master e
    ON s.Employee_ID = e.Employee_ID

GROUP BY
    s.Employee_ID,
    e.Employee_Name,
    e.Department,
    e.Designation

ORDER BY
    Total_Sales DESC

LIMIT 10;


-- ============================================================
-- RESULT 11: DEPARTMENT PERFORMANCE
-- ============================================================

SELECT
    e.Department,

    COUNT(DISTINCT e.Employee_ID)
        AS Headcount,

    ROUND(
        AVG(e.Monthly_Salary),
        2
    ) AS Avg_Monthly_Salary,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0) /
        NULLIF(COUNT(DISTINCT e.Employee_ID),0),
        2
    ) AS Revenue_Per_Employee

FROM employee_master e

LEFT JOIN sales_transactions s
    ON e.Employee_ID = s.Employee_ID

GROUP BY
    e.Department

ORDER BY
    Total_Sales DESC;


-- ============================================================
-- RESULT 12: REGION EMPLOYEE PERFORMANCE
-- ============================================================

SELECT
    e.Region_ID,

    COUNT(DISTINCT e.Employee_ID)
        AS Headcount,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0),
        2
    ) AS Total_Sales,

    ROUND(
        COALESCE(SUM(s.Profit),0),
        2
    ) AS Total_Profit,

    ROUND(
        COALESCE(SUM(s.Sales_Value),0) /
        NULLIF(COUNT(DISTINCT e.Employee_ID),0),
        2
    ) AS Revenue_Per_Employee

FROM employee_master e

LEFT JOIN sales_transactions s
    ON e.Employee_ID = s.Employee_ID

GROUP BY
    e.Region_ID

ORDER BY
    Total_Sales DESC;


-- ============================================================
-- RESULT 13: ATTENDANCE STATUS SUMMARY
-- ============================================================

SELECT
    Attendance_Status,

    COUNT(*) AS Record_Count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Percentage

FROM attendance_data

GROUP BY
    Attendance_Status

ORDER BY
    Record_Count DESC;


-- ============================================================
-- RESULT 14: EMPLOYEE DATA RELATIONSHIP EXCEPTIONS
-- ============================================================

SELECT
    a.Employee_ID,

    COUNT(*) AS Attendance_Records,

    'Attendance Employee not found in Employee Master'
        AS Exception_Reason

FROM attendance_data a

LEFT JOIN employee_master e
    ON a.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL

GROUP BY
    a.Employee_ID

UNION ALL

SELECT
    s.Employee_ID,

    COUNT(*) AS Sales_Records,

    'Sales Employee not found in Employee Master'
        AS Exception_Reason

FROM sales_transactions s

LEFT JOIN employee_master e
    ON s.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL

GROUP BY
    s.Employee_ID;


-- ============================================================
-- PART 12 COMPLETE
-- ============================================================