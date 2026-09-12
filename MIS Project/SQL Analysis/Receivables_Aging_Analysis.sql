USE integrated_business;

-- ============================================================
-- PART 9 - RECEIVABLES AGING & CREDIT RISK ANALYSIS
-- ============================================================


-- ============================================================
-- RESULT 1: RECEIVABLES AGING SUMMARY
-- ============================================================

WITH Reference_Date AS (
    SELECT GREATEST(
        COALESCE((SELECT MAX(Sales_Date)
                  FROM sales_transactions), '1900-01-01'),
        COALESCE((SELECT MAX(Invoice_Date)
                  FROM invoice_data), '1900-01-01'),
        COALESCE((SELECT MAX(Payment_Date)
                  FROM payment_data), '1900-01-01')
    ) AS Report_Date
),

Payment_Summary AS (
    SELECT
        Invoice_ID,
        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount
    FROM payment_data
    GROUP BY Invoice_ID
),

Aging_Data AS (
    SELECT
        i.Invoice_ID,
        i.Order_ID,
        i.Invoice_Date,
        i.Due_Date,
        i.Invoice_Amount,

        COALESCE(p.Paid_Amount, 0) AS Paid_Amount,

        GREATEST(
            i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
            0
        ) AS Outstanding_Amount,

        GREATEST(
            DATEDIFF(r.Report_Date, i.Due_Date),
            0
        ) AS Aging_Days

    FROM invoice_data i

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    CROSS JOIN Reference_Date r

    WHERE i.Invoice_Amount > COALESCE(p.Paid_Amount, 0)
),

Aging_Buckets AS (
    SELECT
        Invoice_ID,
        Outstanding_Amount,

        CASE
            WHEN Aging_Days BETWEEN 0 AND 30
                THEN '0-30 Days'
            WHEN Aging_Days BETWEEN 31 AND 60
                THEN '31-60 Days'
            WHEN Aging_Days BETWEEN 61 AND 90
                THEN '61-90 Days'
            WHEN Aging_Days BETWEEN 91 AND 180
                THEN '91-180 Days'
            WHEN Aging_Days BETWEEN 181 AND 365
                THEN '181-365 Days'
            ELSE '365+ Days'
        END AS Aging_Bucket

    FROM Aging_Data
)

SELECT
    Aging_Bucket,

    COUNT(*) AS Invoice_Count,

    ROUND(
        SUM(Outstanding_Amount),
        2
    ) AS Outstanding_Amount,

    ROUND(
        SUM(Outstanding_Amount) * 100.0
        / SUM(SUM(Outstanding_Amount)) OVER(),
        2
    ) AS Outstanding_Percentage

FROM Aging_Buckets

GROUP BY Aging_Bucket

ORDER BY
    CASE Aging_Bucket
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        WHEN '91-180 Days' THEN 4
        WHEN '181-365 Days' THEN 5
        ELSE 6
    END;


-- ============================================================
-- RESULT 2: TOTAL OUTSTANDING / OVERDUE / MONEY AT RISK
-- Money At Risk = Outstanding > 90 days past due
-- ============================================================

WITH Reference_Date AS (
    SELECT GREATEST(
        COALESCE((SELECT MAX(Sales_Date)
                  FROM sales_transactions), '1900-01-01'),
        COALESCE((SELECT MAX(Invoice_Date)
                  FROM invoice_data), '1900-01-01'),
        COALESCE((SELECT MAX(Payment_Date)
                  FROM payment_data), '1900-01-01')
    ) AS Report_Date
),

Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
),

Receivable_Data AS (
    SELECT
        i.Invoice_ID,
        i.Due_Date,

        GREATEST(
            i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
            0
        ) AS Outstanding_Amount,

        DATEDIFF(
            r.Report_Date,
            i.Due_Date
        ) AS Days_Past_Due

    FROM invoice_data i

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    CROSS JOIN Reference_Date r

    WHERE i.Invoice_Amount > COALESCE(p.Paid_Amount, 0)
)

