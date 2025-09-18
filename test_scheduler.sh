#!/bin/bash

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