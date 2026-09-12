USE integrated_business;

-- ============================================================
-- PART 8 - FINANCE RECONCILIATION & COLLECTION ANALYSIS
-- ============================================================


-- ============================================================
-- 1. FINANCE KPI SUMMARY
-- Billing, Successful Collections, Outstanding, Collection %
-- Payment is capped at invoice amount for outstanding calculation
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
        ) AS Successful_Payment
    FROM payment_data
    GROUP BY Invoice_ID
),

Finance AS (
    SELECT
        i.Invoice_ID,
        i.Invoice_Amount,
        COALESCE(p.Successful_Payment,0) AS Successful_Payment,

        LEAST(
            COALESCE(p.Successful_Payment,0),
            i.Invoice_Amount
        ) AS Applied_Collection,

        GREATEST(
            i.Invoice_Amount - COALESCE(p.Successful_Payment,0),
            0
        ) AS Outstanding
    FROM invoice_data i
    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID
)

SELECT
    COUNT(*) AS Total_Invoices,

    ROUND(SUM(Invoice_Amount),2)
        AS Total_Billing,

    ROUND(SUM(Applied_Collection),2)
        AS Total_Collection,

    ROUND(SUM(Outstanding),2)
        AS Total_Outstanding,

    ROUND(
        SUM(Applied_Collection)
        / NULLIF(SUM(Invoice_Amount),0) * 100,
        2
    ) AS Collection_Percentage

FROM Finance;


-- ============================================================
-- 2. SALES WITHOUT ORDERS
-- Sales Order_ID not found in order master
-- ============================================================

SELECT
    COUNT(*) AS Sales_Without_Orders,
    ROUND(SUM(s.Sales_Value),2) AS Sales_Value_At_Risk

FROM sales_transactions s

LEFT JOIN order_transactions o
    ON s.Order_ID = o.Order_ID

WHERE o.Order_ID IS NULL;


-- ============================================================
-- 3. ORDERS WITHOUT SALES
-- ============================================================

SELECT
    COUNT(*) AS Orders_Without_Sales

FROM order_transactions o

LEFT JOIN sales_transactions s
    ON o.Order_ID = s.Order_ID

WHERE s.Order_ID IS NULL;


-- ============================================================
-- 4. ORDERS WITHOUT INVOICES
-- ============================================================

SELECT
    COUNT(*) AS Orders_Without_Invoices

FROM order_transactions o

LEFT JOIN invoice_data i
    ON o.Order_ID = i.Order_ID

WHERE i.Invoice_ID IS NULL;


-- ============================================================
-- 5. INVOICES WITHOUT VALID ORDERS
-- ============================================================

SELECT
    COUNT(*) AS Invoices_Without_Orders,
    ROUND(SUM(i.Invoice_Amount),2)
        AS Invoice_Value_Without_Order

FROM invoice_data i

LEFT JOIN order_transactions o
    ON i.Order_ID = o.Order_ID

WHERE o.Order_ID IS NULL;


-- ============================================================
-- 6. INVOICES WITHOUT SUCCESSFUL PAYMENTS
-- Includes invoices with no payment or only failed payments
-- ============================================================

WITH Successful_Payments AS (
    SELECT DISTINCT Invoice_ID
    FROM payment_data
    WHERE TRIM(Payment_Status) = 'Success'
)

SELECT
    COUNT(*) AS Invoices_Without_Successful_Payment,
    ROUND(SUM(i.Invoice_Amount),2)
        AS Invoice_Value_Without_Successful_Payment

FROM invoice_data i

LEFT JOIN Successful_Payments p
    ON i.Invoice_ID = p.Invoice_ID

WHERE p.Invoice_ID IS NULL;


-- ============================================================
-- 7. PAYMENTS WITHOUT VALID INVOICES
-- ============================================================

SELECT
    COUNT(*) AS Payments_Without_Invoices,

    ROUND(
        SUM(p.Payment_Amount),
        2
    ) AS Invalid_Payment_Value

FROM payment_data p

LEFT JOIN invoice_data i
    ON p.Invoice_ID = i.Invoice_ID

WHERE i.Invoice_ID IS NULL;


-- ============================================================
-- 8. DUPLICATE INVOICE CHECK
-- Invoice_ID is PK, so exact duplicate IDs should be zero.
-- Business duplicate = multiple invoices for same Order_ID
-- ============================================================

SELECT
    Order_ID,
    COUNT(*) AS Invoice_Count,
    ROUND(SUM(Invoice_Amount),2)
        AS Total_Invoice_Value

FROM invoice_data

GROUP BY Order_ID

HAVING COUNT(*) > 1

ORDER BY Invoice_Count DESC,
         Total_Invoice_Value DESC;


-- ============================================================
-- 9. DUPLICATE PAYMENT CHECK
-- Business duplicate based on Reference_No
-- ============================================================

SELECT
    Reference_No,

    COUNT(*) AS Duplicate_Count,

    ROUND(
        SUM(Payment_Amount),
        2
    ) AS Payment_Value

