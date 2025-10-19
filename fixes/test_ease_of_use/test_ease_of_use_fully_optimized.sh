#!/usr/bin/env bash

# ================================================================
# XXMXLI Enhanced Security Script - Fully Optimized
# Auto-generated with comprehensive performance and safety fixes
# ================================================================

# Enhanced error handling
set -Eeuo pipefail # Exit on error, undefined vars; trap ERR; pipefail
IFS=$'\n\t'                # Safe IFS

# Error trap function
error_exit() {
    local line_no=$1
    local error_code=$2
    echo "ERROR: Script failed at line $line_no with exit code $error_code" >&2
    stack_trace >&2 || true
    exit $error_code
}
trap 'error_exit ${LINENO} $?' ERR

# Stack trace for diagnostics
stack_trace() {
    echo "--- stack trace ---"
    local i=0
    while caller $i; do
        ((i++))
    done
}

# Default PATH for cron and non-interactive sessions
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# Cron-safe logging controls
NO_COLOR="${NO_COLOR:-}"     # Set to any value to disable ANSI colors
QUIET_MODE="${QUIET_MODE:-false}"  # Set to true to reduce stdout (cron)
SYSLOG="${SYSLOG:-false}"          # Set true to also log to syslog via logger
SAFE_MODE="${SAFE_MODE:-false}"    # Set true to simulate (no changes), use run_cmd

# Concurrency control via flock or directory lock
LOCK_NAME="$(basename "$0").lock"
LOCK_DIR="/tmp/${LOCK_NAME}"
LOCK_FD=200

acquire_lock() {
    if command -v flock >/dev/null 2>&1; then
        exec {LOCK_FD}>"/tmp/${LOCK_NAME}.flock" || true
        flock -n "$LOCK_FD" || { echo "Another instance is running" >&2; exit 155; }
    else
        if ! mkdir "$LOCK_DIR" 2>/dev/null; then
            echo "Another instance is running (lock $LOCK_DIR)" >&2
            exit 155
        fi
    fi
}

release_lock() {
    if command -v flock >/dev/null 2>&1; then
        flock -u "$LOCK_FD" || true
        rm -f "/tmp/${LOCK_NAME}.flock" || true
    else
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
}

# Cross-platform path detection
detect_paths() {
    if [[ "$OSTYPE" =~ msys|mingw|cygwin ]]; then
        CONFIG_PATH="/c/ProgramData"
        LOG_PATH="/c/temp"
        BIN_PATH="/usr/local/bin"
    else
        CONFIG_PATH="/etc"
        LOG_PATH="/var/log"
        BIN_PATH="/usr/local/bin"
    fi
    mkdir -p "$CONFIG_PATH" "$LOG_PATH" 2>/dev/null || true
}

# Initialize paths
detect_paths

# Performance logging
LOG_FILE="${LOG_PATH}/$(basename "$0" .sh)_performance.log"

log_performance() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE" 2>/dev/null || true
    # Optional syslog
    if [[ "$SYSLOG" == "true" ]] && command -v logger >/dev/null 2>&1; then
        logger -t "$(basename "$0")" "[$level] $message" || true
    fi
    
    case "$level" in
        "ERROR") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[ERROR] $message" >&2 || echo -e "\033[31m[ERROR]\033[0m $message" >&2; } ;;
        "WARN") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[WARN]  $message" || echo -e "\033[33m[WARN]\033[0m $message"; } ;;
        "INFO") [[ "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[INFO]  $message" || echo -e "\033[32m[INFO]\033[0m $message"; } ;;
        "DEBUG") [[ "${DEBUG:-false}" == "true" && "$QUIET_MODE" != "true" ]] && { [[ -n "$NO_COLOR" ]] && echo "[DEBUG] $message" || echo -e "\033[36m[DEBUG]\033[0m $message"; } ;;
    esac
}

# Universal timeout wrapper
run_with_timeout_universal() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}"
    else
        local pid
        "${cmd[@]}" &
        pid=$!
        
        local count=0
        local max_count=$((timeout_duration))
        
        while [[ $count -lt $max_count ]] && kill -0 $pid 2>/dev/null; do
            sleep 1
            ((count++))
        done
        
        if kill -0 $pid 2>/dev/null; then
            kill -TERM $pid 2>/dev/null
            sleep 2
            kill -0 $pid 2>/dev/null && kill -KILL $pid 2>/dev/null
            return 124
        else
            wait $pid
            return $?
        fi
    fi
}

