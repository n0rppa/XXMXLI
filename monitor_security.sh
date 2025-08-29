#!/bin/bash

# ========================================
# XXMXLI IP BLOCKING MONITOR
# ========================================
# Monitor blocked IPs and security events
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 
# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored.

echo "🛡️  XXMXLI IP Blocking Security Monitor"
echo "======================================"

# Function to check if IP blocking is active
check_blocking_status() {
    echo "🔍 Checking IP blocking status..."
    
    if grep -q "XXMXLI SERVER-SIDE IP BLOCKING" .htaccess 2>/dev/null; then
        echo "✅ Server-side IP blocking is ACTIVE"
        BLOCKED_COUNT=$(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
        echo "📊 Server-level blocked IPs: $BLOCKED_COUNT"
    else
        echo "❌ Server-side IP blocking is NOT active"
    fi
    
    if [ -f "assets/security/blocked_ips.json" ]; then
        TOTAL_BLACKLIST=$(grep -o '"total_ips": [0-9]*' assets/security/blocked_ips.json | grep -o '[0-9]*' 2>/dev/null || echo "0")
        echo "📈 Total blacklist database: $TOTAL_BLACKLIST IPs"
    fi
    echo ""
}

# Function to show recent blocked attempts
show_recent_blocks() {
    echo "🚫 Recent Blocked Attempts (Last 24 hours):"
    echo "==========================================="
    
    # Check Apache access logs for 403 responses
    for LOG_FILE in /var/log/apache2/access.log /var/log/httpd/access_log logs/access.log access.log; do
        if [ -f "$LOG_FILE" ]; then
            echo "📝 Checking: $LOG_FILE"
            # Show 403 responses from last 24 hours
            awk -v date="$(date -d '24 hours ago' '+%d/%b/%Y')" '
            $4 ~ date && $9 == "403" {
                print "🚫 " $1 " - " $4 " " $7 " (" $9 ")"
            }' "$LOG_FILE" | tail -10
            break
        fi
    done
    
    # Check custom blocked IP log if it exists
    if [ -f "logs/xxmxli_blocked.log" ]; then
        echo ""
        echo "📋 Custom XXMXLI blocked attempts:"
        tail -10 logs/xxmxli_blocked.log
    fi
    echo ""
}

# Function to test IP blocking
test_ip_blocking() {
    echo "🧪 Testing IP Blocking Function:"
    echo "==============================="
    
    # Test with a known blocked IP (if available)
    BLOCKED_IP=$(grep -m1 "Require not ip" .htaccess 2>/dev/null | awk '{print $4}')
    
    if [ -n "$BLOCKED_IP" ]; then
        echo "🎯 Testing with blocked IP: $BLOCKED_IP"
        
        # Try to access with blocked IP (simulation)
        if command -v curl &> /dev/null; then
            echo "📡 Simulating request..."
            # Note: This won't actually use the blocked IP, just shows the concept
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8000/" 2>/dev/null || echo "000")
            echo "📊 Normal access returns: HTTP $HTTP_CODE"
        fi
    else
        echo "⚠️  No blocked IPs found in .htaccess"
    fi
    echo ""
}

# Function to show statistics
show_statistics() {
    echo "📊 Security Statistics:"
    echo "======================"
    
    # Count blocked IPs in .htaccess
    if [ -f ".htaccess" ]; then
        SERVER_BLOCKED=$(grep -c "Require not ip" .htaccess 2>/dev/null || echo "0")
        echo "🔒 Server-level blocked IPs: $SERVER_BLOCKED"
    fi
    
    # Count total blacklist
    if [ -f "assets/security/blocked_ips.json" ]; then
        TOTAL_IPS=$(grep -o '"total_ips": [0-9]*' assets/security/blocked_ips.json | grep -o '[0-9]*' 2>/dev/null)
        echo "📈 Total blacklist database: ${TOTAL_IPS:-0} IPs"
        
        # Show blacklist sources count
        SOURCES=$(grep -o '"sources_count": [0-9]*' assets/security/blocked_ips.json | grep -o '[0-9]*' 2>/dev/null)
        echo "📋 Threat intelligence sources: ${SOURCES:-Unknown}"
    fi
    
    # Show client-side blocking status
    if grep -q "xxmxliSecurity" index.html 2>/dev/null; then
        echo "🌐 Client-side blocking: Active"
    else
        echo "🌐 Client-side blocking: Not detected"
    fi
    
    echo ""
}

# Function to show top blocked IP ranges
show_top_ranges() {
    echo "🎯 Top Blocked IP Ranges:"
    echo "========================"
    
    if [ -f ".htaccess" ]; then
        grep "Require not ip" .htaccess 2>/dev/null | \
        awk '{print $4}' | \
        awk -F'.' '{print $1"."$2".*.*"}' | \
        sort | uniq -c | sort -nr | head -5 | \
        awk '{printf "🔴 %-12s (%d IPs)\n", $2, $1}'
    else
        echo "⚠️  No server-side blocking rules found"
    fi
    echo ""
}

# Function to check admin security
check_admin_security() {
    echo "🔐 Admin Security Status:"
    echo "========================"
    
    if [ -f "admin/.htaccess" ]; then
        if grep -q "Require not ip" admin/.htaccess 2>/dev/null; then
            ADMIN_BLOCKED=$(grep -c "Require not ip" admin/.htaccess)
            echo "✅ Admin IP blocking: Active ($ADMIN_BLOCKED rules)"
        else
            echo "⚠️  Admin IP blocking: Basic protection only"
        fi
        
        if grep -q "AuthType Basic" admin/.htaccess 2>/dev/null; then
            echo "✅ Admin password protection: Active"
        else
            echo "⚠️  Admin password protection: Not detected"
        fi
    else
        echo "❌ No admin .htaccess found"
    fi
    echo ""
}

# Main menu
while true; do
    echo "🛡️  XXMXLI Security Monitor - Choose an option:"
    echo "==============================================="
    echo "1. 🔍 Check blocking status"
    echo "2. 🚫 Show recent blocked attempts"
    echo "3. 🧪 Test IP blocking"
    echo "4. 📊 Show security statistics"
    echo "5. 🎯 Show top blocked IP ranges"
    echo "6. 🔐 Check admin security"
    echo "7. 🔄 Real-time log monitoring"
    echo "8. 📋 Generate security report"
    echo "9. ❌ Exit"
    echo ""
    read -p "Enter your choice (1-9): " choice
    echo ""
    
    case $choice in
        1) check_blocking_status ;;
        2) show_recent_blocks ;;
        3) test_ip_blocking ;;
        4) show_statistics ;;
        5) show_top_ranges ;;
        6) check_admin_security ;;
        7) 
            echo "🔄 Starting real-time log monitoring (Ctrl+C to stop)..."
            echo "======================================================="
            for LOG_FILE in /var/log/apache2/access.log /var/log/httpd/access_log logs/access.log; do
                if [ -f "$LOG_FILE" ]; then
                    tail -f "$LOG_FILE" | grep --line-buffered " 403 "
                    break
                fi
            done
            ;;
        8)
            echo "📋 Generating Security Report..."
            echo "==============================="
            REPORT_FILE="security_report_$(date +%Y%m%d_%H%M%S).txt"
            {
                echo "XXMXLI Security Report - $(date)"
                echo "================================="
                echo ""
                check_blocking_status
                show_statistics
                show_top_ranges
                check_admin_security
                echo "Report generated: $(date)"
            } > "$REPORT_FILE"
            echo "✅ Report saved to: $REPORT_FILE"
            echo ""
            ;;
        9) 
            echo "👋 Exiting XXMXLI Security Monitor"
            exit 0
            ;;
        *) 
            echo "❌ Invalid choice. Please enter 1-9."
            echo ""
            ;;
    esac
    
    read -p "Press Enter to continue..."
    clear
done