FROM payment_data

WHERE Reference_No IS NOT NULL
  AND TRIM(Reference_No) <> ''

GROUP BY Reference_No

HAVING COUNT(*) > 1

ORDER BY Duplicate_Count DESC;


-- ============================================================
-- 10. INVOICE VS PAYMENT RECONCILIATION
-- Matched / Underpaid / Overpaid / Unpaid
-- Successful payments only
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
        ) AS Paid_Amount,

        MAX(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Date
            END
        ) AS Last_Payment_Date

    FROM payment_data

    GROUP BY Invoice_ID
),

Reconciliation AS (
    SELECT
        i.Invoice_ID,
        i.Order_ID,
        i.Invoice_Date,
        i.Due_Date,
        i.Invoice_Amount,

        COALESCE(p.Paid_Amount,0)
            AS Paid_Amount,

        i.Invoice_Amount
        - COALESCE(p.Paid_Amount,0)
            AS Balance,

        p.Last_Payment_Date,

        CASE
            WHEN COALESCE(p.Paid_Amount,0) = 0
                THEN 'Unpaid'

            WHEN COALESCE(p.Paid_Amount,0)
                 < i.Invoice_Amount
                THEN 'Underpaid'

            WHEN COALESCE(p.Paid_Amount,0)
                 > i.Invoice_Amount
                THEN 'Overpaid'

            ELSE 'Matched'
        END AS Reconciliation_Status

    FROM invoice_data i

    LEFT JOIN Payment_Summary p
        ON i.Invoice_ID = p.Invoice_ID
)

SELECT
    Reconciliation_Status,

    COUNT(*) AS Invoice_Count,

    ROUND(
        SUM(Invoice_Amount),
        2
    ) AS Invoice_Value,

    ROUND(
        SUM(Paid_Amount),
        2
    ) AS Payment_Value,

    ROUND(
        SUM(Balance),
        2
    ) AS Balance

FROM Reconciliation

GROUP BY Reconciliation_Status

ORDER BY Invoice_Count DESC;


-- ============================================================
-- 11. INCORRECT PAYMENT AMOUNTS - DETAIL
-- Underpaid and Overpaid invoices
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
)

SELECT
    i.Invoice_ID,
    i.Order_ID,

    ROUND(i.Invoice_Amount,2)
        AS Invoice_Amount,

    ROUND(
        COALESCE(p.Paid_Amount,0),
        2
    ) AS Paid_Amount,

    ROUND(
        COALESCE(p.Paid_Amount,0)
        - i.Invoice_Amount,
        2
    ) AS Payment_Difference,

    CASE
        WHEN COALESCE(p.Paid_Amount,0) = 0
            THEN 'Unpaid'

        WHEN COALESCE(p.Paid_Amount,0)
             < i.Invoice_Amount
            THEN 'Underpaid'

        WHEN COALESCE(p.Paid_Amount,0)
             > i.Invoice_Amount
            THEN 'Overpaid'

        ELSE 'Matched'
    END AS Payment_Status_Check

FROM invoice_data i

LEFT JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID

WHERE COALESCE(p.Paid_Amount,0)
      <> i.Invoice_Amount

ORDER BY ABS(
    COALESCE(p.Paid_Amount,0)
    - i.Invoice_Amount
) DESC;


-- ============================================================
-- 12. OUTSTANDING INVOICE DETAIL
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
)

SELECT
    i.Invoice_ID,
    i.Order_ID,
    i.Invoice_Date,
    i.Due_Date,

    ROUND(i.Invoice_Amount,2)
        AS Invoice_Amount,

    ROUND(
        COALESCE(p.Paid_Amount,0),
        2
    ) AS Paid_Amount,

    ROUND(
        GREATEST(
            i.Invoice_Amount
            - COALESCE(p.Paid_Amount,0),
            0
        ),
        2
    ) AS Outstanding_Amount

FROM invoice_data i

LEFT JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID

WHERE i.Invoice_Amount
      > COALESCE(p.Paid_Amount,0)

ORDER BY Outstanding_Amount DESC;


-- ============================================================
-- 13. OVERDUE OUTSTANDING
-- Dataset reference date used instead of today's date
-- ============================================================