SELECT
    COUNT(*) AS Outstanding_Invoices,

    ROUND(
        SUM(Outstanding_Amount),
        2
    ) AS Total_Outstanding,

    ROUND(
        SUM(
            CASE
                WHEN Days_Past_Due > 0
                THEN Outstanding_Amount
                ELSE 0
            END
        ),
        2
    ) AS Total_Overdue,

    ROUND(
        SUM(
            CASE
                WHEN Days_Past_Due > 90
                THEN Outstanding_Amount
                ELSE 0
            END
        ),
        2
    ) AS Money_At_Risk,

    ROUND(
        SUM(
            CASE
                WHEN Days_Past_Due > 90
                THEN Outstanding_Amount
                ELSE 0
            END
        )
        / NULLIF(SUM(Outstanding_Amount), 0)
        * 100,
        2
    ) AS Risk_Percentage

FROM Receivable_Data;


-- ============================================================
-- RESULT 3: TOP 20 OVERDUE CUSTOMERS
-- ============================================================

WITH Reference_Date AS (
    SELECT GREATEST(
        COALESCE((SELECT MAX(Sales_Date)
                  FROM sales_transactions), '1900-01-01'),
        COALESCE((SELECT MAX(Invoice_Date)
                  FROM invoice_data), '1900-01-01'),
        COALESCE((SELECT MAX(Payment_Date)
                  FROM payment_data), '1900-01-01')
    ) AS Report_Date
),

Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
)

SELECT
    o.Customer_ID,

    COALESCE(
        c.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    COUNT(DISTINCT i.Invoice_ID)
        AS Overdue_Invoice_Count,

    ROUND(
        SUM(
            GREATEST(
                i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                0
            )
        ),
        2
    ) AS Overdue_Amount,

    MAX(
        DATEDIFF(
            r.Report_Date,
            i.Due_Date
        )
    ) AS Maximum_Days_Overdue

FROM invoice_data i

INNER JOIN order_transactions o
    ON i.Order_ID = o.Order_ID

LEFT JOIN customer_master c
    ON o.Customer_ID = c.Customer_ID

LEFT JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID

CROSS JOIN Reference_Date r

WHERE i.Due_Date < r.Report_Date

  AND i.Invoice_Amount >
      COALESCE(p.Paid_Amount, 0)

GROUP BY
    o.Customer_ID,
    c.Customer_Name

ORDER BY
    Overdue_Amount DESC

LIMIT 20;


-- ============================================================
-- RESULT 4: CUSTOMERS EXCEEDING CREDIT LIMIT
-- ============================================================

WITH Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
),

Customer_Outstanding AS (
    SELECT
        o.Customer_ID,

        SUM(
            GREATEST(
                i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                0
            )
        ) AS Outstanding_Amount

    FROM invoice_data i

    INNER JOIN order_transactions o
        ON i.Order_ID = o.Order_ID

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    WHERE i.Invoice_Amount >
          COALESCE(p.Paid_Amount, 0)

    GROUP BY o.Customer_ID
)

