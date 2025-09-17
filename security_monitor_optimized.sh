#!/bin/bash

# ================================================================
# XXMXLI OPTIMIZED SECURITY MONITORING SYSTEM v2.0
# Enhanced Performance, Error Handling & Configuration Management
# ================================================================

# Load configuration from external files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/security_monitor.conf"
CONFIG_JSON="${SCRIPT_DIR}/config/security_monitor.json"
CONFIG_YAML="${SCRIPT_DIR}/config/security_monitor.yaml"

# Performance optimization: Use faster tools when available
SEARCH_TOOL="grep"
if command -v rg >/dev/null 2>&1; then
    SEARCH_TOOL="rg"
elif command -v ag >/dev/null 2>&1; then
    SEARCH_TOOL="ag"
elif command -v awk >/dev/null 2>&1; then
    SEARCH_TOOL="awk"
fi

# Enhanced color definitions with error checking
setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        # Terminal supports colors
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
        # Fallback ANSI codes
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

# Enhanced Unicode symbols with fallbacks
setup_symbols() {
    if locale charmap 2>/dev/null | grep -qi utf; then
        CHECK="✅"
        CROSS="❌"
        WARNING="⚠️"
        ARROW="➤"
        SHIELD="🛡️"
        GEAR="⚙️"
        MAGNIFY="🔍"
        CHART="📊"
        FIRE="🔥"
        LIGHTNING="⚡"
        LOCK="🔐"
        EYE="👁️"
        INFO="ℹ️"
        BLOCKED="🚫"
    else
        # ASCII fallbacks
        CHECK="[✓]"
        CROSS="[✗]"
        WARNING="[!]"
        ARROW=">"
        SHIELD="[S]"
        GEAR="[G]"
        MAGNIFY="[?]"
        CHART="[C]"
        FIRE="[F]"
        LIGHTNING="[L]"
        LOCK="[L]"
        EYE="[E]"
        INFO="[i]"
        BLOCKED="[B]"
    fi
}

# Configuration loading with multiple formats
load_configuration() {
    local config_loaded=false
    
    # Try JSON first (fastest parsing)
    if [[ -f "$CONFIG_JSON" ]] && command -v jq >/dev/null 2>&1; then
        log_debug "Loading JSON configuration: $CONFIG_JSON"
        if jq -e . "$CONFIG_JSON" >/dev/null 2>&1; then
            # Load critical settings from JSON
            SEARCH_TIMEOUT=$(jq -r '.performance.search_timeout // 30' "$CONFIG_JSON" 2>/dev/null)
            LOG_RETENTION_DAYS=$(jq -r '.logging.retention_days // 30' "$CONFIG_JSON" 2>/dev/null)
            MAX_LOG_SIZE=$(jq -r '.logging.max_size_mb // 100' "$CONFIG_JSON" 2>/dev/null)
            ENABLE_NOTIFICATIONS=$(jq -r '.notifications.enabled // true' "$CONFIG_JSON" 2>/dev/null)
            config_loaded=true
            log_info "Configuration loaded from JSON"
        fi
    fi
    
    # Try YAML if available
    if [[ ! "$config_loaded" == "true" ]] && [[ -f "$CONFIG_YAML" ]] && command -v yq >/dev/null 2>&1; then
        log_debug "Loading YAML configuration: $CONFIG_YAML"
        if yq eval . "$CONFIG_YAML" >/dev/null 2>&1; then
            SEARCH_TIMEOUT=$(yq eval '.performance.search_timeout // 30' "$CONFIG_YAML" 2>/dev/null)
            LOG_RETENTION_DAYS=$(yq eval '.logging.retention_days // 30' "$CONFIG_YAML" 2>/dev/null)
            MAX_LOG_SIZE=$(yq eval '.logging.max_size_mb // 100' "$CONFIG_YAML" 2>/dev/null)
            ENABLE_NOTIFICATIONS=$(yq eval '.notifications.enabled // true' "$CONFIG_YAML" 2>/dev/null)
            config_loaded=true
            log_info "Configuration loaded from YAML"
        fi
    fi
    
    # Fallback to .conf file
    if [[ ! "$config_loaded" == "true" ]] && [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Loading .conf configuration: $CONFIG_FILE"
        if source "$CONFIG_FILE" 2>/dev/null; then
            config_loaded=true
            log_info "Configuration loaded from .conf file"
        fi
    fi
    
    # Set default values if no config loaded
    if [[ ! "$config_loaded" == "true" ]]; then
        SEARCH_TIMEOUT=30
        LOG_RETENTION_DAYS=30
        MAX_LOG_SIZE=100
        ENABLE_NOTIFICATIONS=true
        log_warn "Using default configuration - no config file found"
    fi
}

# Enhanced logging with levels and rotation
setup_logging() {
    LOG_DIR="${SCRIPT_DIR}/logs"
    REPORT_DIR="${SCRIPT_DIR}/reports"
    LOG_FILE="${LOG_DIR}/security_monitor.log"
    DEBUG_LOG="${LOG_DIR}/debug.log"
    
    # Create directories if they don't exist
    mkdir -p "$LOG_DIR" "$REPORT_DIR" 2>/dev/null
    
    # Log rotation check
    if [[ -f "$LOG_FILE" ]]; then
        local log_size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        local max_bytes=$((MAX_LOG_SIZE * 1024 * 1024))
        
        if [[ $log_size -gt $max_bytes ]]; then
            log_warn "Rotating log file (size: ${log_size} bytes)"
            mv "$LOG_FILE" "${LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
            gzip "${LOG_FILE}.$(date +%Y%m%d_%H%M%S).old" 2>/dev/null || true
        fi
    fi
}

# Enhanced logging functions with file output
log_debug() { 
    [[ "${DEBUG:-false}" == "true" ]] && {
        echo -e "${CYAN}[DEBUG $(date +'%H:%M:%S')]${NC} $1" >&2
        echo "[DEBUG $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG" 2>/dev/null
    }
}

log_info() { 
    echo -e "${BLUE}${INFO}${NC} $1"
    echo "[INFO $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

log_success() { 
    echo -e "${GREEN}${CHECK}${NC} $1"
    echo "[SUCCESS $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

log_warn() { 
    echo -e "${YELLOW}${WARNING}${NC} $1" >&2
    echo "[WARN $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

log_error() { 
    echo -e "${RED}${CROSS}${NC} $1" >&2
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

log_critical() { 
    echo -e "${RED}${FIRE}${NC} ${BOLD}$1${NC}" >&2
    echo "[CRITICAL $(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null
}

# Timeout wrapper for commands that might hang
run_with_timeout() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}" 2>/dev/null
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}" 2>/dev/null
    else
        # Fallback without timeout
        log_warn "No timeout command available, running without timeout protection"
        "${cmd[@]}" 2>/dev/null
    fi
}

# Optimized search function with fallback tools
optimized_search() {
    local pattern="$1"
    local file="$2"
    local timeout="${3:-$SEARCH_TIMEOUT}"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    case "$SEARCH_TOOL" in
        "rg")
            run_with_timeout "$timeout" rg --color=never "$pattern" "$file"
            ;;
        "ag")
            run_with_timeout "$timeout" ag --nocolor "$pattern" "$file"
            ;;
        "awk")
            run_with_timeout "$timeout" awk "/$pattern/" "$file"
            ;;
        *)
            run_with_timeout "$timeout" grep "$pattern" "$file"
            ;;
    esac
}

