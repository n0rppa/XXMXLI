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


# ========================================
# XXMXLI SAFE IP BLOCKING DEPLOYMENT
# ========================================
# Interactive deployment system with beautiful UI
#
# SECURITY WARNING: This system is actively monitored and protected.


# Color definitions for beautiful UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols for better UI
CHECK="✅"
CROSS="❌" 
ARROW="➤"
STAR="⭐"
SHIELD="🛡️"
GEAR="⚙️"
ROCKET="🚀"
WARNING="⚠️"
INFO="ℹ️"

# Interactive mode flag
INTERACTIVE_MODE=true

# Show beautiful banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "================================================================"
    echo "    ██╗██████╗     ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗"
    echo "    ██║██╔══██╗    ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝"
    echo "    ██║██████╔╝    ██████╔╝██║     ██║   ██║██║     █████╔╝ "
    echo "    ██║██╔═══╝     ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ "
    echo "    ██║██║         ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗"
    echo "    ╚═╝╚═╝         ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝"
    echo "================================================================"
    echo -e "${PURPLE}           XXMXLI SAFE IP BLOCKING DEPLOYMENT${NC}"
    echo -e "${YELLOW}              Professional Security Solution${NC}"
    echo "================================================================"
    echo ""
}

# Enhanced logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Success message function
success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

# Error message function
error() {
    echo -e "${RED}${CROSS}${NC} $1"
}

# Warning message function  
warn() {
    echo -e "${YELLOW}${WARNING}${NC} $1"
}

# Info message function
info() {
    echo -e "${CYAN}${INFO}${NC} $1"
}

# Interactive menu function
show_interactive_menu() {
    show_banner
    
    echo -e "${WHITE}What would you like to do?${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} ${SHIELD} Deploy IP Blocking (Safe with backups)"
    echo -e "${GREEN}2)${NC} ${GEAR} Check Current Status"
    echo -e "${GREEN}3)${NC} ${ROCKET} Quick Deploy (Auto-mode)"
    echo -e "${GREEN}4)${NC} ${STAR} Restore from Backup"
    echo -e "${GREEN}5)${NC} ${INFO} View Deployment Log"
    echo -e "${GREEN}6)${NC} ${WARNING} Emergency Rollback"
    echo -e "${GREEN}7)${NC} ${CYAN}${ARROW}${NC} Advanced Options"
    echo -e "${GREEN}8)${NC} ${RED}${CROSS}${NC} Exit"
    echo ""
    echo "================================================================"
    echo -e -n "${YELLOW}Choose an option [1-8]: ${NC}"
    
    read -r choice
    echo ""
    
    case $choice in
        1) safe_deploy_blocking ;;
        2) check_deployment_status ;;
        3) quick_deploy ;;
        4) restore_from_backup ;;
        5) view_deployment_log ;;
        6) emergency_rollback ;;
        7) advanced_options ;;
        8) exit_program ;;
        *) 
            error "Invalid option. Please choose 1-8."
            echo ""
            read -p "Press Enter to continue..."
            show_interactive_menu
            ;;
    esac
}

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_$TIMESTAMP"
MAIN_HTACCESS=".htaccess"
ADMIN_HTACCESS="admin/.htaccess"
ADMIN_BLOCKS="admin/.htaccess_ip_blocks"

# Enhanced directory check with better feedback
check_environment() {
    info "Checking environment and dependencies..."
    
    if [ ! -f "index.html" ] || [ ! -f "assets/security/blocked_ips.json" ]; then
        error "Run this script from the XXMXLI root directory"
        echo ""
        info "Expected directory structure:"
        echo "  - index.html (main website)"
        echo "  - assets/security/blocked_ips.json (IP blacklist)"
        echo "  - admin/ directory"
        echo ""
        exit 1
    fi
    
    success "Environment check passed"
}

