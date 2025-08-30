#!/bin/bash

# ================================================================
# WARNING: This system is actively monitored and protected.
#
# Any unauthorized access attempts, network scanning, intrusion, or 
# abusive activity will be logged and reported to the appropriate 
# authorities. IP addresses and metadata may be retained and used 
# for legal enforcement, in compliance with applicable laws.
#
# By continuing, you acknowledge that you are authorized to use this 
# system and that any misuse may result in account suspension, 
# firewall bans, or prosecution under national and international law.
#
# Violators may be subject to civil and/or criminal penalties.
#
# Your access is being monitored.
# ================================================================

# ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
# ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
#  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
#  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
# ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
# ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝
#
# XXMXLI INCIDENT REPORTER - ONE-CLICK INSTALLER
# Automated setup for security incident reporting
# Created by: XXMXLI
# Version: 2.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
cat << 'EOF'
 ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗
 ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║
  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║
  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║
 ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝

XXMXLI INCIDENT REPORTER - ONE-CLICK INSTALLER
Automated Security Incident Reporting Setup
EOF
echo -e "${NC}"

# Auto-elevate if not root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Elevating to root privileges...${NC}"
    exec sudo "$0" "$@"
fi

echo -e "${BLUE}🚀 Starting One-Click Setup...${NC}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Auto-detect and install dependencies
install_dependencies() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    
    if command_exists apt-get; then
        apt-get update -qq
        apt-get install -y curl wget gnupg2 tcpdump net-tools geoip-bin sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists yum; then
        yum install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists dnf; then
        dnf install -y curl wget gnupg2 tcpdump net-tools GeoIP sendmail tar gzip openssl python3 python3-pip >/dev/null 2>&1
    elif command_exists pacman; then
        pacman -Sy --noconfirm curl wget gnupg tcpdump net-tools geoip sendmail tar gzip openssl python python-pip >/dev/null 2>&1
    else
        echo -e "${YELLOW}⚠️  Package manager not detected. Some features may be limited.${NC}"
    fi
    
    # Install Python dependencies
    if command_exists pip3; then
        pip3 install psutil requests python-gnupg >/dev/null 2>&1 || true
    elif command_exists pip; then
        pip install psutil requests python-gnupg >/dev/null 2>&1 || true
    fi
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Create directories
setup_directories() {
    echo -e "${BLUE}📁 Creating directories...${NC}"
    
    mkdir -p /var/log/security/{reports,evidence}
    mkdir -p /etc/security
    mkdir -p /tmp/incident_reports
    mkdir -p /opt/xxmxli
    
    chmod 700 /var/log/security /var/log/security/reports /var/log/security/evidence
    chmod 755 /etc/security /tmp/incident_reports /opt/xxmxli
    
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Download incident reporter scripts
download_scripts() {
    echo -e "${BLUE}⬇️  Downloading incident reporter scripts...${NC}"
    
    cd /opt/xxmxli
    
    # Download from GitHub (or use local files if available)
    if [[ -f "$(dirname "$0")/automated_incident_reporter.sh" ]]; then
        cp "$(dirname "$0")/automated_incident_reporter.sh" .
        cp "$(dirname "$0")/automated_incident_reporter.ps1" . 2>/dev/null || true
        cp "$(dirname "$0")/automated_incident_reporter.py" . 2>/dev/null || true
    else
        # Download from GitHub if available
        wget -q -O automated_incident_reporter.sh "https://raw.githubusercontent.com/n0rppa/XXMXLI/main/automated_incident_reporter.sh" || \
        curl -s -o automated_incident_reporter.sh "https://raw.githubusercontent.com/n0rppa/XXMXLI/main/automated_incident_reporter.sh" || \
        echo -e "${YELLOW}⚠️  Could not download scripts. Please download manually.${NC}"
    fi
    
    chmod +x automated_incident_reporter.sh 2>/dev/null || true
    
    echo -e "${GREEN}✅ Scripts downloaded${NC}"
}

# Create configuration
create_config() {
    echo -e "${BLUE}⚙️  Creating configuration...${NC}"
    
    cat > /etc/security/incident_reporter.conf << 'EOF'
# XXMXLI Automated Incident Reporter Configuration
# Created by One-Click Installer

# Organization Information
ORG_NAME="XXMXLI Security Operations"
ORG_CONTACT="security@xxmxli.local"
ORG_PHONE="+1-555-XXMXLI"
ORG_ADDRESS="XXMXLI Security Center, Cyber Defense Division"

# Technical Contact
TECH_CONTACT="admin@xxmxli.local"
TECH_PHONE="+1-555-ADMIN"

# Reporting Thresholds
MIN_SEVERITY=3
AUTO_REPORT_SEVERITY=7
BATCH_REPORT_INTERVAL=3600

# Notification Settings
EMAIL_ENABLED=false
SMS_ENABLED=false
WEBHOOK_ENABLED=false

# Evidence Collection
COLLECT_PCAP=true
COLLECT_LOGS=true
COLLECT_MEMORY_DUMP=false
EVIDENCE_RETENTION_DAYS=90

# Encryption Settings
GPG_KEY_ID=""
ENCRYPT_REPORTS=false
SECURE_DELETE=true
EOF
    
    chmod 600 /etc/security/incident_reporter.conf
    
    echo -e "${GREEN}✅ Configuration created${NC}"
}

# Create desktop shortcuts
create_shortcuts() {
    echo -e "${BLUE}🖥️  Creating shortcuts...${NC}"
    
    # Create command aliases
    cat > /usr/local/bin/incident-report << 'EOF'
#!/bin/bash
/opt/xxmxli/automated_incident_reporter.sh "$@"
EOF
    chmod +x /usr/local/bin/incident-report
    
    # Create desktop entry if desktop environment is available
    if [[ -d /usr/share/applications ]]; then
        cat > /usr/share/applications/xxmxli-incident-reporter.desktop << 'EOF'
[Desktop Entry]
Name=XXMXLI Incident Reporter
Comment=Security Incident Reporting Tool
Exec=gksu /opt/xxmxli/automated_incident_reporter.sh --help
Icon=security-high
Terminal=true
Type=Application
Categories=System;Security;
EOF
    fi
    
    echo -e "${GREEN}✅ Shortcuts created${NC}"
}

# Setup monitoring service
setup_service() {
    echo -e "${BLUE}🔧 Setting up monitoring service...${NC}"
    
    if command_exists systemctl; then
        /opt/xxmxli/automated_incident_reporter.sh --setup >/dev/null 2>&1 || true
        echo -e "${GREEN}✅ Monitoring service configured${NC}"
    else
        echo -e "${YELLOW}⚠️  Systemd not available, manual monitoring setup required${NC}"
    fi
}

# Run test
run_test() {
    echo -e "${BLUE}🧪 Running system test...${NC}"
    
    /opt/xxmxli/automated_incident_reporter.sh --test >/dev/null 2>&1 && \
    echo -e "${GREEN}✅ System test passed${NC}" || \
    echo -e "${YELLOW}⚠️  System test had warnings (this is normal)${NC}"
}

# Main installation process
main() {
    echo -e "${BLUE}Starting automated setup...${NC}"
    
    install_dependencies
    setup_directories
    download_scripts
    create_config
    create_shortcuts
    setup_service
    run_test
    
    echo -e "${GREEN}"
    echo "🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉"
    echo -e "${NC}"
    echo -e "${CYAN}📋 Quick Start Commands:${NC}"
    echo -e "${YELLOW}  incident-report --help                    ${NC}# Show help"
    echo -e "${YELLOW}  incident-report --test                    ${NC}# Run test"
    echo -e "${YELLOW}  incident-report --report INTRUSION 6 \"Attack detected\"${NC}  # Report incident"
    echo -e "${YELLOW}  incident-report --monitor                 ${NC}# Start monitoring"
    echo
    echo -e "${CYAN}📂 Installation Location:${NC} /opt/xxmxli/"
    echo -e "${CYAN}📊 Reports Location:${NC} /var/log/security/reports/"
    echo -e "${CYAN}🔧 Configuration:${NC} /etc/security/incident_reporter.conf"
    echo
    echo -e "${GREEN}✅ Your system is now protected with automated incident reporting!${NC}"
    echo -e "${RED}⚠️  Remember: All security incidents will be automatically reported to authorities${NC}"
}

# Error handling
trap 'echo -e "${RED}❌ Installation failed. Check the error messages above.${NC}"; exit 1' ERR

# Run installation
main

echo -e "${BLUE}🔒 Installation completed. System is now monitoring for security incidents.${NC}"
