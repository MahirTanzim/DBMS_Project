--  Create Database

Drop Database if exists salary_management;
CREATE DATABASE salary_management;
USE salary_management;



CREATE TABLE Department (       -- Department Table
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    total_employee INT DEFAULT 0
);



CREATE TABLE Employee (     -- Employee Table
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    dept INT,
    designation VARCHAR(100),
    FOREIGN KEY (dept) REFERENCES Department(dept_id)
);



CREATE TABLE Salary (       -- Salary Table
    emp_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2),
    bonus DECIMAL(10,2),
    allowance DECIMAL(10,2),
    overtime_rate DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);



CREATE TABLE Attendance (       -- Attendance Table
    id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    date DATE,
    status ENUM('present', 'absent'), 
    overtime INT DEFAULT 0,
    time_in TIME,
    time_out TIME,
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id) 
);



CREATE TABLE Deduction (        -- Deduction Table
    emp_id INT PRIMARY KEY,
    days_of_abs INT,
    late_entries INT DEFAULT 0,
    early_leaves INT DEFAULT 0,
    total_deduction DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);


CREATE TABLE Payroll (      -- Payroll Table
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    month VARCHAR(20),
    base_salary DECIMAL(10,2),
    bonus DECIMAL(10,2),
    allowance DECIMAL(10,2),
    overtime DECIMAL(10,2),
    days_of_absent INT DEFAULT 0,
    late_entries INT DEFAULT 0,
    early_leaves INT DEFAULT 0,
    total_deduction DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    payment_date DATE,
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);




DELIMITER //
CREATE TRIGGER trg_increase_employee_count  --  Trigger: Update total_employee count in each dept when new employee added
AFTER INSERT ON Employee
FOR EACH ROW
BEGIN
    UPDATE Department
    SET total_employee = total_employee + 1
    WHERE dept_id = NEW.dept;
END;
//
DELIMITER ;



DELIMITER //
CREATE TRIGGER trg_decrease_employee_count      --  Trigger: Update total_employee count in each dept when employee removed
AFTER DELETE ON Employee
FOR EACH ROW
BEGIN
    UPDATE Department
    SET total_employee = total_employee - 1
    WHERE dept_id = OLD.dept;
END;
//
DELIMITER ;



--  procedure for deduction and payroll table
DELIMITER //
DROP PROCEDURE IF EXISTS update_deductions_and_payroll //
CREATE PROCEDURE update_deductions_and_payroll(IN target_emp INT, IN target_month VARCHAR(20))
BEGIN
    DECLARE abs_days INT DEFAULT 0;
    DECLARE total_ot INT DEFAULT 0;
    DECLARE base DECIMAL(10,2) DEFAULT 0;
    DECLARE bonus_val DECIMAL(10,2) DEFAULT 0;
    DECLARE allowance_val DECIMAL(10,2) DEFAULT 0;
    DECLARE rate DECIMAL(10,2) DEFAULT 0;
    DECLARE gross DECIMAL(10,2);
    DECLARE deduct DECIMAL(10,2) DEFAULT 0;
    DECLARE net DECIMAL(10,2);
    DECLARE late_count INT DEFAULT 0;
    DECLARE early_leave_count INT DEFAULT 0;
    DECLARE late_penalty DECIMAL(10,2) DEFAULT 0;
    DECLARE early_penalty DECIMAL(10,2) DEFAULT 0;
    DECLARE month_num INT;
    DECLARE emp_exists INT DEFAULT 0;
    
    
    SELECT COUNT(*) INTO emp_exists FROM Employee WHERE emp_id = target_emp; --  Check if employee exists
    
    IF emp_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Employee does not exist';
    ELSE
        
        SET month_num = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y')); -- Convert month string to month number
        
        IF month_num IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid month format';
        ELSE
            
            SELECT COUNT(*) INTO abs_days -- Count absent days
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'absent'
              AND MONTH(date) = month_num;

           
            SELECT IFNULL(SUM(overtime), 0) INTO total_ot  -- Sum total overtime (handle NULL values)
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND MONTH(date) = month_num;

          
            SELECT COUNT(*) INTO late_count   --  3. Count late and early leaves
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND time_in > '09:15:00'
              AND MONTH(date) = month_num;

            SELECT COUNT(*) INTO early_leave_count
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND time_out < '17:00:00'
              AND MONTH(date) = month_num;

            
            SET late_penalty = late_count * 50.00;       -- Calculate penalties
            SET early_penalty = early_leave_count * 50.00; 

            
            SELECT base_salary, bonus, allowance, overtime_rate  -- Get salary data
            INTO base, bonus_val, allowance_val, rate
            FROM Salary 
            WHERE emp_id = target_emp;

            
            SET deduct = (base / 30) * abs_days + late_penalty + early_penalty;     --  Calculate deduction

            
            INSERT INTO Deduction (emp_id, days_of_abs, late_entries, early_leaves, total_deduction)   -- Update Deduction Table with new columns
            VALUES (target_emp, abs_days, late_count, early_leave_count, deduct)
            ON DUPLICATE KEY UPDATE
                days_of_abs = abs_days,
                late_entries = late_count,
                early_leaves = early_leave_count,
                total_deduction = deduct;

            
            SET gross = base + bonus_val + allowance_val + (rate * total_ot);    -- Compute payroll
            SET net = gross - deduct;

            
            DELETE FROM Payroll         -- Update Payroll table with new columns to avoid duplicates
            WHERE emp_id = target_emp AND month = target_month;
            
            INSERT INTO Payroll (
                emp_id, month, base_salary, bonus, allowance, 
                overtime, total_deduction, net_salary, payment_date,
                days_of_absent, late_entries, early_leaves
            )
            VALUES (
                target_emp, target_month, base, bonus_val, allowance_val, 
                total_ot * rate, deduct, net, CURDATE(),
                abs_days, late_count, early_leave_count
            );
        END IF;
    END IF;
END //
DELIMITER ;


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