USE integrated_business;

-- ============================================================
-- PART 3 - RELATIONAL DATABASE
-- FOREIGN KEYS + RELATIONSHIPS + CONSTRAINTS
--
-- IMPORTANT:
-- Original imported tables are NOT modified.
-- New relational tables are created using only valid
-- master/transaction relationships.
-- ============================================================


-- ============================================================
-- 1. DROP RELATIONAL TABLES IF THEY ALREADY EXIST
-- Child tables first -> Parent tables last
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS customer_complaints_rel;
DROP TABLE IF EXISTS attendance_rel;
DROP TABLE IF EXISTS inventory_rel;
DROP TABLE IF EXISTS purchase_rel;
DROP TABLE IF EXISTS payment_rel;
DROP TABLE IF EXISTS invoice_rel;
DROP TABLE IF EXISTS order_transactions_rel;
DROP TABLE IF EXISTS sales_transactions_rel;
DROP TABLE IF EXISTS sales_targets_rel;

DROP TABLE IF EXISTS product_rel;
DROP TABLE IF EXISTS customer_rel;
DROP TABLE IF EXISTS employee_rel;
DROP TABLE IF EXISTS supplier_rel;
DROP TABLE IF EXISTS region_rel;

SET FOREIGN_KEY_CHECKS = 1;


-- ============================================================
-- 2. REGION MASTER
-- Parent table
-- ============================================================

CREATE TABLE region_rel LIKE region_master;

INSERT INTO region_rel
SELECT *
FROM region_master;


-- ============================================================
-- 3. SUPPLIER MASTER
-- Parent table
-- ============================================================

CREATE TABLE supplier_rel LIKE supplier_master;

INSERT INTO supplier_rel
SELECT *
FROM supplier_master;


-- ============================================================
-- 4. EMPLOYEE MASTER
-- Parent table
-- ============================================================

CREATE TABLE employee_rel LIKE employee_master;

INSERT INTO employee_rel
SELECT *
FROM employee_master;


-- ============================================================
-- 5. CUSTOMER MASTER
-- Keep only customers having valid Region_ID
-- ============================================================

CREATE TABLE customer_rel LIKE customer_master;

INSERT INTO customer_rel
SELECT c.*
FROM customer_master c
INNER JOIN region_rel r
    ON c.Region_ID = r.Region_ID;


-- Customer -> Region Foreign Key

