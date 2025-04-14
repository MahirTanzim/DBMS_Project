-- Trigger: Update Deduction table based on attendance (monthly logic)
DELIMITER //
CREATE PROCEDURE update_deductions_and_payroll(in target_emp INT, in target_month VARCHAR(20))
BEGIN
    DECLARE abs_days INT;
    DECLARE total_ot INT DEFAULT 0;
    DECLARE base DECIMAL(10,2);
    DECLARE bonus DECIMAL(10,2);
    DECLARE allowance DECIMAL(10,2);
    DECLARE rate DECIMAL(10,2);
    DECLARE gross DECIMAL(10,2);
    DECLARE deduct DECIMAL(10,2);
    DECLARE net DECIMAL(10,2);
    DECLARE late_count INT DEFAULT 0;
    DECLARE early_leave_count INT DEFAULT 0;
    DECLARE late_penalty DECIMAL(10,2) DEFAULT 0;
    DECLARE early_penalty DECIMAL(10,2) DEFAULT 0;

    -- 1. Count absent days
    SELECT COUNT(*) INTO abs_days
    FROM Attendance
    WHERE emp_id = target_emp AND status = 'absent'
      AND MONTH(date) = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y'));

    -- 2. Sum total overtime
    SELECT SUM(overtime) INTO total_ot
    FROM Attendance
    WHERE emp_id = target_emp AND status = 'present'
      AND MONTH(date) = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y'));

    -- 3. Count late and early leaves
    SELECT COUNT(*) INTO late_count
    FROM Attendance
    WHERE emp_id = target_emp AND status = 'present'
      AND time_in > '09:15:00'
      AND MONTH(date) = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y'));

    SELECT COUNT(*) INTO early_leave_count
    FROM Attendance
    WHERE emp_id = target_emp AND status = 'present'
      AND time_out < '17:00:00'
      AND MONTH(date) = MONTH(STR_TO_DATE(CONCAT('01-', target_month), '%d-%M-%Y'));

    -- 4. Calculate penalties
    SET late_penalty = late_count * 50.00;
    SET early_penalty = early_leave_count * 50.00;

    -- 5. Get salary data
    SELECT base_salary, bonus, allowance, overtime_rate INTO base, bonus, allowance, rate
    FROM Salary WHERE emp_id = target_emp;

    -- 6. Calculate deduction
    SET deduct = (base / 30) * abs_days + late_penalty + early_penalty;

    -- 7. Update Deduction Table
    INSERT INTO Deduction (emp_id, days_of_abs, total_deduction)
    VALUES (target_emp, abs_days, deduct)
    ON DUPLICATE KEY UPDATE
        days_of_abs = abs_days,
        total_deduction = deduct;

    -- 8. Compute payroll
    SET gross = base + bonus + allowance + (rate * IFNULL(total_ot, 0));
    SET net = gross - deduct;

    INSERT INTO Payroll (emp_id, month, base_salary, bonus, allowance, overtime, total_deduction, net_salary, payment_date)
    VALUES (target_emp, target_month, base, bonus, allowance, total_ot * rate, deduct, net, CURDATE());
END;
//
DELIMITER ;