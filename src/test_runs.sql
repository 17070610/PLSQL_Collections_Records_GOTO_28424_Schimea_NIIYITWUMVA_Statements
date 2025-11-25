SET SERVEROUTPUT ON SIZE 1000000
SET ECHO OFF

PROMPT === Initial stock ===
EXEC pkg_bulk_order.show_products;

PROMPT === Running test order (anonymous block) ===
DECLARE
  v_order t_order_table := t_order_table();
BEGIN
  v_order.EXTEND(4);
  v_order(1) := t_order_item(1, 5);
  v_order(2) := t_order_item(2, 12);
  v_order(3) := t_order_item(3, 3);
  v_order(4) := t_order_item(5, 5); 

  pkg_bulk_order.process_bulk_order(v_order);
END;
/

PROMPT === Stock after processing ===
EXEC pkg_bulk_order.show_products;

PROMPT === Backorders table ===
SET PAGESIZE 500
COLUMN backorder_id FORMAT 99999
SELECT backorder_id, product_id, requested_qty, created_at
FROM order_backorders
ORDER BY backorder_id;
