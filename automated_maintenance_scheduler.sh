#!/bin/bash

# ================================================================
# XXMXLI Automated Maintenance Scheduler v2.0
# Comprehensive security system maintenance with predictive monitoring
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
MAINTENANCE_LOG="$LOG_DIR/automated_maintenance.log"
SCHEDULE_CONFIG="$CONFIG_DIR/maintenance_schedule.conf"

# Setup colors and symbols
setup_output() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1); GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4); PURPLE=$(tput setaf 5); CYAN=$(tput setaf 6)
        WHITE=$(tput setaf 7); BOLD=$(tput bold); NC=$(tput sgr0)
    else
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
        BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'
        WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'
    fi
    
    # Symbols
    if [[ "${LANG:-}" =~ UTF-8 ]] || [[ "${LC_ALL:-}" =~ UTF-8 ]]; then
        CHECK="✅"; CROSS="❌"; WARNING="⚠️"; INFO="ℹ️"; CLOCK="⏰"
        CALENDAR="📅"; GEAR="⚙️"; SHIELD="🛡️"; ROCKET="🚀"; BELL="🔔"
    else
        CHECK="[OK]"; CROSS="[ERR]"; WARNING="[WARN]"; INFO="[INFO]"
        CLOCK="[TIME]"; CALENDAR="[SCHED]"; GEAR="[MAINT]"; SHIELD="[SEC]"
        ROCKET="[PERF]"; BELL="[ALERT]"
    fi
}

# Enhanced logging
log_maintenance() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    mkdir -p "$LOG_DIR" 2>/dev/null
    echo "[$timestamp] $level: $message" >> "$MAINTENANCE_LOG"
    
    case "$level" in
        "SUCCESS") echo -e "${GREEN}${CHECK}${NC} $message" ;;
        "ERROR") echo -e "${RED}${CROSS}${NC} $message" >&2 ;;
        "WARNING") echo -e "${YELLOW}${WARNING}${NC} $message" ;;
        "INFO") echo -e "${CYAN}${INFO}${NC} $message" ;;
        "SCHEDULE") echo -e "${BLUE}${CALENDAR}${NC} $message" ;;
        "MAINTENANCE") echo -e "${PURPLE}${GEAR}${NC} $message" ;;
        "SECURITY") echo -e "${BLUE}${SHIELD}${NC} $message" ;;
        "PERFORMANCE") echo -e "${GREEN}${ROCKET}${NC} $message" ;;
        "ALERT") echo -e "${RED}${BELL}${NC} $message" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

# Load maintenance configuration
load_maintenance_config() {
    # Default settings
    DAILY_ENABLED=true
    WEEKLY_ENABLED=true
    MONTHLY_ENABLED=true
    ALERT_EMAIL=""
    CRITICAL_THRESHOLD=80
    WARNING_THRESHOLD=60
    AUTO_FIX_ENABLED=false
    BACKUP_ENABLED=true
    
    if [[ -f "$SCHEDULE_CONFIG" ]]; then
        source "$SCHEDULE_CONFIG" 2>/dev/null
        log_maintenance "SUCCESS" "Loaded maintenance configuration"
    else
        log_maintenance "INFO" "Using default maintenance configuration"
        create_default_config
    fi
}

# Create default configuration
create_default_config() {
    mkdir -p "$CONFIG_DIR" 2>/dev/null
    
    cat > "$SCHEDULE_CONFIG" << 'EOF'
# XXMXLI Automated Maintenance Configuration

# Schedule Settings
DAILY_ENABLED=true
WEEKLY_ENABLED=true  
MONTHLY_ENABLED=true

# Monitoring Thresholds
CRITICAL_THRESHOLD=80  # Percentage for critical alerts
WARNING_THRESHOLD=60   # Percentage for warning alerts

# Automation Settings
AUTO_FIX_ENABLED=false # Auto-fix non-critical issues
BACKUP_ENABLED=true    # Create backups before fixes

# Notification Settings
ALERT_EMAIL=""         # Email for critical alerts (optional)
ALERT_WEBHOOK=""       # Webhook URL for alerts (optional)

# Maintenance Tasks
DAILY_TASKS="system_check dependency_validation log_rotation"
WEEKLY_TASKS="security_scan compatibility_check performance_analysis"
MONTHLY_TASKS="full_optimization security_audit system_hardening"

# Retention Settings
LOG_RETENTION_DAYS=30
BACKUP_RETENTION_DAYS=90
REPORT_RETENTION_DAYS=180
EOF

    log_maintenance "SUCCESS" "Created default maintenance configuration: $SCHEDULE_CONFIG"
}