# Enhanced IP analysis with faster tools
analyze_blocked_ips() {
    local htaccess_file=".htaccess"
    
    if [[ ! -f "$htaccess_file" ]]; then
        log_error "No .htaccess file found"
        return 1
    fi
    
    log_info "Analyzing blocked IP patterns..."
    
    # Use awk for faster processing instead of multiple grep calls
    local ip_stats
    if command -v awk >/dev/null 2>&1; then
        ip_stats=$(awk '/Require not ip/ {
            ip = $4
            # Extract network ranges
            gsub(/\.[0-9]+\.[0-9]+$/, ".x.x", ip)
            ranges[ip]++
            total++
        } 
        END {
            for (range in ranges) {
                printf "%s: %d\n", range, ranges[range]
            }
            printf "TOTAL: %d\n", total
        }' "$htaccess_file" 2>/dev/null)
        
        echo "$ip_stats" | head -10
    else
        # Fallback to grep/sort method
        run_with_timeout "$SEARCH_TIMEOUT" grep "Require not ip" "$htaccess_file" | \
            awk '{print $4}' | \
            awk -F'.' '{print $1"."$2".x.x"}' | \
            sort | uniq -c | sort -nr | head -10
    fi
}

# Performance-optimized log analysis
analyze_logs_optimized() {
    local log_file="${1:-/var/log/auth.log}"
    local hours="${2:-24}"
    
    if [[ ! -f "$log_file" ]]; then
        log_warn "Log file not found: $log_file"
        return 1
    fi
    
    log_info "Analyzing logs from last $hours hours..."
    
    # Calculate timestamp for filtering
    local since_timestamp
    if command -v date >/dev/null 2>&1; then
        if date --version 2>/dev/null | grep -q GNU; then
            # GNU date
            since_timestamp=$(date -d "$hours hours ago" '+%b %d %H:')
        else
            # BSD date
            since_timestamp=$(date -v-"${hours}H" '+%b %d %H:')
        fi
    else
        log_warn "Date command not available, analyzing full log"
        since_timestamp=""
    fi
    
    # Use optimized search tools
    local failed_attempts
    if [[ -n "$since_timestamp" ]]; then
        failed_attempts=$(optimized_search "Failed password.*$since_timestamp" "$log_file" | wc -l)
    else
        failed_attempts=$(optimized_search "Failed password" "$log_file" | tail -1000 | wc -l)
    fi
    
    log_info "Failed login attempts: $failed_attempts"
    
    # Extract unique attacking IPs efficiently
    if [[ $failed_attempts -gt 0 ]]; then
        local attacking_ips
        attacking_ips=$(optimized_search "Failed password" "$log_file" | \
            awk '{for(i=1;i<=NF;i++) if($i~/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) print $i}' | \
            sort | uniq -c | sort -nr | head -5)
        
        if [[ -n "$attacking_ips" ]]; then
            echo ""
            log_info "Top attacking IPs:"
            echo "$attacking_ips" | while read count ip; do
                echo -e "${RED}${BLOCKED}${NC} $ip ($count attempts)"
            done
        fi
    fi
}

# Error handling wrapper
safe_execute() {
    local description="$1"
    shift
    local cmd=("$@")
    
    log_debug "Executing: $description"
    
    if "${cmd[@]}" 2>/dev/null; then
        log_success "$description completed"
        return 0
    else
        local exit_code=$?
        log_error "$description failed (exit code: $exit_code)"
        return $exit_code
    fi
}

# Main security status check with error handling
security_status_check() {
    local issues=0
    local checks=0
    
    echo -e "${PURPLE}${SHIELD} SECURITY STATUS OVERVIEW${NC}"
    echo "================================================================"
    echo ""
    
    # Check .htaccess file
    ((checks++))
    if [[ -f ".htaccess" ]] && optimized_search "XXMXLI" ".htaccess" >/dev/null; then
        log_success "Server-side IP blocking: ACTIVE"
    else
        log_error "Server-side IP blocking: MISSING"
        ((issues++))
    fi
    
    # Check admin protection
    ((checks++))
    if [[ -f "admin/.htaccess" ]]; then
        log_success "Admin directory protection: CONFIGURED"
    else
        log_warn "Admin directory protection: NOT CONFIGURED"
        ((issues++))
    fi
    
    # Check blocked IPs count with timeout
    ((checks++))
    local blocked_count
    if blocked_count=$(run_with_timeout 10 grep -c "Require not ip" .htaccess 2>/dev/null); then
        if [[ ${blocked_count:-0} -gt 0 ]]; then
            log_success "Blocked IPs: $blocked_count entries"
        else
            log_warn "Blocked IPs: No entries found"
            ((issues++))
        fi
    else
        log_error "Could not count blocked IPs (timeout or file error)"
        ((issues++))
    fi
    
    # Calculate security score
    local score=$((100 * (checks - issues) / checks))
    echo ""
    echo -e "${WHITE}${ARROW} SECURITY SCORE: ${NC}"
    
    if [[ $score -ge 90 ]]; then
        echo -e "${GREEN}${FIRE} EXCELLENT ($score%)${NC}"
    elif [[ $score -ge 70 ]]; then
        echo -e "${YELLOW}${WARNING} GOOD ($score%)${NC}"
    else
        echo -e "${RED}${CROSS} NEEDS ATTENTION ($score%)${NC}"
    fi
    
    echo ""
    return $issues
}

# Initialize everything
init_system() {
    setup_colors
    setup_symbols
    setup_logging
    load_configuration
    
    log_info "XXMXLI Security Monitor v2.0 initialized"
    log_debug "Using search tool: $SEARCH_TOOL"
    log_debug "Configuration loaded: timeout=${SEARCH_TIMEOUT}s, log_retention=${LOG_RETENTION_DAYS}d"
}

# Show enhanced banner
show_banner() {
    clear
    echo -e "${RED}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║              ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗          ║
    ║              ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║          ║
    ║               ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║          ║
    ║               ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║          ║
    ║              ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗     ║
    ║              ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝     ║
    ║                                                              ║
    ║               OPTIMIZED SECURITY MONITORING v2.0            ║
    ║           Enhanced Performance • Better Error Handling       ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}        ${LIGHTNING} Performance Optimized • ${GEAR} Configuration Driven${NC}"
    echo -e "${GREEN}        ${SHIELD} Using: $SEARCH_TOOL for searches • Timeout: ${SEARCH_TIMEOUT}s${NC}"
    echo ""
}

# Enhanced interactive menu
show_interactive_menu() {
    show_banner
    
    echo -e "${WHITE}${ARROW} OPTIMIZED SECURITY MONITORING OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC}  ${SHIELD} Security Status Check (Enhanced)"
    echo -e "${GREEN}2)${NC}  ${CHART} Blocked IP Analysis (Fast)"
    echo -e "${GREEN}3)${NC}  ${EYE} Log Analysis (Optimized)"
    echo -e "${GREEN}4)${NC}  ${GEAR} System Performance Test"
    echo -e "${GREEN}5)${NC}  ${FIRE} Configuration Management"
    echo -e "${GREEN}6)${NC}  ${LIGHTNING} Debug Mode Toggle"
    echo -e "${GREEN}7)${NC}  ${INFO} Show System Info"
    echo -e "${GREEN}0)${NC}  ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "$(echo -e "${CYAN}Choose option [0-7]:${NC} ")" choice
    
    case "$choice" in
        1) security_status_check; read -p "Press Enter to continue..." ;;
        2) analyze_blocked_ips; read -p "Press Enter to continue..." ;;
        3) analyze_logs_optimized; read -p "Press Enter to continue..." ;;
        4) performance_test; read -p "Press Enter to continue..." ;;
        5) config_management; read -p "Press Enter to continue..." ;;
        6) toggle_debug_mode; show_interactive_menu ;;
        7) show_system_info; read -p "Press Enter to continue..." ;;
        0) log_info "Exiting security monitor"; exit 0 ;;
        *) log_error "Invalid option: $choice"; sleep 1 ;;
    esac
    
    show_interactive_menu
}

