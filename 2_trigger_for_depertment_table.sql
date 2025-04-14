
DELIMITER //
CREATE TRIGGER trg_increase_employee_count  -- Trigger: Update total_employee count in each dept when new employee added
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
CREATE TRIGGER trg_decrease_employee_count      -- Trigger: Update total_employee count in each dept when employee removed
AFTER DELETE ON Employee
FOR EACH ROW
BEGIN
    UPDATE Department
    SET total_employee = total_employee - 1
    WHERE dept_id = OLD.dept;
END;
//
DELIMITER ;