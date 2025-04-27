/* ===========================================
   LIBRARY MANAGEMENT SYSTEM TASKS & QUERIES
=========================================== */

-- View Data from Core Tables
SELECT * FROM return_status;
SELECT * FROM books;
SELECT * FROM employee;
SELECT * FROM issued_status;
SELECT * FROM branch;

-------------------------------------------------------------
-- 1️⃣ Task: Create a New Book Record
-------------------------------------------------------------
INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');

-- Verify the insertion
SELECT * FROM books;

-------------------------------------------------------------
-- 2️⃣ Task: Update an Existing Member's Address
-------------------------------------------------------------
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-------------------------------------------------------------
-- 3️⃣ Task: Delete a Record from Issued Status Table
-- Objective: Delete record where issued_id = 'IS121'
-------------------------------------------------------------
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-------------------------------------------------------------
-- 4️⃣ Task: Retrieve All Books Issued by a Specific Employee
-- Objective: Get books issued by emp_id = 'E101'
-------------------------------------------------------------
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-------------------------------------------------------------
-- 5️⃣ Task: List Members Who Have Issued More Than One Book
-------------------------------------------------------------
SELECT
    issued_emp_id,
    COUNT(*) AS books_issued
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(*) > 1;

-------------------------------------------------------------
-- 6️⃣ Task: Create Summary Table for Book Issue Count (CTAS)
-------------------------------------------------------------
CREATE TABLE book_issued_cnt AS
SELECT 
    b.isbn, 
    b.book_title, 
    COUNT(ist.issued_id) AS issue_count
FROM issued_status AS ist
JOIN books AS b
    ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;

-- View the summary table
SELECT * FROM book_issued_cnt;

-------------------------------------------------------------
-- 7️⃣ Task: Retrieve All Books in the 'Classic' Category
-------------------------------------------------------------
SELECT * FROM books
WHERE category = 'Classic';

-------------------------------------------------------------
-- 8️⃣ Task: Find Total Rental Income by Category
-------------------------------------------------------------
SELECT 
    b.category,
    SUM(b.rental_price) AS total_income,
    COUNT(*) AS total_issues
FROM issued_status AS ist
JOIN books AS b
    ON b.isbn = ist.issued_book_isbn
GROUP BY b.category;

-------------------------------------------------------------
-- 9️⃣ Task: List Employees with Their Branch Manager and Branch Details
-------------------------------------------------------------
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.branch_id,
    b.branch_address,
    b.manager_id,
    e2.emp_name AS manager_name
FROM employee AS e1
JOIN branch AS b
    ON e1.branch_id = b.branch_id    
JOIN employee AS e2
    ON e2.emp_id = b.manager_id;

-------------------------------------------------------------
-- 🔟 Task: Create Table for Books with High Rental Price (> 7.00)
-------------------------------------------------------------
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

-- View expensive books
SELECT * FROM expensive_books;

-------------------------------------------------------------
-- 1️⃣1️⃣ Task: Retrieve List of Books Not Yet Returned
-------------------------------------------------------------
SELECT 
    ist.*
FROM issued_status AS ist
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;