WITH Reference_Date AS (
    SELECT
        GREATEST(
            COALESCE((SELECT MAX(Sales_Date)
                      FROM sales_transactions),'1900-01-01'),

            COALESCE((SELECT MAX(Invoice_Date)
                      FROM invoice_data),'1900-01-01'),

            COALESCE((SELECT MAX(Payment_Date)
                      FROM payment_data),'1900-01-01')
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
    COUNT(*) AS Overdue_Invoices,

    ROUND(
        SUM(
            GREATEST(
                i.Invoice_Amount
                - COALESCE(p.Paid_Amount,0),
                0
            )
        ),
        2
    ) AS Overdue_Amount

FROM invoice_data i

LEFT JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID

CROSS JOIN Reference_Date r

WHERE i.Due_Date < r.Report_Date

  AND i.Invoice_Amount
      > COALESCE(p.Paid_Amount,0);


-- ============================================================
-- 14. COLLECTION PERFORMANCE
-- Average Collection Days for invoices receiving success payment
-- ============================================================

WITH Payment_Summary AS (
    SELECT
        Invoice_ID,

        MAX(Payment_Date)
            AS Last_Payment_Date,

        SUM(Payment_Amount)
            AS Paid_Amount

    FROM payment_data

    WHERE TRIM(Payment_Status) = 'Success'

    GROUP BY Invoice_ID
)

SELECT
    COUNT(*) AS Invoices_With_Collections,

    ROUND(
        AVG(
            DATEDIFF(
                p.Last_Payment_Date,
                i.Invoice_Date
            )
        ),
        2
    ) AS Average_Collection_Days,

    ROUND(
        AVG(
            DATEDIFF(
                p.Last_Payment_Date,
                i.Due_Date
            )
        ),
        2
    ) AS Average_Days_From_Due_Date

FROM invoice_data i

INNER JOIN Payment_Summary p
    ON i.Invoice_ID = p.Invoice_ID;


-- ============================================================
-- 15. PAYMENT STATUS SUMMARY
-- ============================================================

SELECT
    TRIM(Payment_Status)
        AS Payment_Status,

    COUNT(*) AS Payment_Count,

    ROUND(
        SUM(Payment_Amount),
        2
    ) AS Payment_Value,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(),
        2
    ) AS Payment_Percentage

FROM payment_data

GROUP BY TRIM(Payment_Status)

ORDER BY Payment_Count DESC;


-- ============================================================
-- 16. INVOICE STATUS SUMMARY
-- ============================================================

SELECT
    TRIM(Invoice_Status)
        AS Invoice_Status,

    COUNT(*) AS Invoice_Count,

    ROUND(
        SUM(Invoice_Amount),
        2
    ) AS Invoice_Value,

    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER(),
        2
    ) AS Invoice_Percentage

FROM invoice_data

GROUP BY TRIM(Invoice_Status)

ORDER BY Invoice_Count DESC;


-- ============================================================
-- 17. MONTHLY BILLING VS COLLECTION
-- ============================================================

WITH Monthly_Billing AS (
    SELECT
        DATE_FORMAT(Invoice_Date,'%Y-%m')
            AS Month,

        SUM(Invoice_Amount)
            AS Billing
    FROM invoice_data
    GROUP BY DATE_FORMAT(Invoice_Date,'%Y-%m')
),

Monthly_Collection AS (
    SELECT
        DATE_FORMAT(Payment_Date,'%Y-%m')
            AS Month,

        SUM(
            CASE
                WHEN TRIM(Payment_Status) = 'Success'
                THEN Payment_Amount
                ELSE 0
            END
        ) AS Collection

    FROM payment_data

    GROUP BY DATE_FORMAT(Payment_Date,'%Y-%m')
),

Months AS (
    SELECT Month FROM Monthly_Billing

    UNION

    SELECT Month FROM Monthly_Collection
)

SELECT
    m.Month,

    ROUND(
        COALESCE(b.Billing,0),
        2
    ) AS Billing,

    ROUND(
        COALESCE(c.Collection,0),
        2
    ) AS Collection,

    ROUND(
        COALESCE(c.Collection,0)
        - COALESCE(b.Billing,0),
        2
    ) AS Monthly_Cash_Gap,

    ROUND(
        COALESCE(c.Collection,0)
        /
        NULLIF(COALESCE(b.Billing,0),0)
        * 100,
        2
    ) AS Collection_To_Billing_Percentage

FROM Months m

LEFT JOIN Monthly_Billing b
    ON m.Month = b.Month

LEFT JOIN Monthly_Collection c
    ON m.Month = c.Month

ORDER BY m.Month;


-- ============================================================
-- 18. FINANCE RECONCILIATION EXCEPTION SUMMARY
-- ============================================================

SELECT
    'Sales Without Orders'
        AS Exception_Type,

    COUNT(*) AS Exception_Count

FROM sales_transactions s

LEFT JOIN order_transactions o
    ON s.Order_ID = o.Order_ID

WHERE o.Order_ID IS NULL

UNION ALL

SELECT
    'Orders Without Invoices',
    COUNT(*)

FROM order_transactions o

LEFT JOIN invoice_data i
    ON o.Order_ID = i.Order_ID

WHERE i.Invoice_ID IS NULL

UNION ALL

SELECT
    'Invoices Without Orders',
    COUNT(*)

FROM invoice_data i

LEFT JOIN order_transactions o
    ON i.Order_ID = o.Order_ID

WHERE o.Order_ID IS NULL

UNION ALL

SELECT
    'Payments Without Invoices',
    COUNT(*)

FROM payment_data p

LEFT JOIN invoice_data i
    ON p.Invoice_ID = i.Invoice_ID

WHERE i.Invoice_ID IS NULL;


-- ============================================================
-- PART 8 COMPLETE
-- ============================================================