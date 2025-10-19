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
    exit $error_code
}
trap 'error_exit ${LINENO} $?' ERR

# Default PATH for cron and non-interactive sessions
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${PATH:-}"

# Cron-safe logging controls
NO_COLOR="${NO_COLOR:-}"     # Set to any value to disable ANSI colors
QUIET_MODE="${QUIET_MODE:-false}"  # Set to true to reduce stdout (cron)

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
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
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

# Initialize logging
log_performance "INFO" "Script $(basename "$0") started with enhanced optimizations"

# Acquire lock to prevent overlap
acquire_lock
trap 'release_lock' EXIT

test_log "INFO" "Testing function: log"
test_function_exists "log"
test_function_syntax "log"
echo ""

# Test success
test_log "INFO" "Testing function: success"
test_function_exists "success"
test_function_syntax "success"

# Optimized search function with timeout protection
optimized_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-30}"
    
    for tool in rg ag awk grep; do
        if command -v "$tool" >/dev/null 2>&1; then
            case "$tool" in
                "rg") timeout "$timeout" rg --color=never "$pattern" "$file" 2>/dev/null && return 0 ;;
                "ag") timeout "$timeout" ag --nocolor "$pattern" "$file" 2>/dev/null && return 0 ;;
                "awk") timeout "$timeout" awk "/$pattern/" "$file" 2>/dev/null && return 0 ;;
                "grep") timeout "$timeout" grep "$pattern" "$file" 2>/dev/null && return 0 ;;
            esac
        fi
    done
    return 1
}

echo ""

# Test error
test_log "INFO" "Testing function: error"
test_function_exists "error"
test_function_syntax "error"
echo ""

# Test warn
test_log "INFO" "Testing function: warn"
test_function_exists "warn"
test_function_syntax "warn"
echo ""

# Test info
test_log "INFO" "Testing function: info"
test_function_exists "info"
test_function_syntax "info"
echo ""

# Test show_banner
test_log "INFO" "Testing function: show_banner"
test_function_exists "show_banner"
test_function_syntax "show_banner"
echo ""

# Test show_interactive_menu
test_log "INFO" "Testing function: show_interactive_menu"
test_function_exists "show_interactive_menu"
test_function_syntax "show_interactive_menu"
echo ""

# Test check_environment
test_log "INFO" "Testing function: check_environment"
test_function_exists "check_environment"
test_function_syntax "check_environment"
echo ""

# Test full_health_check
test_log "INFO" "Testing function: full_health_check"
test_function_exists "full_health_check"
test_function_syntax "full_health_check"
echo ""

# Test directory_check
test_log "INFO" "Testing function: directory_check"
test_function_exists "directory_check"
test_function_syntax "directory_check"
echo ""

# Test server_api_check
test_log "INFO" "Testing function: server_api_check"
test_function_exists "server_api_check"
test_function_syntax "server_api_check"
echo ""

# Test data_validation
test_log "INFO" "Testing function: data_validation"
test_function_exists "data_validation"
test_function_syntax "data_validation"
echo ""

# Test github_pages_check
test_log "INFO" "Testing function: github_pages_check"
test_function_exists "github_pages_check"
test_function_syntax "github_pages_check"
echo ""

# Test performance_analysis
test_log "INFO" "Testing function: performance_analysis"
test_function_exists "performance_analysis"
test_function_syntax "performance_analysis"
echo ""

# Test security_check
test_log "INFO" "Testing function: security_check"
test_function_exists "security_check"
test_function_syntax "security_check"
echo ""

# Test generate_health_report
test_log "INFO" "Testing function: generate_health_report"
test_function_exists "generate_health_report"
test_function_syntax "generate_health_report"
echo ""

# Test show_help
test_log "INFO" "Testing function: show_help"
test_function_exists "show_help"
test_function_syntax "show_help"
echo ""

# Test directory_check_silent
test_log "INFO" "Testing function: directory_check_silent"
test_function_exists "directory_check_silent"
test_function_syntax "directory_check_silent"
echo ""

# Test server_check_silent
test_log "INFO" "Testing function: server_check_silent"
test_function_exists "server_check_silent"
test_function_syntax "server_check_silent"
echo ""

# Test api_check_silent
test_log "INFO" "Testing function: api_check_silent"
test_function_exists "api_check_silent"
test_function_syntax "api_check_silent"
echo ""

# Test data_validation_silent
test_log "INFO" "Testing function: data_validation_silent"
test_function_exists "data_validation_silent"
test_function_syntax "data_validation_silent"
echo ""

# Test github_pages_check_silent
test_log "INFO" "Testing function: github_pages_check_silent"
test_function_exists "github_pages_check_silent"
test_function_syntax "github_pages_check_silent"
echo ""

# Test performance_check_silent
test_log "INFO" "Testing function: performance_check_silent"
test_function_exists "performance_check_silent"
test_function_syntax "performance_check_silent"
echo ""

# Test security_check_silent
test_log "INFO" "Testing function: security_check_silent"
test_function_exists "security_check_silent"
test_function_syntax "security_check_silent"
echo ""

# Test exit_program
test_log "INFO" "Testing function: exit_program"
test_function_exists "exit_program"
test_function_syntax "exit_program"
echo ""

# Test main
test_log "INFO" "Testing function: main"
test_function_exists "main"
test_function_syntax "main"
echo ""

# Test Summary
echo "📊 Test Summary"
echo "=============="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $PASSED_TESTS"
echo "Failed: $FAILED_TESTS"
echo "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"

if [[ $FAILED_TESTS -gt 0 ]]; then
    echo ""
    echo "🚨 Some tests failed. Check the output above for details."
    exit 1
else
    echo ""
    echo "✅ All tests passed!"
    exit 0
fi
