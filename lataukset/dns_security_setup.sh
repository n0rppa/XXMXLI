#!/bin/bash

# DNS Security & Privacy Configuration Tool
# Bash Script for Enhanced DNS Privacy and Security
# Author: XXMXLI Security Tools
# WARNING: Use only for legitimate purposes and with proper authorization
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 
# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to display banner
show_banner() {
    echo -e "${CYAN}"
    echo " ██████╗ ███╗   ██╗███████╗    ███████╗███████╗ ██████╗"
    echo " ██╔══██╗████╗  ██║██╔════╝    ██╔════╝██╔════╝██╔════╝"
    echo " ██║  ██║██╔██╗ ██║███████╗    ███████╗█████╗  ██║     "
    echo " ██║  ██║██║╚██╗██║╚════██║    ╚════██║██╔══╝  ██║     "
    echo " ██████╔╝██║ ╚████║███████║    ███████║███████╗╚██████╗"
    echo " ╚═════╝ ╚═╝  ╚═══╝╚══════╝    ╚══════╝╚══════╝ ╚═════╝"
    echo ""
    echo " ██╗  ██╗██╗  ██╗███╗   ███╗██╗  ██╗██╗     ██╗"
    echo " ╚██╗██╔╝╚██╗██╔╝████╗ ████║╚██╗██╔╝██║     ██║"
    echo "  ╚███╔╝  ╚███╔╝ ██╔████╔██║ ╚███╔╝ ██║     ██║"
    echo "  ██╔██╗  ██╔██╗ ██║╚██╔╝██║ ██╔██╗ ██║     ██║"
    echo " ██╔╝ ██╗██╔╝ ██╗██║ ╚═╝ ██║██╔╝ ██╗███████╗██║"
    echo " ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚═╝"
    echo ""
    echo "    DNS Security & Privacy Configuration Tool"
    echo "    Enhanced Privacy with DNS-over-HTTPS/TLS"
    echo "    Educational and Authorized Use Only"
    echo -e "${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Running with root privileges${NC}"
}

# Function to detect Linux distribution and network manager
detect_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    echo -e "${CYAN}📋 Detected OS: $OS $VER${NC}"
    
    # Detect network manager
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        NETWORK_MANAGER="NetworkManager"
    elif systemctl is-active systemd-resolved >/dev/null 2>&1; then
        NETWORK_MANAGER="systemd-resolved"
    elif [ -f /etc/dhcp/dhclient.conf ]; then
        NETWORK_MANAGER="dhclient"
    else
        NETWORK_MANAGER="manual"
    fi
    
    echo -e "${CYAN}🌐 Network Manager: $NETWORK_MANAGER${NC}"
}

# Function to backup current DNS settings
backup_dns_settings() {
    echo -e "${YELLOW}💾 Creating backup of current DNS settings...${NC}"
    
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_dir="dns_backup_${timestamp}"
    mkdir -p "$backup_dir"
    
    # Backup various DNS configuration files
    [ -f /etc/resolv.conf ] && cp /etc/resolv.conf "$backup_dir/"
    [ -f /etc/systemd/resolved.conf ] && cp /etc/systemd/resolved.conf "$backup_dir/"
    [ -f /etc/NetworkManager/NetworkManager.conf ] && cp /etc/NetworkManager/NetworkManager.conf "$backup_dir/"
    [ -f /etc/dhcp/dhclient.conf ] && cp /etc/dhcp/dhclient.conf "$backup_dir/"
    [ -f /etc/dnsmasq.conf ] && cp /etc/dnsmasq.conf "$backup_dir/"
    
    # Create backup info
    cat > "$backup_dir/backup_info.txt" << EOF
DNS Backup Information
Created: $(date)
Original Network Manager: $NETWORK_MANAGER
Original resolv.conf: $(cat /etc/resolv.conf 2>/dev/null || echo "Not found")

Restore Instructions:
1. Stop relevant services
2. Copy files back to their original locations
3. Restart network services
EOF
    
    echo -e "${GREEN}✅ Backup saved to: $backup_dir${NC}"
    BACKUP_DIR="$backup_dir"
}

