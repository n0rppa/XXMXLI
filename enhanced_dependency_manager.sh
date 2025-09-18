#!/bin/bash

# ================================================================
# XXMXLI Enhanced Dependency Manager & Cross-Platform Compatibility Tool v2.0
# Manages dependencies, ensures cross-platform compatibility, and provides predictive maintenance
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
DEPS_LOG="$LOG_DIR/dependency_management.log"
COMPAT_LOG="$LOG_DIR/compatibility_check.log"

# Colors and symbols for cross-platform output
setup_output() {
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
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi
    
    # Unicode symbols with ASCII fallbacks
    if [[ "${LANG:-}" =~ UTF-8 ]] || [[ "${LC_ALL:-}" =~ UTF-8 ]]; then
        CHECK="✅"
        CROSS="❌"
        WARNING="⚠️"
        INFO="ℹ️"
        GEAR="⚙️"
        PACKAGE="📦"
        COMPUTER="💻"
        SHIELD="🛡️"
        ROCKET="🚀"
        TARGET="🎯"
    else
        CHECK="[OK]"
        CROSS="[ERR]"
        WARNING="[WARN]"
        INFO="[INFO]"
        GEAR="[CFG]"
        PACKAGE="[PKG]"
        COMPUTER="[SYS]"
        SHIELD="[SEC]"
        ROCKET="[PERF]"
        TARGET="[FIX]"
    fi
}

# Enhanced logging with multiple outputs
log_dependency() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" 2>/dev/null
    
    # Log to file
    echo "[$timestamp] $level: $message" >> "$DEPS_LOG"
    
    # Display with colors
    case "$level" in
        "SUCCESS") echo -e "${GREEN}${CHECK}${NC} $message" ;;
        "ERROR") echo -e "${RED}${CROSS}${NC} $message" >&2 ;;
        "WARNING") echo -e "${YELLOW}${WARNING}${NC} $message" ;;
        "INFO") echo -e "${CYAN}${INFO}${NC} $message" ;;
        "SYSTEM") echo -e "${BLUE}${COMPUTER}${NC} $message" ;;
        "PACKAGE") echo -e "${PURPLE}${PACKAGE}${NC} $message" ;;
        "SECURITY") echo -e "${BLUE}${SHIELD}${NC} $message" ;;
        "PERFORMANCE") echo -e "${GREEN}${ROCKET}${NC} $message" ;;
        "TARGET") echo -e "${YELLOW}${TARGET}${NC} $message" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

# Platform detection with detailed information
detect_platform() {
    log_dependency "SYSTEM" "Detecting platform and environment"
    
    # Basic OS detection
    OS=""
    DISTRO=""
    VERSION=""
    ARCH=""
    PACKAGE_MANAGER=""
    SHELL_TYPE=""
    
    # Determine OS
    case "$OSTYPE" in
        linux*)
            OS="Linux"
            ARCH=$(uname -m)
            
            # Detect distribution
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                DISTRO="$NAME"
                VERSION="$VERSION_ID"
            elif [[ -f /etc/redhat-release ]]; then
                DISTRO=$(cat /etc/redhat-release | cut -d' ' -f1)
                VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
            elif [[ -f /etc/debian_version ]]; then
                DISTRO="Debian"
                VERSION=$(cat /etc/debian_version)
            fi
            
            # Detect package manager
            if command -v apt >/dev/null 2>&1; then
                PACKAGE_MANAGER="apt"
            elif command -v yum >/dev/null 2>&1; then
                PACKAGE_MANAGER="yum"
            elif command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            elif command -v pacman >/dev/null 2>&1; then
                PACKAGE_MANAGER="pacman"
            elif command -v zypper >/dev/null 2>&1; then
                PACKAGE_MANAGER="zypper"
            elif command -v emerge >/dev/null 2>&1; then
                PACKAGE_MANAGER="emerge"
            fi
            ;;
        darwin*)
            OS="macOS"
            DISTRO="macOS"
            VERSION=$(sw_vers -productVersion 2>/dev/null)
            ARCH=$(uname -m)
            if command -v brew >/dev/null 2>&1; then
                PACKAGE_MANAGER="brew"
            elif command -v port >/dev/null 2>&1; then
                PACKAGE_MANAGER="macports"
            fi
            ;;
        msys*|mingw*|cygwin*)
            OS="Windows"
            DISTRO="Windows"
            ARCH=$(uname -m)
            if command -v pacman >/dev/null 2>&1; then
                PACKAGE_MANAGER="pacman"  # MSYS2
            elif command -v choco >/dev/null 2>&1; then
                PACKAGE_MANAGER="chocolatey"
            elif command -v winget >/dev/null 2>&1; then
                PACKAGE_MANAGER="winget"
            fi
            ;;
        freebsd*)
            OS="FreeBSD"
            DISTRO="FreeBSD"
            VERSION=$(uname -r)
            ARCH=$(uname -m)
            PACKAGE_MANAGER="pkg"
            ;;
        *)
            OS="Unknown"
            DISTRO="Unknown"
            VERSION="Unknown"
            ARCH=$(uname -m 2>/dev/null || echo "Unknown")
            ;;
    esac
    
    # Detect shell
    SHELL_TYPE=$(basename "${SHELL:-/bin/bash}")
    
    # Display platform information
    log_dependency "SYSTEM" "Platform: $OS ($DISTRO $VERSION)"
    log_dependency "SYSTEM" "Architecture: $ARCH"
    log_dependency "SYSTEM" "Package Manager: ${PACKAGE_MANAGER:-None detected}"
    log_dependency "SYSTEM" "Shell: $SHELL_TYPE"
    
    # Export for other functions
    export DETECTED_OS="$OS"
    export DETECTED_DISTRO="$DISTRO"
    export DETECTED_VERSION="$VERSION"
    export DETECTED_ARCH="$ARCH"
    export DETECTED_PACKAGE_MANAGER="$PACKAGE_MANAGER"
    export DETECTED_SHELL="$SHELL_TYPE"
}

