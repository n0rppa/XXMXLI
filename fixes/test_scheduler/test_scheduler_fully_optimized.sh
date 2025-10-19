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


# ================================================================
# XXMXLI Automated Testing Scheduler v1.0
# Automated periodic testing with notifications
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_SUITE="$SCRIPT_DIR/comprehensive_test_suite.sh"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
SCHEDULER_LOG="$LOG_DIR/test_scheduler.log"

# Load configuration
load_scheduler_config() {
    # Default values
    SCHEDULE_INTERVAL_HOURS=24
    RUN_COMPREHENSIVE_TESTS=true
    RUN_PERFORMANCE_TESTS=true
    RUN_SECURITY_TESTS=true
    ENABLE_NOTIFICATIONS=true
    MAX_LOG_RETENTION_DAYS=30
    ALERT_ON_FAILURES=true
    
    # Try to load from config files
    if [[ -f "$CONFIG_DIR/test_scheduler.json" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_DIR/test_scheduler.json" >/dev/null 2>&1; then
            SCHEDULE_INTERVAL_HOURS=$(jq -r '.schedule_interval_hours // 24' "$CONFIG_DIR/test_scheduler.json")
            RUN_COMPREHENSIVE_TESTS=$(jq -r '.run_comprehensive_tests // true' "$CONFIG_DIR/test_scheduler.json")
            ENABLE_NOTIFICATIONS=$(jq -r '.enable_notifications // true' "$CONFIG_DIR/test_scheduler.json")
        fi
    elif [[ -f "$CONFIG_DIR/test_scheduler.conf" ]]; then
        source "$CONFIG_DIR/test_scheduler.conf" 2>/dev/null
    fi
}

# Enhanced logging
log_scheduler() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "[$timestamp] $level: $message" >> "$SCHEDULER_LOG"
    
    case "$level" in
        "SUCCESS") echo "✅ $message" ;;
        "ERROR") echo "❌ $message" ;;
        "WARNING") echo "⚠️ $message" ;;
        "INFO") echo "ℹ️ $message" ;;
        *) echo "$message" ;;
    esac
}

# Run scheduled tests
run_scheduled_tests() {
    log_scheduler "INFO" "Starting scheduled test execution"
    
    local test_start_time=$(date +%s)
    local test_failures=0
    local test_results_dir="$SCRIPT_DIR/tests/results"
    local latest_report=""
    
    # Run comprehensive tests if enabled
    if [[ "$RUN_COMPREHENSIVE_TESTS" == true ]]; then
        log_scheduler "INFO" "Running comprehensive test suite"
        
        if "$TEST_SUITE" --full >/dev/null 2>&1; then
            log_scheduler "SUCCESS" "Comprehensive tests completed successfully"
        else
            log_scheduler "ERROR" "Comprehensive tests failed"
            ((test_failures++))
        fi
        
        # Find the latest report
        if [[ -d "$test_results_dir" ]]; then
            latest_report=$(ls -t "$test_results_dir"/test_summary_*.txt 2>/dev/null | head -1)
        fi
    fi
    
    # Run performance tests separately if configured
    if [[ "$RUN_PERFORMANCE_TESTS" == true ]]; then
        log_scheduler "INFO" "Running performance benchmark"
        
        if "$TEST_SUITE" --performance >/dev/null 2>&1; then
            log_scheduler "SUCCESS" "Performance tests completed"
        else
            log_scheduler "WARNING" "Performance tests had issues"
        fi
    fi
    
    # Run security tests separately if configured
    if [[ "$RUN_SECURITY_TESTS" == true ]]; then
        log_scheduler "INFO" "Running security validation"
        
        if "$TEST_SUITE" --security >/dev/null 2>&1; then
            log_scheduler "SUCCESS" "Security tests completed"
        else
            log_scheduler "WARNING" "Security tests found issues"
        fi
    fi
    
    local test_end_time=$(date +%s)
    local test_duration=$((test_end_time - test_start_time))
    
    # Generate summary
    {
        echo "AUTOMATED TEST EXECUTION SUMMARY"
        echo "==============================="
        echo "Execution Time: $(date)"
        echo "Duration: ${test_duration} seconds"
        echo "Failures: $test_failures"
        echo ""
        if [[ -n "$latest_report" && -f "$latest_report" ]]; then
            echo "LATEST TEST RESULTS:"
            cat "$latest_report"
        fi
    } > "$LOG_DIR/last_scheduled_test.txt"
    
    # Send notifications if enabled
    if [[ "$ENABLE_NOTIFICATIONS" == true ]]; then
        send_test_notification "$test_failures" "$test_duration"
    fi
    
    # Alert on failures if configured
    if [[ "$ALERT_ON_FAILURES" == true && $test_failures -gt 0 ]]; then
        log_scheduler "ERROR" "Automated tests detected $test_failures failure(s) - manual review required"
        # Here you could add email notifications, webhook calls, etc.
    fi
    
    log_scheduler "INFO" "Scheduled test execution completed (Duration: ${test_duration}s, Failures: $test_failures)"
}

