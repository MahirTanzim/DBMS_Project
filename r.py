import random
from datetime import datetime, timedelta

num_employees = 50
start_date = datetime(2025, 3, 1)
end_date = datetime(2025, 3, 30)

def random_time_in():

    late_chance = random.random()
    if late_chance < 0.2:
        return f"'09:{random.randint(16, 59):02d}:00'"
    else:
        return f"'09:{random.randint(0, 15):02d}:00'"

def random_time_out():
    early_chance = random.random()
    if early_chance < 0.2:
        return f"'16:{random.randint(0, 59):02d}:00'"
    else:
        return f"'17:{random.randint(0, 30):02d}:00'"

def generate_attendance_sql():
    current_date = start_date
    statements = []

    while current_date <= end_date:
        for emp_id in range(1, num_employees + 1):
            status = 'present' if random.random() > 0.1 else 'absent'
            overtime = random.randint(0, 3) if status == 'present' else 0
            time_in = random_time_in() if status == 'present' else 'NULL'
            time_out = random_time_out() if status == 'present' else 'NULL'

            stmt = f"INSERT INTO Attendance (emp_id, date, status, overtime, time_in, time_out) VALUES ({emp_id}, '{current_date.strftime('%Y-%m-%d')}', '{status}', {overtime}, {time_in}, {time_out});"
            statements.append(stmt)

        current_date += timedelta(days=1)

    return "\n".join(statements)

attendance_sql = generate_attendance_sql()
with open("attendance_data.sql", "w") as f:
    f.write(attendance_sql)

print("✅ Attendance INSERT statements generated and saved to attendance_data.sql")
