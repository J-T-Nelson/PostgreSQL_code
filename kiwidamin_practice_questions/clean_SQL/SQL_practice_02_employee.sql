SELECT *
FROM department;

SELECT *
FROM employee;

-- Question set: 
-- This is a small data set, where querries could be completed by hand and compared to SQL results if desired. 

-- 1. List all the employees in order of descreasing salary
SELECT name AS employee, salary
FROM employee
ORDER BY salary DESC;


-- 2. List all the department names, and the number of employees in that department. 
--		Order by number of employess in department (greatest to least)
WITH dptNameJoin AS (
	SELECT name, empid, e.deptid, deptname
	FROM employee e
	FULL JOIN department d
	ON e.deptid = d.deptid
)
SELECT deptname, COUNT(name) AS num_employees
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


-- 4. List all employees by name, and the name of their manager. If the employee doesn't have a manager, leave the column as NULL.
SELECT e.empid, e.name, m.name as manager
FROM employee e
LEFT JOIN employee m
ON e.managerid = m.empid;


-- 5. For each manager, list the number of employees he or she is managing. For these purposes, 
-- 		a manager is anyone who is not managed by someone else, even if that person has no direct reports.
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
-- Going to guess there is a better way to answer this, though, my answer did get the correct response. 


-- 6. Find the two highest paid people per department
WITH ranked_salaries AS (
    SELECT 
        name, deptid, salary, 
        ROW_NUMBER() OVER (PARTITION BY deptid ORDER BY salary DESC) AS rank
    FROM 
        employee
)
SELECT 
    name, deptid, salary, rank
FROM 
    ranked_salaries
WHERE 
    rank <= 2;
-- This is correct. Important to note here is how window functions are helping us solve this problem. 
-- The ROW_NUMBER window function is helpful as it gives us a ranking value when used in conjunction with the order by clause