SELECT
    co.Customer_ID,

    COALESCE(
        c.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    ROUND(
        c.Credit_Limit,
        2
    ) AS Credit_Limit,

    ROUND(
        co.Outstanding_Amount,
        2
    ) AS Outstanding_Amount,

    ROUND(
        co.Outstanding_Amount - c.Credit_Limit,
        2
    ) AS Credit_Limit_Exceeded_By,

    ROUND(
        co.Outstanding_Amount
        / NULLIF(c.Credit_Limit, 0)
        * 100,
        2
    ) AS Credit_Utilization_Percentage

FROM Customer_Outstanding co

INNER JOIN customer_master c
    ON co.Customer_ID = c.Customer_ID

WHERE co.Outstanding_Amount >
      c.Credit_Limit

ORDER BY
    Credit_Limit_Exceeded_By DESC;


-- ============================================================
-- RESULT 5: REPEATED DELAYED PAYMENT CUSTOMERS
-- Corrected CTE name: Delayed_Payments
-- Repeated = at least 2 invoices paid after due date
-- ============================================================

WITH Successful_Payment AS (
    SELECT
        Invoice_ID,

        MAX(Payment_Date)
            AS Last_Payment_Date

    FROM payment_data

    WHERE TRIM(Payment_Status) = 'Success'

    GROUP BY Invoice_ID
),

Delayed_Payments AS (
    SELECT
        o.Customer_ID,
        i.Invoice_ID,

        DATEDIFF(
            p.Last_Payment_Date,
            i.Due_Date
        ) AS Delay_Days

    FROM invoice_data i

    INNER JOIN order_transactions o
        ON i.Order_ID = o.Order_ID

    INNER JOIN Successful_Payment p
        ON i.Invoice_ID = p.Invoice_ID

    WHERE p.Last_Payment_Date >
          i.Due_Date
)

SELECT
    dp.Customer_ID,

    COALESCE(
        c.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    COUNT(DISTINCT dp.Invoice_ID)
        AS Delayed_Invoice_Count,

    ROUND(
        AVG(dp.Delay_Days),
        2
    ) AS Average_Delay_Days,

    MAX(dp.Delay_Days)
        AS Maximum_Delay_Days

FROM Delayed_Payments dp

LEFT JOIN customer_master c
    ON dp.Customer_ID = c.Customer_ID

GROUP BY
    dp.Customer_ID,
    c.Customer_Name

HAVING COUNT(DISTINCT dp.Invoice_ID) >= 2

ORDER BY
    Delayed_Invoice_Count DESC,
    Average_Delay_Days DESC;


-- ============================================================
-- RESULT 6: HIGH OUTSTANDING CUSTOMERS
-- High Outstanding = Above average customer outstanding
-- ============================================================

WITH Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
),

Customer_Outstanding AS (
    SELECT
        o.Customer_ID,

        SUM(
            GREATEST(
                i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                0
            )
        ) AS Outstanding_Amount

    FROM invoice_data i

    INNER JOIN order_transactions o
        ON i.Order_ID = o.Order_ID

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    WHERE i.Invoice_Amount >
          COALESCE(p.Paid_Amount, 0)

    GROUP BY o.Customer_ID
),

Outstanding_Benchmark AS (
    SELECT
        AVG(Outstanding_Amount)
            AS Average_Outstanding

    FROM Customer_Outstanding
)

SELECT
    co.Customer_ID,

    COALESCE(
        c.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    ROUND(
        co.Outstanding_Amount,
        2
    ) AS Outstanding_Amount,

    ROUND(
        ob.Average_Outstanding,
        2
    ) AS Average_Customer_Outstanding

FROM Customer_Outstanding co

LEFT JOIN customer_master c
    ON co.Customer_ID = c.Customer_ID

CROSS JOIN Outstanding_Benchmark ob

WHERE co.Outstanding_Amount >
      ob.Average_Outstanding

ORDER BY
    Outstanding_Amount DESC;


-- ============================================================
-- RESULT 7: CUSTOMER CREDIT RISK DETAIL
-- ============================================================

WITH Reference_Date AS (
    SELECT GREATEST(
        COALESCE((SELECT MAX(Sales_Date)
                  FROM sales_transactions), '1900-01-01'),
        COALESCE((SELECT MAX(Invoice_Date)
                  FROM invoice_data), '1900-01-01'),
        COALESCE((SELECT MAX(Payment_Date)
                  FROM payment_data), '1900-01-01')
    ) AS Report_Date
),

Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
),

Customer_Risk_Base AS (
    SELECT
        o.Customer_ID,

        SUM(
            GREATEST(
                i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                0
            )
        ) AS Outstanding_Amount,

        SUM(
            CASE
                WHEN DATEDIFF(
                    r.Report_Date,
                    i.Due_Date
                ) > 90
                THEN GREATEST(
                    i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                    0
                )
                ELSE 0
            END
        ) AS Over_90_Days_Amount,

        MAX(
            DATEDIFF(
                r.Report_Date,
                i.Due_Date
            )
        ) AS Maximum_Days_Past_Due

    FROM invoice_data i

    INNER JOIN order_transactions o
        ON i.Order_ID = o.Order_ID

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    CROSS JOIN Reference_Date r

    WHERE i.Invoice_Amount >
          COALESCE(p.Paid_Amount, 0)

    GROUP BY o.Customer_ID
)

SELECT
    rb.Customer_ID,

    COALESCE(
        c.Customer_Name,
        'Unmapped Customer'
    ) AS Customer_Name,

    ROUND(
        rb.Outstanding_Amount,
        2
    ) AS Outstanding_Amount,

    ROUND(
        rb.Over_90_Days_Amount,
        2
    ) AS Over_90_Days_Amount,

    rb.Maximum_Days_Past_Due,

    ROUND(
        c.Credit_Limit,
        2
    ) AS Credit_Limit,

    CASE
        WHEN rb.Over_90_Days_Amount > 0
             AND rb.Outstanding_Amount >
                 COALESCE(c.Credit_Limit, 0)
            THEN 'Critical'

        WHEN rb.Over_90_Days_Amount > 0
            THEN 'High Risk'

        WHEN rb.Maximum_Days_Past_Due > 30
            THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS Risk_Category

FROM Customer_Risk_Base rb

LEFT JOIN customer_master c
    ON rb.Customer_ID = c.Customer_ID

ORDER BY
    CASE
        WHEN rb.Over_90_Days_Amount > 0
             AND rb.Outstanding_Amount >
                 COALESCE(c.Credit_Limit, 0)
            THEN 1

        WHEN rb.Over_90_Days_Amount > 0
            THEN 2

        WHEN rb.Maximum_Days_Past_Due > 30
            THEN 3

        ELSE 4
    END,

    rb.Outstanding_Amount DESC;


-- ============================================================
-- RESULT 8: CREDIT RISK CATEGORY SUMMARY
-- ============================================================

WITH Reference_Date AS (
    SELECT GREATEST(
        COALESCE((SELECT MAX(Sales_Date)
                  FROM sales_transactions), '1900-01-01'),
        COALESCE((SELECT MAX(Invoice_Date)
                  FROM invoice_data), '1900-01-01'),
        COALESCE((SELECT MAX(Payment_Date)
                  FROM payment_data), '1900-01-01')
    ) AS Report_Date
),

Payment_Summary AS (
    SELECT
        Invoice_ID,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Paid_Amount

    FROM payment_data
    GROUP BY Invoice_ID
),

Customer_Risk_Base AS (
    SELECT
        o.Customer_ID,

        SUM(
            GREATEST(
                i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                0
            )
        ) AS Outstanding_Amount,

        SUM(
            CASE
                WHEN DATEDIFF(
                    r.Report_Date,
                    i.Due_Date
                ) > 90
                THEN GREATEST(
                    i.Invoice_Amount - COALESCE(p.Paid_Amount, 0),
                    0
                )
                ELSE 0
            END
        ) AS Over_90_Days_Amount,

        MAX(
            DATEDIFF(
                r.Report_Date,
                i.Due_Date
            )
        ) AS Maximum_Days_Past_Due

    FROM invoice_data i

    INNER JOIN order_transactions o
        ON i.Order_ID = o.Order_ID

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID

    CROSS JOIN Reference_Date r

    WHERE i.Invoice_Amount >
          COALESCE(p.Paid_Amount, 0)

    GROUP BY o.Customer_ID
),

Risk_Data AS (
    SELECT
        rb.Customer_ID,
        rb.Outstanding_Amount,
        rb.Over_90_Days_Amount,
        rb.Maximum_Days_Past_Due,
        c.Credit_Limit,

        CASE
            WHEN rb.Over_90_Days_Amount > 0
                 AND rb.Outstanding_Amount >
                     COALESCE(c.Credit_Limit, 0)
                THEN 'Critical'

            WHEN rb.Over_90_Days_Amount > 0
                THEN 'High Risk'

            WHEN rb.Maximum_Days_Past_Due > 30
                THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS Risk_Category

    FROM Customer_Risk_Base rb

    LEFT JOIN customer_master c
        ON rb.Customer_ID = c.Customer_ID
)

SELECT
    Risk_Category,

    COUNT(*) AS Customer_Count,

    ROUND(
        SUM(Outstanding_Amount),
        2
    ) AS Outstanding_Amount,

    ROUND(
        SUM(Over_90_Days_Amount),
        2
    ) AS Money_At_Risk

FROM Risk_Data

GROUP BY Risk_Category

ORDER BY
    CASE Risk_Category
        WHEN 'Critical' THEN 1
        WHEN 'High Risk' THEN 2
        WHEN 'Medium Risk' THEN 3
        ELSE 4
    END;


-- ============================================================
-- PART 9 COMPLETE
-- ============================================================