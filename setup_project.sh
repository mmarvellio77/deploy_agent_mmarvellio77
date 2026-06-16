#!/bin/bash

get_user_input(){
	read -p "Enter a unique identifier: " input
	input=$(echo "$input" | tr -d '[:space:]')
	if [ -z "$input" ]; then
		echo "[ERROR] Project identifier can't be empty!"
		exit 1
	fi
}

cleanup_on_interrupt(){
	echo -e "\n\n[INTERRUPT DETECTED] Script cancelled by user (SIGINT)."
	
	if [ -d "$parent_dir" ]; then
		echo "[CLEANUP] Packaging currennt incomplete state into $archive_name..."
		tar -czf "$archive_name" "$parent_dir" 2>/dev/null

		echo "[CLEANUP] Removing incomplete directory to keep workspace clean..."
		rm -rf "$parent_dir" 
	fi
	
	echo "[CLEANUP] Complete. Exiting safely."
	exit 130
}

setup_directories(){
 	echo "--------------------------------------------------"
	echo "[1/4] Building Directory Architecture..."
	echo "--------------------------------------------------"

	if [ -d "$parent_dir" ]; then
		echo "[ERROR] Directory '$parent_dir' already exists. Aborting to prevent overwrite."
		exit 1
	fi

	mkdir -p "$parent_dir"/{Helpers,reports}
	
		

	if [ $? -ne 0 ]; then
		echo "[ERROR] Failed to create directories. Check write permissions."
		exit 1
	fi

	cat << 'EOF' > "$parent_dir/attendance_checker.py"
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            attendance_pct = (attended / total_sessions) * 100
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

cat << 'EOF' > "$parent_dir/Helpers/assets.csv"
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

cat << 'EOF' > "$parent_dir/Helpers/config.json"
{
	"thresholds": {
		"warning": 75,
		"failure": 50
	},
	"run_mode": "live",
	"total_sessions": 15
}
EOF

	cat << 'EOF'>"$parent_dir/reports/reports.log"
	[INFO] System initialized.
EOF
	
	echo "[SUCCESS] Directory structure successfully provisioned."
}

get_threshold(){
	local prompt=$1
	local default=$2
	local value

	read -p "$prompt (Default): " value

	if [ -z "$value" ]; then
		echo $default
	elif [[ !  "$value" =~ ^[0-9]+$ ]]; then
		echo "[WARN] Invalid input. Using default: $default" >&2
		echo $default
	else 
		echo $value
	fi
}

update_config(){

	echo -e "\n--------------------------------------------------"
	echo "[2/4] Dynamic Configuration Setup"
	echo "--------------------------------------------------"

	read -p "Do you want to update the attendance thresholds? y/N): " MODIFY_CONFIG

	if [[ "$MODIFY_CONFIG" =~ ^[Yy]$ ]]; then
		warning_input=$(get_threshold "Enter Warning Threshold %" 75)
		failure_input=$(get_threshold "Enter Failure Threshold %" 50)

		echo "[CONFIG] Updating config.json values dynamically..."
		
		sed -i '' "s/\"warning\": .*/\"warning\":$warning_input,/g" "$parent_dir/Helpers/config.json"
		
		sed -i '' "s/\"failure\": .*/\"failure\": $failure_input/g" "$parent_dir/Helpers/config.json"

		echo "[SUCCESS] Updated config.json content:"
		cat "$parent_dir/Helpers/config.json"
	else
		echo "[CONFIG] Retaining standard base configuration thresholds."
	fi
}


run_health_checks(){
	echo -e "\n--------------------------------------------------"
	echo "[3/4] Running System Health Checks..."
	echo "--------------------------------------------------"
	
	if command -v python3 &> /dev/null; then
		echo "[HEALTH CHECK] Python3 found: $(python3 --version)"
	else
		echo "[WARNING] python3 is missing! The tracker will not execute natively."
	fi

	if [ -f "$parent_dir/attendance_checker.py" ] && [ -f "$parent_dir/Helpers/config.json" ]; then
		echo "[HEALTH CHECK] Directory structure validation: PASSED"
	else
		echo "[HEALTH CHECK] Director structure validation: FAILED"
	fi
}

final(){
	
	echo -e "\n--------------------------------------------------"
	echo "[4/4] Finalizing Environment"
	echo "--------------------------------------------------"
	echo "[SUCCESS] Project Factory complete!"
	echo "Your workspace is ready at: ./$parent_dir"
}

get_user_input
parent_dir="attendance_tracker_${input}"
archive_name="attendance_tracker_${input}_archive.tar.gz"

trap cleanup_on_interrupt SIGINT

setup_directories
update_config
run_health_checks
final
