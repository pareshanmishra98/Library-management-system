
CREATE DATABASE libmanagementsys;
USE libmanagementsys;
CREATE TABLE branch(branch_id VARCHAR(10) PRIMARY KEY,
manager_id VARCHAR(10),
branch_address VARCHAR(30),
contact_no VARCHAR(15)
);

CREATE TABLE employees(
emp_id VARCHAR(10) PRIMARY KEY,
emp_name VARCHAR(30),
position VARCHAR(30),
salary INT,
branch_id VARCHAR(10),
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id)
);

CREATE TABLE books(
isbn VARCHAR(50) PRIMARY KEY,
book_title VARCHAR(80),
category VARCHAR(30),
rental_price INT,
status VARCHAR(10),
author VARCHAR(30),
publisher VARCHAR(30)
);

CREATE TABLE members(
member_id VARCHAR(10) PRIMARY KEY,
member_name VARCHAR(30),
member_address VARCHAR(30),
reg_date DATE
);

CREATE TABLE return_status(
return_id VARCHAR(10),
issued_id VARCHAR(30),
return_book_name VARCHAR(80),
return_date DATE,
return_book_isbn VARCHAR(50),
FOREIGN KEY (return_book_isbn)
REFERENCES books(isbn)
);


CREATE TABLE issued_status(
issued_id VARCHAR(10),
issued_member_id VARCHAR(30),
issued_book_name VARCHAR(50),
issued_date DATE,
issued_book_isbn VARCHAR(50),
issued_emp_id VARCHAR(10),
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id),
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id),
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn)
);
SELECT * FROM issued_status;

-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

-- Task 2: Update an Existing Member's Address
UPDATE members SET member_address='new address' WHERE member_id='C119';
SELECT * FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
SET SQL_SAFE_UPDATES = 0;
DELETE FROM issued_status WHERE issued_id='IS121';
SET SQL_SAFE_UPDATES = 1;

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT issued_book_name FROM issued_status WHERE issued_emp_id='E101';

-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_emp_id, count(issued_emp_id) AS cnt FROM issued_status GROUP BY issued_emp_id HAVING cnt>1; 

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count 
FROM issued_status as ist 
JOIN books as b ON ist.issued_book_isbn = b.isbn 
GROUP BY b.isbn, b.book_title;
SELECT * FROM book_issued_cnt;

-- Task 7. Retrieve All Books in a Specific Category:
SELECT * FROM books WHERE category='classic';

-- Task 8: Find Total Rental Income by Category:
SELECT category, SUM(rental_price) FROM books GROUP BY category;

-- Task 9: List Members Who Registered in the Last 180 Days:
SELECT * FROM members WHERE reg_date >= current_date - INTERVAL 180 day;

-- Task 10: List Employees with Their Branch Manager's Name and their branch details:
SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;
SELECT * FROM expensive_books;

-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;


-- Entering some more data for advanced SQL problems
INSERT INTO issued_status(issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
VALUES
('IS151', 'C118', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL 24 day,  '978-0-553-29698-2', 'E108'),
('IS152', 'C119', 'The Catcher in the Rye', CURRENT_DATE - INTERVAL 13 day,  '978-0-553-29698-2', 'E109'),
('IS153', 'C106', 'Pride and Prejudice', CURRENT_DATE - INTERVAL 7 day,  '978-0-14-143951-8', 'E107'),
('IS154', 'C105', 'The Road', CURRENT_DATE - INTERVAL 32 day,  '978-0-375-50167-0', 'E101');

ALTER TABLE return_status
ADD Column book_quality VARCHAR(15) DEFAULT('Good');

SET SQL_SAFE_UPDATES=0;
UPDATE return_status
SET book_quality = 'Damaged'
WHERE issued_id 
    IN ('IS112', 'IS117', 'IS118');
SELECT * FROM return_status;
SET SQL_SAFE_UPDATES=1;

 /* 
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, 
issue date, and days overdue.
*/
SELECT 
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1;

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

DROP PROCEDURE IF EXISTS add_return_record;
DELIMITER $$
CREATE PROCEDURE add_return_records(IN p_return_id VARCHAR(10),IN p_issued_id VARCHAR(10),IN p_book_quality VARCHAR(10), OUT v_isbn VARCHAR(50), OUT v_book_name VARCHAR(50))
    
BEGIN
    -- all your logic and code
    -- inserting into returns based on users input
    INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    SELECT 
        issued_book_isbn,
        issued_book_name
        INTO
        v_isbn,
        v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;
END$$
DELIMITER ;
-- calling function 
CALL add_return_records('RS138', 'IS135', 'Good');
SELECT * FROM books;

-- Task 15: Branch Performance Report
-- Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_reports
AS
SELECT 
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id) as number_book_issued,
    COUNT(rs.return_id) as number_of_book_return,
    SUM(bk.rental_price) as total_revenue
FROM issued_status as ist
JOIN 
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
JOIN 
books as bk
ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;

SELECT * FROM branch_reports;

/* 
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 
12 months.
*/

CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
                        DISTINCT issued_member_id   
                    FROM issued_status
                    WHERE 
                        issued_date >=  CURRENT_DATE - INTERVAL 12 month
                    )
;

SELECT * FROM active_members;

/* 
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their 
branch.
*/

SELECT 
    e.emp_name,
    b.*,
    COUNT(ist.issued_id) as no_book_issued
FROM issued_status as ist
JOIN
employees as e
ON e.emp_id = ist.issued_emp_id
JOIN
branch as b
ON e.branch_id = b.branch_id
GROUP BY 1, 2 
ORDER BY no_book_issued DESC LIMIT 3;

/* 
Task 18: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify 
overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not
 returned within 30 days. The table should include: The number of overdue books. The total fines, with each day's 
 fine calculated at $0.50. The number of books issued by each member. The resulting table should show: Member ID 
 Number of overdue books, Total fines
*/

SELECT DISTINCT member_id, COUNT(member_id) AS NO_OF_OVERDUE_BOOKS, SUM(over_dues_days*0.5) AS Total_fine FROM
(SELECT 
    ist.issued_member_id AS member_id,
    bk.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date as over_dues_days
FROM issued_status as ist
JOIN 
members as m
    ON m.member_id = ist.issued_member_id
JOIN 
books as bk
ON bk.isbn = ist.issued_book_isbn
LEFT JOIN 
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE 
    rs.return_date IS NULL
    AND
    (CURRENT_DATE - ist.issued_date) > 30
ORDER BY 1) AS overdue_data
GROUP BY member_id;
/* 
Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: 
Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as 
follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the book is available 
(status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the
 book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/


DELIMITER $$
CREATE PROCEDURE issue_book(IN p_issued_id VARCHAR(10),IN p_issued_member_id VARCHAR(30),IN p_issued_book_isbn VARCHAR(30),IN p_issued_emp_id VARCHAR(10))
BEGIN
DECLARE v_status VARCHAR(10);
    SELECT 
        status 
        INTO
        v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN

        INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
        (p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);

        UPDATE books
            SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

SIGNAL SQLSTATE '01000'
    SET MESSAGE_TEXT = 'Book records added successfully.';
      
    ELSE
    
        SIGNAL SQLSTATE '01000'
    SET MESSAGE_TEXT = 'Sorry to inform you the book you have requested is unavailable.';
      
    END IF;
END;
$$
DELIMITER ;

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL issue_book('IS124', 'C104', '978-0-06-025492-6', 'E104');
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

