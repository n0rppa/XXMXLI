#!/bin/bash

# ================================================================
# XXMXLI Comprehensive Security System Status & Diagnostic Report v3.0
# Final debugging summary, performance analysis, and maintenance recommendations
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
LOG_DIR="$SCRIPT_DIR/logs"
REPORTS_DIR="$SCRIPT_DIR/reports"
FIXES_DIR="$SCRIPT_DIR/fixes"
FINAL_REPORT="$REPORTS_DIR/comprehensive_system_status_$(date +%Y%m%d_%H%M%S).json"
SUMMARY_REPORT="$REPORTS_DIR/executive_summary_$(date +%Y%m%d_%H%M%S).txt"

# Colors and symbols
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
        STAR="⭐"
        ROCKET="🚀"
        SHIELD="🛡️"
        CHART="📊"
        GEAR="⚙️"
        BULB="💡"
        TARGET="🎯"
        CLOCK="⏰"
    else
        CHECK="[OK]"
        CROSS="[ERR]"
        WARNING="[WARN]"
        INFO="[INFO]"
        STAR="[*]"
        ROCKET="[FAST]"
        SHIELD="[SEC]"
        CHART="[RPT]"
        GEAR="[CFG]"
        BULB="[TIP]"
        TARGET="[FIX]"
        CLOCK="[TIME]"
    fi
}

# Enhanced logging
log_status() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "SUCCESS") echo -e "${GREEN}${CHECK}${NC} $message" ;;
        "ERROR") echo -e "${RED}${CROSS}${NC} $message" >&2 ;;
        "WARNING") echo -e "${YELLOW}${WARNING}${NC} $message" ;;
        "INFO") echo -e "${CYAN}${INFO}${NC} $message" ;;
        "SECURITY") echo -e "${BLUE}${SHIELD}${NC} $message" ;;
        "PERFORMANCE") echo -e "${GREEN}${ROCKET}${NC} $message" ;;
        "REPORT") echo -e "${PURPLE}${CHART}${NC} $message" ;;
        "TIP") echo -e "${YELLOW}${BULB}${NC} $message" ;;
        "TARGET") echo -e "${CYAN}${TARGET}${NC} $message" ;;
        "TIME") echo -e "${BLUE}${CLOCK}${NC} $message" ;;
        *) echo -e "${WHITE}$message${NC}" ;;
    esac
}

# System overview
get_system_overview() {
    log_status "INFO" "Gathering system overview"
    
    # Basic system information
    local hostname=$(hostname 2>/dev/null || echo "Unknown")
    local uptime=$(uptime 2>/dev/null | awk -F',' '{print $1}' | sed 's/.*up //' || echo "Unknown")
    local load_avg=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | sed 's/^ *//' || echo "Unknown")
    local disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "Unknown")
    local memory_usage=$(free -m 2>/dev/null | awk 'NR==2{printf "%.1f%%", $3*100/$2}' || echo "Unknown")
    
    # Security tools availability
    local security_tools=("iptables" "ufw" "fail2ban" "nmap" "netstat" "ss")
    local available_security_tools=0
    for tool in "${security_tools[@]}"; do
        command -v "$tool" >/dev/null 2>&1 && ((available_security_tools++))
    done
    
    # Performance tools availability
    local performance_tools=("rg" "ag" "jq" "yq" "timeout" "parallel")
    local available_performance_tools=0
    for tool in "${performance_tools[@]}"; do
        command -v "$tool" >/dev/null 2>&1 && ((available_performance_tools++))
    done
    
    log_status "SUCCESS" "System: $hostname (Uptime: $uptime)"
    log_status "INFO" "Load Average: $load_avg"
    log_status "INFO" "Disk Usage: $disk_usage"
    log_status "INFO" "Memory Usage: $memory_usage"
    log_status "SECURITY" "Security Tools: $available_security_tools/${#security_tools[@]} available"
    log_status "PERFORMANCE" "Performance Tools: $available_performance_tools/${#performance_tools[@]} available"
    
    # Export for report
    export SYS_HOSTNAME="$hostname"
    export SYS_UPTIME="$uptime"
    export SYS_LOAD="$load_avg"
    export SYS_DISK="$disk_usage"
    export SYS_MEMORY="$memory_usage"
    export SYS_SECURITY_TOOLS="$available_security_tools/${#security_tools[@]}"
    export SYS_PERFORMANCE_TOOLS="$available_performance_tools/${#performance_tools[@]}"
}

# Analyze existing reports
analyze_existing_reports() {
    log_status "REPORT" "Analyzing existing diagnostic reports"
    
    local total_reports=0
    local dependency_reports=0
    local compatibility_reports=0
    local error_reports=0
    local test_reports=0
    
    # Count different report types
    [[ -d "$REPORTS_DIR" ]] && {
        dependency_reports=$(find "$REPORTS_DIR" -name "dependency_report_*.json" 2>/dev/null | wc -l)
        compatibility_reports=$(find "$REPORTS_DIR" -name "compatibility_report_*.json" 2>/dev/null | wc -l)
        error_reports=$(find "$REPORTS_DIR" -name "error_analysis_*.json" 2>/dev/null | wc -l)
        total_reports=$((dependency_reports + compatibility_reports + error_reports))
    }
    
    [[ -d "$LOG_DIR" ]] && {
        test_reports=$(find "$LOG_DIR" -name "*test*.json" 2>/dev/null | wc -l)
    }
    
    log_status "INFO" "Found $total_reports diagnostic reports"
    log_status "INFO" "  - Dependency Reports: $dependency_reports"
    log_status "INFO" "  - Compatibility Reports: $compatibility_reports"
    log_status "INFO" "  - Error Analysis Reports: $error_reports"
    log_status "INFO" "  - Test Reports: $test_reports"
    
    # Analyze latest reports if available
    local latest_issues=0
    local latest_warnings=0
    local latest_errors=0
    
    if [[ $error_reports -gt 0 ]]; then
        local latest_error_report=$(find "$REPORTS_DIR" -name "error_analysis_*.json" -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        if [[ -f "$latest_error_report" ]] && command -v jq >/dev/null 2>&1; then
            latest_errors=$(jq '.error_report.analysis_summary.total_errors // 0' "$latest_error_report" 2>/dev/null || echo 0)
            latest_warnings=$(jq '.error_report.analysis_summary.total_warnings // 0' "$latest_error_report" 2>/dev/null || echo 0)
            log_status "INFO" "Latest Error Analysis: $latest_errors errors, $latest_warnings warnings"
        fi
    fi
    
    # Export for report
    export RPT_TOTAL="$total_reports"
    export RPT_DEPENDENCY="$dependency_reports"
    export RPT_COMPATIBILITY="$compatibility_reports"
    export RPT_ERROR="$error_reports"
    export RPT_TEST="$test_reports"
    export RPT_LATEST_ERRORS="$latest_errors"
    export RPT_LATEST_WARNINGS="$latest_warnings"
}

# Check optimization status
check_optimization_status() {
    log_status "INFO" "Checking optimization and fixes status"
    
    local total_scripts=0
    local optimized_scripts=0
    local fixed_scripts=0
    local test_scripts=0
    
    # Count original scripts
    total_scripts=$(find . -name "*.sh" -type f ! -name "*_optimized*" ! -name "*_fixed*" ! -name "*_test*" 2>/dev/null | wc -l)
    
    # Count optimized versions
    optimized_scripts=$(find . -name "*_optimized*.sh" -type f 2>/dev/null | wc -l)
    
    # Count fixed versions
    [[ -d "$FIXES_DIR" ]] && {
        fixed_scripts=$(find "$FIXES_DIR" -name "*_fully_optimized.sh" -type f 2>/dev/null | wc -l)
        test_scripts=$(find . -name "*_test.sh" -type f 2>/dev/null | wc -l)
    }
    
    local optimization_percentage=0
    [[ $total_scripts -gt 0 ]] && optimization_percentage=$(( (optimized_scripts + fixed_scripts) * 100 / total_scripts ))
    
    log_status "INFO" "Scripts Overview:"
    log_status "INFO" "  - Total Scripts: $total_scripts"
    log_status "INFO" "  - Optimized Scripts: $optimized_scripts"
    log_status "INFO" "  - Fixed Scripts: $fixed_scripts"
    log_status "INFO" "  - Test Scripts: $test_scripts"
    log_status "PERFORMANCE" "Optimization Coverage: $optimization_percentage%"
    
    # Performance assessment
    if [[ $optimization_percentage -ge 80 ]]; then
        log_status "SUCCESS" "Excellent optimization coverage"
    elif [[ $optimization_percentage -ge 60 ]]; then
        log_status "WARNING" "Good optimization coverage, room for improvement"
    else
        log_status "WARNING" "Low optimization coverage, more work needed"
    fi
    
    # Export for report
    export OPT_TOTAL_SCRIPTS="$total_scripts"
    export OPT_OPTIMIZED="$optimized_scripts"
    export OPT_FIXED="$fixed_scripts"
    export OPT_TEST="$test_scripts"
    export OPT_PERCENTAGE="$optimization_percentage"
}

# Security posture assessment
assess_security_posture() {
    log_status "SECURITY" "Assessing security posture"
    
    local security_score=0
    local max_security_score=100
    local security_issues=()
    
    # Check firewall status
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        security_score=$((security_score + 20))
        log_status "SUCCESS" "UFW firewall is active"
    elif command -v iptables >/dev/null 2>&1 && iptables -L 2>/dev/null | grep -q "Chain"; then
        security_score=$((security_score + 15))
        log_status "SUCCESS" "iptables firewall configured"
    else
        security_issues+=("No active firewall detected")
        log_status "WARNING" "No active firewall detected"
    fi
    
    # Check fail2ban
    if command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client status 2>/dev/null | grep -q "Number of jail"; then
        security_score=$((security_score + 20))
        log_status "SUCCESS" "Fail2ban is active"
    else
        security_issues+=("Fail2ban not detected or inactive")
        log_status "WARNING" "Fail2ban not detected or inactive"
    fi
    
    # Check SSH configuration
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
            security_score=$((security_score + 15))
            log_status "SUCCESS" "SSH password authentication disabled"
        else
            security_issues+=("SSH password authentication may be enabled")
            log_status "WARNING" "SSH password authentication may be enabled"
        fi
        
        if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
            security_score=$((security_score + 15))
            log_status "SUCCESS" "SSH root login disabled"
        else
            security_issues+=("SSH root login may be enabled")
            log_status "WARNING" "SSH root login may be enabled"
        fi
    else
        security_issues+=("SSH configuration not found")
    fi
    
    # Check for security monitoring tools
    if command -v nmap >/dev/null 2>&1; then
        security_score=$((security_score + 10))
        log_status "SUCCESS" "Nmap available for security scanning"
    fi
    
    if command -v netstat >/dev/null 2>&1 || command -v ss >/dev/null 2>&1; then
        security_score=$((security_score + 10))
        log_status "SUCCESS" "Network monitoring tools available"
    fi
    
    # Check system updates
    if command -v apt >/dev/null 2>&1; then
        local updates=$(apt list --upgradable 2>/dev/null | wc -l)
        if [[ $updates -le 5 ]]; then
            security_score=$((security_score + 10))
            log_status "SUCCESS" "System appears up to date ($updates pending updates)"
        else
            security_issues+=("Many pending system updates ($updates)")
            log_status "WARNING" "Many pending system updates ($updates)"
        fi
    fi
    
    # Calculate security percentage
    local security_percentage=$((security_score * 100 / max_security_score))
    
    log_status "SECURITY" "Security Score: $security_score/$max_security_score ($security_percentage%)"
    
    if [[ $security_percentage -ge 80 ]]; then
        log_status "SUCCESS" "Excellent security posture"
    elif [[ $security_percentage -ge 60 ]]; then
        log_status "WARNING" "Good security posture, some improvements recommended"
    else
        log_status "WARNING" "Security posture needs improvement"
    fi
    
    # Export for report
    export SEC_SCORE="$security_score"
    export SEC_MAX_SCORE="$max_security_score"
    export SEC_PERCENTAGE="$security_percentage"
    export SEC_ISSUES="${security_issues[*]}"
}

# Performance analysis
analyze_performance() {
    log_status "PERFORMANCE" "Analyzing system performance"
    
    local performance_score=0
    local max_performance_score=100
    
    # Check available performance tools
    local perf_tools=("rg" "ag" "jq" "parallel" "timeout")
    local available_perf_tools=0
    for tool in "${perf_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            ((available_perf_tools++))
            performance_score=$((performance_score + 15))
        fi
    done
    
    log_status "INFO" "Performance tools: $available_perf_tools/${#perf_tools[@]} available"
    
    # Check system resources
    local load_avg_1min=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | sed 's/^ *//' | cut -d'.' -f1 2>/dev/null || echo 0)
    local cpu_cores=$(nproc 2>/dev/null || echo 1)
    
    if [[ $load_avg_1min -lt $cpu_cores ]]; then
        performance_score=$((performance_score + 15))
        log_status "SUCCESS" "CPU load is healthy ($load_avg_1min < $cpu_cores cores)"
    else
        log_status "WARNING" "CPU load is high ($load_avg_1min >= $cpu_cores cores)"
    fi
    
    # Check memory usage
    local memory_percentage=$(free 2>/dev/null | awk 'NR==2{printf "%.0f", $3*100/$2}' 2>/dev/null || echo 0)
    if [[ $memory_percentage -lt 80 ]]; then
        performance_score=$((performance_score + 10))
        log_status "SUCCESS" "Memory usage is healthy (${memory_percentage}%)"
    else
        log_status "WARNING" "Memory usage is high (${memory_percentage}%)"
    fi
    
    # Check disk I/O (simplified)
    local disk_usage_percentage=$(df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo 0)
    if [[ $disk_usage_percentage -lt 85 ]]; then
        performance_score=$((performance_score + 10))
        log_status "SUCCESS" "Disk usage is healthy (${disk_usage_percentage}%)"
    else
        log_status "WARNING" "Disk usage is high (${disk_usage_percentage}%)"
    fi
    
    local performance_percentage=$((performance_score * 100 / max_performance_score))
    
    log_status "PERFORMANCE" "Performance Score: $performance_score/$max_performance_score ($performance_percentage%)"
    
    # Export for report
    export PERF_SCORE="$performance_score"
    export PERF_MAX_SCORE="$max_performance_score"
    export PERF_PERCENTAGE="$performance_percentage"
    export PERF_TOOLS_AVAILABLE="$available_perf_tools"
    export PERF_TOOLS_TOTAL="${#perf_tools[@]}"
}

# Generate maintenance recommendations
generate_recommendations() {
    log_status "TIP" "Generating maintenance recommendations"
    
    local recommendations=()
    local priorities=()
    
    # Security recommendations
    if [[ ${SEC_PERCENTAGE:-0} -lt 80 ]]; then
        if [[ "$SEC_ISSUES" =~ "firewall" ]]; then
            recommendations+=("SECURITY: Configure and enable firewall (ufw or iptables)")
            priorities+=("HIGH")
        fi
        if [[ "$SEC_ISSUES" =~ "fail2ban" ]]; then
            recommendations+=("SECURITY: Install and configure fail2ban for intrusion prevention")
            priorities+=("HIGH")
        fi
        if [[ "$SEC_ISSUES" =~ "SSH" ]]; then
            recommendations+=("SECURITY: Harden SSH configuration (disable password auth, disable root login)")
            priorities+=("HIGH")
        fi
    fi
    
    # Performance recommendations
    if [[ ${PERF_PERCENTAGE:-0} -lt 70 ]]; then
        if [[ ${PERF_TOOLS_AVAILABLE:-0} -lt 3 ]]; then
            recommendations+=("PERFORMANCE: Install performance tools (ripgrep, jq, parallel)")
            priorities+=("MEDIUM")
        fi
    fi
    
    # Optimization recommendations
    if [[ ${OPT_PERCENTAGE:-0} -lt 60 ]]; then
        recommendations+=("OPTIMIZATION: Run comprehensive script optimization on remaining scripts")
        priorities+=("MEDIUM")
    fi
    
    # General recommendations
    recommendations+=("MAINTENANCE: Schedule weekly dependency checks")
    priorities+=("LOW")
    recommendations+=("MAINTENANCE: Setup automated security monitoring")
    priorities+=("MEDIUM")
    recommendations+=("MAINTENANCE: Create backup strategy for optimized scripts")
    priorities+=("LOW")
    
    # Display recommendations
    for i in "${!recommendations[@]}"; do
        local priority="${priorities[$i]}"
        case "$priority" in
            "HIGH") log_status "ERROR" "${recommendations[$i]}" ;;
            "MEDIUM") log_status "WARNING" "${recommendations[$i]}" ;;
            "LOW") log_status "INFO" "${recommendations[$i]}" ;;
        esac
    done
    
    # Export for report
    export RECOMMENDATIONS="${recommendations[*]}"
    export RECOMMENDATION_PRIORITIES="${priorities[*]}"
}

# Generate comprehensive JSON report
generate_json_report() {
    log_status "REPORT" "Generating comprehensive JSON report"
    
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    
    {
        echo "{"
        echo "  \"comprehensive_system_status\": {"
        echo "    \"metadata\": {"
        echo "      \"report_version\": \"3.0\","
        echo "      \"generated_timestamp\": \"$(date -Iseconds)\","
        echo "      \"generated_by\": \"XXMXLI Comprehensive Security System\","
        echo "      \"report_type\": \"comprehensive_diagnostic\""
        echo "    },"
        echo "    \"system_overview\": {"
        echo "      \"hostname\": \"${SYS_HOSTNAME:-Unknown}\","
        echo "      \"uptime\": \"${SYS_UPTIME:-Unknown}\","
        echo "      \"load_average\": \"${SYS_LOAD:-Unknown}\","
        echo "      \"disk_usage\": \"${SYS_DISK:-Unknown}\","
        echo "      \"memory_usage\": \"${SYS_MEMORY:-Unknown}\","
        echo "      \"security_tools_available\": \"${SYS_SECURITY_TOOLS:-Unknown}\","
        echo "      \"performance_tools_available\": \"${SYS_PERFORMANCE_TOOLS:-Unknown}\""
        echo "    },"
        echo "    \"reports_analysis\": {"
        echo "      \"total_reports\": ${RPT_TOTAL:-0},"
        echo "      \"dependency_reports\": ${RPT_DEPENDENCY:-0},"
        echo "      \"compatibility_reports\": ${RPT_COMPATIBILITY:-0},"
        echo "      \"error_reports\": ${RPT_ERROR:-0},"
        echo "      \"test_reports\": ${RPT_TEST:-0},"
        echo "      \"latest_errors\": ${RPT_LATEST_ERRORS:-0},"
        echo "      \"latest_warnings\": ${RPT_LATEST_WARNINGS:-0}"
        echo "    },"
        echo "    \"optimization_status\": {"
        echo "      \"total_scripts\": ${OPT_TOTAL_SCRIPTS:-0},"
        echo "      \"optimized_scripts\": ${OPT_OPTIMIZED:-0},"
        echo "      \"fixed_scripts\": ${OPT_FIXED:-0},"
        echo "      \"test_scripts\": ${OPT_TEST:-0},"
        echo "      \"optimization_percentage\": ${OPT_PERCENTAGE:-0}"
        echo "    },"
        echo "    \"security_assessment\": {"
        echo "      \"security_score\": ${SEC_SCORE:-0},"
        echo "      \"max_security_score\": ${SEC_MAX_SCORE:-100},"
        echo "      \"security_percentage\": ${SEC_PERCENTAGE:-0},"
        echo "      \"identified_issues\": \"${SEC_ISSUES:-None}\""
        echo "    },"
        echo "    \"performance_analysis\": {"
        echo "      \"performance_score\": ${PERF_SCORE:-0},"
        echo "      \"max_performance_score\": ${PERF_MAX_SCORE:-100},"
        echo "      \"performance_percentage\": ${PERF_PERCENTAGE:-0},"
        echo "      \"performance_tools_available\": ${PERF_TOOLS_AVAILABLE:-0},"
        echo "      \"performance_tools_total\": ${PERF_TOOLS_TOTAL:-0}"
        echo "    },"
        echo "    \"maintenance_recommendations\": ["
        
        # Convert recommendations to JSON array
        IFS=' ' read -ra rec_array <<< "${RECOMMENDATIONS:-}"
        IFS=' ' read -ra pri_array <<< "${RECOMMENDATION_PRIORITIES:-}"
        local first=true
        for i in "${!rec_array[@]}"; do
            [[ "$first" == true ]] && first=false || echo ","
            echo -n "      {"
            echo -n "\"priority\": \"${pri_array[$i]:-UNKNOWN}\", "
            echo -n "\"recommendation\": \"${rec_array[$i]:-}\""
            echo -n "}"
        done
        
        echo ""
        echo "    ],"
        echo "    \"overall_health\": {"
        
        # Calculate overall health score
        local overall_score=$(( (SEC_PERCENTAGE + PERF_PERCENTAGE + OPT_PERCENTAGE) / 3 ))
        local health_status="UNKNOWN"
        
        if [[ $overall_score -ge 80 ]]; then
            health_status="EXCELLENT"
        elif [[ $overall_score -ge 70 ]]; then
            health_status="GOOD" 
        elif [[ $overall_score -ge 60 ]]; then
            health_status="FAIR"
        else
            health_status="NEEDS_IMPROVEMENT"
        fi
        
        echo "      \"overall_score\": $overall_score,"
        echo "      \"health_status\": \"$health_status\","
        echo "      \"last_assessment\": \"$(date -Iseconds)\""
        echo "    }"
        echo "  }"
        echo "}"
    } > "$FINAL_REPORT"
    
    log_status "SUCCESS" "JSON report generated: $FINAL_REPORT"
}

# Generate executive summary
generate_executive_summary() {
    log_status "REPORT" "Generating executive summary"
    
    local overall_score=$(( (SEC_PERCENTAGE + PERF_PERCENTAGE + OPT_PERCENTAGE) / 3 ))
    
    {
        echo "════════════════════════════════════════════════════════════════"
        echo "              XXMXLI SECURITY SYSTEM EXECUTIVE SUMMARY"
        echo "                    Comprehensive Status Report"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "Report Generated: $(date)"
        echo "System: ${SYS_HOSTNAME:-Unknown}"
        echo ""
        echo "🎯 OVERALL HEALTH SCORE: $overall_score/100"
        echo ""
        if [[ $overall_score -ge 80 ]]; then
            echo "✅ STATUS: EXCELLENT - System is well-optimized and secure"
        elif [[ $overall_score -ge 70 ]]; then
            echo "🟡 STATUS: GOOD - System is healthy with minor improvements needed"
        elif [[ $overall_score -ge 60 ]]; then
            echo "🟠 STATUS: FAIR - System needs attention in several areas"
        else
            echo "🔴 STATUS: NEEDS IMPROVEMENT - Immediate attention required"
        fi
        echo ""
        echo "📊 DETAILED SCORES:"
        echo "  🛡️  Security:     ${SEC_PERCENTAGE:-0}% (${SEC_SCORE:-0}/${SEC_MAX_SCORE:-100})"
        echo "  🚀 Performance:  ${PERF_PERCENTAGE:-0}% (${PERF_SCORE:-0}/${PERF_MAX_SCORE:-100})"
        echo "  ⚙️  Optimization: ${OPT_PERCENTAGE:-0}% (Coverage)"
        echo ""
        echo "📈 SYSTEM METRICS:"
        echo "  • Total Scripts: ${OPT_TOTAL_SCRIPTS:-0}"
        echo "  • Optimized: ${OPT_OPTIMIZED:-0} + ${OPT_FIXED:-0} = $((${OPT_OPTIMIZED:-0} + ${OPT_FIXED:-0}))"
        echo "  • Test Coverage: ${OPT_TEST:-0} test scripts"
        echo "  • Diagnostic Reports: ${RPT_TOTAL:-0}"
        echo "  • Recent Issues: ${RPT_LATEST_ERRORS:-0} errors, ${RPT_LATEST_WARNINGS:-0} warnings"
        echo ""
        echo "🔍 KEY FINDINGS:"
        if [[ ${SEC_PERCENTAGE:-0} -lt 70 ]]; then
            echo "  ⚠️  Security posture requires attention"
        else
            echo "  ✅ Security posture is strong"
        fi
        
        if [[ ${PERF_PERCENTAGE:-0} -lt 70 ]]; then
            echo "  ⚠️  Performance optimization needed"
        else
            echo "  ✅ Performance is well-optimized"
        fi
        
        if [[ ${OPT_PERCENTAGE:-0} -lt 60 ]]; then
            echo "  ⚠️  Script optimization coverage is low"
        else
            echo "  ✅ Good script optimization coverage"
        fi
        echo ""
        echo "🎯 TOP RECOMMENDATIONS:"
        
        # Show high priority recommendations
        IFS=' ' read -ra rec_array <<< "${RECOMMENDATIONS:-}"
        IFS=' ' read -ra pri_array <<< "${RECOMMENDATION_PRIORITIES:-}"
        local high_count=0
        for i in "${!rec_array[@]}"; do
            if [[ "${pri_array[$i]}" == "HIGH" ]] && [[ $high_count -lt 3 ]]; then
                echo "  🔴 ${rec_array[$i]}"
                ((high_count++))
            fi
        done
        
        if [[ $high_count -eq 0 ]]; then
            echo "  ✅ No high-priority issues identified"
        fi
        
        echo ""
        echo "📋 NEXT STEPS:"
        echo "  1. Address high-priority security recommendations"
        echo "  2. Complete script optimization for remaining files"
        echo "  3. Setup automated monitoring and maintenance"
        echo "  4. Schedule regular security assessments"
        echo ""
        echo "📁 DETAILED REPORTS:"
        echo "  • Comprehensive JSON: $(basename "$FINAL_REPORT")"
        echo "  • Log Directory: $LOG_DIR"
        echo "  • Reports Directory: $REPORTS_DIR"
        echo "  • Fixes Directory: $FIXES_DIR"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "For technical details, see the comprehensive JSON report."
        echo "For immediate action items, prioritize HIGH recommendations."
        echo "════════════════════════════════════════════════════════════════"
    } > "$SUMMARY_REPORT"
    
    log_status "SUCCESS" "Executive summary generated: $SUMMARY_REPORT"
}

# Display final status
display_final_status() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 FINAL SYSTEM STATUS SUMMARY                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    local overall_score=$(( (SEC_PERCENTAGE + PERF_PERCENTAGE + OPT_PERCENTAGE) / 3 ))
    
    log_status "STAR" "Overall System Health: $overall_score/100"
    
    if [[ $overall_score -ge 80 ]]; then
        log_status "SUCCESS" "🎉 EXCELLENT! Your security system is well-optimized"
    elif [[ $overall_score -ge 70 ]]; then
        log_status "SUCCESS" "👍 GOOD! Minor improvements will enhance your system"
    elif [[ $overall_score -ge 60 ]]; then
        log_status "WARNING" "⚠️  FAIR - Address recommendations to improve security"
    else
        log_status "WARNING" "🚨 NEEDS WORK - Prioritize security and optimization"
    fi
    
    echo ""
    log_status "REPORT" "📊 Reports Available:"
    log_status "INFO" "  Executive Summary: $SUMMARY_REPORT"
    log_status "INFO" "  Technical Report: $FINAL_REPORT"
    echo ""
    log_status "TIME" "⏰ Recommended Schedule:"
    log_status "TIP" "  Daily: Monitor logs and system health"
    log_status "TIP" "  Weekly: Run dependency and compatibility checks"
    log_status "TIP" "  Monthly: Full security assessment and script optimization"
    echo ""
}

# Main execution
main() {
    echo "🔧 XXMXLI Comprehensive Security System Status & Diagnostic Report v3.0"
    echo "========================================================================"
    
    # Initialize
    setup_output
    mkdir -p "$CONFIG_DIR" "$LOG_DIR" "$REPORTS_DIR" "$FIXES_DIR" 2>/dev/null
    
    # Gather all information
    log_status "INFO" "Starting comprehensive system analysis..."
    echo ""
    
    get_system_overview
    echo ""
    
    analyze_existing_reports
    echo ""
    
    check_optimization_status
    echo ""
    
    assess_security_posture
    echo ""
    
    analyze_performance
    echo ""
    
    generate_recommendations
    echo ""
    
    # Generate reports
    log_status "REPORT" "Generating comprehensive reports..."
    generate_json_report
    generate_executive_summary
    
    # Display final status
    display_final_status
    
    echo ""
    log_status "SUCCESS" "🎯 Comprehensive analysis completed successfully!"
    echo ""
}

# Run main function
main "$@"