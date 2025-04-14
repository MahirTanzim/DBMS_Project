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
