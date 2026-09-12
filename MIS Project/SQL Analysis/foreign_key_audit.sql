USE integrated_business;

-- ============================================================
-- PART 3 - FOREIGN KEY / RELATIONSHIP INTEGRITY AUDIT
-- ============================================================

DROP PROCEDURE IF EXISTS Check_FK;

DELIMITER $$

CREATE PROCEDURE Check_FK(
    IN p_relation VARCHAR(150),
    IN p_child_table VARCHAR(100),
    IN p_child_column VARCHAR(100),
    IN p_parent_table VARCHAR(100),
    IN p_parent_column VARCHAR(100)
)
BEGIN

    DECLARE child_exists INT DEFAULT 0;
    DECLARE parent_exists INT DEFAULT 0;

    SELECT COUNT(*)
    INTO child_exists
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = p_child_table
      AND column_name = p_child_column;

    SELECT COUNT(*)
    INTO parent_exists
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = p_parent_table
      AND column_name = p_parent_column;

    IF child_exists = 1 AND parent_exists = 1 THEN

        SET @sql_text = CONCAT(
            'SELECT ''', p_relation, ''' AS Relationship, ',
            '''', p_child_table, ''' AS Child_Table, ',
            '''', p_child_column, ''' AS Child_Column, ',
            '''', p_parent_table, ''' AS Parent_Table, ',
            'COUNT(*) AS Orphan_Records ',
            'FROM `', p_child_table, '` c ',
            'LEFT JOIN `', p_parent_table, '` p ',
            'ON c.`', p_child_column, '` = p.`', p_parent_column, '` ',
            'WHERE c.`', p_child_column, '` IS NOT NULL ',
            'AND p.`', p_parent_column, '` IS NULL'
        );

        PREPARE stmt FROM @sql_text;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    ELSE

        SELECT
            p_relation AS Relationship,
            p_child_table AS Child_Table,
            p_child_column AS Child_Column,
            p_parent_table AS Parent_Table,
            'SKIPPED - COLUMN NOT FOUND' AS Audit_Status;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- MASTER / TRANSACTION RELATIONSHIP CHECKS
-- ============================================================

-- 1. Customer -> Region
CALL Check_FK(
    'Customer to Region',
    'customer_master',
    'Region_ID',
    'region_master',
    'Region_ID'
);


-- 2. Product -> Supplier
CALL Check_FK(
    'Product to Supplier',
    'product_master',
    'Supplier_ID',
    'supplier_master',
    'Supplier_ID'
);


-- 3. Sales -> Customer
CALL Check_FK(
    'Sales to Customer',
    'sales_transactions',
    'Customer_ID',
    'customer_master',
    'Customer_ID'
);


-- 4. Sales -> Product
CALL Check_FK(
    'Sales to Product',
    'sales_transactions',
    'Product_ID',
    'product_master',
    'Product_ID'
);


-- 5. Sales -> Employee
CALL Check_FK(
    'Sales to Employee',
    'sales_transactions',
    'Employee_ID',
    'employee_master',
    'Employee_ID'
);


-- 6. Sales -> Region
CALL Check_FK(
    'Sales to Region',
    'sales_transactions',
    'Region_ID',
    'region_master',
    'Region_ID'
);


-- 7. Sales Targets -> Employee
CALL Check_FK(
    'Sales Target to Employee',
    'sales_targets',
    'Employee_ID',
    'employee_master',
    'Employee_ID'
);


-- 8. Orders -> Customer
CALL Check_FK(
    'Order to Customer',
    'order_transactions',
    'Customer_ID',
    'customer_master',
    'Customer_ID'
);


-- 9. Orders -> Employee
CALL Check_FK(
    'Order to Employee',
    'order_transactions',
    'Employee_ID',
    'employee_master',
    'Employee_ID'
);


-- 10. Invoice -> Order
CALL Check_FK(
    'Invoice to Order',
    'invoice_data',
    'Order_ID',
    'order_transactions',
    'Order_ID'
);


-- 11. Payment -> Invoice
CALL Check_FK(
    'Payment to Invoice',
    'payment_data',
    'Invoice_ID',
    'invoice_data',
    'Invoice_ID'
);


-- 12. Purchase -> Product
CALL Check_FK(
    'Purchase to Product',
    'purchase_data',
    'Product_ID',
    'product_master',
    'Product_ID'
);


-- 13. Purchase -> Supplier
CALL Check_FK(
    'Purchase to Supplier',
    'purchase_data',
    'Supplier_ID',
    'supplier_master',
    'Supplier_ID'
);


-- 14. Inventory -> Product
CALL Check_FK(
    'Inventory to Product',
    'inventory_data',
    'Product_ID',
    'product_master',
    'Product_ID'
);


-- 15. Attendance -> Employee
CALL Check_FK(
    'Attendance to Employee',
    'attendance_data',
    'Employee_ID',
    'employee_master',
    'Employee_ID'
);


-- 16. Complaints -> Customer
CALL Check_FK(
    'Complaint to Customer',
    'customer_complaints',
    'Customer_ID',
    'customer_master',
    'Customer_ID'
);


-- ============================================================
-- CHECK EXISTING FOREIGN KEYS
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
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ============================================================
-- SHOW PRIMARY KEYS
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME;


-- ============================================================
-- CLEAN UP TEMPORARY PROCEDURE
-- ============================================================

DROP PROCEDURE IF EXISTS Check_FK;