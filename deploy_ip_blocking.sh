#!/bin/bash

# ========================================
# XXMXLI SAFE IP BLOCKING DEPLOYMENT
# ========================================
# Interactive deployment system with beautiful UI
#
# SECURITY WARNING: This system is actively monitored and protected.
#
# Usage quick-notes:
# - Source blacklist: assets/security/blocked_ips.json
#   Accepts either:
#     1) Array form: ["1.2.3.4", "2.3.4.5/24", ...]
#     2) Object form: {"blocked_ips": [ ... ], "total_ips": N, ...}
# - Deployment caps the number of emitted Require rules to MAX_DEPLOY_IPS (default 500).
#   Override per-run: MAX_DEPLOY_IPS=1000 ./deploy_ip_blocking.sh --deploy
# - Non-interactive modes: --deploy | --status | --rollback | --help

set -euo pipefail

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

# Resolved W folder (global)
RESOLVED_W_FOLDER=""

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

# Emit IPs (one per line) from a JSON array file using jq if present or Python fallback
list_ips_from_json() {
    local file="$1"
    # Emit each IP/CIDR on its own line. Supports:
    #  - top-level array: ["1.2.3.4", ...]
    #  - object with key "blocked_ips": {"blocked_ips": ["1.2.3.4", ...]}
    if command -v jq >/dev/null 2>&1; then
        jq -r 'if type=="array" then .[] else (.blocked_ips // [])[] end' "$file"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
if isinstance(data, list):
    items = data
elif isinstance(data, dict) and 'blocked_ips' in data and isinstance(data['blocked_ips'], list):
    items = data['blocked_ips']
else:
    items = []
for item in items:
    # Only emit str-like items
    if isinstance(item, str):
        print(item)
PY
    else
        # No parser available
        return 1
    fi
}

# Return length of JSON array file, or 'unknown' if no parser
json_array_length() {
    local file="$1"
    # Return count of entries to be deployed (array length or .blocked_ips length)
    if command -v jq >/dev/null 2>&1; then
        jq -r 'if type=="array" then length else (.blocked_ips // []) | length end' "$file" 2>/dev/null || echo "unknown"
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "$file" <<'PY'
import json, sys
try:
    with open(sys.argv[1], 'r', encoding='utf-8') as f:
        data = json.load(f)
    if isinstance(data, list):
        print(len(data))
    elif isinstance(data, dict) and isinstance(data.get('blocked_ips'), list):
        print(len(data['blocked_ips']))
    else:
        print(0)
except Exception:
    print('unknown')
PY
    else
        echo "unknown"
    fi
}

# Resolve W folder with safe fallbacks and export to environment
resolve_w_folder() {
    # Priority: env W_FOLDER (if dir) > ./w > script_dir/w > parent/w > hardcoded
    local hardcoded="/home/kodachi/Desktop/kotisivu/w"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ -n "${W_FOLDER:-}" && -d "${W_FOLDER}" ]]; then
        RESOLVED_W_FOLDER="${W_FOLDER}"
    elif [[ -d "./w" ]]; then
        RESOLVED_W_FOLDER="$(cd ./w && pwd)"
    elif [[ -d "${script_dir}/w" ]]; then
        RESOLVED_W_FOLDER="${script_dir}/w"
    elif [[ -d "${script_dir%/*}/w" ]]; then
        RESOLVED_W_FOLDER="${script_dir%/*}/w"
    elif [[ -d "${hardcoded}" ]]; then
        RESOLVED_W_FOLDER="${hardcoded}"
    else
        # Default to hardcoded path even if missing; we will warn later
        RESOLVED_W_FOLDER="${hardcoded}"
    fi

    export W_FOLDER="${RESOLVED_W_FOLDER}"
    info "W folder resolved to: ${W_FOLDER}"

    if [[ ! -d "${W_FOLDER}" ]]; then
        warn "Resolved W folder does not exist: ${W_FOLDER}"
        warn "Set W_FOLDER to override, e.g.: export W_FOLDER=/path/to/w"
    fi
}

# Ensure assets/security/blocked_ips.json exists; build from W folder if missing
ensure_blacklist_json() {
    local json_path="assets/security/blocked_ips.json"
    if [[ -f "${json_path}" && -s "${json_path}" ]]; then
        return 0
    fi

    info "Blacklist JSON missing; attempting to generate from W folder: ${W_FOLDER}"

    # Prefer Python processor if available
    if command -v python3 >/dev/null 2>&1 && [[ -f "process_w_blacklists.py" ]]; then
        info "Running Python generator: process_w_blacklists.py"
        if W_FOLDER="${W_FOLDER}" python3 process_w_blacklists.py >/dev/null 2>&1; then
            if [[ -f "${json_path}" && -s "${json_path}" ]]; then
                success "Generated ${json_path} via Python processor"
                return 0
            fi
        else
            warn "Python processor failed; falling back to shell-based generator"
        fi
    fi

    # Fallback shell-based generator: scrape IPv4s from W folder and write JSON array
    if [[ -d "${W_FOLDER}" ]]; then
        info "Building minimal JSON from IPv4s found under ${W_FOLDER}"
        mkdir -p "$(dirname "${json_path}")"
        # Collect unique IPv4 addresses with basic octet bounds check
        mapfile -t ips < <(grep -RhoE "([0-9]{1,3}\.){3}[0-9]{1,3}" "${W_FOLDER}" 2>/dev/null \
            | awk -F. '$1<256 && $2<256 && $3<256 && $4<256' \
            | sort -u)

        {
            echo "["
            if [[ ${#ips[@]} -gt 0 ]]; then
                for ((i=0; i<${#ips[@]}; i++)); do
                    ip="${ips[$i]}"
                    if [[ $i -lt $((${#ips[@]}-1)) ]]; then
                        echo "  \"${ip}\"," 
                    else
                        echo "  \"${ip}\""
                    fi
                done
            fi
            echo "]"
        } > "${json_path}"

        if [[ -s "${json_path}" ]]; then
            success "Generated ${json_path} via shell fallback"
            return 0
        fi
    fi

    error "Unable to generate ${json_path}. Provide it or set W_FOLDER correctly."
    return 1
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
    
    if [ ! -f "index.html" ]; then
        error "Run this script from the XXMXLI root directory"
        echo ""
        info "Expected directory structure:"
        echo "  - index.html (main website)"
        echo "  - assets/security/blocked_ips.json (IP blacklist)"
        echo "  - admin/ directory"
        echo ""
        exit 1
    fi

    # Resolve W folder and ensure blacklist JSON is present (generate if needed)
    resolve_w_folder
    if ! ensure_blacklist_json; then
        echo ""
        error "Blacklist JSON is required for deployment."
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
        local ip_count=$(json_array_length assets/security/blocked_ips.json)
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
    
    # Safety cap to avoid gigantic .htaccess files. Override with env MAX_DEPLOY_IPS
    local max_ips=${MAX_DEPLOY_IPS:-500}
    if ! [[ "$max_ips" =~ ^[0-9]+$ ]]; then
        max_ips=500
    fi

    # Generate main site blocking
    if [ -f "assets/security/blocked_ips.json" ]; then
        echo "# XXMXLI SERVER-SIDE IP BLOCKING" > "$MAIN_HTACCESS"
        echo "# Generated on $(date)" >> "$MAIN_HTACCESS"
        echo "# Backup available in $BACKUP_DIR" >> "$MAIN_HTACCESS"
        echo "# Source: assets/security/blocked_ips.json" >> "$MAIN_HTACCESS"
        echo "" >> "$MAIN_HTACCESS"

        # Start rules block
        echo "<RequireAll>" >> "$MAIN_HTACCESS"
        echo "    Require all granted" >> "$MAIN_HTACCESS"

        # Add blocked IPs (up to max_ips)
        local added=0
        if ips_output=$(list_ips_from_json "assets/security/blocked_ips.json" 2>/dev/null); then
            # Allow IPv4 or IPv4/CIDR up to /32
            while IFS= read -r ip; do
                [[ -z "$ip" ]] && continue
                if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
                    # Basic octet bounds check when not CIDR or for base IP of CIDR
                    base_ip=${ip%%/*}
                    IFS='.' read -r o1 o2 o3 o4 <<<"$base_ip"
                    if [[ $o1 -lt 256 && $o2 -lt 256 && $o3 -lt 256 && $o4 -lt 256 ]]; then
                        echo "    Require not ip $ip" >> "$MAIN_HTACCESS"
                        added=$((added+1))
                        if [ "$added" -ge "$max_ips" ]; then
                            break
                        fi
                    fi
                fi
            done <<< "$ips_output"
        else
            warn "No JSON parser available; falling back to scanning W folder for IPv4s"
            if [[ -d "${W_FOLDER:-}" ]]; then
                added=0
                grep -RhoE "([0-9]{1,3}\.){3}[0-9]{1,3}" "${W_FOLDER}" 2>/dev/null \
                | awk -F. '$1<256 && $2<256 && $3<256 && $4<256' \
                | sort -u \
                | while read -r ip; do
                    echo "    Require not ip $ip" >> "$MAIN_HTACCESS"
                    added=$((added+1))
                    if [ "$added" -ge "$max_ips" ]; then
                        break
                    fi
                done
            else
                error "Cannot enumerate IPs: W_FOLDER not set or directory missing"
            fi
        fi

        echo "</RequireAll>" >> "$MAIN_HTACCESS"
        echo "" >> "$MAIN_HTACCESS"
        echo "# Deployed $added blocked IP(s); cap MAX_DEPLOY_IPS=$max_ips" >> "$MAIN_HTACCESS"

        success "Main site IP blocking deployed"
    fi
    
    # Generate admin protection
    if [ -d "admin" ]; then
        echo "# XXMXLI ADMIN PROTECTION" > "$ADMIN_HTACCESS"
        echo "# Generated on $(date)" >> "$ADMIN_HTACCESS"
        echo "# Source: assets/security/blocked_ips.json" >> "$ADMIN_HTACCESS"
        echo "" >> "$ADMIN_HTACCESS"

        echo "<RequireAll>" >> "$ADMIN_HTACCESS"
        echo "    Require all granted" >> "$ADMIN_HTACCESS"

        local a_added=0
        if [ -f "assets/security/blocked_ips.json" ]; then
            if ips_output=$(list_ips_from_json "assets/security/blocked_ips.json" 2>/dev/null); then
                while IFS= read -r ip; do
                    [[ -z "$ip" ]] && continue
                    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
                        base_ip=${ip%%/*}
                        IFS='.' read -r o1 o2 o3 o4 <<<"$base_ip"
                        if [[ $o1 -lt 256 && $o2 -lt 256 && $o3 -lt 256 && $o4 -lt 256 ]]; then
                            echo "    Require not ip $ip" >> "$ADMIN_HTACCESS"
                            a_added=$((a_added+1))
                            if [ "$a_added" -ge "$max_ips" ]; then
                                break
                            fi
                        fi
                    fi
                done <<< "$ips_output"
            else
                warn "No JSON parser available; falling back to scanning W folder for IPv4s"
                if [[ -d "${W_FOLDER:-}" ]]; then
                    a_added=0
                    grep -RhoE "([0-9]{1,3}\.){3}[0-9]{1,3}" "${W_FOLDER}" 2>/dev/null \
                    | awk -F. '$1<256 && $2<256 && $3<256 && $4<256' \
                    | sort -u \
                    | while read -r ip; do
                        echo "    Require not ip $ip" >> "$ADMIN_HTACCESS"
                        a_added=$((a_added+1))
                        if [ "$a_added" -ge "$max_ips" ]; then
                            break
                        fi
                    done
                else
                    error "Cannot enumerate IPs: W_FOLDER not set or directory missing"
                fi
            fi
        fi

        echo "</RequireAll>" >> "$ADMIN_HTACCESS"
        echo "" >> "$ADMIN_HTACCESS"
        echo "# Deployed $a_added blocked IP(s) to admin; cap MAX_DEPLOY_IPS=$max_ips" >> "$ADMIN_HTACCESS"

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

        # Count deployed IPs and compare to source size
        local blocked_count=$(grep -c "^[[:space:]]*Require not ip" "$MAIN_HTACCESS" 2>/dev/null || echo "0")
        local src_count="unknown"
        if [ -f "assets/security/blocked_ips.json" ]; then
            src_count=$(json_array_length assets/security/blocked_ips.json)
        fi
        info "Blocked IPs deployed: $blocked_count (of $src_count available)"
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
            local blocked_count=$(grep -c "^[[:space:]]*Require not ip" "$MAIN_HTACCESS" 2>/dev/null || echo "0")
            local src_count="unknown"
            if [ -f "assets/security/blocked_ips.json" ]; then
                src_count=$(json_array_length assets/security/blocked_ips.json)
            fi
            info "Blocked IPs deployed: $blocked_count (source has $src_count)"
            # Show a small sample of currently blocked IP entries
            info "Sample blocked entries:"
            grep -E "^[[:space:]]*Require not ip" "$MAIN_HTACCESS" | head -5 | sed 's/^/  /'
            
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

    # Only pause and return to menu in interactive mode
    if [[ "${INTERACTIVE_MODE}" == true ]]; then
        echo ""
        read -p "Press Enter to return to menu..." -r
        show_interactive_menu
    fi
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
        if command -v jq >/dev/null 2>&1; then
            if jq -e 'if type=="array" then true elif (has("blocked_ips") and (.blocked_ips|type=="array")) then true else false end' assets/security/blocked_ips.json >/dev/null 2>&1; then
                success "Blacklist JSON is valid"
                local ip_count=$(json_array_length assets/security/blocked_ips.json)
                info "Contains $ip_count IP addresses"
            else
                error "Blacklist JSON format invalid (expected array or object with blocked_ips array)"
            fi
        elif command -v python3 >/dev/null 2>&1; then
            if python3 - <<'PY'
import json,sys
try:
    with open('assets/security/blocked_ips.json','r',encoding='utf-8') as f:
        data=json.load(f)
    ok = isinstance(data, list) or (isinstance(data, dict) and isinstance(data.get('blocked_ips'), list))
    if not ok:
        raise SystemExit(1)
    print('OK')
except Exception:
    sys.exit(1)
PY
            then
                success "Blacklist JSON is valid"
                local ip_count=$(json_array_length assets/security/blocked_ips.json)
                info "Contains $ip_count IP addresses"
            else
                error "Blacklist JSON is invalid"
            fi
        else
            warn "Neither jq nor python3 is available to validate JSON"
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