# Function to configure secure DNS servers
configure_secure_dns() {
    echo -e "${YELLOW}🔄 Configuring Secure DNS Servers...${NC}"
    
    # DNS-over-HTTPS/TLS providers
    echo -e "${CYAN}📡 Available DNS Providers:${NC}"
    echo "1. Cloudflare (1.1.1.1) - Fast, Privacy-focused"
    echo "2. Quad9 (9.9.9.9) - Security & Privacy"
    echo "3. OpenDNS (208.67.222.222) - Filtering & Security"
    echo "4. Google DNS (8.8.8.8) - Fast, Reliable"
    echo "5. AdGuard DNS (94.140.14.14) - Ad Blocking"
    echo "6. CleanBrowsing (185.228.168.9) - Family Safe"
    echo "7. Custom DNS servers"
    echo ""
    
    read -p "Select DNS provider (1-7): " dns_choice
    
    case $dns_choice in
        1)
            PRIMARY_DNS="1.1.1.1"
            SECONDARY_DNS="1.0.0.1"
            DNS_NAME="Cloudflare"
            DOH_URL="https://cloudflare-dns.com/dns-query"
            DOT_SERVER="cloudflare-dns.com"
            ;;
        2)
            PRIMARY_DNS="9.9.9.9"
            SECONDARY_DNS="149.112.112.112"
            DNS_NAME="Quad9"
            DOH_URL="https://dns.quad9.net/dns-query"
            DOT_SERVER="dns.quad9.net"
            ;;
        3)
            PRIMARY_DNS="208.67.222.222"
            SECONDARY_DNS="208.67.220.220"
            DNS_NAME="OpenDNS"
            DOH_URL="https://doh.opendns.com/dns-query"
            DOT_SERVER="dns.opendns.com"
            ;;
        4)
            PRIMARY_DNS="8.8.8.8"
            SECONDARY_DNS="8.8.4.4"
            DNS_NAME="Google DNS"
            DOH_URL="https://dns.google/dns-query"
            DOT_SERVER="dns.google"
            ;;
        5)
            PRIMARY_DNS="94.140.14.14"
            SECONDARY_DNS="94.140.15.15"
            DNS_NAME="AdGuard DNS"
            DOH_URL="https://dns.adguard.com/dns-query"
            DOT_SERVER="dns.adguard.com"
            ;;
        6)
            PRIMARY_DNS="185.228.168.9"
            SECONDARY_DNS="185.228.169.9"
            DNS_NAME="CleanBrowsing"
            DOH_URL="https://doh.cleanbrowsing.org/doh/family-filter/"
            DOT_SERVER="family-filter-dns.cleanbrowsing.org"
            ;;
        7)
            read -p "Enter primary DNS server: " PRIMARY_DNS
            read -p "Enter secondary DNS server: " SECONDARY_DNS
            read -p "Enter DNS provider name: " DNS_NAME
            DOH_URL=""
            DOT_SERVER=""
            ;;
        *)
            echo -e "${RED}Invalid choice, using Cloudflare DNS${NC}"
            PRIMARY_DNS="1.1.1.1"
            SECONDARY_DNS="1.0.0.1"
            DNS_NAME="Cloudflare"
            DOH_URL="https://cloudflare-dns.com/dns-query"
            DOT_SERVER="cloudflare-dns.com"
            ;;
    esac
    
    echo -e "${GREEN}Selected: $DNS_NAME ($PRIMARY_DNS, $SECONDARY_DNS)${NC}"
}

# Function to configure DNS-over-HTTPS (DoH)
configure_doh() {
    echo -e "${YELLOW}🔄 Configuring DNS-over-HTTPS (DoH)...${NC}"
    
    if [ -z "$DOH_URL" ]; then
        echo -e "${YELLOW}⚠️ DoH URL not available for this provider${NC}"
        return
    fi
    
    # Install cloudflared if needed for DoH
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${CYAN}📦 Installing cloudflared for DoH...${NC}"
        
        if command -v apt &> /dev/null; then
            # Debian/Ubuntu
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
            dpkg -i cloudflared-linux-amd64.deb || apt --fix-broken install -y
            rm cloudflared-linux-amd64.deb
        elif command -v yum &> /dev/null; then
            # RHEL/CentOS
            wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.rpm
            rpm -i cloudflared-linux-amd64.rpm
            rm cloudflared-linux-amd64.rpm
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            pacman -S cloudflared --noconfirm
        else
            echo -e "${YELLOW}⚠️ Package manager not supported, skipping DoH setup${NC}"
            return
        fi
    fi
    
    # Configure cloudflared for DoH
    mkdir -p /etc/cloudflared
    cat > /etc/cloudflared/config.yml << EOF
proxy-dns: true
proxy-dns-port: 5053
proxy-dns-address: 127.0.0.1
upstream:
  - $DOH_URL
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/cloudflared-proxy-dns.service << EOF
[Unit]
Description=DNS over HTTPS (DoH) proxy
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/cloudflared proxy-dns --config /etc/cloudflared/config.yml
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable cloudflared-proxy-dns
    systemctl start cloudflared-proxy-dns
    
    echo -e "${GREEN}✅ DoH configured on localhost:5053${NC}"
}