# Daily maintenance tasks
run_daily_maintenance() {
    log_maintenance "MAINTENANCE" "Starting daily maintenance tasks"
    
    local issues_found=0
    local start_time=$(date +%s)
    
    # System health check
    log_maintenance "INFO" "Running system health check..."
    if ! ./comprehensive_system_status.sh >/dev/null 2>&1; then
        log_maintenance "WARNING" "System health check completed with warnings"
        ((issues_found++))
    else
        log_maintenance "SUCCESS" "System health check passed"
    fi
    
    # Dependency validation
    log_maintenance "INFO" "Validating dependencies..."
    if ! ./enhanced_dependency_manager.sh --check-only >/dev/null 2>&1; then
        log_maintenance "WARNING" "Dependency validation found issues"
        ((issues_found++))
    else
        log_maintenance "SUCCESS" "All dependencies validated"
    fi
    
    # Log rotation
    log_maintenance "INFO" "Performing log rotation..."
    if [[ -d "$LOG_DIR" ]]; then
        find "$LOG_DIR" -name "*.log" -size +10M -exec gzip {} \; 2>/dev/null
        find "$LOG_DIR" -name "*.log.gz" -mtime +${LOG_RETENTION_DAYS:-30} -delete 2>/dev/null
        log_maintenance "SUCCESS" "Log rotation completed"
    fi
    
    # Quick security scan
    log_maintenance "INFO" "Running quick security scan..."
    local security_issues=0
    
    # Check for suspicious processes
    if pgrep -f "nc.*-l\|ncat.*-l" >/dev/null 2>&1; then
        log_maintenance "ALERT" "Suspicious listening processes detected"
        ((security_issues++))
    fi
    
    # Check disk usage
    local disk_usage=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo 0)
    if [[ $disk_usage -gt 90 ]]; then
        log_maintenance "ALERT" "Critical disk usage: ${disk_usage}%"
        ((security_issues++))
    elif [[ $disk_usage -gt 80 ]]; then
        log_maintenance "WARNING" "High disk usage: ${disk_usage}%"
    fi
    
    # Check memory usage
    local memory_usage=$(free 2>/dev/null | awk 'NR==2{printf "%.0f", $3*100/$2}' || echo 0)
    if [[ $memory_usage -gt 90 ]]; then
        log_maintenance "ALERT" "Critical memory usage: ${memory_usage}%"
        ((security_issues++))
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_maintenance "SUCCESS" "Daily maintenance completed in ${duration}s"
    log_maintenance "INFO" "Issues found: $issues_found, Security alerts: $security_issues"
    
    # Alert if critical issues found
    if [[ $security_issues -gt 0 ]]; then
        send_alert "CRITICAL" "Daily maintenance found $security_issues critical security issues"
    fi
    
    return $issues_found
}

# Weekly maintenance tasks
run_weekly_maintenance() {
    log_maintenance "MAINTENANCE" "Starting weekly maintenance tasks"
    
    local start_time=$(date +%s)
    
    # Full security scan
    log_maintenance "SECURITY" "Running comprehensive security scan..."
    ./security_debug_optimizer.sh --debug >/dev/null 2>&1
    
    # Compatibility check
    log_maintenance "INFO" "Running cross-platform compatibility check..."
    ./enhanced_dependency_manager.sh --compatibility >/dev/null 2>&1
    
    # Performance analysis
    log_maintenance "PERFORMANCE" "Analyzing system performance..."
    ./comprehensive_system_status.sh >/dev/null 2>&1
    
    # Update security databases
    log_maintenance "SECURITY" "Updating security databases..."
    if command -v nmap >/dev/null 2>&1; then
        nmap --script-updatedb >/dev/null 2>&1 || log_maintenance "WARNING" "Failed to update nmap scripts"
    fi
    
    # Backup critical files
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        log_maintenance "INFO" "Creating weekly backup..."
        create_system_backup "weekly"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_maintenance "SUCCESS" "Weekly maintenance completed in ${duration}s"
}

# Monthly maintenance tasks
run_monthly_maintenance() {
    log_maintenance "MAINTENANCE" "Starting monthly maintenance tasks"
    
    local start_time=$(date +%s)
    
    # Full system optimization
    log_maintenance "INFO" "Running full system optimization..."
    ./advanced_script_fixer.sh --all-security >/dev/null 2>&1
    
    # Security audit
    log_maintenance "SECURITY" "Performing security audit..."
    
    # Check for outdated packages
    if command -v apt >/dev/null 2>&1; then
        local updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $updates -gt 20 ]]; then
            log_maintenance "WARNING" "Many outdated packages: $updates updates available"
        fi
    fi
    
    # System hardening check
    log_maintenance "SECURITY" "Checking system hardening..."
    
    # Check SSH configuration
    if [[ -f /etc/ssh/sshd_config ]]; then
        if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
            log_maintenance "WARNING" "SSH password authentication enabled"
        fi
    fi
    
    # Generate comprehensive report
    log_maintenance "INFO" "Generating monthly comprehensive report..."
    ./comprehensive_system_status.sh >/dev/null 2>&1
    
    # Cleanup old files
    log_maintenance "INFO" "Cleaning up old files..."
    cleanup_old_files
    
    # Full backup
    if [[ "$BACKUP_ENABLED" == "true" ]]; then
        log_maintenance "INFO" "Creating monthly backup..."
        create_system_backup "monthly"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_maintenance "SUCCESS" "Monthly maintenance completed in ${duration}s"
}

# Create system backup
create_system_backup() {
    local backup_type="$1"
    local backup_dir="$SCRIPT_DIR/backups/${backup_type}_$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$backup_dir" 2>/dev/null
    
    # Backup configuration files
    [[ -d "$CONFIG_DIR" ]] && cp -r "$CONFIG_DIR" "$backup_dir/"
    
    # Backup optimized scripts
    [[ -d "$SCRIPT_DIR/fixes" ]] && cp -r "$SCRIPT_DIR/fixes" "$backup_dir/"
    
    # Backup important logs (last 7 days)
    if [[ -d "$LOG_DIR" ]]; then
        mkdir -p "$backup_dir/logs"
        find "$LOG_DIR" -name "*.log" -mtime -7 -exec cp {} "$backup_dir/logs/" \; 2>/dev/null
    fi
    
    # Backup reports
    if [[ -d "$SCRIPT_DIR/reports" ]]; then
        mkdir -p "$backup_dir/reports"
        find "$SCRIPT_DIR/reports" -name "*.json" -mtime -30 -exec cp {} "$backup_dir/reports/" \; 2>/dev/null
    fi
    
    # Compress backup
    if command -v tar >/dev/null 2>&1; then
        tar -czf "${backup_dir}.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")" 2>/dev/null
        rm -rf "$backup_dir" 2>/dev/null
        log_maintenance "SUCCESS" "Created $backup_type backup: ${backup_dir}.tar.gz"
    else
        log_maintenance "SUCCESS" "Created $backup_type backup: $backup_dir"
    fi
}

# Cleanup old files
cleanup_old_files() {
    # Cleanup old logs
    [[ -d "$LOG_DIR" ]] && find "$LOG_DIR" -name "*.log.gz" -mtime +${LOG_RETENTION_DAYS:-30} -delete 2>/dev/null
    
    # Cleanup old reports  
    [[ -d "$SCRIPT_DIR/reports" ]] && find "$SCRIPT_DIR/reports" -name "*.json" -mtime +${REPORT_RETENTION_DAYS:-180} -delete 2>/dev/null
    
    # Cleanup old backups
    [[ -d "$SCRIPT_DIR/backups" ]] && find "$SCRIPT_DIR/backups" -name "*.tar.gz" -mtime +${BACKUP_RETENTION_DAYS:-90} -delete 2>/dev/null
    
    log_maintenance "SUCCESS" "Cleanup completed"
}

# Send alert notification
send_alert() {
    local severity="$1"
    local message="$2"
    
    log_maintenance "ALERT" "[$severity] $message"
    
    # Email notification (if configured)
    if [[ -n "$ALERT_EMAIL" ]] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "XXMXLI Security Alert [$severity]" "$ALERT_EMAIL" 2>/dev/null
    fi
    
    # Webhook notification (if configured)
    if [[ -n "$ALERT_WEBHOOK" ]] && command -v curl >/dev/null 2>&1; then
        curl -X POST "$ALERT_WEBHOOK" \
             -H "Content-Type: application/json" \
             -d "{\"severity\":\"$severity\",\"message\":\"$message\",\"timestamp\":\"$(date -Iseconds)\"}" \
             >/dev/null 2>&1
    fi
}

# Setup cron jobs
setup_cron_jobs() {
    log_maintenance "SCHEDULE" "Setting up automated maintenance schedule"
    
    local cron_file="/tmp/xxmxli_maintenance_cron"
    local current_cron=""
    
    # Get current crontab
    crontab -l > "$cron_file" 2>/dev/null || touch "$cron_file"
    
    # Remove existing XXMXLI entries
    grep -v "XXMXLI Maintenance" "$cron_file" > "${cron_file}.tmp" 2>/dev/null || touch "${cron_file}.tmp"
    mv "${cron_file}.tmp" "$cron_file"
    
    # Add new maintenance jobs
    {
        echo "# XXMXLI Maintenance Scheduler"
        echo "# Daily maintenance at 2:00 AM"
        echo "0 2 * * * cd $SCRIPT_DIR && ./automated_maintenance_scheduler.sh --daily"
        echo "# Weekly maintenance on Sundays at 3:00 AM"  
        echo "0 3 * * 0 cd $SCRIPT_DIR && ./automated_maintenance_scheduler.sh --weekly"
        echo "# Monthly maintenance on 1st at 4:00 AM"
        echo "0 4 1 * * cd $SCRIPT_DIR && ./automated_maintenance_scheduler.sh --monthly"
        echo ""
    } >> "$cron_file"
    
    # Install new crontab
    if crontab "$cron_file" 2>/dev/null; then
        log_maintenance "SUCCESS" "Cron jobs installed successfully"
        log_maintenance "INFO" "Daily maintenance: 2:00 AM"
        log_maintenance "INFO" "Weekly maintenance: Sundays 3:00 AM"
        log_maintenance "INFO" "Monthly maintenance: 1st of month 4:00 AM"
    else
        log_maintenance "ERROR" "Failed to install cron jobs"
    fi
    
    rm -f "$cron_file" 2>/dev/null
}

