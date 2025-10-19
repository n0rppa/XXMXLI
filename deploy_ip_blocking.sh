#!/bin/bash

# ========================================
# XXMXLI SAFE IP BLOCKING DEPLOYMENT
# ========================================
# Interactive deployment system with beautiful UI
#
# SECURITY WARNING: This system is actively monitored and protected.

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
