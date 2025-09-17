#!/bin/bash

# ================================================================
# XXMXLI Security Health Check System v2.0
# Automated monitoring and maintenance for security scripts
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
HEALTH_LOG="$LOG_DIR/health_check.log"

# Load configuration
source "$CONFIG_DIR/security_monitor.conf" 2>/dev/null || {
    echo "Warning: Config file not found, using defaults"
    HEALTH_CHECK_INTERVAL_HOURS=24
    AUTO_CLEANUP_ENABLED=true
    CLEANUP_INTERVAL_DAYS=7
}

# Enhanced colors with fallback
setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        PURPLE=$(tput setaf 5)
        CYAN=$(tput setaf 6)
        WHITE=$(tput setaf 7)
        BOLD=$(tput bold)
        NC=$(tput sgr0)
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi
}

# Unicode symbols with fallbacks
setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi utf; then
        CHECK="✅"
        CROSS="❌" 
        WARNING="⚠️"
        INFO="ℹ️"
        GEAR="⚙️"
        SHIELD="🛡️"
        CLOCK="🕒"
        FIRE="🔥"
        ROCKET="🚀"
        HEART="💚"
        TOOL="🔧"
    else
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        INFO="[i]"
        GEAR="[G]"
        SHIELD="[S]"
        CLOCK="[T]"
        FIRE="[F]"
        ROCKET="[R]"
        HEART="[♥]"
        TOOL="[T]"
    fi
}

# Logging functions
log_with_timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HEALTH_LOG"
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    log_with_timestamp "INFO: $1"
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    log_with_timestamp "SUCCESS: $1"
}

log_warning() { 
    echo -e "${YELLOW}${WARNING}${NC} $1"
    log_with_timestamp "WARNING: $1"
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1"
    log_with_timestamp "ERROR: $1"
}

log_critical() { 
    echo -e "${RED}${FIRE}${NC} ${BOLD}$1${NC}"
    log_with_timestamp "CRITICAL: $1"
}

# Initialize logging
setup_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    # Rotate log if too large
    if [[ -f "$HEALTH_LOG" ]]; then
        local log_size=$(stat -f%z "$HEALTH_LOG" 2>/dev/null || stat -c%s "$HEALTH_LOG" 2>/dev/null || echo 0)
        if [[ $log_size -gt 10485760 ]]; then  # 10MB
            mv "$HEALTH_LOG" "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old"
            gzip "${HEALTH_LOG}.$(date +%Y%m%d_%H%M%S).old" 2>/dev/null || true
        fi
    fi
}

# System health banner
show_health_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 XXMXLI SECURITY HEALTH CHECK                ║
║              Automated System Maintenance v2.0              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${HEART} Monitoring Security • ${TOOL} Maintaining Performance${NC}"
    echo ""
}

# Check if required tools are available
check_system_dependencies() {
    log_info "Checking system dependencies..."
    
    local required_tools=("grep" "awk" "curl" "python3" "bash")
    local optional_tools=("rg" "ag" "jq" "yq" "timeout")
    local missing_required=()
    local missing_optional=()
    
    # Check required tools
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log_success "$tool: available"
        else
            missing_required+=("$tool")
            log_error "$tool: MISSING (required)"
        fi
    done
    
    # Check optional tools
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version=""
            case "$tool" in
                "rg") version=$(rg --version | head -1 | awk '{print $2}') ;;
                "ag") version=$(ag --version | head -1 | awk '{print $3}') ;;
                "jq") version=$(jq --version | tr -d '"') ;;
                *) version="installed" ;;
            esac
            log_success "$tool: available ($version)"
        else
            missing_optional+=("$tool")
            log_warning "$tool: not available (optional, improves performance)"
        fi
    done
    
    # Report results
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_critical "Missing required tools: ${missing_required[*]}"
        return 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_warning "Missing optional tools: ${missing_optional[*]}"
        echo "  Install for better performance:"
        [[ " ${missing_optional[*]} " =~ " rg " ]] && echo "    - ripgrep: https://github.com/BurntSushi/ripgrep"
        [[ " ${missing_optional[*]} " =~ " ag " ]] && echo "    - the_silver_searcher: https://github.com/ggreer/the_silver_searcher"
        [[ " ${missing_optional[*]} " =~ " jq " ]] && echo "    - jq: https://stedolan.github.io/jq/"
    fi
    
    return 0
}