ALTER TABLE customer_rel
ADD CONSTRAINT fk_customer_region
FOREIGN KEY (Region_ID)
REFERENCES region_rel(Region_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 6. PRODUCT MASTER
-- Keep only products having valid Supplier_ID
-- ============================================================

CREATE TABLE product_rel LIKE product_master;

INSERT INTO product_rel
SELECT p.*
FROM product_master p
INNER JOIN supplier_rel s
    ON p.Supplier_ID = s.Supplier_ID;


-- Product -> Supplier Foreign Key

ALTER TABLE product_rel
ADD CONSTRAINT fk_product_supplier
FOREIGN KEY (Supplier_ID)
REFERENCES supplier_rel(Supplier_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 7. SALES TARGETS
-- Remove targets for employees not found in Employee Master
-- ============================================================

CREATE TABLE sales_targets_rel LIKE sales_targets;

INSERT INTO sales_targets_rel
SELECT st.*
FROM sales_targets st
INNER JOIN employee_rel e
    ON st.Employee_ID = e.Employee_ID;


ALTER TABLE sales_targets_rel
ADD CONSTRAINT fk_target_employee
FOREIGN KEY (Employee_ID)
REFERENCES employee_rel(Employee_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 8. SALES TRANSACTIONS
--
-- All four relationships must exist:
-- Customer
-- Product
-- Employee
-- Region
-- ============================================================

CREATE TABLE sales_transactions_rel LIKE sales_transactions;

INSERT INTO sales_transactions_rel
SELECT s.*
FROM sales_transactions s

INNER JOIN customer_rel c
    ON s.Customer_ID = c.Customer_ID

INNER JOIN product_rel p
    ON s.Product_ID = p.Product_ID

INNER JOIN employee_rel e
    ON s.Employee_ID = e.Employee_ID

INNER JOIN region_rel r
    ON s.Region_ID = r.Region_ID;


-- Sales -> Customer

ALTER TABLE sales_transactions_rel
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (Customer_ID)
REFERENCES customer_rel(Customer_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- Sales -> Product

ALTER TABLE sales_transactions_rel
ADD CONSTRAINT fk_sales_product
FOREIGN KEY (Product_ID)
REFERENCES product_rel(Product_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- Sales -> Employee

ALTER TABLE sales_transactions_rel
ADD CONSTRAINT fk_sales_employee
FOREIGN KEY (Employee_ID)
REFERENCES employee_rel(Employee_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- Sales -> Region

ALTER TABLE sales_transactions_rel
ADD CONSTRAINT fk_sales_region
FOREIGN KEY (Region_ID)
REFERENCES region_rel(Region_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 9. ORDER TRANSACTIONS
-- Customer + Employee must exist
-- ============================================================

CREATE TABLE order_transactions_rel LIKE order_transactions;

INSERT INTO order_transactions_rel
SELECT o.*
FROM order_transactions o

INNER JOIN customer_rel c
    ON o.Customer_ID = c.Customer_ID

INNER JOIN employee_rel e
    ON o.Employee_ID = e.Employee_ID;


ALTER TABLE order_transactions_rel
ADD CONSTRAINT fk_order_customer
FOREIGN KEY (Customer_ID)
REFERENCES customer_rel(Customer_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


ALTER TABLE order_transactions_rel
ADD CONSTRAINT fk_order_employee
FOREIGN KEY (Employee_ID)
REFERENCES employee_rel(Employee_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 10. INVOICE DATA
--
-- Invoice is valid only when Order_ID exists
-- in the cleaned relational Order table.
-- ============================================================

CREATE TABLE invoice_rel LIKE invoice_data;

INSERT INTO invoice_rel
SELECT i.*
FROM invoice_data i

INNER JOIN order_transactions_rel o
    ON i.Order_ID = o.Order_ID;


ALTER TABLE invoice_rel
ADD CONSTRAINT fk_invoice_order
FOREIGN KEY (Order_ID)
REFERENCES order_transactions_rel(Order_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 11. PAYMENT DATA
--
-- Payment is valid only when Invoice_ID exists
-- in relational Invoice table.
-- ============================================================

CREATE TABLE payment_rel LIKE payment_data;

INSERT INTO payment_rel
SELECT p.*
FROM payment_data p

INNER JOIN invoice_rel i
    ON p.Invoice_ID = i.Invoice_ID;


ALTER TABLE payment_rel
ADD CONSTRAINT fk_payment_invoice
FOREIGN KEY (Invoice_ID)
REFERENCES invoice_rel(Invoice_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 12. PURCHASE DATA
--
-- Product + Supplier must both exist.
-- ============================================================

CREATE TABLE purchase_rel LIKE purchase_data;

INSERT INTO purchase_rel
SELECT pu.*
FROM purchase_data pu

INNER JOIN product_rel p
    ON pu.Product_ID = p.Product_ID

INNER JOIN supplier_rel s
    ON pu.Supplier_ID = s.Supplier_ID;


ALTER TABLE purchase_rel
ADD CONSTRAINT fk_purchase_product
FOREIGN KEY (Product_ID)
REFERENCES product_rel(Product_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


ALTER TABLE purchase_rel
ADD CONSTRAINT fk_purchase_supplier
FOREIGN KEY (Supplier_ID)
REFERENCES supplier_rel(Supplier_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 13. INVENTORY DATA
-- Product must exist
-- ============================================================

CREATE TABLE inventory_rel LIKE inventory_data;

INSERT INTO inventory_rel
SELECT i.*
FROM inventory_data i

INNER JOIN product_rel p
    ON i.Product_ID = p.Product_ID;


ALTER TABLE inventory_rel
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (Product_ID)
REFERENCES product_rel(Product_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 14. ATTENDANCE DATA
-- Employee must exist
-- ============================================================

CREATE TABLE attendance_rel LIKE attendance_data;

INSERT INTO attendance_rel
SELECT a.*
FROM attendance_data a

INNER JOIN employee_rel e
    ON a.Employee_ID = e.Employee_ID;


ALTER TABLE attendance_rel
ADD CONSTRAINT fk_attendance_employee
FOREIGN KEY (Employee_ID)
REFERENCES employee_rel(Employee_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 15. CUSTOMER COMPLAINTS
-- Customer must exist
-- ============================================================

CREATE TABLE customer_complaints_rel LIKE customer_complaints;

INSERT INTO customer_complaints_rel
SELECT cc.*
FROM customer_complaints cc

INNER JOIN customer_rel c
    ON cc.Customer_ID = c.Customer_ID;


ALTER TABLE customer_complaints_rel
ADD CONSTRAINT fk_complaint_customer
FOREIGN KEY (Customer_ID)
REFERENCES customer_rel(Customer_ID)
ON UPDATE CASCADE
ON DELETE RESTRICT;


-- ============================================================
-- 16. ADDITIONAL BUSINESS CONSTRAINTS
--
-- These protect the relational Sales table from
-- logically invalid analytical values.
-- ============================================================

ALTER TABLE sales_transactions_rel
ADD CONSTRAINT chk_sales_quantity
CHECK (Quantity >= 0);


ALTER TABLE sales_transactions_rel
ADD CONSTRAINT chk_sales_value
CHECK (Sales_Value >= 0);


ALTER TABLE sales_transactions_rel
ADD CONSTRAINT chk_discount_pct
CHECK (
    Discount_Pct >= 0
    AND Discount_Pct <= 1
);


-- ============================================================
-- 17. VERIFY ORIGINAL VS RELATIONAL ROW COUNTS
-- ============================================================

SELECT
    'Sales' AS Dataset,
    (SELECT COUNT(*) FROM sales_transactions) AS Original_Rows,
    (SELECT COUNT(*) FROM sales_transactions_rel) AS Relational_Rows,
    (
        (SELECT COUNT(*) FROM sales_transactions)
        -
        (SELECT COUNT(*) FROM sales_transactions_rel)
    ) AS Excluded_Rows

UNION ALL

SELECT
    'Sales Targets',
    (SELECT COUNT(*) FROM sales_targets),
    (SELECT COUNT(*) FROM sales_targets_rel),
    (
        (SELECT COUNT(*) FROM sales_targets)
        -
        (SELECT COUNT(*) FROM sales_targets_rel)
    )

UNION ALL

SELECT
    'Orders',
    (SELECT COUNT(*) FROM order_transactions),
    (SELECT COUNT(*) FROM order_transactions_rel),
    (
        (SELECT COUNT(*) FROM order_transactions)
        -
        (SELECT COUNT(*) FROM order_transactions_rel)
    )

UNION ALL

SELECT
    'Invoices',
    (SELECT COUNT(*) FROM invoice_data),
    (SELECT COUNT(*) FROM invoice_rel),
    (
        (SELECT COUNT(*) FROM invoice_data)
        -
        (SELECT COUNT(*) FROM invoice_rel)
    )

UNION ALL

SELECT
    'Payments',
    (SELECT COUNT(*) FROM payment_data),
    (SELECT COUNT(*) FROM payment_rel),
    (
        (SELECT COUNT(*) FROM payment_data)
        -
        (SELECT COUNT(*) FROM payment_rel)
    )

UNION ALL

SELECT
    'Purchases',
    (SELECT COUNT(*) FROM purchase_data),
    (SELECT COUNT(*) FROM purchase_rel),
    (
        (SELECT COUNT(*) FROM purchase_data)
        -
        (SELECT COUNT(*) FROM purchase_rel)
    )

UNION ALL

SELECT
    'Inventory',
    (SELECT COUNT(*) FROM inventory_data),
    (SELECT COUNT(*) FROM inventory_rel),
    (
        (SELECT COUNT(*) FROM inventory_data)
        -
        (SELECT COUNT(*) FROM inventory_rel)
    )

UNION ALL

SELECT
    'Attendance',
    (SELECT COUNT(*) FROM attendance_data),
    (SELECT COUNT(*) FROM attendance_rel),
    (
        (SELECT COUNT(*) FROM attendance_data)
        -
        (SELECT COUNT(*) FROM attendance_rel)
    )

UNION ALL

SELECT
    'Customer Complaints',
    (SELECT COUNT(*) FROM customer_complaints),
    (SELECT COUNT(*) FROM customer_complaints_rel),
    (
        (SELECT COUNT(*) FROM customer_complaints)
        -
        (SELECT COUNT(*) FROM customer_complaints_rel)
    );


-- ============================================================
-- 18. VERIFY FOREIGN KEYS
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME

FROM information_schema.KEY_COLUMN_USAGE

WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME IS NOT NULL

ORDER BY
    TABLE_NAME,
    COLUMN_NAME;


-- ============================================================
-- 19. VERIFY CHECK CONSTRAINTS
-- ============================================================

SELECT
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE

FROM information_schema.TABLE_CONSTRAINTS tc

WHERE tc.CONSTRAINT_SCHEMA = DATABASE()
  AND tc.TABLE_NAME LIKE '%_rel'

ORDER BY
    tc.TABLE_NAME,
    tc.CONSTRAINT_TYPE;


-- ============================================================
-- 20. VERIFY PRIMARY KEYS
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME

FROM information_schema.KEY_COLUMN_USAGE

WHERE TABLE_SCHEMA = DATABASE()
  AND CONSTRAINT_NAME = 'PRIMARY'
  AND TABLE_NAME LIKE '%_rel'

ORDER BY TABLE_NAME;


-- ============================================================
-- 21. VERIFY INDEXES
-- ============================================================

SHOW INDEX FROM sales_transactions_rel;

SHOW INDEX FROM order_transactions_rel;

SHOW INDEX FROM invoice_rel;

SHOW INDEX FROM payment_rel;


-- ============================================================
-- 22. FINAL REFERENTIAL INTEGRITY TEST
--
-- Every result below should return 0.
-- ============================================================


-- Sales -> Customer

SELECT
    'Sales -> Customer' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM sales_transactions_rel s

LEFT JOIN customer_rel c
    ON s.Customer_ID = c.Customer_ID

WHERE c.Customer_ID IS NULL;


-- Sales -> Product

SELECT
    'Sales -> Product' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM sales_transactions_rel s

LEFT JOIN product_rel p
    ON s.Product_ID = p.Product_ID

WHERE p.Product_ID IS NULL;


-- Sales -> Employee

SELECT
    'Sales -> Employee' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM sales_transactions_rel s

LEFT JOIN employee_rel e
    ON s.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL;


-- Sales -> Region

SELECT
    'Sales -> Region' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM sales_transactions_rel s

LEFT JOIN region_rel r
    ON s.Region_ID = r.Region_ID

WHERE r.Region_ID IS NULL;


-- Orders -> Customer

SELECT
    'Orders -> Customer' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM order_transactions_rel o

LEFT JOIN customer_rel c
    ON o.Customer_ID = c.Customer_ID

WHERE c.Customer_ID IS NULL;


-- Orders -> Employee

SELECT
    'Orders -> Employee' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM order_transactions_rel o

LEFT JOIN employee_rel e
    ON o.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL;


-- Invoice -> Order

SELECT
    'Invoice -> Order' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM invoice_rel i

LEFT JOIN order_transactions_rel o
    ON i.Order_ID = o.Order_ID

WHERE o.Order_ID IS NULL;


-- Payment -> Invoice

SELECT
    'Payment -> Invoice' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM payment_rel p

LEFT JOIN invoice_rel i
    ON p.Invoice_ID = i.Invoice_ID

WHERE i.Invoice_ID IS NULL;


-- Inventory -> Product

SELECT
    'Inventory -> Product' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM inventory_rel i

LEFT JOIN product_rel p
    ON i.Product_ID = p.Product_ID

WHERE p.Product_ID IS NULL;


-- Attendance -> Employee

SELECT
    'Attendance -> Employee' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM attendance_rel a

LEFT JOIN employee_rel e
    ON a.Employee_ID = e.Employee_ID

WHERE e.Employee_ID IS NULL;


-- Complaints -> Customer

SELECT
    'Complaints -> Customer' AS Relationship,
    COUNT(*) AS Orphan_Records

FROM customer_complaints_rel cc

LEFT JOIN customer_rel c
    ON cc.Customer_ID = c.Customer_ID

WHERE c.Customer_ID IS NULL;


-- ============================================================
-- PART 3 FINAL DATABASE DESIGN COMPLETE
-- ============================================================

/*

DATABASE DESIGN:

Primary Keys             - Implemented / inherited
Foreign Keys             - Implemented
Relationships            - Implemented
Constraints              - Implemented
Indexes                  - Implemented / inherited
Referential Integrity    - Validated

ORIGINAL TABLES:
Preserved for audit / exception analysis.

RELATIONAL TABLES:
Contain only records satisfying master-detail relationships.

*/