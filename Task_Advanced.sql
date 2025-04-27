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