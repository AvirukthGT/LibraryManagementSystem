--Library Management System--

select * from books;
select * from branch;
select * from employee;
select * from issued_status;
select * from members;
select * from return_status;


-- Identifying members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

select 
	ist.issued_member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	current_date-ist.issued_date as overdue_days
from issued_status as ist
join 
members as m 
	on ist.issued_member_id=m.member_id
join
books as b
	on b.isbn=ist.issued_book_isbn
left join
return_status as rs
	on rs.issued_id =ist.issued_id
where return_date is NULL 
and (current_date-ist.issued_date)>30
order by
5 desc

--  Update  status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

--Manual Approach-- NOT IDEAL

select * from books 
where isbn='978-0-451-52994-2'

select * from issued_status
where issued_book_isbn='978-0-451-52994-2'

select * from return_status where issued_id= 'IS130'

update books set status = 'no' where isbn ='978-0-451-52994-2'

--Store Procedures
CREATE OR REPLACE PROCEDURE add_return_records(p_return_id varchar(10),p_issued_id varchar(20),p_book_quality varchar(20))
language plpgsql
as $$


declare
	v_isbn varchar(50);
	v_book_name varchar(60);
begin
	--Inserting into return_status
	insert into return_status(return_id,issued_id,return_date,book_quality) 
	values 
	(p_return_id,p_issued_id,current_date,p_book_quality);

	select issued_book_isbn,issued_book_name into v_isbn,v_book_name 
	from issued_status
	where issued_id=p_issued_id;

	

	update books 
	set status = 'yes' 
	where isbn =   v_isbn;

	raise notice 'Thank You for Returning the Book: %',v_book_name;

end
$$

call add_return_records('RS138','IS135','Good');


--Generating a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.
create table branch_report
as
select 
b.branch_id,
b.manager_id,
count(ist.issued_id) as num_books_issued,
count(rs.return_id) as num_books_returned,
SUM(bk.rental_price) as total_revenue
from issued_status as ist
JOIN
employee as e 
on e.emp_id=ist.issued_emp_id
join branch as b
on e.branch_id=b.branch_id
left join return_status as rs
on rs.issued_id=ist.issued_id
join 
books as bk 
on ist.issued_book_isbn=bk.isbn
group by 1,2;

select * from branch_report

-- New table active_members containing members who have issued at least one book in the last 2 months.

drop table if exists active_members;

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >= CURRENT_DATE - INTERVAL '2 month'
                    )
;

SELECT * FROM active_members;

--Finding the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.


select e.emp_name,count(ist.issued_id) as no_of_books_issued,b.branch_address from employee e join 
issued_status ist on e.emp_id = ist.issued_emp_id 
join branch b on b.branch_id=e.branch_id
group by 1,3
order by 2 desc
limit 3


/*
Stored procedure to manage the status of books in a library system. 
Description: stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows: 
The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.
*/

create or replace procedure issue_book(p_issued_id varchar(10),p_issued_member_id varchar(30),p_issued_book_isbn varchar(30),p_issued_emp_id varchar(10))
language plpgsql
as $$
declare
	v_status varchar(10);

begin
	SELECT status as v_status
	from books 
	where isbn=p_issued_book_isbn;

	IF v_status='yes' then
		INSERT INTO issued_status(issued_id,issued_member_id,issued_date,issued_book_isbn,issued_emp_id) 
			VALUES(p_issued_id,p_issued_member_id,current_date,p_issued_book_isbn,p_issued_emp_id);
			update books 
			set status = 'no' 
			where isbn =   p_issued_book_isbn;
			raise notice 'Book isbn : % issued successfully',p_issued_book_isbn;

			
	ELSE
		raise notice 'Book Not Available';

	END IF;

	
end
$$

-- Testing The procedure
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-451-52994-2" -- no
SELECT * FROM issued_status;

CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL issue_book('IS130', 'C106', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8'