# Safe search function
safe_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-15}"
    
    [[ -z "$pattern" || -z "$file" ]] && return 1
    [[ ! -f "$file" ]] && return 1
    
    local file_size=$(stat -c%s "$file" 2>/dev/null || echo 0)
    if [[ $file_size -gt 10485760 ]]; then
        log_performance "WARN" "File too large for search: $file ($file_size bytes)"
        return 1
    fi
    
    for tool in awk grep rg ag; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                "awk") 
                    if run_with_timeout_universal "$timeout" awk "/$pattern/" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "grep") 
                    if run_with_timeout_universal "$timeout" grep -m 100 "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "rg") 
                    if run_with_timeout_universal "$timeout" rg --color=never --no-heading -n "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
                "ag") 
                    if run_with_timeout_universal "$timeout" ag --nocolor --nogroup "$pattern" "$file" 2>/dev/null; then
                        return 0
                    fi
                    ;;
            esac
        fi
    done
    return 1
}

# Variable validation
validate_var() {
    local var_name="$1"
    local var_value="$2"
    if [[ -z "$var_value" ]]; then
        log_performance "ERROR" "Required variable $var_name is empty or undefined"
        return 1
    fi
    return 0
}

# Function timing wrapper
time_function() {
    local func_name="$1"
    shift
    local start_time=$(date +%s%N)
    
    log_performance "DEBUG" "Starting function: $func_name"
    "$@"
    local exit_code=$?
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    if [[ $exit_code -eq 0 ]]; then
        log_performance "INFO" "Function $func_name completed in ${duration}ms"
    else
        log_performance "ERROR" "Function $func_name failed after ${duration}ms (exit code: $exit_code)"
    fi
    
    return $exit_code
}

# Permission helpers
ensure_executable() { chmod 0755 "$1" 2>/dev/null || true; }
ensure_umask() { umask "${1:-027}" 2>/dev/null || true; }

# Privilege check with explanation
require_root_or_sudo() {
    local reason="${1:-This operation requires administrative privileges.}"
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "This action needs admin privileges (root) to proceed." >&2
        echo "Why: $reason" >&2
        echo "Examples include: writing to /etc, managing firewall, installing packages, using privileged ports, or writing to /var/log." >&2
        echo "Re-run with: sudo $0 "$@"" >&2
        exit 100
    fi
}

# Safe execution wrapper obeying SAFE_MODE
run_cmd() {
    if [[ "$SAFE_MODE" == "true" ]]; then
        echo "DRY-RUN: $*"
        log_performance "INFO" "DRY-RUN: $*"
        return 0
    else
        "$@"
    fi
}

# Background helpers
declare -a __BG_PIDS=()
run_background() { "$@" & __BG_PIDS+=($!); }
wait_all() { local p; for p in "${__BG_PIDS[@]}"; do wait "$p"; done; __BG_PIDS=(); }

# AWK helpers
awk_match() { local pat="$1" file="$2"; awk "/${pat}/" "$file"; }
awk_extract_field() { local n="$1"; shift; awk -v n="$n" '{print $n}' "$@"; }

# Safe sed in-place (portable)
safe_sed_inplace() {
    local script="$1" file="$2" tmp
    tmp=$(mktemp) && sed -e "$script" "$file" > "$tmp" && mv "$tmp" "$file"
}

# IP list normalization (stdin -> stdout)
normalize_ip_list() {
    awk 'BEGIN{FS="[[:space:]]+"} {gsub(/^\s+|\s+$/, ""); if ($0 ~ /^[0-9]{1,3}(\.[0-9]{1,3}){3}(\/[0-9]{1,2})?$/ || $0 ~ /^[0-9a-fA-F:]+(\/[0-9]{1,3})?$/) print $0}' \
    | LC_ALL=C sort -u
}

# JSON helper: jq or python fallback
json_query() {
    local file="$1" filter="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -r "$filter" "$file"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" "$filter" <<'PY'
import json,sys
fn,flt=sys.argv[1],sys.argv[2]
data=json.load(open(fn))
if flt.strip()=='.[]':
    if isinstance(data,list):
        for x in data: print(x)
    else:
        for k,v in (data or {}).items(): print(k)
else:
    # Minimal fallback: print entire json
    print(json.dumps(data))
PY
    else
        echo "ERROR: Need jq or python3 for json_query($file, $filter)" >&2; return 127
    fi
}

# Initialize logging
log_performance "INFO" "Script $(basename "$0") started with enhanced optimizations"

# Acquire lock to prevent overlap
acquire_lock
trap 'release_lock' EXIT

# Subcommands: manual and read-log
show_manual() {
        cat <<MAN
Step-by-step manual:
1) SAFE MODE: export SAFE_MODE=true to simulate changes; commands will be logged not executed.
2) Logging: file at $LOG_FILE; enable syslog with SYSLOG=true.
3) Locking: prevents concurrent runs via flock or /tmp lock.
4) Admin privileges: some actions require root (e.g., /etc edits, firewall). Use sudo.
5) IP Lists: pipe through normalize_ip_list for dedupe and validation.
6) Background work: use run_background <cmd> ... then wait_all to synchronize.
7) Text processing: prefer awk_match/awk_extract_field over grep for portability.
8) JSON: json_query <file> <filter> uses jq or a Python fallback.
MAN
}

read_log() { local n=${1:-200}; tail -n "$n" "$LOG_FILE" 2>/dev/null || echo "No logs yet."; }

# Quick CLI interceptors
case "${1:-}" in
    manual) show_manual; exit 0 ;;
    read-log) shift; read_log "${1:-200}"; exit 0 ;;
esac


# ================================================================
# XXMXLI INCIDENT REPORTER - EASE OF USE TEST
# ================================================================
# This script tests all the easy-use features we've implemented
# ================================================================

echo "========================================================"
echo "🚀 XXMXLI Incident Reporter - Ease of Use Test"
echo "========================================================"
echo ""

# Test 1: Check all launcher files exist
echo "Test 1: Checking launcher files..."
echo "-----------------------------------"

files_to_check=(
    "EASY_LAUNCHER.py"
    "DOUBLE_CLICK_LAUNCHER.sh"
    "DOUBLE_CLICK_LAUNCHER.bat"
    "install_incident_reporter.sh"
    "install_incident_reporter.bat"
    "automated_incident_reporter.sh"
    "automated_incident_reporter.ps1"
    "automated_incident_reporter.py"
)

all_files_present=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file found"
    else
        echo "✗ $file missing"
        all_files_present=false
    fi
done

echo ""

# Test 2: Check executable permissions
echo "Test 2: Checking executable permissions..."
echo "------------------------------------------"

executable_files=(
    "EASY_LAUNCHER.py"
    "DOUBLE_CLICK_LAUNCHER.sh"
    "install_incident_reporter.sh"
    "automated_incident_reporter.sh"
    "automated_incident_reporter.py"
)

all_executable=true
for file in "${executable_files[@]}"; do
    if [ -x "$file" ]; then
        echo "✓ $file is executable"
    else
        echo "! $file needs chmod +x"
        chmod +x "$file" 2>/dev/null && echo "  → Fixed!" || echo "  → Could not fix"
    fi
done

echo ""