# Comprehensive dependency checker
check_dependencies() {
    log_dependency "INFO" "Starting comprehensive dependency analysis"
    
    # Define dependency categories
    local -A CRITICAL_DEPS=(
        ["bash"]="Shell interpreter"
        ["grep"]="Text searching"
        ["awk"]="Text processing"
        ["sed"]="Stream editing"
        ["curl"]="HTTP client"
        ["wget"]="Web downloader"
    )
    
    local -A SECURITY_DEPS=(
        ["nmap"]="Network scanning"
        ["netstat"]="Network statistics"
        ["ss"]="Socket statistics"
        ["iptables"]="Firewall management"
        ["fail2ban"]="Intrusion prevention"
        ["ufw"]="Uncomplicated firewall"
    )
    
    local -A PERFORMANCE_DEPS=(
        ["rg"]="Fast text search (ripgrep)"
        ["ag"]="Silver searcher"
        ["jq"]="JSON processor"
        ["yq"]="YAML processor"
        ["timeout"]="Command timeout"
        ["parallel"]="Parallel processing"
    )
    
    local -A SYSTEM_DEPS=(
        ["systemctl"]="System service control"
        ["service"]="Legacy service control"
        ["crontab"]="Task scheduling"
        ["logrotate"]="Log management"
        ["rsync"]="File synchronization"
        ["tar"]="Archive management"
    )
    
    # Check each category
    check_dependency_category "CRITICAL" CRITICAL_DEPS
    check_dependency_category "SECURITY" SECURITY_DEPS
    check_dependency_category "PERFORMANCE" PERFORMANCE_DEPS
    check_dependency_category "SYSTEM" SYSTEM_DEPS
    
    # Generate dependency report
    generate_dependency_report
}

# Check specific dependency category
check_dependency_category() {
    local category="$1"
    local -n deps_ref=$2
    
    log_dependency "INFO" "Checking $category dependencies"
    
    local missing_deps=()
    local available_deps=()
    
    for dep in "${!deps_ref[@]}"; do
        local description="${deps_ref[$dep]}"
        
        if command -v "$dep" >/dev/null 2>&1; then
            local version=$(get_tool_version "$dep")
            log_dependency "SUCCESS" "$dep ($description) - $version"
            available_deps+=("$dep")
        else
            log_dependency "WARNING" "$dep ($description) - MISSING"
            missing_deps+=("$dep")
        fi
    done
    
    # Store results for report generation
    eval "MISSING_${category}_DEPS=(\"\${missing_deps[@]}\")"
    eval "AVAILABLE_${category}_DEPS=(\"\${available_deps[@]}\")"
}

