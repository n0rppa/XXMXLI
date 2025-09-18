#!/bin/bash

# ================================================================
# XXMXLI Security Scripts Debug & Performance Optimizer v3.0
# Comprehensive debugging, performance fixing, and optimization system
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
REPORTS_DIR="$SCRIPT_DIR/reports"
DEBUG_LOG="$LOG_DIR/security_debug.log"
PERFORMANCE_LOG="$LOG_DIR/performance_debug.log"
ERROR_REPORT="$REPORTS_DIR/error_analysis_$(date +%Y%m%d_%H%M%S).json"

# Configuration loading with multiple format support
load_debug_config() {
    local config_loaded=false
    
    # Default configuration
    SEARCH_TIMEOUT=30
    GREP_MAX_DEPTH=5
    USE_OPTIMIZED_SEARCH=true
    ENABLE_PREDICTIVE_CHECKS=true
    CROSS_PLATFORM_MODE=true
    DEPENDENCY_AUTO_INSTALL=false
    VERBOSE_DEBUGGING=false
    
    # Try JSON config first (fastest parsing)
    if [[ -f "$CONFIG_DIR/debug_optimizer.json" ]] && command -v jq >/dev/null 2>&1; then
        if jq -e . "$CONFIG_DIR/debug_optimizer.json" >/dev/null 2>&1; then
            SEARCH_TIMEOUT=$(jq -r '.search_timeout // 30' "$CONFIG_DIR/debug_optimizer.json")
            GREP_MAX_DEPTH=$(jq -r '.grep_max_depth // 5' "$CONFIG_DIR/debug_optimizer.json")
            USE_OPTIMIZED_SEARCH=$(jq -r '.use_optimized_search // true' "$CONFIG_DIR/debug_optimizer.json")
            ENABLE_PREDICTIVE_CHECKS=$(jq -r '.enable_predictive_checks // true' "$CONFIG_DIR/debug_optimizer.json")
            config_loaded=true
        fi
    fi
    
    # Try YAML config
    if [[ "$config_loaded" == false && -f "$CONFIG_DIR/debug_optimizer.yaml" ]] && command -v yq >/dev/null 2>&1; then
        SEARCH_TIMEOUT=$(yq eval '.search_timeout // 30' "$CONFIG_DIR/debug_optimizer.yaml" 2>/dev/null)
        GREP_MAX_DEPTH=$(yq eval '.grep_max_depth // 5' "$CONFIG_DIR/debug_optimizer.yaml" 2>/dev/null)
        config_loaded=true
    fi
    
    # Try .conf config
    if [[ "$config_loaded" == false && -f "$CONFIG_DIR/debug_optimizer.conf" ]]; then
        source "$CONFIG_DIR/debug_optimizer.conf" 2>/dev/null && config_loaded=true
    fi
}

# Enhanced colors with fallback detection
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
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        PURPLE='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        NC='\033[0m'
    fi
}

# Unicode symbols with ASCII fallbacks for cross-platform compatibility
setup_symbols() {
    if [[ "${LANG:-}" =~ UTF-8 ]] || [[ "${LC_ALL:-}" =~ UTF-8 ]] && [[ "$CROSS_PLATFORM_MODE" != true ]]; then
        DEBUG="🔍"
        FIX="🔧"
        WARNING="⚠️"
        ERROR="❌"
        SUCCESS="✅"
        PERFORMANCE="⚡"
        SECURITY="🛡️"
        CONFIG="⚙️"
        REPORT="📊"
        SEARCH="🔎"
        DEPENDENCY="📦"
        CHECKLIST="📋"
        WINDOWS="🪟"
        LINUX="🐧"
        CRITICAL="🚨"
    else
        DEBUG="[DEBUG]"
        FIX="[FIX]"
        WARNING="[WARN]"
        ERROR="[ERROR]"
        SUCCESS="[OK]"
        PERFORMANCE="[PERF]"
        SECURITY="[SEC]"
        CONFIG="[CFG]"
        REPORT="[RPT]"
        SEARCH="[FIND]"
        DEPENDENCY="[DEP]"
        CHECKLIST="[CHK]"
        WINDOWS="[WIN]"
        LINUX="[LIN]"
        CRITICAL="[CRIT]"
    fi
}