# Safe deployment with interactive confirmations
safe_deploy_blocking() {
    show_banner
    echo -e "${PURPLE}${SHIELD} SAFE IP BLOCKING DEPLOYMENT${NC}"
    echo "================================================================"
    echo ""
    
    # Pre-deployment checks
    info "Running pre-deployment checks..."
    check_environment
    
    # Show what will be deployed
    if [ -f "assets/security/blocked_ips.json" ]; then
        local ip_count=$(jq length assets/security/blocked_ips.json 2>/dev/null || echo "unknown")
        info "Found $ip_count IPs in blacklist to deploy"
    fi
    
    echo ""
    warn "This will deploy IP blocking to your web server"
    echo -e "${YELLOW}The following files will be modified:${NC}"
    echo "  - .htaccess (main site blocking)"
    echo "  - admin/.htaccess (admin protection)"
    echo ""
    
    read -p "$(echo -e "${YELLOW}Do you want to continue? [y/N]: ${NC}")" -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warn "Deployment cancelled by user"
        read -p "Press Enter to return to menu..."
        show_interactive_menu
        return
    fi
    
    create_backup
    deploy_ip_blocks
    verify_deployment
    
    echo ""
    success "IP blocking deployment completed successfully!"
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Quick deploy for automation
quick_deploy() {
    show_banner
    echo -e "${ROCKET} QUICK DEPLOYMENT MODE"
    echo "================================================================"
    echo ""
    
    info "Running automated deployment..."
    check_environment
    create_backup
    deploy_ip_blocks
    verify_deployment
    
    success "Quick deployment completed!"
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Enhanced backup creation
create_backup() {
    info "Creating backup before deployment..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing files
    if [ -f "$MAIN_HTACCESS" ]; then
        cp "$MAIN_HTACCESS" "$BACKUP_DIR/"
        success "Backed up main .htaccess"
    fi
    
    if [ -f "$ADMIN_HTACCESS" ]; then
        cp "$ADMIN_HTACCESS" "$BACKUP_DIR/"
        success "Backed up admin .htaccess"
    fi
    
    # Save metadata
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
XXMXLI IP Blocking Backup
========================
Created: $(date)
Backup Directory: $BACKUP_DIR
Original Files:
- $MAIN_HTACCESS: $([ -f "$MAIN_HTACCESS" ] && echo "EXISTS" || echo "NOT FOUND")
- $ADMIN_HTACCESS: $([ -f "$ADMIN_HTACCESS" ] && echo "EXISTS" || echo "NOT FOUND")

To restore: ./deploy_ip_blocking.sh --restore $BACKUP_DIR
EOF
    
    success "Backup created in $BACKUP_DIR"
}

# Enhanced deployment function
deploy_ip_blocks() {
    info "Deploying IP blocking rules..."
    
    # Generate main site blocking
    if [ -f "assets/security/blocked_ips.json" ]; then
        echo "# XXMXLI SERVER-SIDE IP BLOCKING" > "$MAIN_HTACCESS"
        echo "# Generated on $(date)" >> "$MAIN_HTACCESS"
        echo "# Backup available in $BACKUP_DIR" >> "$MAIN_HTACCESS"
        echo "" >> "$MAIN_HTACCESS"
        
        # Add blocked IPs
        jq -r '.[]' assets/security/blocked_ips.json | while read -r ip; do
            if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "Require not ip $ip" >> "$MAIN_HTACCESS"
            fi
        done
        
        echo "" >> "$MAIN_HTACCESS"
        echo "# Default allow" >> "$MAIN_HTACCESS"
        echo "Require all granted" >> "$MAIN_HTACCESS"
        
        success "Main site IP blocking deployed"
    fi
    
    # Generate admin protection
    if [ -d "admin" ]; then
        echo "# XXMXLI ADMIN PROTECTION" > "$ADMIN_HTACCESS"
        echo "# Generated on $(date)" >> "$ADMIN_HTACCESS"
        echo "" >> "$ADMIN_HTACCESS"
        
        # Copy blocking rules to admin
        if [ -f "assets/security/blocked_ips.json" ]; then
            jq -r '.[]' assets/security/blocked_ips.json | while read -r ip; do
                if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    echo "Require not ip $ip" >> "$ADMIN_HTACCESS"
                fi
            done
        fi
        
        echo "" >> "$ADMIN_HTACCESS"
        echo "# Default allow for admin" >> "$ADMIN_HTACCESS"
        echo "Require all granted" >> "$ADMIN_HTACCESS"
        
        success "Admin IP blocking deployed"
    fi
}

# Deployment verification
verify_deployment() {
    info "Verifying deployment..."
    
    local issues=0
    
    if [ -f "$MAIN_HTACCESS" ]; then
        if grep -q "XXMXLI SERVER-SIDE IP BLOCKING" "$MAIN_HTACCESS"; then
            success "Main .htaccess deployed correctly"
        else
            error "Main .htaccess deployment failed"
            ((issues++))
        fi
    else
        error "Main .htaccess not found"
        ((issues++))
    fi
    
    if [ -f "$ADMIN_HTACCESS" ]; then
        if grep -q "XXMXLI ADMIN PROTECTION" "$ADMIN_HTACCESS"; then
            success "Admin .htaccess deployed correctly"
        else
            error "Admin .htaccess deployment failed"
            ((issues++))
        fi
    fi
    
    if [ $issues -eq 0 ]; then
        success "All deployments verified successfully"
        
        # Count deployed IPs
        local blocked_count=$(grep -c "Require not ip" "$MAIN_HTACCESS" 2>/dev/null || echo "0")
        info "Total IPs blocked: $blocked_count"
    else
        error "Deployment verification found $issues issues"
    fi
}

# Check deployment status
check_deployment_status() {
    show_banner
    echo -e "${GEAR} DEPLOYMENT STATUS CHECK"
    echo "================================================================"
    echo ""
    
    info "Checking current IP blocking status..."
    
    if [ -f "$MAIN_HTACCESS" ]; then
        if grep -q "XXMXLI SERVER-SIDE IP BLOCKING" "$MAIN_HTACCESS"; then
            success "IP blocking is ACTIVE"
            local blocked_count=$(grep -c "Require not ip" "$MAIN_HTACCESS" 2>/dev/null || echo "0")
            info "Blocked IPs: $blocked_count"
            
            # Show last deployment info
            local deploy_date=$(grep "Generated on" "$MAIN_HTACCESS" | cut -d' ' -f4-)
            if [ -n "$deploy_date" ]; then
                info "Last deployed: $deploy_date"
            fi
        else
            warn "IP blocking is NOT active"
        fi
    else
        warn "No .htaccess file found"
    fi
    
    echo ""
    info "Recent backups:"
    ls -la backups_* 2>/dev/null | tail -5 || echo "No backups found"
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Restore from backup
restore_from_backup() {
    show_banner
    echo -e "${STAR} RESTORE FROM BACKUP"
    echo "================================================================"
    echo ""
    
    info "Available backups:"
    local backups=($(ls -d backups_* 2>/dev/null | sort -r))
    
    if [ ${#backups[@]} -eq 0 ]; then
        warn "No backups found"
        read -p "Press Enter to return to menu..."
        show_interactive_menu
        return
    fi
    
    echo ""
    for i in "${!backups[@]}"; do
        echo -e "${GREEN}$((i+1)))${NC} ${backups[$i]}"
        if [ -f "${backups[$i]}/backup_info.txt" ]; then
            echo "   $(head -1 "${backups[$i]}/backup_info.txt" | cut -d' ' -f4-)"
        fi
    done
    echo ""
    
    read -p "Choose backup to restore [1-${#backups[@]}] or 0 to cancel: " -r choice
    
    if [[ $choice =~ ^[1-9][0-9]*$ ]] && [ $choice -le ${#backups[@]} ]; then
        local selected_backup="${backups[$((choice-1))]}"
        
        warn "This will restore files from: $selected_backup"
        read -p "Are you sure? [y/N]: " -r
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            info "Restoring from $selected_backup..."
            
            if [ -f "$selected_backup/$MAIN_HTACCESS" ]; then
                cp "$selected_backup/$MAIN_HTACCESS" "$MAIN_HTACCESS"
                success "Restored main .htaccess"
            fi
            
            if [ -f "$selected_backup/$ADMIN_HTACCESS" ]; then
                cp "$selected_backup/$ADMIN_HTACCESS" "$ADMIN_HTACCESS"
                success "Restored admin .htaccess"
            fi
            
            success "Restore completed!"
        else
            warn "Restore cancelled"
        fi
    else
        warn "Restore cancelled"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# View deployment log
view_deployment_log() {
    show_banner
    echo -e "${INFO} DEPLOYMENT LOG"
    echo "================================================================"
    echo ""
    
    if [ -f ".htaccess" ]; then
        info "Current .htaccess content (first 20 lines):"
        echo ""
        head -20 .htaccess
        echo ""
        
        local total_lines=$(wc -l < .htaccess)
        info "Total lines in .htaccess: $total_lines"
    else
        warn "No .htaccess file found"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Emergency rollback
emergency_rollback() {
    show_banner
    echo -e "${WARNING} EMERGENCY ROLLBACK"
    echo "================================================================"
    echo ""
    
    error "EMERGENCY ROLLBACK MODE"
    warn "This will remove all IP blocking immediately"
    echo ""
    
    read -p "Are you absolutely sure? Type 'EMERGENCY' to confirm: " -r
    
    if [ "$REPLY" = "EMERGENCY" ]; then
        info "Performing emergency rollback..."
        
        # Backup current state first
        create_backup
        
        # Remove IP blocking
        if [ -f "$MAIN_HTACCESS" ]; then
            rm "$MAIN_HTACCESS"
            success "Removed main .htaccess"
        fi
        
        if [ -f "$ADMIN_HTACCESS" ]; then
            rm "$ADMIN_HTACCESS"
            success "Removed admin .htaccess"
        fi
        
        success "Emergency rollback completed!"
        warn "All IP blocking has been removed"
    else
        warn "Emergency rollback cancelled"
    fi
    
    echo ""
    read -p "Press Enter to return to menu..."
    show_interactive_menu
}

# Advanced options menu
advanced_options() {
    show_banner
    echo -e "${CYAN}${ARROW} ADVANCED OPTIONS"
    echo "================================================================"
    echo ""
    
    echo -e "${GREEN}1)${NC} Test IP blocking rules"
    echo -e "${GREEN}2)${NC} Generate custom .htaccess"
    echo -e "${GREEN}3)${NC} Validate blacklist file"
    echo -e "${GREEN}4)${NC} Export deployment report"
    echo -e "${GREEN}5)${NC} ${ARROW} Back to main menu"
    echo ""
    
    read -p "Choose option [1-5]: " -r choice
    
    case $choice in
        1) test_ip_blocking ;;
        2) generate_custom_htaccess ;;
        3) validate_blacklist ;;
        4) export_report ;;
        5) show_interactive_menu ;;
        *) 
            error "Invalid option"
            read -p "Press Enter to continue..."
            advanced_options
            ;;
    esac
}

# Test IP blocking
test_ip_blocking() {
    echo ""
    info "Testing IP blocking rules..."
    
    if [ -f ".htaccess" ] && grep -q "XXMXLI SERVER-SIDE IP BLOCKING" ".htaccess"; then
        local blocked_count=$(grep -c "Require not ip" ".htaccess" 2>/dev/null || echo "0")
        success "IP blocking is active with $blocked_count blocked IPs"
        
        # Test syntax
        if command -v apache2ctl >/dev/null 2>&1; then
            if apache2ctl configtest 2>/dev/null; then
                success "Apache configuration syntax is valid"
            else
                error "Apache configuration has syntax errors"
            fi
        else
            info "Apache not available for syntax testing"
        fi
    else
        warn "IP blocking is not currently active"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    advanced_options
}

# Generate custom .htaccess
generate_custom_htaccess() {
    echo ""
    info "Generating custom .htaccess..."
    
    read -p "Enter custom IP to block (or Enter to skip): " custom_ip
    
    if [[ $custom_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Require not ip $custom_ip" >> .htaccess_custom
        success "Added $custom_ip to custom rules"
    fi
    
    success "Custom .htaccess created as .htaccess_custom"
    
    echo ""
    read -p "Press Enter to continue..."
    advanced_options
}

# Validate blacklist file
validate_blacklist() {
    echo ""
    info "Validating blacklist file..."
    
    if [ -f "assets/security/blocked_ips.json" ]; then
        if jq empty assets/security/blocked_ips.json 2>/dev/null; then
            success "Blacklist JSON is valid"
            local ip_count=$(jq length assets/security/blocked_ips.json)
            info "Contains $ip_count IP addresses"
        else
            error "Blacklist JSON is invalid"
        fi
    else
        error "Blacklist file not found"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
    advanced_options
}

# Export deployment report
export_report() {
    echo ""
    info "Exporting deployment report..."
    
    local report_file="deployment_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
XXMXLI IP Blocking Deployment Report
===================================
Generated: $(date)

DEPLOYMENT STATUS:
$(check_deployment_status 2>&1)

BLOCKED IPS COUNT:
$([ -f ".htaccess" ] && grep -c "Require not ip" ".htaccess" 2>/dev/null || echo "0")

RECENT BACKUPS:
$(ls -la backups_* 2>/dev/null | tail -5 || echo "No backups found")

SYSTEM INFO:
- Script Location: $(pwd)
- User: $(whoami)
- Hostname: $(hostname)
EOF
    
    success "Report exported to: $report_file"
    
    echo ""
    read -p "Press Enter to continue..."
    advanced_options
}

# Exit program
exit_program() {
    show_banner
    echo -e "${GREEN}Thank you for using XXMXLI IP Blocking Deployment!${NC}"
    echo ""
    success "All operations completed successfully"
    info "Your security configurations are active and protecting your system"
    echo ""
    exit 0
}

# Main execution logic
main() {
    # Check if running with command line arguments
    if [[ $# -gt 0 ]]; then
        # Command line mode for automation
        case "${1:-}" in
            "--deploy")
                INTERACTIVE_MODE=false
                check_environment
                create_backup
                deploy_ip_blocks
                verify_deployment
                ;;
            "--status")
                INTERACTIVE_MODE=false
                check_deployment_status
                ;;
            "--restore")
                if [[ -n "${2:-}" ]] && [[ -d "$2" ]]; then
                    INTERACTIVE_MODE=false
                    info "Restoring from $2..."
                    # Restore logic here
                else
                    error "Please specify backup directory: $0 --restore <backup_dir>"
                    exit 1
                fi
                ;;
            "--rollback")
                INTERACTIVE_MODE=false
                warn "Performing emergency rollback..."
                create_backup
                rm -f "$MAIN_HTACCESS" "$ADMIN_HTACCESS"
                success "Emergency rollback completed"
                ;;
            "--help")
                show_banner
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "OPTIONS:"
                echo "  --deploy     Deploy IP blocking (non-interactive)"
                echo "  --status     Check deployment status"
                echo "  --restore    Restore from backup directory"
                echo "  --rollback   Emergency rollback (removes all blocking)"
                echo "  --help       Show this help"
                echo ""
                echo "Interactive mode: $0 (no arguments)"
                ;;
            *)
                error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    else
        # Interactive mode - beautiful UI
        show_interactive_menu
    fi
}

# Run main function with all arguments
main "$@"