# Get tool version information
get_tool_version() {
    local tool="$1"
    local version="Unknown"
    
    case "$tool" in
        "bash") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
        "grep") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1) ;;
        "awk") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
        "curl") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
        "rg") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1) ;;
        "jq") version=$($tool --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1) ;;
        "nmap") version=$($tool --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1) ;;
        *) 
            # Try generic version detection
            for flag in "--version" "-V" "-v" "version"; do
                if version=$($tool $flag 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1); then
                    break
                fi
            done
            ;;
    esac
    
    echo "${version:-Available}"
}

# Install missing dependencies
install_missing_dependencies() {
    local auto_install="${1:-false}"
    
    log_dependency "PACKAGE" "Preparing dependency installation"
    
    if [[ -z "$DETECTED_PACKAGE_MANAGER" ]]; then
        log_dependency "ERROR" "No package manager detected. Cannot auto-install dependencies."
        return 1
    fi
    
    # Combine all missing dependencies
    local all_missing=()
    all_missing+=("${MISSING_CRITICAL_DEPS[@]:-}")
    all_missing+=("${MISSING_SECURITY_DEPS[@]:-}")
    all_missing+=("${MISSING_PERFORMANCE_DEPS[@]:-}")
    all_missing+=("${MISSING_SYSTEM_DEPS[@]:-}")
    
    if [[ ${#all_missing[@]} -eq 0 ]]; then
        log_dependency "SUCCESS" "All dependencies are already installed"
        return 0
    fi
    
    log_dependency "INFO" "Missing dependencies: ${all_missing[*]}"
    
    # Generate installation commands
    local install_commands=()
    generate_install_commands install_commands "${all_missing[@]}"
    
    if [[ "$auto_install" == "true" ]]; then
        log_dependency "PACKAGE" "Auto-installing missing dependencies"
        execute_install_commands "${install_commands[@]}"
    else
        log_dependency "INFO" "Manual installation required. Commands:"
        for cmd in "${install_commands[@]}"; do
            log_dependency "TARGET" "$cmd"
        done
        
        echo ""
        read -p "Would you like to install missing dependencies now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            execute_install_commands "${install_commands[@]}"
        fi
    fi
}

# Generate installation commands based on package manager
generate_install_commands() {
    local -n cmd_array=$1
    shift
    local missing_deps=("$@")
    
    case "$DETECTED_PACKAGE_MANAGER" in
        "apt")
            cmd_array+=("sudo apt update")
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "rg") cmd_array+=("sudo apt install ripgrep") ;;
                    "ag") cmd_array+=("sudo apt install silversearcher-ag") ;;
                    "jq") cmd_array+=("sudo apt install jq") ;;
                    "yq") cmd_array+=("wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq") ;;
                    "nmap") cmd_array+=("sudo apt install nmap") ;;
                    "fail2ban") cmd_array+=("sudo apt install fail2ban") ;;
                    "ufw") cmd_array+=("sudo apt install ufw") ;;
                    *) cmd_array+=("sudo apt install $dep") ;;
                esac
            done
            ;;
        "yum"|"dnf")
            local pkg_cmd="$DETECTED_PACKAGE_MANAGER"
            cmd_array+=("sudo $pkg_cmd update")
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "rg") cmd_array+=("sudo $pkg_cmd install ripgrep") ;;
                    "ag") cmd_array+=("sudo $pkg_cmd install the_silver_searcher") ;;
                    "jq") cmd_array+=("sudo $pkg_cmd install jq") ;;
                    *) cmd_array+=("sudo $pkg_cmd install $dep") ;;
                esac
            done
            ;;
        "pacman")
            cmd_array+=("sudo pacman -Sy")
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "rg") cmd_array+=("sudo pacman -S ripgrep") ;;
                    "ag") cmd_array+=("sudo pacman -S the_silver_searcher") ;;
                    "jq") cmd_array+=("sudo pacman -S jq") ;;
                    *) cmd_array+=("sudo pacman -S $dep") ;;
                esac
            done
            ;;
        "brew")
            cmd_array+=("brew update")
            for dep in "${missing_deps[@]}"; do
                case "$dep" in
                    "rg") cmd_array+=("brew install ripgrep") ;;
                    "ag") cmd_array+=("brew install the_silver_searcher") ;;
                    *) cmd_array+=("brew install $dep") ;;
                esac
            done
            ;;
        *)
            log_dependency "WARNING" "Unsupported package manager: $DETECTED_PACKAGE_MANAGER"
            ;;
    esac
}

