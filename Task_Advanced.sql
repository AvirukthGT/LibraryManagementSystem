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