# Check security script health
check_security_scripts() {
    log_info "Checking security script health..."
    
    local scripts=(
        "monitor_security.sh"
        "security_monitor_optimized.sh"
        "process_w_blacklists.py"
        "blacklist_processor_optimized.py"
        "health-check.sh"
    )
    
    local healthy=0
    local total=${#scripts[@]}
    
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/$script" ]]; then
            # Check if script is executable
            if [[ -x "$SCRIPT_DIR/$script" ]]; then
                log_success "$script: executable and ready"
                ((healthy++))
            else
                log_warning "$script: exists but not executable"
                # Try to make it executable
                if chmod +x "$SCRIPT_DIR/$script" 2>/dev/null; then
                    log_success "$script: made executable"
                    ((healthy++))
                else
                    log_error "$script: cannot make executable"
                fi
            fi
        else
            log_warning "$script: not found"
        fi
    done
    
    local health_percentage=$((healthy * 100 / total))
    
    if [[ $health_percentage -ge 80 ]]; then
        log_success "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    elif [[ $health_percentage -ge 60 ]]; then
        log_warning "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    else
        log_error "Script health: $health_percentage% ($healthy/$total scripts healthy)"
    fi
    
    return $((total - healthy))
}

# Check configuration files
check_configuration_files() {
    log_info "Checking configuration files..."
    
    local config_files=(
        "config/security_monitor.conf"
        "config/security_monitor.json" 
        "config/security_monitor.yaml"
        "config/blacklist_processor.json"
    )
    
    local valid_configs=0
    
    for config_file in "${config_files[@]}"; do
        local full_path="$SCRIPT_DIR/$config_file"
        
        if [[ -f "$full_path" ]]; then
            # Validate config based on type
            case "$config_file" in
                *.json)
                    if command -v jq >/dev/null 2>&1; then
                        if jq -e . "$full_path" >/dev/null 2>&1; then
                            log_success "$config_file: valid JSON"
                            ((valid_configs++))
                        else
                            log_error "$config_file: invalid JSON syntax"
                        fi
                    else
                        log_warning "$config_file: exists but cannot validate (jq not available)"
                        ((valid_configs++))
                    fi
                    ;;
                *.yaml|*.yml)
                    if command -v yq >/dev/null 2>&1; then
                        if yq eval . "$full_path" >/dev/null 2>&1; then
                            log_success "$config_file: valid YAML"
                            ((valid_configs++))
                        else
                            log_error "$config_file: invalid YAML syntax"
                        fi
                    else
                        log_warning "$config_file: exists but cannot validate (yq not available)"
                        ((valid_configs++))
                    fi
                    ;;
                *.conf)
                    if source "$full_path" 2>/dev/null; then
                        log_success "$config_file: valid configuration"
                        ((valid_configs++))
                    else
                        log_error "$config_file: syntax errors detected"
                    fi
                    ;;
            esac
        else
            log_warning "$config_file: not found"
        fi
    done
    
    log_info "Configuration status: $valid_configs/${#config_files[@]} files valid"
    return $((${#config_files[@]} - valid_configs))
}

# Check log file health and perform rotation
check_log_health() {
    log_info "Checking log file health..."
    
    local log_files=(
        "logs/security_monitor.log"
        "logs/blacklist_processor.log"
        "logs/health_check.log"
        "logs/debug.log"
    )
    
    local max_size_mb=10
    local rotated_count=0
    
    for log_file in "${log_files[@]}"; do
        local full_path="$SCRIPT_DIR/$log_file"
        
        if [[ -f "$full_path" ]]; then
            local size_bytes=$(stat -f%z "$full_path" 2>/dev/null || stat -c%s "$full_path" 2>/dev/null || echo 0)
            local size_mb=$((size_bytes / 1024 / 1024))
            
            if [[ $size_mb -gt $max_size_mb ]]; then
                log_warning "$log_file: large size (${size_mb}MB), rotating..."
                
                # Rotate log
                local timestamp=$(date +%Y%m%d_%H%M%S)
                if mv "$full_path" "${full_path}.${timestamp}.old" 2>/dev/null; then
                    if gzip "${full_path}.${timestamp}.old" 2>/dev/null; then
                        log_success "$log_file: rotated and compressed"
                    else
                        log_success "$log_file: rotated (compression failed)"
                    fi
                    ((rotated_count++))
                else
                    log_error "$log_file: rotation failed"
                fi
            else
                log_success "$log_file: healthy (${size_mb}MB)"
            fi
        else
            log_info "$log_file: not present (will be created when needed)"
        fi
    done
    
    # Clean old log files
    if [[ $rotated_count -gt 0 ]] || [[ "$AUTO_CLEANUP_ENABLED" == "true" ]]; then
        local old_logs=$(find "$LOG_DIR" -name "*.old*" -mtime +30 2>/dev/null | wc -l)
        if [[ $old_logs -gt 0 ]]; then
            find "$LOG_DIR" -name "*.old*" -mtime +30 -delete 2>/dev/null
            log_success "Cleaned up $old_logs old log files"
        fi
    fi
    
    return 0
}

# Performance optimization check
check_performance() {
    log_info "Checking system performance..."
    
    # Test search tool performance
    local test_file=".htaccess"
    if [[ -f "$test_file" ]]; then
        local pattern="Require not ip"
        
        # Test different search tools
        for tool in grep rg ag awk; do
            if command -v "$tool" >/dev/null 2>&1; then
                local start_time=$(date +%s%N)
                
                case "$tool" in
                    "rg") rg --color=never "$pattern" "$test_file" >/dev/null 2>&1 ;;
                    "ag") ag --nocolor "$pattern" "$test_file" >/dev/null 2>&1 ;;
                    "awk") awk "/$pattern/" "$test_file" >/dev/null 2>&1 ;;
                    *) grep "$pattern" "$test_file" >/dev/null 2>&1 ;;
                esac
                
                local end_time=$(date +%s%N)
                local duration=$(( (end_time - start_time) / 1000000 ))
                
                if [[ $duration -lt 100 ]]; then
                    log_success "$tool performance: ${duration}ms (excellent)"
                elif [[ $duration -lt 500 ]]; then
                    log_success "$tool performance: ${duration}ms (good)"
                else
                    log_warning "$tool performance: ${duration}ms (slow)"
                fi
            fi
        done
    fi
    
    # Check disk space
    local disk_usage=$(df "$SCRIPT_DIR" | awk 'NR==2 {print $5}' | tr -d '%')
    if [[ $disk_usage -lt 80 ]]; then
        log_success "Disk usage: ${disk_usage}% (healthy)"
    elif [[ $disk_usage -lt 90 ]]; then
        log_warning "Disk usage: ${disk_usage}% (monitor closely)"
    else
        log_error "Disk usage: ${disk_usage}% (cleanup needed)"
    fi
    
    # Check memory usage (if available)
    if command -v free >/dev/null 2>&1; then
        local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [[ $mem_usage -lt 80 ]]; then
            log_success "Memory usage: ${mem_usage}% (healthy)"
        else
            log_warning "Memory usage: ${mem_usage}% (high)"
        fi
    fi
    
    return 0
}

# Security infrastructure check
check_security_infrastructure() {
    log_info "Checking security infrastructure..."
    
    local issues=0
    
    # Check .htaccess files
    if [[ -f ".htaccess" ]]; then
        if grep -q "XXMXLI" ".htaccess" 2>/dev/null; then
            local blocked_count=$(grep -c "Require not ip" ".htaccess" 2>/dev/null || echo 0)
            log_success "Main .htaccess: active with $blocked_count blocked IPs"
        else
            log_error "Main .htaccess: missing XXMXLI security rules"
            ((issues++))
        fi
    else
        log_error "Main .htaccess: file not found"
        ((issues++))
    fi
    
    # Check admin protection
    if [[ -f "admin/.htaccess" ]]; then
        log_success "Admin .htaccess: protection configured"
    else
        log_warning "Admin .htaccess: not configured"
        ((issues++))
    fi
    
    # Check security assets
    if [[ -f "assets/security/blocked_ips.js" ]]; then
        local file_age=$(( ($(date +%s) - $(stat -f%m "assets/security/blocked_ips.js" 2>/dev/null || stat -c%Y "assets/security/blocked_ips.js" 2>/dev/null || echo 0)) / 3600 ))
        if [[ $file_age -lt 24 ]]; then
            log_success "Blocked IPs database: fresh (${file_age}h old)"
        else
            log_warning "Blocked IPs database: outdated (${file_age}h old)"
        fi
    else
        log_warning "Blocked IPs database: not found"
    fi
    
    return $issues
}

# Generate health report
generate_health_report() {
    local report_file="$SCRIPT_DIR/reports/health_report_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$(dirname "$report_file")" 2>/dev/null
    
    {
        echo "XXMXLI SECURITY HEALTH REPORT"
        echo "=============================="
        echo "Generated: $(date)"
        echo "System: $(uname -a)"
        echo ""
        
        echo "DEPENDENCY CHECK:"
        check_system_dependencies 2>&1 | grep -E "(available|MISSING|not available)"
        echo ""
        
        echo "SCRIPT HEALTH:"
        check_security_scripts 2>&1 | grep -E "(executable|not found|health:)"
        echo ""
        
        echo "CONFIGURATION STATUS:"
        check_configuration_files 2>&1 | grep -E "(valid|invalid|not found|status:)"
        echo ""
        
        echo "PERFORMANCE METRICS:"
        check_performance 2>&1 | grep -E "(performance:|usage:)"
        echo ""
        
        echo "SECURITY INFRASTRUCTURE:"
        check_security_infrastructure 2>&1 | grep -E "(htaccess:|database:)"
        echo ""
        
    } > "$report_file"
    
    log_success "Health report generated: $report_file"
}