# Send notifications (basic implementation)
send_test_notification() {
    local failures="$1"
    local duration="$2"
    
    local notification_file="$LOG_DIR/test_notification_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "🧪 XXMXLI Automated Test Notification"
        echo "===================================="
        echo "Timestamp: $(date)"
        echo "Test Duration: ${duration} seconds"
        echo "Test Failures: $failures"
        echo ""
        if [[ $failures -eq 0 ]]; then
            echo "✅ All tests passed successfully!"
            echo "🎉 Your optimized scripts are running perfectly."
        else
            echo "⚠️ Some tests failed or had warnings."
            echo "🔧 Review required - check test reports for details."
        fi
        echo ""
        echo "📊 Latest test report: $LOG_DIR/last_scheduled_test.txt"
        echo "🔍 Detailed logs: $SCHEDULER_LOG"
    } > "$notification_file"
    
    log_scheduler "INFO" "Test notification saved: $notification_file"
    
    # Basic desktop notification if available
    if command -v notify-send >/dev/null 2>&1; then
        if [[ $failures -eq 0 ]]; then
            notify-send "XXMXLI Tests" "✅ All automated tests passed!" -t 5000
        else
            notify-send "XXMXLI Tests" "⚠️ $failures test(s) failed - review needed" -t 10000
        fi
    fi
}

# Schedule tests using cron
schedule_automatic_tests() {
    log_scheduler "INFO" "Setting up automatic test scheduling"
    
    local cron_entry="0 */$SCHEDULE_INTERVAL_HOURS * * * $SCRIPT_DIR/test_scheduler.sh --run-scheduled >/dev/null 2>&1"
    local temp_cron=$(mktemp)
    
    # Get current crontab
    crontab -l 2>/dev/null | grep -v "test_scheduler.sh" > "$temp_cron"
    
    # Add our cron entry
    echo "$cron_entry" >> "$temp_cron"
    
    # Install new crontab
    if crontab "$temp_cron" 2>/dev/null; then
        log_scheduler "SUCCESS" "Automatic testing scheduled every $SCHEDULE_INTERVAL_HOURS hours"
        echo "📅 Automatic testing scheduled:"
        echo "   Interval: Every $SCHEDULE_INTERVAL_HOURS hours"
        echo "   Command: $cron_entry"
    else
        log_scheduler "ERROR" "Failed to schedule automatic tests"
        echo "❌ Failed to schedule automatic tests"
        echo "💡 You may need to manually add this to your crontab:"
        echo "   $cron_entry"
    fi
    
    rm -f "$temp_cron"
}

# Remove scheduled tests
unschedule_automatic_tests() {
    log_scheduler "INFO" "Removing automatic test scheduling"
    
    local temp_cron=$(mktemp)
    
    # Get current crontab without our entries
    crontab -l 2>/dev/null | grep -v "test_scheduler.sh" > "$temp_cron"
    
    # Install cleaned crontab
    if crontab "$temp_cron" 2>/dev/null; then
        log_scheduler "SUCCESS" "Automatic testing unscheduled"
        echo "✅ Automatic testing has been unscheduled"
    else
        log_scheduler "WARNING" "Failed to remove automatic tests from crontab"
        echo "⚠️ Failed to remove automatic tests - please check crontab manually"
    fi
    
    rm -f "$temp_cron"
}

