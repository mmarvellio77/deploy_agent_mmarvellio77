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
	
	cp "$(dirname "$0")/config.json" "$parent_dir/Helpers/config.json"
	cp "$(dirname "$0")/assets.csv" "$parent_dir/Helpers/assets.csv"
	cp "$(dirname "$0")/attendance_checker.py" "$parent_dir/attendance_checker.py"	
	
	if [ $? -ne 0 ]; then
		echo "[ERROR] Failed to create directories. Check write permissions."
		exit 1
	fi


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