# Interactive health check menu
show_health_menu() {
    show_health_banner
    
    echo -e "${WHITE}${GEAR} SECURITY HEALTH CHECK OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${CHECK} Full System Health Check"
    echo -e "${GREEN}2)${NC} ${GEAR} Check Dependencies"
    echo -e "${GREEN}3)${NC} ${SHIELD} Check Security Scripts"
    echo -e "${GREEN}4)${NC} ${INFO} Check Configuration Files"
    echo -e "${GREEN}5)${NC} ${CLOCK} Check Log Health"
    echo -e "${GREEN}6)${NC} ${ROCKET} Performance Check"
    echo -e "${GREEN}7)${NC} ${FIRE} Security Infrastructure Check"
    echo -e "${GREEN}8)${NC} ${TOOL} Generate Health Report"
    echo -e "${GREEN}9)${NC} ${HEART} Schedule Automatic Checks"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-9]:${NC} ")" choice
    
    case "$choice" in
        1) run_full_health_check ;;
        2) check_system_dependencies ;;
        3) check_security_scripts ;;
        4) check_configuration_files ;;
        5) check_log_health ;;
        6) check_performance ;;
        7) check_security_infrastructure ;;
        8) generate_health_report ;;
        9) schedule_automatic_checks ;;
        0) log_info "Exiting health check system"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_health_menu
}

# Run full health check
run_full_health_check() {
    echo -e "${PURPLE}${BOLD}🏥 FULL SYSTEM HEALTH CHECK${NC}"
    echo "================================================================"
    echo ""
    
    local start_time=$(date +%s)
    local total_issues=0
    
    # Run all checks
    check_system_dependencies || ((total_issues += $?))
    echo ""
    
    check_security_scripts || ((total_issues += $?))
    echo ""
    
    check_configuration_files || ((total_issues += $?))
    echo ""
    
    check_log_health || ((total_issues += $?))
    echo ""
    
    check_performance || ((total_issues += $?))
    echo ""
    
    check_security_infrastructure || ((total_issues += $?))
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo "================================================================"
    
    if [[ $total_issues -eq 0 ]]; then
        log_success "Health check completed in ${duration}s - System is healthy! ${HEART}"
    elif [[ $total_issues -lt 5 ]]; then
        log_warning "Health check completed in ${duration}s - Minor issues detected ($total_issues)"
    else
        log_error "Health check completed in ${duration}s - Multiple issues found ($total_issues)"
    fi
}

# Schedule automatic checks
schedule_automatic_checks() {
    echo -e "${PURPLE}${CLOCK} AUTOMATIC HEALTH CHECK SCHEDULING${NC}"
    echo "================================================================"
    echo ""
    
    local cron_entry="0 */6 * * * $SCRIPT_DIR/security_health_check.sh --auto 2>&1 | logger -t xxmxli-health"
    
    log_info "Current schedule: Every 6 hours"
    log_info "Log location: System journal (use journalctl -t xxmxli-health)"
    echo ""
    
    if crontab -l 2>/dev/null | grep -q "security_health_check.sh"; then
        log_success "Automatic health checks are already scheduled"
    else
        echo "Would you like to schedule automatic health checks?"
        read -p "Enter 'yes' to confirm: " confirm
        
        if [[ "$confirm" == "yes" ]]; then
            (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
            log_success "Automatic health checks scheduled"
        else
            log_info "Automatic scheduling cancelled"
        fi
    fi
}

# Main execution
main() {
    # Handle command line arguments
    case "${1:-}" in
        "--auto"|"-a")
            # Automated mode (for cron)
            setup_colors
            setup_symbols  
            setup_logging
            run_full_health_check
            generate_health_report
            ;;
        "--report"|"-r")
            # Report only mode
            setup_colors
            setup_symbols
            setup_logging
            generate_health_report
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--auto|--report|--help]"
            echo "  --auto     Run automated health check (for cron)"
            echo "  --report   Generate health report only"
            echo "  --help     Show this help"
            exit 0
            ;;
        *)
            # Interactive mode
            setup_colors
            setup_symbols
            setup_logging
            show_health_menu
            ;;
    esac
}

# Trap for cleanup
trap 'log_info "Health check system terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi