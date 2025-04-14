-- Create Database
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
    total_deduction DECIMAL(10,2),
    net_salary DECIMAL(10,2),
    payment_date DATE,
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);

