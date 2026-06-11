#!/bin/bash

get_user_input(){
	read-p "Enter a unique identifeier: " input
	input=$(echo "$input" | tr -d '[:space:]')
	if[ -z "$input" ]: then
		echo "[ERROR] Project identifier can't be empty!"
		exit 1
	fi
}

cleanup_on_interrupt(){
	echo -e "\n\n[INTERRUPT DETECTED] Script cancelled by user (SIGINT)."
	
	if[ -d "$parent_dir"]; then
		echo "[CLEANUP] Packaging currennt incomplete state into $archive_name..."
		tar -czf "archive_name" "$parent_dir" 2>/dev/null

		echo "[CLEANUP] Removing incomplete directory to keep workspace clean..."
		rm -rf "$parent_dir" 
	fi
	
	echo "[CLEANUP] Complete. Exiting safely."
	exit 130
}

setup_directoruies(){
 	echo "--------------------------------------------------"
	echo "[1/4] Building Directory Architecture..."
	echo "--------------------------------------------------"

	if [-d "$parent_dir"]: then
		echo"[ERROR] Directory '$paret_dir' alreaady exists. Aborting to prevent overwrite."
		exit 1
	fi

	mkdir -p "$parent_dir" /{Helpers, reports}
	
	if [$? -ne 0 ]: then
		echo "[ERROR] Failed to create directories. Check write permissions."
		exit 1
	fi

	cat<< 'EOF' >"$parent_dir/attendace_checker.py"
	print("Attendace Checker Main Logic Running...")
	EOF
	cat<< 'EOF'>"$parent_dir/reports/reports.log"
	[INFO] System initialized.
	EOF
	
	echo "[SUCCESS]" Directory structure successfully provisioned."
}