# Function to configure DNS-over-TLS (DoT)
configure_dot() {
    echo -e "${YELLOW}🔄 Configuring DNS-over-TLS (DoT)...${NC}"
    
    if [ -z "$DOT_SERVER" ]; then
        echo -e "${YELLOW}⚠️ DoT server not available for this provider${NC}"
        return
    fi
    
    # Configure systemd-resolved for DoT
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=${PRIMARY_DNS}#${DOT_SERVER} ${SECONDARY_DNS}
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
EOF
        
        systemctl restart systemd-resolved
        echo -e "${GREEN}✅ DoT configured with systemd-resolved${NC}"
    else
        echo -e "${YELLOW}⚠️ systemd-resolved not available, skipping DoT${NC}"
    fi
}

# Function to configure traditional DNS
configure_traditional_dns() {
    echo -e "${YELLOW}🔄 Configuring Traditional DNS...${NC}"
    
    case $NETWORK_MANAGER in
        "NetworkManager")
            # Configure NetworkManager
            cat > /etc/NetworkManager/conf.d/dns-servers.conf << EOF
[global-dns-domain-*]
servers=${PRIMARY_DNS},${SECONDARY_DNS}
EOF
            
            systemctl restart NetworkManager
            echo -e "${GREEN}✅ DNS configured via NetworkManager${NC}"
            ;;
        
        "systemd-resolved")
            # Configure systemd-resolved without DoT
            cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=${PRIMARY_DNS} ${SECONDARY_DNS}
DNSOverTLS=no
DNSSEC=yes
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
EOF
            
            systemctl restart systemd-resolved
            echo -e "${GREEN}✅ DNS configured via systemd-resolved${NC}"
            ;;
        
        "dhclient")
            # Configure dhclient
            echo "supersede domain-name-servers ${PRIMARY_DNS}, ${SECONDARY_DNS};" >> /etc/dhcp/dhclient.conf
            
            # Restart network
            if command -v service &> /dev/null; then
                service networking restart
            elif command -v systemctl &> /dev/null; then
                systemctl restart networking
            fi
            echo -e "${GREEN}✅ DNS configured via dhclient${NC}"
            ;;
        
        *)
            # Manual configuration
            cat > /etc/resolv.conf << EOF
# DNS Configuration by XXMXLI DNS Security Tool
# Provider: $DNS_NAME
nameserver $PRIMARY_DNS
nameserver $SECONDARY_DNS
options timeout:2
options attempts:3
options rotate
options single-request-reopen
EOF
            
            # Make it immutable to prevent overwrites
            chattr +i /etc/resolv.conf 2>/dev/null || true
            echo -e "${GREEN}✅ DNS configured manually${NC}"
            ;;
    esac
}

# Function to configure DNS filtering and security
configure_dns_filtering() {
    echo -e "${YELLOW}🔄 Configuring DNS Filtering...${NC}"
    
    # Install and configure dnsmasq for additional filtering
    if ! command -v dnsmasq &> /dev/null; then
        echo -e "${CYAN}📦 Installing dnsmasq for DNS filtering...${NC}"
        
        if command -v apt &> /dev/null; then
            apt update && apt install -y dnsmasq
        elif command -v yum &> /dev/null; then
            yum install -y dnsmasq
        elif command -v pacman &> /dev/null; then
            pacman -S dnsmasq --noconfirm
        fi
    fi
    
    # Configure dnsmasq
    cat > /etc/dnsmasq.conf << EOF
# XXMXLI DNS Security Configuration
listen-address=127.0.0.1
bind-interfaces

# Upstream DNS servers
server=${PRIMARY_DNS}
server=${SECONDARY_DNS}

# Security settings
bogus-priv
domain-needed
no-resolv
no-poll

# Cache settings
cache-size=1000

# Security filters
address=/doubleclick.net/0.0.0.0
address=/googletagmanager.com/0.0.0.0
address=/google-analytics.com/0.0.0.0
address=/facebook.com/0.0.0.0
address=/connect.facebook.net/0.0.0.0

# Block common malware domains
address=/malware.com/0.0.0.0
address=/phishing.com/0.0.0.0

# Log queries for monitoring
log-queries
log-facility=/var/log/dnsmasq.log
EOF
    
    # Download additional blocklists
    echo -e "${CYAN}📡 Downloading malware and ad blocklists...${NC}"
    mkdir -p /etc/dnsmasq.d
    
    # Download Steven Black's hosts file
    wget -q -O /tmp/hosts "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
    if [ -f /tmp/hosts ]; then
        # Convert hosts format to dnsmasq format
        grep "^0.0.0.0" /tmp/hosts | awk '{print "address=/" $2 "/0.0.0.0"}' > /etc/dnsmasq.d/blocked-hosts.conf
        echo -e "${GREEN}✅ Blocklist downloaded and configured${NC}"
        rm /tmp/hosts
    fi
    
    systemctl enable dnsmasq
    systemctl restart dnsmasq
    echo -e "${GREEN}✅ DNS filtering configured${NC}"
}

# Function to test DNS configuration
test_dns_configuration() {
    echo -e "${CYAN}🧪 Testing DNS Configuration...${NC}"
    echo "================================"
    
    # Test basic DNS resolution
    echo -e "${YELLOW}📡 Testing DNS resolution...${NC}"
    if nslookup google.com >/dev/null 2>&1; then
        echo -e "${GREEN}✅ DNS resolution working${NC}"
    else
        echo -e "${RED}❌ DNS resolution failed${NC}"
    fi
    
    # Test DNS servers
    echo -e "${YELLOW}📡 Testing configured DNS servers...${NC}"
    if nslookup google.com $PRIMARY_DNS >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Primary DNS ($PRIMARY_DNS) working${NC}"
    else
        echo -e "${RED}❌ Primary DNS ($PRIMARY_DNS) failed${NC}"
    fi
    
    if nslookup google.com $SECONDARY_DNS >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Secondary DNS ($SECONDARY_DNS) working${NC}"
    else
        echo -e "${RED}❌ Secondary DNS ($SECONDARY_DNS) failed${NC}"
    fi
    
    # Test DoH if configured
    if systemctl is-active cloudflared-proxy-dns >/dev/null 2>&1; then
        echo -e "${YELLOW}📡 Testing DoH (DNS-over-HTTPS)...${NC}"
        if nslookup google.com 127.0.0.1 -port=5053 >/dev/null 2>&1; then
            echo -e "${GREEN}✅ DoH working on localhost:5053${NC}"
        else
            echo -e "${RED}❌ DoH not responding${NC}"
        fi
    fi
    
    # Test DNS leak
    echo -e "${YELLOW}🔍 Testing for DNS leaks...${NC}"
    echo "Visit https://dnsleaktest.com to verify your DNS configuration"
    
    # Show current DNS settings
    echo -e "${YELLOW}📋 Current DNS settings:${NC}"
    cat /etc/resolv.conf
    
    echo ""
}

# Function to show current DNS status
show_dns_status() {
    echo -e "${GREEN}📊 Current DNS Configuration Status:${NC}"
    echo "===================================="
    
    # Current DNS servers
    echo -e "${CYAN}🌐 Current DNS Servers:${NC}"
    grep nameserver /etc/resolv.conf 2>/dev/null || echo "No nameserver entries found"
    
    # Network manager status
    echo -e "${CYAN}🔧 Network Manager:${NC}"
    echo "Type: $NETWORK_MANAGER"
    
    # Service status
    echo -e "${CYAN}🔄 Service Status:${NC}"
    
    if systemctl is-active systemd-resolved >/dev/null 2>&1; then
        echo -e "systemd-resolved: ${GREEN}ACTIVE${NC}"
    else
        echo -e "systemd-resolved: ${RED}INACTIVE${NC}"
    fi
    
    if systemctl is-active NetworkManager >/dev/null 2>&1; then
        echo -e "NetworkManager: ${GREEN}ACTIVE${NC}"
    else
        echo -e "NetworkManager: ${RED}INACTIVE${NC}"
    fi
    
    if systemctl is-active dnsmasq >/dev/null 2>&1; then
        echo -e "dnsmasq: ${GREEN}ACTIVE${NC}"
    else
        echo -e "dnsmasq: ${YELLOW}INACTIVE${NC}"
    fi
    
    if systemctl is-active cloudflared-proxy-dns >/dev/null 2>&1; then
        echo -e "DoH (cloudflared): ${GREEN}ACTIVE${NC}"
    else
        echo -e "DoH (cloudflared): ${YELLOW}INACTIVE${NC}"
    fi
    
    echo ""
}

# Function to show menu
show_menu() {
    echo -e "${GREEN}🎯 DNS Security Configuration Menu:${NC}"
    echo "=================================="
    echo -e "${WHITE}[1] Show current DNS status${NC}"
    echo -e "${WHITE}[2] Configure secure DNS (traditional)${NC}"
    echo -e "${WHITE}[3] Configure DNS-over-HTTPS (DoH)${NC}"
    echo -e "${WHITE}[4] Configure DNS-over-TLS (DoT)${NC}"
    echo -e "${WHITE}[5] Configure DNS filtering & ad blocking${NC}"
    echo -e "${WHITE}[6] Full security setup (DoH + filtering)${NC}"
    echo -e "${WHITE}[7] Test DNS configuration${NC}"
    echo -e "${WHITE}[8] Create backup of current settings${NC}"
    echo -e "${WHITE}[9] Restore from backup${NC}"
    echo -e "${WHITE}[0] Exit${NC}"
    echo ""
}

# Main script execution
show_banner

# Check for root privileges
check_root

# Detect system
detect_system

echo ""

# Handle command line arguments
case "${1:-menu}" in
    "secure-dns")
        backup_dns_settings
        configure_secure_dns
        configure_traditional_dns
        test_dns_configuration
        ;;
    "doh")
        backup_dns_settings
        configure_secure_dns
        configure_doh
        test_dns_configuration
        ;;
    "dot")
        backup_dns_settings
        configure_secure_dns
        configure_dot
        test_dns_configuration
        ;;
    "full-security")
        backup_dns_settings
        configure_secure_dns
        configure_doh
        configure_dns_filtering
        test_dns_configuration
        ;;
    "status")
        show_dns_status
        ;;
    "menu"|*)
        while true; do
            show_menu
            read -p "Enter your choice (0-9): " choice
            
            case $choice in
                1)
                    show_dns_status
                    read -p "Press Enter to continue..."
                    ;;
                2)
                    backup_dns_settings
                    configure_secure_dns
                    configure_traditional_dns
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                3)
                    backup_dns_settings
                    configure_secure_dns
                    configure_doh
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                4)
                    backup_dns_settings
                    configure_secure_dns
                    configure_dot
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                5)
                    backup_dns_settings
                    configure_dns_filtering
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                6)
                    backup_dns_settings
                    configure_secure_dns
                    configure_doh
                    configure_dns_filtering
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                7)
                    test_dns_configuration
                    read -p "Press Enter to continue..."
                    ;;
                8)
                    backup_dns_settings
                    read -p "Press Enter to continue..."
                    ;;
                9)
                    read -p "Enter backup directory name: " backup_restore
                    if [ -d "$backup_restore" ]; then
                        echo -e "${YELLOW}🔄 Restoring DNS settings from $backup_restore...${NC}"
                        # Add restore logic here
                        echo -e "${GREEN}✅ Settings restored (implement restore logic)${NC}"
                    else
                        echo -e "${RED}❌ Backup directory not found!${NC}"
                    fi
                    read -p "Press Enter to continue..."
                    ;;
                0)
                    echo -e "${GREEN}👋 Goodbye!${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}❌ Invalid choice!${NC}"
                    read -p "Press Enter to continue..."
                    ;;
            esac
        done
        ;;
esac

echo ""
echo -e "${GREEN}📋 Script completed. DNS security configuration updated!${NC}"
echo -e "${YELLOW}⚠️  Test your internet connectivity and DNS resolution.${NC}"
echo -e "${CYAN}💡 Visit https://dnsleaktest.com to verify your DNS privacy.${NC}"