# Clean up old logs and reports
cleanup_old_files() {
    log_scheduler "INFO" "Cleaning up old test files"
    
    local files_cleaned=0
    
    # Clean old log files
    if [[ -d "$LOG_DIR" ]]; then
        while IFS= read -r -d '' file; do
            rm -f "$file"
            ((files_cleaned++))
        done < <(find "$LOG_DIR" -name "*.log.*" -mtime +$MAX_LOG_RETENTION_DAYS -print0 2>/dev/null)
    fi
    
    # Clean old test reports
    if [[ -d "$SCRIPT_DIR/tests/results" ]]; then
        # Keep last 10 reports
        cd "$SCRIPT_DIR/tests/results" 2>/dev/null
        ls -t test_summary_*.txt 2>/dev/null | tail -n +11 | xargs rm -f
        ls -t comprehensive_test_report_*.html 2>/dev/null | tail -n +11 | xargs rm -f
        cd - >/dev/null
    fi
    
    # Clean old notification files
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((files_cleaned++))
    done < <(find "$LOG_DIR" -name "test_notification_*.txt" -mtime +7 -print0 2>/dev/null)
    
    log_scheduler "SUCCESS" "Cleanup completed - $files_cleaned old files removed"
}

# Show scheduler status
show_scheduler_status() {
    echo ""
    echo "🔍 XXMXLI Test Scheduler Status"
    echo "==============================="
    echo ""
    
    # Show configuration
    echo "📋 Configuration:"
    echo "   Schedule Interval: $SCHEDULE_INTERVAL_HOURS hours"
    echo "   Comprehensive Tests: $RUN_COMPREHENSIVE_TESTS"
    echo "   Performance Tests: $RUN_PERFORMANCE_TESTS"
    echo "   Security Tests: $RUN_SECURITY_TESTS"
    echo "   Notifications: $ENABLE_NOTIFICATIONS"
    echo ""
    
    # Check if scheduled
    if crontab -l 2>/dev/null | grep -q "test_scheduler.sh"; then
        echo "📅 Scheduling Status: ✅ ACTIVE"
        echo "   Next execution: $(crontab -l 2>/dev/null | grep test_scheduler.sh | head -1)"
    else
        echo "📅 Scheduling Status: ❌ NOT SCHEDULED"
    fi
    echo ""
    
    # Show recent activity
    if [[ -f "$LOG_DIR/last_scheduled_test.txt" ]]; then
        echo "📊 Last Test Execution:"
        head -10 "$LOG_DIR/last_scheduled_test.txt"
    else
        echo "📊 No recent test executions found"
    fi
    echo ""
}

# Interactive menu
show_scheduler_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 XXMXLI TEST SCHEDULER                       ║"
    echo "║              Automated Testing Management                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "⏰ SCHEDULER OPTIONS"
    echo "================================================================"
    echo ""
    echo "1) 🚀 Run Tests Now"
    echo "2) 📅 Schedule Automatic Tests"
    echo "3) ❌ Unschedule Automatic Tests"
    echo "4) 🔍 Show Scheduler Status"
    echo "5) 🧹 Clean Up Old Files"
    echo "6) ⚙️ Configure Scheduler"
    echo "0) 🚪 Exit"
    echo ""
    
    local choice
    read -p "Choose option [0-6]: " choice
    
    case "$choice" in
        1) run_scheduled_tests ;;
        2) schedule_automatic_tests ;;
        3) unschedule_automatic_tests ;;
        4) show_scheduler_status ;;
        5) cleanup_old_files ;;
        6) 
            echo "📝 Configuration files:"
            echo "   JSON: $CONFIG_DIR/test_scheduler.json"
            echo "   CONF: $CONFIG_DIR/test_scheduler.conf"
            echo ""
            echo "💡 Edit these files to customize scheduler behavior"
            ;;
        0) log_scheduler "INFO" "Exiting test scheduler"; exit 0 ;;
        *) echo "❌ Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_scheduler_menu
}

# Main execution
main() {
    load_scheduler_config
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    case "${1:-}" in
        "--run-scheduled")
            run_scheduled_tests
            ;;
        "--schedule")
            schedule_automatic_tests
            ;;
        "--unschedule")
            unschedule_automatic_tests
            ;;
        "--status")
            show_scheduler_status
            ;;
        "--cleanup")
            cleanup_old_files
            ;;
        "--help"|"-h")
            echo "XXMXLI Test Scheduler v1.0"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --run-scheduled  Run scheduled tests now"
            echo "  --schedule       Set up automatic test scheduling"
            echo "  --unschedule     Remove automatic test scheduling"
            echo "  --status         Show scheduler status"
            echo "  --cleanup        Clean up old files"
            echo "  --help, -h       Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            show_scheduler_menu
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Trap for cleanup
trap 'log_scheduler "INFO" "Test scheduler terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