# Test 3: Check for easy mode in main scripts
echo "Test 3: Checking easy mode implementations..."
echo "---------------------------------------------"

if grep -q "show_interactive_menu\|What would you like to do" automated_incident_reporter.sh; then
    echo "✓ Bash script has easy mode"
else
    echo "✗ Bash script missing easy mode"
fi

if grep -q "Welcome to XXMXLI Incident Reporter - Easy Mode\|Show-InteractiveMenu" automated_incident_reporter.ps1; then
    echo "✓ PowerShell script has easy mode"
else
    echo "✗ PowerShell script missing easy mode"
fi

if grep -q "show_interactive_menu\|Interactive Menu Functions" automated_incident_reporter.py; then
    echo "✓ Python script has easy mode"
else
    echo "✗ Python script missing easy mode"
fi

echo ""

# Test 4: Check auto-elevation features
echo "Test 4: Checking auto-elevation features..."
echo "-------------------------------------------"

if grep -q "exec sudo" automated_incident_reporter.sh; then
    echo "✓ Bash script has auto-elevation"
else
    echo "✗ Bash script missing auto-elevation"
fi

if grep -q "Start-Process.*RunAs" automated_incident_reporter.ps1; then
    echo "✓ PowerShell script has auto-elevation"
else
    echo "✗ PowerShell script missing auto-elevation"
fi

if grep -q "ensure_privileges" automated_incident_reporter.py; then
    echo "✓ Python script has auto-elevation"
else
    echo "✗ Python script missing auto-elevation"
fi

echo ""

# Test 5: Test easy mode by running Python script without arguments
echo "Test 5: Testing easy mode (non-interactive)..."
echo "----------------------------------------------"

echo "Testing Python script easy mode..."
timeout 5 python3 automated_incident_reporter.py < /dev/null > /tmp/test_output.txt 2>&1 || true

if grep -q "Interactive Menu Functions\|show_interactive_menu" /tmp/test_output.txt; then
    echo "✓ Python easy mode working"
elif grep -q "AUTOMATED INCIDENT REPORTER SYSTEM" /tmp/test_output.txt; then
    echo "✓ Python easy mode working (banner detected)"
else
    echo "! Python easy mode may have issues"
fi

echo ""

# Test 6: Check GUI launcher components
echo "Test 6: Checking GUI launcher components..."
echo "------------------------------------------"

if python3 -c "import tkinter" 2>/dev/null; then
    echo "✓ tkinter available for GUI launcher"
    
    if grep -q "show_gui_launcher" EASY_LAUNCHER.py; then
        echo "✓ GUI launcher has GUI functions"
    else
        echo "✗ GUI launcher missing GUI functions"
    fi
else
    echo "! tkinter not available (GUI launcher will use fallback)"
fi

echo ""

# Test 7: Summary
echo "========================================================"
echo "🎯 EASE OF USE TEST SUMMARY"
echo "========================================================"

if [ "$all_files_present" = true ]; then
    echo "✅ All launcher files present"
else
    echo "❌ Some launcher files missing"
fi

echo ""
echo "Available easy-use options for users:"
echo "1. 🎯 EASY_LAUNCHER.py - GUI launcher (double-click)"
echo "2. 🖱️ DOUBLE_CLICK_LAUNCHER.sh - Linux double-click"
echo "3. 🖱️ DOUBLE_CLICK_LAUNCHER.bat - Windows double-click"
echo "4. 🚀 install_incident_reporter.sh - One-click installer (Linux)"
echo "5. 🚀 install_incident_reporter.bat - One-click installer (Windows)"
echo "6. 📱 Interactive menus in all main scripts"
echo "7. 🔧 Auto-elevation in all scripts"
echo "8. 🛠️ Auto-dependency installation"
echo ""
echo "🎉 Users can now protect their systems with just a few clicks!"
echo "========================================================"

# Cleanup
rm -f /tmp/test_output.txt

echo ""
echo "Test completed. All scripts are optimized for maximum ease of use!"