# Execute installation commands
execute_install_commands() {
    local commands=("$@")
    
    for cmd in "${commands[@]}"; do
        log_dependency "PACKAGE" "Executing: $cmd"
        if eval "$cmd"; then
            log_dependency "SUCCESS" "Command completed successfully"
        else
            log_dependency "ERROR" "Command failed: $cmd"
        fi
    done
}

# Cross-platform compatibility checker
check_cross_platform_compatibility() {
    log_dependency "INFO" "Checking cross-platform compatibility"
    
    # Find all scripts to check
    local scripts=()
    while IFS= read -r -d '' script; do
        scripts+=("$script")
    done < <(find . -name "*.sh" -type f -print0 2>/dev/null)
    
    log_dependency "INFO" "Found ${#scripts[@]} shell scripts to analyze"
    
    # Check each script
    for script in "${scripts[@]}"; do
        if [[ ! "$script" =~ _test\.|_fixed\.|_optimized\. ]]; then
            analyze_script_compatibility "$script"
        fi
    done
    
    # Generate compatibility report
    generate_compatibility_report
}

# Analyze individual script for compatibility issues
analyze_script_compatibility() {
    local script_file="$1"
    local script_name=$(basename "$script_file")
    
    log_dependency "INFO" "Analyzing: $script_name"
    
    local issues=()
    
    # Check for Linux-specific commands
    local linux_commands=("apt" "yum" "systemctl" "service" "ifconfig" "netstat" "iptables" "ufw")
    for cmd in "${linux_commands[@]}"; do
        if grep -q "\\b$cmd\\b" "$script_file" 2>/dev/null; then
            issues+=("LINUX:$cmd")
            log_dependency "WARNING" "$script_name uses Linux-specific command: $cmd"
        fi
    done
    
    # Check for Windows-specific patterns
    if grep -q "C:\\\\\|\.exe\|\.bat\|\.cmd\|powershell" "$script_file" 2>/dev/null; then
        issues+=("WINDOWS:path_patterns")
        log_dependency "WARNING" "$script_name contains Windows-specific patterns"
    fi
    
    # Check for bash-specific features
    if grep -q "\\[\\[.*\\]\\]\|declare\|local" "$script_file" 2>/dev/null; then
        issues+=("BASH:bash_specific")
        log_dependency "INFO" "$script_name uses bash-specific features"
    fi
    
    # Check for hardcoded paths
    if grep -q "/home/\|/usr/local/\|/etc/\|/var/" "$script_file" 2>/dev/null; then
        issues+=("PATHS:hardcoded")
        log_dependency "WARNING" "$script_name contains hardcoded paths"
    fi
    
    # Check for unsafe operations
    if grep -q "rm.*-rf.*\\\$\|sudo.*\\\$" "$script_file" 2>/dev/null; then
        issues+=("SECURITY:unsafe_operations")
        log_dependency "ERROR" "$script_name contains potentially unsafe operations"
    fi
    
    # Store issues for reporting
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "${script_file}:${issues[*]}" >> "$LOG_DIR/compatibility_issues.tmp"
    fi
}