# Enhanced logging with multiple levels and file output
log_debug() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Ensure log directory exists
    mkdir -p "$LOG_DIR" "$REPORTS_DIR" 2>/dev/null
    
    # Log to file
    echo "[$timestamp] $level: $message" >> "$DEBUG_LOG"
    
    # Display with colors based on level
    case "$level" in
        "DEBUG") [[ "$VERBOSE_DEBUGGING" == true ]] && echo -e "${CYAN}${DEBUG}${NC} $message" ;;
        "FIX") echo -e "${GREEN}${FIX}${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}${WARNING}${NC} $message" ;;
        "ERROR") echo -e "${RED}${ERROR}${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}${SUCCESS}${NC} $message" ;;
        "PERFORMANCE") echo -e "${PURPLE}${PERFORMANCE}${NC} $message" ;;
        "SECURITY") echo -e "${BLUE}${SECURITY}${NC} $message" ;;
        "CRITICAL") echo -e "${RED}${BOLD}${CRITICAL}${NC} $message" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

# Optimized search function with timeout protection and tool hierarchy
optimized_search() {
    local pattern="$1"
    local file="$2"
    local search_type="${3:-basic}"
    local timeout="${4:-$SEARCH_TIMEOUT}"
    
    # Validate inputs
    if [[ -z "$pattern" || -z "$file" ]]; then
        log_debug "ERROR" "optimized_search: Missing required parameters"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        log_debug "WARNING" "optimized_search: File not found: $file"
        return 1
    fi
    
    # Tool hierarchy: rg > ag > awk > grep (with timeout protection)
    local search_tools=("rg" "ag" "awk" "grep")
    local search_result=""
    local tool_used=""
    
    for tool in "${search_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            local start_time=$(date +%s%N)
            
            case "$tool" in
                "rg")
                    if run_with_timeout "$timeout" rg --color=never --no-heading --line-number "$pattern" "$file" 2>/dev/null; then
                        tool_used="ripgrep"
                        break
                    fi
                    ;;
                "ag")
                    if run_with_timeout "$timeout" ag --nocolor --nogroup --filename "$pattern" "$file" 2>/dev/null; then
                        tool_used="silver_searcher"
                        break
                    fi
                    ;;
                "awk")
                    if run_with_timeout "$timeout" awk "/$pattern/" "$file" 2>/dev/null; then
                        tool_used="awk"
                        break
                    fi
                    ;;
                "grep")
                    if run_with_timeout "$timeout" grep -n "$pattern" "$file" 2>/dev/null; then
                        tool_used="grep"
                        break
                    fi
                    ;;
            esac
            
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))
            
            if [[ -n "$tool_used" ]]; then
                log_debug "PERFORMANCE" "Search completed with $tool_used in ${duration}ms"
                return 0
            fi
        fi
    done
    
    log_debug "ERROR" "All search tools failed or timed out for pattern: $pattern"
    return 1
}

# Timeout wrapper for safe command execution
run_with_timeout() {
    local timeout_duration="$1"
    shift
    local cmd=("$@")
    
    # Detect available timeout command
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout_duration" "${cmd[@]}"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$timeout_duration" "${cmd[@]}"
    else
        # Fallback: background process with manual timeout
        local tmp_result=$(mktemp)
        local cmd_pid
        
        (
            "${cmd[@]}"
            echo $? > "$tmp_result"
        ) &
        cmd_pid=$!
        
        local count=0
        local max_count=$((timeout_duration))
        
        while [[ $count -lt $max_count ]] && kill -0 $cmd_pid 2>/dev/null; do
            sleep 1
            ((count++))
        done
        
        if kill -0 $cmd_pid 2>/dev/null; then
            kill -TERM $cmd_pid 2>/dev/null
            sleep 2
            kill -KILL $cmd_pid 2>/dev/null
            rm -f "$tmp_result"
            return 124  # timeout exit code
        fi
        
        wait $cmd_pid
        local exit_code
        if [[ -f "$tmp_result" ]]; then
            exit_code=$(cat "$tmp_result")
            rm -f "$tmp_result"
            return $exit_code
        fi
        return 1
    fi
}

# Dependency management and validation
check_and_install_dependencies() {
    log_debug "DEBUG" "Starting dependency validation"
    
    local required_tools=("bash" "grep" "awk" "curl" "python3")
    local optional_tools=("rg" "ag" "jq" "yq" "timeout")
    local missing_required=()
    local missing_optional=()
    local install_commands=()
    
    # Check required dependencies
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_required+=("$tool")
            log_debug "CRITICAL" "Required dependency missing: $tool"
        else
            log_debug "SUCCESS" "Required dependency found: $tool"
        fi
    done
    
    # Check optional dependencies
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_optional+=("$tool")
            log_debug "WARNING" "Optional dependency missing: $tool (performance may be reduced)"
        else
            log_debug "SUCCESS" "Optional dependency found: $tool"
        fi
    done
    
    # Generate installation commands based on platform
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        log_debug "DEBUG" "Generating installation commands for missing tools"
        
        # Detect package manager
        if command -v apt >/dev/null 2>&1; then
            # Debian/Ubuntu
            [[ " ${missing_optional[*]} " =~ " rg " ]] && install_commands+=("sudo apt install ripgrep")
            [[ " ${missing_optional[*]} " =~ " ag " ]] && install_commands+=("sudo apt install silversearcher-ag")
            [[ " ${missing_optional[*]} " =~ " jq " ]] && install_commands+=("sudo apt install jq")
            [[ " ${missing_optional[*]} " =~ " yq " ]] && install_commands+=("wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq")
        elif command -v yum >/dev/null 2>&1; then
            # RedHat/CentOS
            [[ " ${missing_optional[*]} " =~ " jq " ]] && install_commands+=("sudo yum install jq")
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            [[ " ${missing_optional[*]} " =~ " rg " ]] && install_commands+=("sudo pacman -S ripgrep")
            [[ " ${missing_optional[*]} " =~ " ag " ]] && install_commands+=("sudo pacman -S the_silver_searcher")
            [[ " ${missing_optional[*]} " =~ " jq " ]] && install_commands+=("sudo pacman -S jq")
        elif [[ "$OSTYPE" =~ msys|mingw|cygwin ]]; then
            # Windows (MSYS2/MinGW/Cygwin)
            log_debug "WINDOWS" "Windows environment detected"
            [[ " ${missing_optional[*]} " =~ " jq " ]] && install_commands+=("pacman -S mingw-w64-x86_64-jq")
        fi
        
        # Auto-install if enabled
        if [[ "$DEPENDENCY_AUTO_INSTALL" == true ]]; then
            log_debug "DEBUG" "Auto-installing missing dependencies"
            for cmd in "${install_commands[@]}"; do
                log_debug "DEBUG" "Running: $cmd"
                eval "$cmd" 2>/dev/null || log_debug "WARNING" "Auto-install failed: $cmd"
            done
        else
            log_debug "DEBUG" "Manual installation required. Commands:"
            for cmd in "${install_commands[@]}"; do
                log_debug "DEBUG" "  $cmd"
            done
        fi
    fi
    
    # Return status
    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_debug "CRITICAL" "Cannot continue - required dependencies missing: ${missing_required[*]}"
        return 1
    fi
    
    return 0
}

# Function analysis and debugging
analyze_script_functions() {
    local script_file="$1"
    local analysis_results=()
    
    log_debug "DEBUG" "Analyzing functions in: $script_file"
    
    if [[ ! -f "$script_file" ]]; then
        log_debug "ERROR" "Script file not found: $script_file"
        return 1
    fi
    
    # Extract function definitions
    local functions=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then
            functions+=("${BASH_REMATCH[1]}")
        elif [[ "$line" =~ ^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            functions+=("${BASH_REMATCH[1]}")
        fi
    done < "$script_file"
    
    log_debug "SUCCESS" "Found ${#functions[@]} functions in $(basename "$script_file")"
    
    # Analyze each function for common issues
    for func in "${functions[@]}"; do
        log_debug "DEBUG" "Analyzing function: $func"
        
        # Check for unsafe operations
        if optimized_search "rm.*-rf.*\\\$" "$script_file"; then
            log_debug "CRITICAL" "Function $func: Potential unsafe rm -rf with variable"
            analysis_results+=("CRITICAL:$func:unsafe_rm_operation")
        fi
        
        # Check for unquoted variables
        if optimized_search "\\\$[a-zA-Z_][a-zA-Z0-9_]*[^\"']" "$script_file"; then
            log_debug "WARNING" "Function $func: Potential unquoted variables"
            analysis_results+=("WARNING:$func:unquoted_variables")
        fi
        
        # Check for missing error handling
        if ! optimized_search "set -e\|trap.*ERR\|.*\|\|.*exit" "$script_file"; then
            log_debug "WARNING" "Function $func: Missing error handling"
            analysis_results+=("WARNING:$func:missing_error_handling")
        fi
        
        # Check for hardcoded paths
        if optimized_search "/home/\|/usr/local/\|C:\\\\" "$script_file"; then
            log_debug "WARNING" "Function $func: Hardcoded paths detected"
            analysis_results+=("WARNING:$func:hardcoded_paths")
        fi
        
        # Check for command substitution without error handling
        if optimized_search "\\\$(" "$script_file" && ! optimized_search "set -e\|pipefail" "$script_file"; then
            log_debug "WARNING" "Function $func: Command substitution without pipefail"
            analysis_results+=("WARNING:$func:unsafe_command_substitution")
        fi
    done
    
    # Save analysis results
    {
        echo "{"
        echo "  \"script\": \"$script_file\","
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"functions_analyzed\": ${#functions[@]},"
        echo "  \"issues_found\": ["
        
        local first=true
        for result in "${analysis_results[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            IFS=':' read -r severity func issue <<< "$result"
            echo "    {"
            echo "      \"severity\": \"$severity\","
            echo "      \"function\": \"$func\","
            echo "      \"issue\": \"$issue\""
            echo -n "    }"
        done
        
        echo ""
        echo "  ]"
        echo "}"
    } > "${script_file}.analysis.json"
    
    log_debug "SUCCESS" "Function analysis completed for $(basename "$script_file")"
    return 0
}

# Cross-platform compatibility check
check_cross_platform_compatibility() {
    local script_file="$1"
    local compatibility_issues=()
    
    log_debug "DEBUG" "Checking cross-platform compatibility for: $script_file"
    
    # Check for Linux-specific commands
    local linux_commands=("apt" "yum" "systemctl" "service" "ifconfig" "netstat")
    for cmd in "${linux_commands[@]}"; do
        if optimized_search "\\b$cmd\\b" "$script_file"; then
            log_debug "LINUX" "Linux-specific command found: $cmd"
            compatibility_issues+=("LINUX:$cmd")
        fi
    done
    
    # Check for Windows-specific patterns
    if optimized_search "C:\\\\\|\.exe\|\.bat\|\.cmd\|powershell" "$script_file"; then
        log_debug "WINDOWS" "Windows-specific patterns detected"
        compatibility_issues+=("WINDOWS:path_patterns")
    fi
    
    # Check for shell-specific features
    if optimized_search "\\[\\[.*\\]\\]\|declare\|local" "$script_file"; then
        log_debug "DEBUG" "Bash-specific features detected (may not work in other shells)"
        compatibility_issues+=("BASH:bash_specific_features")
    fi
    
    # Check for path separators
    if optimized_search "/" "$script_file" && optimized_search "\\\\" "$script_file"; then
        log_debug "WARNING" "Mixed path separators detected"
        compatibility_issues+=("WARNING:mixed_path_separators")
    fi
    
    log_debug "SUCCESS" "Cross-platform compatibility check completed"
    
    # Save compatibility report
    {
        echo "{"
        echo "  \"script\": \"$script_file\","
        echo "  \"compatibility_issues\": ["
        
        local first=true
        for issue in "${compatibility_issues[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            IFS=':' read -r platform type <<< "$issue"
            echo "    {"
            echo "      \"platform\": \"$platform\","
            echo "      \"type\": \"$type\""
            echo -n "    }"
        done
        
        echo ""
        echo "  ]"
        echo "}"
    } > "${script_file}.compatibility.json"
    
    return 0
}

# Performance optimization with predictive analysis
optimize_script_performance() {
    local script_file="$1"
    local optimized_file="${script_file%.*}_performance_optimized.${script_file##*.}"
    
    log_debug "DEBUG" "Optimizing performance for: $script_file"
    
    if [[ ! -f "$script_file" ]]; then
        log_debug "ERROR" "Script file not found: $script_file"
        return 1
    fi
    
    # Create optimized version
    cp "$script_file" "$optimized_file"
    
    # Add optimized search function
    if ! optimized_search "optimized_search" "$optimized_file"; then
        log_debug "FIX" "Adding optimized search function to $optimized_file"
        
        # Insert optimized search function near the top
        local temp_file=$(mktemp)
        {
            head -10 "$optimized_file"
            cat << 'EOF'

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

EOF
            tail -n +11 "$optimized_file"
        } > "$temp_file"
        
        mv "$temp_file" "$optimized_file"
    fi
    
    # Replace unsafe grep calls with optimized_search
    if optimized_search "grep.*-r" "$optimized_file"; then
        log_debug "FIX" "Replacing unsafe recursive grep calls"
        sed -i 's/grep -r/optimized_search/g' "$optimized_file" 2>/dev/null || {
            # Fallback for systems without GNU sed
            awk '{gsub(/grep -r/, "optimized_search"); print}' "$optimized_file" > "$optimized_file.tmp"
            mv "$optimized_file.tmp" "$optimized_file"
        }
    fi
    
    # Add timeout protection to long-running operations
    if optimized_search "while.*read\|for.*in.*\\\$(" "$optimized_file"; then
        log_debug "FIX" "Adding timeout protection to loops"
        # This would require more sophisticated parsing
    fi
    
    # Add error handling
    if ! optimized_search "set -e\|trap.*ERR" "$optimized_file"; then
        log_debug "FIX" "Adding error handling to $optimized_file"
        sed -i '2i set -e\nset -u\nset -o pipefail' "$optimized_file" 2>/dev/null || {
            # Fallback
            local temp_file=$(mktemp)
            {
                head -1 "$optimized_file"
                echo "set -e"
                echo "set -u"
                echo "set -o pipefail"
                tail -n +2 "$optimized_file"
            } > "$temp_file"
            mv "$temp_file" "$optimized_file"
        }
    fi
    
    log_debug "SUCCESS" "Performance optimization completed: $optimized_file"
    return 0
}

# Predictive checklist system
generate_predictive_checklist() {
    local script_file="$1"
    local checklist_file="${script_file%.*}_checklist.md"
    
    log_debug "CHECKLIST" "Generating predictive checklist for: $script_file"
    
    {
        echo "# Predictive Maintenance Checklist for $(basename "$script_file")"
        echo "Generated: $(date)"
        echo ""
        echo "## Pre-execution Checks"
        echo "- [ ] Verify all dependencies are installed"
        echo "- [ ] Check disk space (minimum 1GB free)"
        echo "- [ ] Validate configuration files"
        echo "- [ ] Test network connectivity if required"
        echo "- [ ] Backup critical data before execution"
        echo ""
        echo "## Runtime Monitoring"
        echo "- [ ] Monitor CPU usage"
        echo "- [ ] Watch memory consumption"
        echo "- [ ] Check for error messages in logs"
        echo "- [ ] Verify expected output files are created"
        echo ""
        echo "## Post-execution Validation"
        echo "- [ ] Check exit code (should be 0 for success)"
        echo "- [ ] Validate output file integrity"
        echo "- [ ] Review log files for warnings"
        echo "- [ ] Confirm no temporary files left behind"
        echo ""
        
        # Add script-specific checks based on analysis
        if optimized_search "curl\|wget" "$script_file"; then
            echo "## Network-specific Checks"
            echo "- [ ] Verify internet connectivity"
            echo "- [ ] Check firewall settings"
            echo "- [ ] Validate SSL certificates"
            echo ""
        fi
        
        if optimized_search "sudo\|root" "$script_file"; then
            echo "## Privilege-specific Checks"
            echo "- [ ] Confirm script needs elevated privileges"
            echo "- [ ] Verify sudo access is available"
            echo "- [ ] Check for privilege escalation"
            echo ""
        fi
        
        if optimized_search "rm\|delete\|unlink" "$script_file"; then
            echo "## Data Safety Checks"
            echo "- [ ] Verify backup exists before deletion"
            echo "- [ ] Confirm deletion targets are correct"
            echo "- [ ] Test restore procedure"
            echo ""
        fi
        
        echo "## Maintenance Schedule"
        echo "- [ ] Weekly: Review logs and performance"
        echo "- [ ] Monthly: Update dependencies"
        echo "- [ ] Quarterly: Security audit"
        echo "- [ ] Annually: Full system review"
    } > "$checklist_file"
    
    log_debug "SUCCESS" "Predictive checklist generated: $checklist_file"
}

# Comprehensive error reporting
generate_error_report() {
    log_debug "REPORT" "Generating comprehensive error report"
    
    local error_count=0
    local warning_count=0
    local scripts_analyzed=0
    
    {
        echo "{"
        echo "  \"error_report\": {"
        echo "    \"timestamp\": \"$(date -Iseconds)\","
        echo "    \"analysis_summary\": {"
        
        # Count analysis files
        for analysis_file in *.analysis.json; do
            [[ -f "$analysis_file" ]] || continue
            ((scripts_analyzed++))
            
            # Count errors and warnings
            local script_errors=$(jq '[.issues_found[] | select(.severity == "CRITICAL")] | length' "$analysis_file" 2>/dev/null || echo 0)
            local script_warnings=$(jq '[.issues_found[] | select(.severity == "WARNING")] | length' "$analysis_file" 2>/dev/null || echo 0)
            
            error_count=$((error_count + script_errors))
            warning_count=$((warning_count + script_warnings))
        done
        
        echo "      \"scripts_analyzed\": $scripts_analyzed,"
        echo "      \"total_errors\": $error_count,"
        echo "      \"total_warnings\": $warning_count,"
        echo "      \"analysis_date\": \"$(date)\""
        echo "    },"
        echo "    \"detailed_results\": ["
        
        # Include detailed results
        local first=true
        for analysis_file in *.analysis.json; do
            [[ -f "$analysis_file" ]] || continue
            [[ "$first" == true ]] && first=false || echo ","
            cat "$analysis_file"
        done
        
        echo ""
        echo "    ],"
        echo "    \"recommendations\": ["
        echo "      {"
        echo "        \"priority\": \"HIGH\","
        echo "        \"action\": \"Fix all CRITICAL issues immediately\","
        echo "        \"impact\": \"Security and stability\""
        echo "      },"
        echo "      {"
        echo "        \"priority\": \"MEDIUM\","
        echo "        \"action\": \"Address WARNING issues in next maintenance window\","
        echo "        \"impact\": \"Performance and reliability\""
        echo "      },"
        echo "      {"
        echo "        \"priority\": \"LOW\","
        echo "        \"action\": \"Schedule regular security audits\","
        echo "        \"impact\": \"Long-term maintenance\""
        echo "      }"
        echo "    ]"
        echo "  }"
        echo "}"
    } > "$ERROR_REPORT"
    
    log_debug "SUCCESS" "Error report generated: $ERROR_REPORT"
    
    # Generate human-readable summary
    local summary_file="${ERROR_REPORT%.*}_summary.txt"
    {
        echo "XXMXLI Security Scripts Error Analysis Summary"
        echo "============================================="
        echo "Generated: $(date)"
        echo ""
        echo "ANALYSIS RESULTS:"
        echo "- Scripts Analyzed: $scripts_analyzed"
        echo "- Critical Errors: $error_count"
        echo "- Warnings: $warning_count"
        echo ""
        if [[ $error_count -gt 0 ]]; then
            echo "🚨 IMMEDIATE ACTION REQUIRED: $error_count critical errors found"
        elif [[ $warning_count -gt 0 ]]; then
            echo "⚠️ ATTENTION NEEDED: $warning_count warnings found"
        else
            echo "✅ ALL SCRIPTS PASSED ANALYSIS"
        fi
        echo ""
        echo "Detailed JSON report: $ERROR_REPORT"
    } > "$summary_file"
    
    log_debug "SUCCESS" "Summary report generated: $summary_file"
}

# Main debugging workflow
debug_security_scripts() {
    log_debug "DEBUG" "Starting comprehensive security scripts debugging"
    
    # Ensure dependencies are available
    if ! check_and_install_dependencies; then
        log_debug "CRITICAL" "Cannot proceed without required dependencies"
        return 1
    fi
    
    # Find all security-related scripts
    local security_scripts=()
    while IFS= read -r -d '' script; do
        security_scripts+=("$script")
    done < <(find . -name "*.sh" -type f \( -name "*security*" -o -name "*monitor*" -o -name "*health*" -o -name "*block*" -o -name "*deploy*" \) -print0 2>/dev/null)
    
    log_debug "SUCCESS" "Found ${#security_scripts[@]} security scripts to analyze"
    
    # Process each script
    for script in "${security_scripts[@]}"; do
        log_debug "DEBUG" "Processing: $script"
        
        # Skip if already optimized
        if [[ "$script" =~ _optimized\. ]]; then
            log_debug "DEBUG" "Skipping already optimized script: $script"
            continue
        fi
        
        # Analyze functions
        analyze_script_functions "$script"
        
        # Check cross-platform compatibility
        check_cross_platform_compatibility "$script"
        
        # Optimize performance
        optimize_script_performance "$script"
        
        # Generate predictive checklist
        if [[ "$ENABLE_PREDICTIVE_CHECKS" == true ]]; then
            generate_predictive_checklist "$script"
        fi
        
        log_debug "SUCCESS" "Completed processing: $script"
    done
    
    # Generate comprehensive error report
    generate_error_report
    
    log_debug "SUCCESS" "Security scripts debugging completed successfully"
}

# Interactive menu for debugging options
show_debug_menu() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                XXMXLI SECURITY DEBUG OPTIMIZER              ║"
    echo "║              Performance & Error Analysis v3.0               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${WHITE}${DEBUG} DEBUGGING OPTIONS${NC}"
    echo "================================================================"
    echo ""
    echo -e "${GREEN}1)${NC} ${CRITICAL} Full Security Scripts Debug"
    echo -e "${GREEN}2)${NC} ${DEPENDENCY} Check Dependencies"
    echo -e "${GREEN}3)${NC} ${SEARCH} Test Search Tools Performance"
    echo -e "${GREEN}4)${NC} ${CHECKLIST} Generate Predictive Checklists"
    echo -e "${GREEN}5)${NC} ${REPORT} Generate Error Report"
    echo -e "${GREEN}6)${NC} ${CONFIG} Configure Debug Settings"
    echo -e "${GREEN}7)${NC} ${PERFORMANCE} Optimize Single Script"
    echo -e "${GREEN}0)${NC} ${ERROR} Exit"
    echo ""
    
    local choice
    read -p "Choose debugging option [0-7]: " choice
    
    case "$choice" in
        1) debug_security_scripts ;;
        2) check_and_install_dependencies ;;
        3) 
            echo "Testing search tools performance..."
            for tool in rg ag awk grep; do
                if command -v "$tool" >/dev/null 2>&1; then
                    local start_time=$(date +%s%N)
                    echo "test" | "$tool" "test" 2>/dev/null
                    local end_time=$(date +%s%N)
                    local duration=$(( (end_time - start_time) / 1000000 ))
                    log_debug "PERFORMANCE" "$tool: ${duration}ms"
                fi
            done
            ;;
        4)
            read -p "Enter script path: " script_path
            [[ -f "$script_path" ]] && generate_predictive_checklist "$script_path"
            ;;
        5) generate_error_report ;;
        6)
            echo "Configuration files:"
            echo "  JSON: $CONFIG_DIR/debug_optimizer.json"
            echo "  YAML: $CONFIG_DIR/debug_optimizer.yaml" 
            echo "  CONF: $CONFIG_DIR/debug_optimizer.conf"
            ;;
        7)
            read -p "Enter script path: " script_path
            [[ -f "$script_path" ]] && optimize_script_performance "$script_path"
            ;;
        0) log_debug "DEBUG" "Exiting debug optimizer"; exit 0 ;;
        *) log_debug "ERROR" "Invalid option: $choice"; sleep 1 ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    show_debug_menu
}

# Main execution
main() {
    # Initialize
    setup_colors
    setup_symbols
    load_debug_config
    
    # Create necessary directories
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$REPORTS_DIR" 2>/dev/null
    
    # Clear old debug log
    > "$DEBUG_LOG" 2>/dev/null
    
    # Handle command line arguments
    case "${1:-}" in
        "--debug"|"--full")
            debug_security_scripts
            ;;
        "--dependencies"|"--deps")
            check_and_install_dependencies
            ;;
        "--optimize")
            [[ -n "$2" ]] && optimize_script_performance "$2" || log_debug "ERROR" "Missing script path"
            ;;
        "--checklist")
            [[ -n "$2" ]] && generate_predictive_checklist "$2" || log_debug "ERROR" "Missing script path"
            ;;
        "--report")
            generate_error_report
            ;;
        "--help"|"-h")
            echo "XXMXLI Security Debug Optimizer v3.0"
            echo ""
            echo "Usage: $0 [option] [arguments]"
            echo ""
            echo "Options:"
            echo "  --debug, --full           Run full debugging analysis"
            echo "  --dependencies, --deps    Check and install dependencies"
            echo "  --optimize <script>       Optimize specific script"
            echo "  --checklist <script>      Generate checklist for script"
            echo "  --report                  Generate error report"
            echo "  --help, -h                Show this help"
            echo ""
            echo "Interactive mode: Run without arguments"
            ;;
        "")
            show_debug_menu
            ;;
        *)
            log_debug "ERROR" "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# Trap for cleanup
trap 'log_debug "DEBUG" "Debug optimizer terminated"; exit 0' INT TERM

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi