# Problem Definition – Inventory Order Processing System
## Schimea NIYITWUMVA
## 28424

## 📌 Project Title
**Bulk Inventory Order Processor using PL/SQL Collections, Records, and GOTO**

## 🎯 Objective
Design and implement a PL/SQL-based solution that demonstrates the use of:
- Collections (Associative Arrays, Nested Tables, VARRAYs)
- Records (`%ROWTYPE`, user-defined)
- `GOTO` statement
- PL/SQL package creation (spec & body)
- Proper table design and data manipulation

This project forms part of the assessment for the **Database Engineering (PL/SQL)** course.

---

## 🧩 Problem Scenario

A retail store maintains a small inventory of products.  
They want a simple system to help process **bulk orders** from customers.  

Each order contains multiple product IDs and quantities. The system should:

1. Check if each product exists in the inventory.
2. If the requested quantity is available:
   - Fulfill the order
   - Deduct the quantity from inventory
3. If NOT enough stock:
   - Create a **backorder entry** using the `order_backorders` table  
   - Use a **GOTO** statement to route to the backorder logic
4. Track recently fulfilled products using a **VARRAY**
5. Use a **Nested Table** (`t_order_table`) to receive list of ordered items
6. Use an **Associative Array** as a price lookup cache
7. Use both:
   - Cursor-based `%ROWTYPE` record
   - User-defined RECORD
8. Print out a summary of:
   - Fulfilled items  
   - Backordered items  
   - Total cost  
   - Recently processed product codes  

---

## 📄 Functional Requirements

### ✔ Must Have
- A `products` table representing inventory items
- A `order_backorders` table for insufficient stock
- SQL object types:
  - `t_order_item`
  - `t_order_table`
  - `t_recent_products`
- PL/SQL package (`pkg_bulk_order`) with:
  - `process_bulk_order` procedure
  - `show_products` procedure
- Use of:
  - Associative Arrays
  - Nested Tables
  - VARRAYs
  - `%ROWTYPE`
  - User-defined RECORD
  - Cursor
  - GOTO

### ✔ Output Requirements
The script must print:
- Initial stock
- Each fulfilled item
- Each backorder
- Total order cost
- Recent products list
- Final stock levels
- Backorders table contents

---

## 📂 Deliverables
Your GitHub repository must contain:
- All SQL scripts (`sql/` folder)
- Documentation (`README.md`, `docs/design_notes.md`)
- This `problem.md`
- Lecture file inside `lecture/`
- Screen captures (optional)

---

## 📝 Notes
- The use of `GOTO` is intentional to satisfy assignment criteria.  
- In real production code, structured logic or exception handling would be preferred.  
- DBMS_OUTPUT must be enabled for output visibility.

---