# Performance testing
performance_test() {
    echo -e "${PURPLE}${LIGHTNING} PERFORMANCE TEST${NC}"
    echo "================================================================"
    echo ""
    
    log_info "Testing search tool performance..."
    
    local test_file=".htaccess"
    if [[ ! -f "$test_file" ]]; then
        log_error "Test file not found: $test_file"
        return 1
    fi
    
    local start_time end_time duration
    
    for tool in grep rg ag awk; do
        if command -v "$tool" >/dev/null 2>&1; then
            start_time=$(date +%s%N)
            case "$tool" in
                "rg") rg --color=never "Require not ip" "$test_file" >/dev/null 2>&1 ;;
                "ag") ag --nocolor "Require not ip" "$test_file" >/dev/null 2>&1 ;;
                "awk") awk '/Require not ip/' "$test_file" >/dev/null 2>&1 ;;
                *) grep "Require not ip" "$test_file" >/dev/null 2>&1 ;;
            esac
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            
            if [[ "$tool" == "$SEARCH_TOOL" ]]; then
                echo -e "${GREEN}${CHECK} $tool: ${duration}ms (CURRENT)${NC}"
            else
                echo -e "${CYAN}${INFO} $tool: ${duration}ms${NC}"
            fi
        else
            echo -e "${YELLOW}${WARNING} $tool: not installed${NC}"
        fi
    done
}

# Configuration management
config_management() {
    echo -e "${PURPLE}${GEAR} CONFIGURATION MANAGEMENT${NC}"
    echo "================================================================"
    echo ""
    
    echo "Current configuration:"
    echo "  Search tool: $SEARCH_TOOL"
    echo "  Search timeout: ${SEARCH_TIMEOUT}s"
    echo "  Log retention: ${LOG_RETENTION_DAYS} days"
    echo "  Max log size: ${MAX_LOG_SIZE}MB"
    echo "  Notifications: $ENABLE_NOTIFICATIONS"
    echo ""
    
    echo "Configuration files checked:"
    [[ -f "$CONFIG_JSON" ]] && echo -e "${GREEN}  ✓ JSON: $CONFIG_JSON${NC}" || echo -e "${YELLOW}  - JSON: $CONFIG_JSON (not found)${NC}"
    [[ -f "$CONFIG_YAML" ]] && echo -e "${GREEN}  ✓ YAML: $CONFIG_YAML${NC}" || echo -e "${YELLOW}  - YAML: $CONFIG_YAML (not found)${NC}"
    [[ -f "$CONFIG_FILE" ]] && echo -e "${GREEN}  ✓ CONF: $CONFIG_FILE${NC}" || echo -e "${YELLOW}  - CONF: $CONFIG_FILE (not found)${NC}"
}

# Debug mode toggle
toggle_debug_mode() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        DEBUG=false
        log_info "Debug mode disabled"
    else
        DEBUG=true
        log_info "Debug mode enabled"
    fi
}

# System information
show_system_info() {
    echo -e "${PURPLE}${INFO} SYSTEM INFORMATION${NC}"
    echo "================================================================"
    echo ""
    
    echo "Script directory: $SCRIPT_DIR"
    echo "Available tools:"
    for tool in rg ag awk grep jq yq timeout; do
        if command -v "$tool" >/dev/null 2>&1; then
            local version
            case "$tool" in
                "rg") version=$(rg --version | head -1) ;;
                "ag") version=$(ag --version | head -1) ;;
                "jq") version=$(jq --version) ;;
                *) version="installed" ;;
            esac
            echo -e "${GREEN}  ✓ $tool ($version)${NC}"
        else
            echo -e "${YELLOW}  - $tool (not available)${NC}"
        fi
    done
    
    echo ""
    echo "Log files:"
    [[ -f "$LOG_FILE" ]] && echo "  Main log: $LOG_FILE ($(du -h "$LOG_FILE" 2>/dev/null | cut -f1))"
    [[ -f "$DEBUG_LOG" ]] && echo "  Debug log: $DEBUG_LOG ($(du -h "$DEBUG_LOG" 2>/dev/null | cut -f1))"
}

# Main execution
main() {
    # Handle command line arguments
    case "${1:-}" in
        "--debug"|"-d")
            DEBUG=true
            shift
            ;;
        "--help"|"-h")
            echo "Usage: $0 [--debug] [--help]"
            echo "  --debug    Enable debug mode"
            echo "  --help     Show this help"
            exit 0
            ;;
    esac
    
    # Initialize system
    init_system
    
    # Run interactive mode
    show_interactive_menu
}

# Trap for cleanup
trap 'log_info "Security monitor terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi