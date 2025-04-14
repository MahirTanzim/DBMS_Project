-- Create Database

Drop Database if exists salary_management;
CREATE DATABASE salary_management;
USE salary_management;

-- 1. Department Table
CREATE TABLE Department (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    total_employee INT DEFAULT 0
);

-- 2. Employee Table
CREATE TABLE Employee (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    dept INT,
    designation VARCHAR(100),
    FOREIGN KEY (dept) REFERENCES Department(dept_id)
);

-- Trigger: Update total_employee count when new employee added
DELIMITER //
CREATE TRIGGER trg_increment_employee_count
AFTER INSERT ON Employee
FOR EACH ROW
BEGIN
    UPDATE Department
    SET total_employee = total_employee + 1
    WHERE dept_id = NEW.dept;
END;
//
DELIMITER ;


-- Trigger: Update total_employee count when employee removed
DELIMITER //
CREATE TRIGGER trg_decrement_employee_count
AFTER DELETE ON Employee
FOR EACH ROW
BEGIN
    UPDATE Department
    SET total_employee = total_employee - 1
    WHERE dept_id = OLD.dept;
END;
//
DELIMITER ;


-- 3. Salary Table
CREATE TABLE Salary (
    emp_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2),
    bonus DECIMAL(10,2),
    allowance DECIMAL(10,2),
    overtime_rate DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);

-- 4. Attendance Table
CREATE TABLE Attendance (
    id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    date DATE,
    status ENUM('present', 'absent'),
    overtime INT DEFAULT 0,
    time_in TIME,
    time_out TIME,
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);

-- 5. Deduction Table (auto-managed)
CREATE TABLE Deduction (
    emp_id INT PRIMARY KEY,
    days_of_abs INT,
    late_entries INT DEFAULT 0,
    early_leaves INT DEFAULT 0,
    total_deduction DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);

-- 6. Payroll Table (auto-managed)
CREATE TABLE Payroll (
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
    
    -- Validate employee exists
    SELECT COUNT(*) INTO emp_exists FROM Employee WHERE emp_id = target_emp;
    
    IF emp_exists = 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Employee does not exist';
    ELSE
        -- Convert month string to month number
        SET month_num = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y'));
        
        IF month_num IS NULL THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid month format';
        ELSE
            -- 1. Count absent days
            SELECT COUNT(*) INTO abs_days
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'absent'
              AND MONTH(date) = month_num;

            -- 2. Sum total overtime (handle NULL values)
            SELECT IFNULL(SUM(overtime), 0) INTO total_ot
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND MONTH(date) = month_num;

            -- 3. Count late and early leaves
            SELECT COUNT(*) INTO late_count
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND time_in > '09:15:00'
              AND MONTH(date) = month_num;

            SELECT COUNT(*) INTO early_leave_count
            FROM Attendance
            WHERE emp_id = target_emp AND status = 'present'
              AND time_out < '17:00:00'
              AND MONTH(date) = month_num;

            -- 4. Calculate penalties
            SET late_penalty = late_count * 50.00;
            SET early_penalty = early_leave_count * 50.00;

            -- 5. Get salary data
            SELECT base_salary, bonus, allowance, overtime_rate 
            INTO base, bonus_val, allowance_val, rate
            FROM Salary 
            WHERE emp_id = target_emp;

            -- 6. Calculate deduction
            SET deduct = (base / 30) * abs_days + late_penalty + early_penalty;

            -- 7. Update Deduction Table with new columns
            INSERT INTO Deduction (emp_id, days_of_abs, late_entries, early_leaves, total_deduction)
            VALUES (target_emp, abs_days, late_count, early_leave_count, deduct)
            ON DUPLICATE KEY UPDATE
                days_of_abs = abs_days,
                late_entries = late_count,
                early_leaves = early_leave_count,
                total_deduction = deduct;

            -- 8. Compute payroll
            SET gross = base + bonus_val + allowance_val + (rate * total_ot);
            SET net = gross - deduct;

            -- 9. Update Payroll table with new columns
            DELETE FROM Payroll 
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