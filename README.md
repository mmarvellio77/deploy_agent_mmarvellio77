# deploy_agent_mmarvellio77 — Automated Project Bootstrapper

A shell script that bootstraps the **Student Attendance Tracker** workspace with one command.

---

## Prerequisites

| Tool | Required? | Notes |
|------|-----------|-------|
| `bash` | ✅ Yes | Version 4+ recommended |
| `python3` | Optional | Needed to *run* the tracker; the script will warn if missing |
| `tar` | ✅ Yes | Used to create the archive on interrupt |
| `sed` | ✅ Yes | Used for in-place config editing |

---

## How to Run

```bash
# 1. Clone the repo
git clone https://github.com/mmarvellio77/deploy_agent_mmarvellio77.git
cd deploy_agent_mmarvellio77

# 2. Make the script executable
chmod +x setup_project.sh
# Note: all source files (attendance_checker.py, assets.csv, config.json, reports.log)
# are generated automatically by the script — no need to download them separately

# 3. Run it
./setup_project.sh
```

You will be prompted for:
- A **project identifier** (letters, numbers, underscores only)
- Whether you want to **update the attendance thresholds** (Warning % and Failure %)

The script will then:
1. Create `attendance_tracker_<identifier>/` with the required structure
2. Populate all source files
3. Optionally update `config.json` thresholds via `sed`
4. Perform an environment health check (python3 + directory structure)

---

## Project Structure Created

```
attendance_tracker_<identifier>/
├── attendance_checker.py   ← Main Python logic
├── Helpers/
│   ├── assets.csv          ← Student records
│   └── config.json         ← Threshold configuration
└── reports/
    └── reports.log         ← Report output (appended on each run)
```

---

## How to Trigger the Archive Feature

The archive feature is triggered by pressing **Ctrl+C** at any point during the script's execution.

**What happens:**

1. The script catches the `SIGINT` signal via a `trap`.
2. It bundles the current (incomplete) project directory into:
   ```
   attendance_tracker_<identifier>_archive.tar.gz
   ```
3. It then **deletes** the incomplete `attendance_tracker_<identifier>/` directory to keep your workspace clean.
4. The script exits cleanly with a status code of `130`.

**Example:**

```
$ ./setup_project.sh
Enter a project identifier: demo
Creating project directory structure...
^C                          ← press Ctrl+C here
[WARN]  Interrupt received! Cleaning up...
[INFO]  Archiving incomplete project to 'attendance_tracker_demo_archive.tar.gz' ...
[OK]    Archive created: attendance_tracker_demo_archive.tar.gz
[INFO]  Removing incomplete project directory 'attendance_tracker_demo' ...
[OK]    Incomplete directory removed.
[ERROR] Setup was cancelled. Exiting.
```

To inspect the archive:
```bash
tar -tzf attendance_tracker_demo_archive.tar.gz
```

To restore it:
```bash
tar -xzf attendance_tracker_demo_archive.tar.gz
```

---

## Running the Attendance Tracker

After a successful setup:

```bash
# Run the Python tracker
python3 attendance_tracker_<identifier>/attendance_checker.py

# View the generated report
cat attendance_tracker_<identifier>/reports/reports.log
```

---

## Input Validation

The script validates all user input before proceeding:

| Input | Validation |
|-------|-----------|
| Project identifier | Must match `^[a-zA-Z0-9_]+$` — no spaces or special characters |
| Warning threshold | Must be a whole number between 1 and 100 |
| Failure threshold | Must be a whole number between 1 and 100 **and** strictly less than the Warning threshold |

---

## Notes

- If the target directory already exists, the script will ask before overwriting it.
- The `sed` backup file (`.bak`) is automatically removed after each config update.
- The script uses `set -euo pipefail` for strict error handling throughout.

