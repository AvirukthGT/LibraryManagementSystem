/* ===========================================
   LIBRARY MANAGEMENT SYSTEM SQL QUERIES
=========================================== */

-- View all records from key tables
SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employee;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;

-------------------------------------------------------------
-- Identify Members with Overdue Books (>30 days)
-------------------------------------------------------------
SELECT 
    ist.issued_member_id,
    m.member_name,
    b.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date AS overdue_days
FROM issued_status AS ist
JOIN members AS m 
    ON ist.issued_member_id = m.member_id
JOIN books AS b
    ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL 
  AND (CURRENT_DATE - ist.issued_date) > 30
ORDER BY overdue_days DESC;

-------------------------------------------------------------
-- Update Book Status to 'Yes' When Returned
-- (Manual Approach Example - NOT IDEAL)
-------------------------------------------------------------
SELECT * FROM books 
WHERE isbn = '978-0-451-52994-2';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-451-52994-2';

SELECT * FROM return_status 
WHERE issued_id = 'IS130';

UPDATE books 
SET status = 'yes' 
WHERE isbn = '978-0-451-52994-2';

-------------------------------------------------------------
-- Stored Procedure: Handle Book Return & Update Status
-------------------------------------------------------------
CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id VARCHAR(10),
    p_issued_id VARCHAR(20),
    p_book_quality VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(60);
BEGIN
    -- Insert return record
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality) 
    VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Get book details from issued_status
    SELECT issued_book_isbn, issued_book_name 
    INTO v_isbn, v_book_name 
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update book status to 'yes' (available)
    UPDATE books 
    SET status = 'yes' 
    WHERE isbn = v_isbn;

    -- Confirmation message
    RAISE NOTICE 'Thank You for Returning the Book: %', v_book_name;
END
$$;

-- Test the procedure
CALL add_return_records('RS138', 'IS135', 'Good');

-------------------------------------------------------------
-- Branch Performance Report: Books Issued, Returned & Revenue
-------------------------------------------------------------
CREATE TABLE branch_report AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) AS num_books_issued,
    COUNT(rs.return_id) AS num_books_returned,
    SUM(bk.rental_price) AS total_revenue
FROM issued_status AS ist
JOIN employee AS e 
    ON e.emp_id = ist.issued_emp_id
JOIN branch AS b
    ON e.branch_id = b.branch_id
LEFT JOIN return_status AS rs
    ON rs.issued_id = ist.issued_id
JOIN books AS bk 
    ON ist.issued_book_isbn = bk.isbn
GROUP BY b.branch_id, b.manager_id;

SELECT * FROM branch_report;

-------------------------------------------------------------
-- Create Table: Active Members in Last 2 Months
-------------------------------------------------------------
DROP TABLE IF EXISTS active_members;

CREATE TABLE active_members AS
SELECT * 
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id   
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL '2 months'
);

SELECT * FROM active_members;

-------------------------------------------------------------
-- Top 3 Employees by Number of Books Processed
-------------------------------------------------------------
SELECT 
    e.emp_name,
    COUNT(ist.issued_id) AS no_of_books_issued,
    b.branch_address 
FROM employee e 
JOIN issued_status ist 
    ON e.emp_id = ist.issued_emp_id 
JOIN branch b 
    ON b.branch_id = e.branch_id
GROUP BY e.emp_name, b.branch_address
ORDER BY no_of_books_issued DESC
LIMIT 3;

-------------------------------------------------------------
-- Stored Procedure: Issue a Book & Update Status
-------------------------------------------------------------
CREATE OR REPLACE PROCEDURE issue_book(
    p_issued_id VARCHAR(10),
    p_issued_member_id VARCHAR(30),
    p_issued_book_isbn VARCHAR(30),
    p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    -- Check book availability
    SELECT status INTO v_status
    FROM books 
    WHERE isbn = p_issued_book_isbn;

    -- If available, issue the book
    IF v_status = 'yes' THEN
        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id) 
        VALUES (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books 
        SET status = 'no' 
        WHERE isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book ISBN: % issued successfully', p_issued_book_isbn;
    ELSE
        RAISE NOTICE 'Book Not Available';
    END IF;
END
$$;

-- Testing the procedure
SELECT * FROM books;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS130', 'C106', '978-0-375-41398-8', 'E104');

-- Check updated book status
SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';
