-- Create Database

Drop Database if exists salary_management;
CREATE DATABASE salary_management;
USE salary_management;



CREATE TABLE Department (       --Department Table
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(100) NOT NULL,
    total_employee INT DEFAULT 0
);



CREATE TABLE Employee (     --Employee Table
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    dept INT,
    designation VARCHAR(100),
    FOREIGN KEY (dept) REFERENCES Department(dept_id)
);



CREATE TABLE Salary (       --Salary Table
    emp_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2),
    bonus DECIMAL(10,2),
    allowance DECIMAL(10,2),
    overtime_rate DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);



CREATE TABLE Attendance (       --Attendance Table
    id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    date DATE,
    status ENUM('present', 'absent'), 
    overtime INT DEFAULT 0,
    time_in TIME,
    time_out TIME,
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id) 
);



CREATE TABLE Deduction (        --Deduction Table
    emp_id INT PRIMARY KEY,
    days_of_abs INT,
    late_entries INT DEFAULT 0,
    early_leaves INT DEFAULT 0,
    total_deduction DECIMAL(10,2),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
);


CREATE TABLE Payroll (      --Payroll Table
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