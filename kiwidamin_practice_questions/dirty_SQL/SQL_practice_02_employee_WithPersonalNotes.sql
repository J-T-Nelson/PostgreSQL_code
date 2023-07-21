SELECT *
FROM department;

SELECT *
FROM employee;

-- Question set: 
-- This is a small data set, where querries could be completed by hand and compared to SQL results if desired. 

-- 1. List all the employees in order of descreasing salary
SELECT name as employee, salary
FROM employee
ORDER BY salary DESC;
-- their answer selects all cols, but no need for the question realisitically 

-- 2. List all the department names, and the number of employees in that department. 
--		Order by number of employess in department (greatest to least)

-- practicing joins
SELECT 
	e, name, empid, e.deptid, 
	d, d.deptid, deptname
FROM employee e
LEFT JOIN department d
ON e.deptid = d.deptid
-- using table aliases in the SELECT statement returns tuples of the table's rows. (mixed data type tuples)


SELECT 
	name, empid, e.deptid, 
	deptname
FROM employee e
LEFT JOIN department d
ON e.deptid = d.deptid

-- attempting to answer
WITH dptNameJoin AS (
	SELECT 
	name, empid, e.deptid, 
	deptname
	FROM employee e
	LEFT JOIN department d
	ON e.deptid = d.deptid)
SELECT deptname, COUNT(deptname) as num_employees
FROM dptNameJoin
GROUP BY deptname
ORDER BY num_employees DESC;
-- This looks good, except I fail to capture the 'SecretOps' department, as there are no employees within it, which results in exclusion
-- Exclusion is coming from the join type I believe. Need more inclusive join to get this right 

WITH dptNameJoin AS (
	SELECT 
	name, empid, e.deptid, 
	deptname
	FROM employee e
	FULL JOIN department d
	ON e.deptid = d.deptid)
SELECT deptname, COUNT(name) as num_employees
FROM dptNameJoin
GROUP BY deptname
ORDER BY num_employees DESC;
-- this gets the correct answer. We need to count the names of employees to properly find there are 0 numbers of employees within the Secret Ops
--	department. Counting deptname gets 1 for num_employees, as its just counting the number of rows. 
--	Further, FULL JOIN is necessary as we don't want to exclude any empty departments for this question, which occurs with other less inclusive joing types. 

-- 3. List all the employees that don't have a manager
SELECT *
FROM employee
WHERE managerid IS null;
-- correct


-- 4. List all employees by name, and the name of their manager. If the employee doesn't have a manager, leave the column as NULL.
SELECT e.empid, e.name, m.name as manager
FROM employee e
INNER JOIN employee m
ON e.managerid = m.empid;
-- INNER JOIN incorrect, as we are dropping null values. 

SELECT e.empid, e.name, m.name as manager
FROM employee e
LEFT JOIN employee m
ON e.managerid = m.empid;
-- This is the result we want. Good. 


-- 5. For each manager, list the number of employees he or she is managing. For these purposes, 
-- 		a manager is anyone who is not managed by someone else, even if that person has no direct reports.
WITH managers AS (
	SELECT empid, name
	FROM employee
	WHERE name IS null
)
SELECT managers.name, COUNT(name)


WITH managers AS (
	SELECT e.empid, e.name, m.name as manager
	FROM employee e
	LEFT JOIN employee m
	ON e.managerid = m.empid
)
SELECT managers.name, COUNT(manager) as num_reports
FROM managers
GROUP BY name;
-- definitely wrong

WITH managers AS (
	SELECT e.empid, e.name, m.name as manager, e.managerid
	FROM employee e
	LEFT JOIN employee m
	ON e.managerid = m.empid
)
SELECT manager, COUNT(name) as num_reports
FROM managers
GROUP BY manager;

-- we need a table where the managers are listed next to all of their reportring employees. Even if they have none. 
-- So we join the manager table with the base employee table using the empid from manager (manager.empid) ON employee.managerid
WITH managers AS (
	SELECT *
	FROM employee
	WHERE managerid IS null
)
SELECT m.name as manager_name, COUNT(e.name) as num_reports 
FROM managers m
LEFT JOIN employee e ON m.empid = e.managerid
GROUP BY manager_name
ORDER BY num_reports DESC;
-- finally correct. Took a few iterations to figure this out. 

SELECT 
    m.name AS manager_name, 
    COUNT(e.empid) AS num_reports 
FROM 
    employee m
LEFT JOIN 
    employee e ON m.empid = e.managerid
GROUP BY 
    m.name
ORDER BY 
    num_reports DESC;
-- chatGPT's answer fails to exclude non managers, which burries Shuri in all employees with no reports. Effectively failing to answer the query. 
-- Going to guess there is a better way to answer this, though, my answer did get the correct response. 

-- 6. Find the two highest paid people per department

-- join dptname into employee table, group by deptname, using MAX(salary) as peak salary
-- answer doesn't actually use dptname... so no join necessary .. missed the part about the top two however, not sure how to limit per group returns

SELECT name, deptid, salary
FROM employee
GROUP BY dptid

-- ChatGPTs answer
WITH ranked_salaries AS (
    SELECT 
        name, 
        deptid, 
        salary, 
        ROW_NUMBER() OVER (PARTITION BY deptid ORDER BY salary DESC) as rn
    FROM 
        employee
)
SELECT 
    name, 
    deptid, 
    salary,
	rn as rank
FROM 
    ranked_salaries
WHERE 
    rn <= 2;
-- This is correct. Important to note here is how window functions are helping us solve this problem. 
-- The ROW_NUMBER window function is helpful as it gives us a ranking value when used in conjunction with the order by clause

-- chatGPT answer #2
WITH ranked_salaries AS (
    SELECT 
        name, 
        deptid, 
        salary, 
        DENSE_RANK() OVER (PARTITION BY deptid ORDER BY salary DESC) as dr
    FROM 
        employee
)
SELECT 
    name, 
    deptid, 
    salary,
	dr as rank
FROM 
    ranked_salaries
WHERE 
    dr <= 2;
-- not sure on the details, but dense rank seems to be working the same as row_number() exactly here. 

-- "The difference is that rank() and dense_rank() will assign the same rank to rows with equal values, 
--  whereas row_number() will assign different row numbers to these rows. 
--	If you want to include all employees who are tied for the second highest salary, you should use rank() or dense_rank()."