# Generate comprehensive dependency report
generate_dependency_report() {
    local report_file="$LOG_DIR/dependency_report_$(date +%Y%m%d_%H%M%S).json"
    
    log_dependency "INFO" "Generating dependency report"
    
    {
        echo "{"
        echo "  \"dependency_report\": {"
        echo "    \"timestamp\": \"$(date -Iseconds)\","
        echo "    \"platform\": {"
        echo "      \"os\": \"$DETECTED_OS\","
        echo "      \"distribution\": \"$DETECTED_DISTRO\","
        echo "      \"version\": \"$DETECTED_VERSION\","
        echo "      \"architecture\": \"$DETECTED_ARCH\","
        echo "      \"package_manager\": \"$DETECTED_PACKAGE_MANAGER\","
        echo "      \"shell\": \"$DETECTED_SHELL\""
        echo "    },"
        echo "    \"categories\": {"
        
        # Critical dependencies
        echo "      \"critical\": {"
        echo "        \"available\": [$(printf '"%s",' "${AVAILABLE_CRITICAL_DEPS[@]:-}" | sed 's/,$//')],"
        echo "        \"missing\": [$(printf '"%s",' "${MISSING_CRITICAL_DEPS[@]:-}" | sed 's/,$//')]"
        echo "      },"
        
        # Security dependencies
        echo "      \"security\": {"
        echo "        \"available\": [$(printf '"%s",' "${AVAILABLE_SECURITY_DEPS[@]:-}" | sed 's/,$//')],"
        echo "        \"missing\": [$(printf '"%s",' "${MISSING_SECURITY_DEPS[@]:-}" | sed 's/,$//')]"
        echo "      },"
        
        # Performance dependencies
        echo "      \"performance\": {"
        echo "        \"available\": [$(printf '"%s",' "${AVAILABLE_PERFORMANCE_DEPS[@]:-}" | sed 's/,$//')],"
        echo "        \"missing\": [$(printf '"%s",' "${MISSING_PERFORMANCE_DEPS[@]:-}" | sed 's/,$//')]"
        echo "      },"
        
        # System dependencies
        echo "      \"system\": {"
        echo "        \"available\": [$(printf '"%s",' "${AVAILABLE_SYSTEM_DEPS[@]:-}" | sed 's/,$//')],"
        echo "        \"missing\": [$(printf '"%s",' "${MISSING_SYSTEM_DEPS[@]:-}" | sed 's/,$//')]"
        echo "      }"
        echo "    },"
        echo "    \"recommendations\": ["
        
        # Generate recommendations
        local recommendations=()
        [[ ${#MISSING_CRITICAL_DEPS[@]} -gt 0 ]] && recommendations+=("\"Install critical dependencies immediately for basic functionality\"")
        [[ ${#MISSING_SECURITY_DEPS[@]} -gt 0 ]] && recommendations+=("\"Install security tools to enhance system protection\"")
        [[ ${#MISSING_PERFORMANCE_DEPS[@]} -gt 0 ]] && recommendations+=("\"Install performance tools to improve script execution speed\"")
        
        echo "      $(IFS=,; echo "${recommendations[*]}")"
        echo "    ]"
        echo "  }"
        echo "}"
    } > "$report_file"
    
    log_dependency "SUCCESS" "Dependency report generated: $report_file"
}

# Generate compatibility report
generate_compatibility_report() {
    local report_file="$LOG_DIR/compatibility_report_$(date +%Y%m%d_%H%M%S).json"
    
    log_dependency "INFO" "Generating compatibility report"
    
    {
        echo "{"
        echo "  \"compatibility_report\": {"
        echo "    \"timestamp\": \"$(date -Iseconds)\","
        echo "    \"target_platforms\": [\"Linux\", \"macOS\", \"Windows\", \"FreeBSD\"],"
        echo "    \"issues\": ["
        
        if [[ -f "$LOG_DIR/compatibility_issues.tmp" ]]; then
            local first=true
            while IFS=':' read -r script_file issues_list; do
                [[ "$first" == true ]] && first=false || echo ","
                echo "      {"
                echo "        \"script\": \"$script_file\","
                echo "        \"issues\": [$(echo "$issues_list" | sed 's/ /","/g' | sed 's/^/"/;s/$/"/')]"
                echo -n "      }"
            done < "$LOG_DIR/compatibility_issues.tmp"
            rm -f "$LOG_DIR/compatibility_issues.tmp"
        fi
        
        echo ""
        echo "    ],"
        echo "    \"recommendations\": ["
        echo "      \"Replace Linux-specific commands with cross-platform alternatives\","
        echo "      \"Use platform detection for conditional command execution\","
        echo "      \"Avoid hardcoded paths in favor of dynamic path detection\","
        echo "      \"Test scripts on multiple platforms before deployment\""
        echo "    ]"
        echo "  }"
        echo "}"
    } > "$report_file"
    
    log_dependency "SUCCESS" "Compatibility report generated: $report_file"
}

# Predictive maintenance scheduler
setup_predictive_maintenance() {
    log_dependency "INFO" "Setting up predictive maintenance"
    
    local cron_script="$SCRIPT_DIR/scheduled_dependency_check.sh"
    
    # Create maintenance script
    cat > "$cron_script" << 'EOF'
#!/bin/bash

# Automated dependency and compatibility check
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "$(date): Running scheduled dependency check" >> logs/maintenance.log

# Run dependency check
./enhanced_dependency_manager.sh --check-only >> logs/maintenance.log 2>&1

# Check if critical issues found
if grep -q "CRITICAL\|ERROR" logs/maintenance.log; then
    echo "$(date): ALERT - Critical issues found in dependency check" >> logs/maintenance.log
    # Here you could add email notifications or other alerting mechanisms
fi

echo "$(date): Scheduled dependency check completed" >> logs/maintenance.log
EOF

    chmod +x "$cron_script"
    
    # Suggest cron schedule
    echo ""
    log_dependency "INFO" "Predictive maintenance script created: $cron_script"
    log_dependency "INFO" "Suggested cron schedule (add to crontab):"
    log_dependency "TARGET" "# Daily dependency check at 2 AM"
    log_dependency "TARGET" "0 2 * * * $cron_script"
    log_dependency "TARGET" ""
    log_dependency "TARGET" "# Weekly compatibility check on Sundays at 3 AM"
    log_dependency "TARGET" "0 3 * * 0 $SCRIPT_DIR/enhanced_dependency_manager.sh --compatibility"
    echo ""
}

# Interactive menu
show_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           XXMXLI Enhanced Dependency Manager v2.0           ║"
    echo "║     Cross-Platform Compatibility & Predictive Maintenance   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${WHITE}${GEAR} DEPENDENCY MANAGEMENT OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${COMPUTER} Detect Platform & Environment"
    echo -e "${GREEN}2)${NC} ${PACKAGE} Check All Dependencies"
    echo -e "${GREEN}3)${NC} ${ROCKET} Install Missing Dependencies"
    echo -e "${GREEN}4)${NC} ${SHIELD} Cross-Platform Compatibility Check"
    echo -e "${GREEN}5)${NC} ${TARGET} Setup Predictive Maintenance"
    echo -e "${GREEN}6)${NC} ${INFO} Generate Reports"
    echo -e "${GREEN}7)${NC} ${GEAR} View Configuration"
    echo -e "${GREEN}0)${NC} ${CROSS} Exit"
    echo ""
    
    local choice
    read -p "Choose option [0-7]: " choice
    
    case "$choice" in
        1) detect_platform ;;
        2) check_dependencies ;;
        3) install_missing_dependencies ;;
        4) check_cross_platform_compatibility ;;
        5) setup_predictive_maintenance ;;
        6) 
            echo "📊 Available reports in: $LOG_DIR"
            ls -la "$LOG_DIR"/*.json 2>/dev/null || echo "No reports found"
            ;;
        7)
            echo "📋 Configuration files:"
            echo "  Logs: $LOG_DIR"
            echo "  Config: $CONFIG_DIR"
            ;;
        0) log_dependency "INFO" "Exiting dependency manager"; exit 0 ;;
        *) log_dependency "WARNING" "Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_menu
}

# Main execution
main() {
    # Initialize
    setup_output
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" 2>/dev/null
    
    # Clear old logs
    > "$DEPS_LOG" 2>/dev/null
    > "$COMPAT_LOG" 2>/dev/null
    
    # Handle command line arguments
    case "${1:-}" in
        "--detect")
            detect_platform
            ;;
        "--check")
            detect_platform
            check_dependencies
            ;;
        "--check-only")
            detect_platform
            check_dependencies
            ;;
        "--install")
            detect_platform
            check_dependencies
            install_missing_dependencies true
            ;;
        "--compatibility")
            detect_platform
            check_cross_platform_compatibility
            ;;
        "--setup-maintenance")
            setup_predictive_maintenance
            ;;
        "--all")
            detect_platform
            check_dependencies
            check_cross_platform_compatibility
            setup_predictive_maintenance
            ;;
        "--help"|"-h")
            echo "XXMXLI Enhanced Dependency Manager v2.0"
            echo ""
            echo "Usage: $0 [option]"
            echo ""
            echo "Options:"
            echo "  --detect              Detect platform only"
            echo "  --check               Check dependencies"
            echo "  --check-only          Check dependencies (no interactive prompts)"
            echo "  --install             Auto-install missing dependencies"
            echo "  --compatibility       Check cross-platform compatibility"
            echo "  --setup-maintenance   Setup predictive maintenance"
            echo "  --all                 Run all checks and setup"
            echo "  --help, -h            Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            detect_platform
            show_menu
            ;;
        *)
            log_dependency "ERROR" "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Trap for cleanup
trap 'log_dependency "INFO" "Dependency manager terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi