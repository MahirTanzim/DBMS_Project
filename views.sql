-- Department-wise Salary Report 
CREATE VIEW DepartmentSalaryReport AS
SELECT d.dept_name, p.month, SUM(p.net_salary) AS total_paid
FROM Payroll p
JOIN Employee e ON p.emp_id = e.emp_id
JOIN Department d ON e.dept = d.dept_id
GROUP BY d.dept_name, p.month;



-- Monthly Attendance Summary View:
CREATE VIEW MonthlyAttendanceSummary AS
SELECT 
    e.emp_id,
    e.name,
    DATE_FORMAT(a.date, '%M-%Y') AS month,
    SUM(a.status = 'present') AS present_days,
    SUM(a.status = 'absent') AS absent_days
FROM Attendance a
JOIN Employee e ON a.emp_id = e.emp_id
GROUP BY e.emp_id, e.name, DATE_FORMAT(a.date, '%M-%Y');


-- Employee Salary Report View
CREATE VIEW EmployeeSalaryReport AS
SELECT 
    e.emp_id,
    e.name,
    p.month,
    p.base_salary,
    p.allowance,
    p.total_deduction,
    p.net_salary
FROM Payroll p
JOIN Employee e ON p.emp_id = e.emp_id;

-- LateSummary
CREATE OR REPLACE VIEW LateSummary AS
SELECT 
    a.emp_id,
    e.name,
    DATE_FORMAT(a.date, '%M-%Y') AS month,
    COUNT(CASE WHEN a.time_in > '09:15:00' THEN 1 END) AS late_entries,
    COUNT(CASE WHEN a.time_out < '17:00:00' THEN 1 END) AS early_leaves,
    COUNT(CASE WHEN a.time_in > '09:15:00' THEN 1 END) * 50 AS late_penalty,
    COUNT(CASE WHEN a.time_out < '17:00:00' THEN 1 END) * 50 AS early_leave_penalty,
    (COUNT(CASE WHEN a.time_in > '09:15:00' THEN 1 END) * 50 +
     COUNT(CASE WHEN a.time_out < '17:00:00' THEN 1 END) * 50) AS total_penalty
FROM 
    Attendance a
JOIN 
    Employee e ON a.emp_id = e.emp_id
WHERE 
    a.status = 'present'
GROUP BY 
    a.emp_id, e.name, DATE_FORMAT(a.date, '%M-%Y');