# Show current schedule
show_schedule() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              XXMXLI MAINTENANCE SCHEDULE STATUS              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_maintenance "SCHEDULE" "Current Maintenance Schedule:"
    echo ""
    
    # Check if cron jobs exist
    if crontab -l 2>/dev/null | grep -q "XXMXLI Maintenance"; then
        log_maintenance "SUCCESS" "Automated scheduling is ACTIVE"
        echo ""
        log_maintenance "SCHEDULE" "Scheduled Tasks:"
        crontab -l 2>/dev/null | grep -A 10 "XXMXLI Maintenance" | sed 's/^/  /'
    else
        log_maintenance "WARNING" "Automated scheduling is NOT configured"
        log_maintenance "INFO" "Run --setup to configure automated maintenance"
    fi
    
    echo ""
    log_maintenance "INFO" "Last maintenance runs:"
    if [[ -f "$MAINTENANCE_LOG" ]]; then
        tail -5 "$MAINTENANCE_LOG" | sed 's/^/  /'
    else
        log_maintenance "INFO" "  No maintenance history found"
    fi
    
    echo ""
    log_maintenance "INFO" "Next scheduled maintenance:"
    if command -v date >/dev/null 2>&1; then
        local tomorrow=$(date -d "tomorrow 02:00" "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "+1 day" "+%Y-%m-%d 02:00" 2>/dev/null || echo "Tomorrow 02:00")
        local next_sunday=$(date -d "next sunday 03:00" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Next Sunday 03:00")
        local next_month=$(date -d "$(date +%Y-%m-01) +1 month 04:00" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Next month 1st 04:00")
        
        log_maintenance "CLOCK" "  Daily: $tomorrow"
        log_maintenance "CLOCK" "  Weekly: $next_sunday"
        log_maintenance "CLOCK" "  Monthly: $next_month"
    fi
    echo ""
}

# Interactive menu
show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║            XXMXLI Automated Maintenance Scheduler           ║"
    echo "║                  Predictive Security Maintenance            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${WHITE}${GEAR} MAINTENANCE OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${CALENDAR} Setup Automated Schedule"
    echo -e "${GREEN}2)${NC} ${GEAR} Run Daily Maintenance Now"
    echo -e "${GREEN}3)${NC} ${SHIELD} Run Weekly Maintenance Now"
    echo -e "${GREEN}4)${NC} ${ROCKET} Run Monthly Maintenance Now"
    echo -e "${GREEN}5)${NC} ${INFO} Show Current Schedule"
    echo -e "${GREEN}6)${NC} ${GEAR} Configure Settings"
    echo -e "${GREEN}7)${NC} ${INFO} View Maintenance Logs"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "Choose maintenance option [0-7]: " choice
    
    case "$choice" in
        1) setup_cron_jobs ;;
        2) run_daily_maintenance ;;
        3) run_weekly_maintenance ;;
        4) run_monthly_maintenance ;;
        5) show_schedule ;;
        6) 
            log_maintenance "INFO" "Configuration file: $SCHEDULE_CONFIG"
            [[ -f "$SCHEDULE_CONFIG" ]] && cat "$SCHEDULE_CONFIG"
            ;;
        7)
            log_maintenance "INFO" "Recent maintenance activity:"
            [[ -f "$MAINTENANCE_LOG" ]] && tail -20 "$MAINTENANCE_LOG" || echo "No logs found"
            ;;
        0) log_maintenance "INFO" "Exiting maintenance scheduler"; exit 0 ;;
        *) log_maintenance "WARNING" "Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

# Main execution
main() {
    setup_output
    load_maintenance_config
    
    case "${1:-}" in
        "--daily")
            run_daily_maintenance
            ;;
        "--weekly")
            run_weekly_maintenance
            ;;
        "--monthly")
            run_monthly_maintenance
            ;;
        "--setup")
            setup_cron_jobs
            ;;
        "--schedule")
            show_schedule
            ;;
        "--help"|"-h")
            echo "XXMXLI Automated Maintenance Scheduler v2.0"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --daily       Run daily maintenance tasks"
            echo "  --weekly      Run weekly maintenance tasks"
            echo "  --monthly     Run monthly maintenance tasks"
            echo "  --setup       Setup automated cron schedule"
            echo "  --schedule    Show current schedule status"
            echo "  --help, -h    Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            show_menu
            ;;
        *)
            log_maintenance "ERROR" "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Trap for cleanup
trap 'log_maintenance "INFO" "Maintenance scheduler terminated"; exit 0' INT TERM

# Run main function
main "$@"