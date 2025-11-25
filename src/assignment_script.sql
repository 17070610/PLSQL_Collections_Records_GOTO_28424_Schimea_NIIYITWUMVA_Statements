SET SERVEROUTPUT ON SIZE UNLIMITED

-- Package specification
CREATE OR REPLACE PACKAGE pkg_bulk_order IS
  PROCEDURE process_bulk_order(p_order_items IN t_order_table);
  PROCEDURE show_products;
END pkg_bulk_order;
/
-- End package spec

-- Package body (corrected: labels only inside procedure)
CREATE OR REPLACE PACKAGE BODY pkg_bulk_order IS

  -- Associative array (index-by) mapping product_code -> unit_price
  TYPE t_price_map IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  g_price_map t_price_map;

  -- User-defined PL/SQL record for item processing
  TYPE t_item_rec IS RECORD (
    product_id NUMBER,
    qty        NUMBER
  );

  -- Helper: add to fixed-size recent-products VARRAY
  PROCEDURE add_recent_product(p_recent IN OUT NOCOPY t_recent_products, p_code VARCHAR2) IS
  BEGIN
    IF p_recent IS NULL THEN
      p_recent := t_recent_products();
    END IF;

    IF p_recent.COUNT < 5 THEN
      p_recent.EXTEND;
      p_recent(p_recent.COUNT) := p_code;
    ELSE
      -- rotate left
      FOR i IN 1 .. p_recent.COUNT - 1 LOOP
        p_recent(i) := p_recent(i + 1);
      END LOOP;
      p_recent(p_recent.COUNT) := p_code;
    END IF;
  END add_recent_product;

  -- Load prices into associative array for quick lookup
  PROCEDURE load_price_map IS
  BEGIN
    FOR r IN (SELECT product_code, unit_price FROM products) LOOP
      g_price_map(r.product_code) := r.unit_price;
    END LOOP;
  END load_price_map;

  -- Main procedure that processes a nested-table order
  PROCEDURE process_bulk_order(p_order_items IN t_order_table) IS

    CURSOR c_prod(p_pid NUMBER) IS
      SELECT * FROM products WHERE product_id = p_pid FOR UPDATE;

    v_prod_rec   c_prod%ROWTYPE;         -- cursor-based record
    v_item_rec   t_item_rec;             -- user-defined record
    v_recent     t_recent_products := NULL;  -- VARRAY
    v_price      NUMBER;
    v_total_cost NUMBER := 0;
    v_backorders NUMBER := 0;

    v_processed  t_order_table := t_order_table(); -- nested-table var

  BEGIN
    IF p_order_items IS NULL OR p_order_items.COUNT = 0 THEN
      DBMS_OUTPUT.PUT_LINE('No order items provided.');
      RETURN;
    END IF;

    load_price_map();

    FOR i IN 1 .. p_order_items.COUNT LOOP
      v_item_rec.product_id := p_order_items(i).product_id;
      v_item_rec.qty := p_order_items(i).qty;

      OPEN c_prod(v_item_rec.product_id);
      FETCH c_prod INTO v_prod_rec;

      IF c_prod%NOTFOUND THEN
        CLOSE c_prod;
        DBMS_OUTPUT.PUT_LINE('Product not found: ' || v_item_rec.product_id);
        CONTINUE;
      END IF;

      -- price lookup from associative array with fallback
      BEGIN
        v_price := g_price_map(v_prod_rec.product_code);
      EXCEPTION WHEN NO_DATA_FOUND THEN
        v_price := v_prod_rec.unit_price;
      END;

      IF v_prod_rec.qty_on_hand >= v_item_rec.qty THEN
        -- fulfill: decrement qty
        UPDATE products
        SET qty_on_hand = qty_on_hand - v_item_rec.qty
        WHERE product_id = v_prod_rec.product_id;

        v_total_cost := v_total_cost + (v_price * v_item_rec.qty);

        v_processed.EXTEND;
        v_processed(v_processed.COUNT) := t_order_item(v_prod_rec.product_id, v_item_rec.qty);

        add_recent_product(v_recent, v_prod_rec.product_code);

        DBMS_OUTPUT.PUT_LINE(
          'Fulfilled: ' || v_prod_rec.product_code ||
          ' qty ' || v_item_rec.qty ||
          ' | Remaining: ' || (v_prod_rec.qty_on_hand - v_item_rec.qty)
        );
      ELSE
        -- not enough stock -> backorder path using GOTO to a local label
        v_backorders := v_backorders + 1;
        GOTO backorder_label;
      END IF;

      -- normal cleanup: close cursor if open
      BEGIN
        CLOSE c_prod;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;

      CONTINUE;

      -- GOTO target: insert backorder record (label inside procedure)
      <<backorder_label>>
      BEGIN
        INSERT INTO order_backorders(backorder_id, product_id, requested_qty)
        VALUES (seq_backorder_id.NEXTVAL, v_prod_rec.product_id, v_item_rec.qty);

        DBMS_OUTPUT.PUT_LINE(
          'Backorder: ' || v_prod_rec.product_code ||
          ' requested: ' || v_item_rec.qty
        );
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Error inserting backorder: ' || SQLERRM);
      END;

      -- ensure cursor is closed
      BEGIN
        CLOSE c_prod;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;

      -- loop will continue to next item
    END LOOP;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('--- Order Completed ---');
    DBMS_OUTPUT.PUT_LINE('Total cost: ' || TO_CHAR(v_total_cost, 'FM99990.00'));
    DBMS_OUTPUT.PUT_LINE('Backorders: ' || v_backorders);

    IF v_recent IS NOT NULL THEN
      DBMS_OUTPUT.PUT_LINE('Recent products processed:');
      FOR i IN 1 .. v_recent.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || v_recent(i));
      END LOOP;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error while processing order: ' || SQLERRM);
  END process_bulk_order;

  -- Utility: show products for quick checks
  PROCEDURE show_products IS
  BEGIN
    FOR r IN (SELECT product_id, product_code, qty_on_hand FROM products ORDER BY product_id) LOOP
      DBMS_OUTPUT.PUT_LINE(r.product_id || ' | ' || r.product_code || ' | ' || r.qty_on_hand);
    END LOOP;
  END show_products;

END pkg_bulk_order;
/
