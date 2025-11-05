#!/bin/bash

# ========================================
# XXMXLI IP BLACKLIST ANALYZER & BLOCKER
# ========================================
# This script analyzes your blacklist and creates server-side blocking rules
#
# SECURITY WARNING: This system is actively monitored and protected.
# Any unauthorized access attempts, network scanning, intrusion, or abusive activity 
# will be logged and reported to the appropriate authorities. IP addresses and metadata 
# may be retained and used for legal enforcement, in compliance with applicable laws.
# By continuing, you acknowledge that you are authorized to use this system and that 
# any misuse may result in account suspension, firewall bans, or prosecution under 
# national and international law. Violators may be subject to civil and/or criminal 
# penalties. Your access is being monitored.

echo "🛡️  XXMXLI IP Blacklist Analysis & Server-Side Blocking Setup"
echo "=============================================================="

# Configuration
BLACKLIST_FILE="assets/security/blocked_ips.json"
OUTPUT_HTACCESS=".htaccess_generated_blocks"
HIGH_PRIORITY_COUNT=100
ADMIN_HTACCESS="admin/.htaccess_ip_blocks"

# Check if blacklist file exists
if [ ! -f "$BLACKLIST_FILE" ]; then
    echo "❌ Error: Blacklist file not found at $BLACKLIST_FILE"
    exit 1
fi

echo "📊 Analyzing blacklist data..."

# Extract total IP count from JSON if present, else compute from blocked_ips length
if command -v jq >/dev/null 2>&1; then
    TOTAL_IPS=$(jq -r 'if has("total_ips") then .total_ips else (.blocked_ips // []) | length end' "$BLACKLIST_FILE" 2>/dev/null || echo 0)
else
    TOTAL_IPS=$(python3 - <<'PY'
import json
try:
    with open('assets/security/blocked_ips.json','r',encoding='utf-8') as f:
        data=json.load(f)
    if isinstance(data, dict):
        print(data.get('total_ips') or len(data.get('blocked_ips') or []))
    elif isinstance(data, list):
        print(len(data))
    else:
        print(0)
except Exception:
    print(0)
PY
)
fi
echo "📈 Total IPs in blacklist: $TOTAL_IPS"

# Create high-priority server-side blocking rules
echo "🔥 Creating high-priority server-side blocking rules..."

cat > "$OUTPUT_HTACCESS" << 'EOF'
# ========================================
# XXMXLI AUTO-GENERATED IP BLOCKING RULES
# ========================================
# Generated on: $(date)
# High-priority IPs that are blocked at server level

RewriteEngine On

# Block high-priority threat IPs
<RequireAll>
    Require all granted
    
EOF

# Extract first 100 IPs for server-side blocking
echo "⚡ Extracting top $HIGH_PRIORITY_COUNT IPs for server-side blocking..."

# Parse JSON and extract first N IPs
python3 << EOF
import json
import sys

try:
    with open('$BLACKLIST_FILE', 'r') as f:
        data = json.load(f)
    # Support both object with blocked_ips and plain array
    if isinstance(data, dict):
        ips = (data.get('blocked_ips') or [])[:$HIGH_PRIORITY_COUNT]
    else:
        ips = (data or [])[:$HIGH_PRIORITY_COUNT]
    
    for ip in ips:
        print(f"    Require not ip {ip}")
        
except Exception as e:
    print(f"Error processing JSON: {e}", file=sys.stderr)
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    # Append the extracted IPs to htaccess file
    python3 << EOF >> "$OUTPUT_HTACCESS"
import json

try:
    with open('$BLACKLIST_FILE', 'r') as f:
        data = json.load(f)
    if isinstance(data, dict):
        ips = (data.get('blocked_ips') or [])[:$HIGH_PRIORITY_COUNT]
    else:
        ips = (data or [])[:$HIGH_PRIORITY_COUNT]
    
    for ip in ips:
        print(f"    Require not ip {ip}")
        
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
EOF

    # Complete the htaccess file
    cat >> "$OUTPUT_HTACCESS" << 'EOF'
    
</RequireAll>

# Block suspicious user agents
RewriteCond %{HTTP_USER_AGENT} (bot|crawler|spider|scraper|hack|scan|vuln) [NC]
RewriteRule .* /blocked.html [R=403,L]

# Block empty user agents
RewriteCond %{HTTP_USER_AGENT} ^-?$
RewriteRule .* /blocked.html [R=403,L]

# Block IP ranges known for attacks
RewriteCond %{REMOTE_ADDR} ^1\.0\.248\.
RewriteRule .* /blocked.html [R=403,L]

RewriteCond %{REMOTE_ADDR} ^185\.220\.
RewriteRule .* /blocked.html [R=403,L]

# Log blocked attempts
RewriteCond %{REQUEST_URI} !^/blocked\.html$
RewriteCond %{REMOTE_ADDR} ^(1\.0\.0\.1|1\.1\.1\.1)$
RewriteRule .* - [E=blocked_ip:1]
CustomLog logs/xxmxli_blocked.log "%h %t \"%r\" %>s %b [BLOCKED]" env=blocked_ip

EOF

    echo "✅ Generated $OUTPUT_HTACCESS with $HIGH_PRIORITY_COUNT high-priority IPs"
else
    echo "❌ Failed to process blacklist JSON"
    exit 1
fi

# Create admin-specific blocking
echo "🔒 Creating admin area protection..."
mkdir -p admin
cat > "$ADMIN_HTACCESS" << 'EOF'
# ========================================
# XXMXLI ADMIN AREA IP PROTECTION
# ========================================
# Extra security for admin directory

AuthType Basic
AuthName "XXMXLI Admin Access"
AuthUserFile /path/to/.htpasswd

<RequireAll>
    Require valid-user
    
    # Block broader IP ranges from admin access
    Require not ip 1.0.0.0/8
    Require not ip 2.0.0.0/8
    Require not ip 46.0.0.0/8
    Require not ip 185.0.0.0/8
    Require not ip 194.0.0.0/8
    
    # Add your trusted admin IPs here:
    # Require ip YOUR.ADMIN.IP.HERE
</RequireAll>

# Additional admin security
<Files "*.php">
    Require all denied
    # Require ip YOUR.ADMIN.IP.HERE
</Files>

EOF

echo "✅ Generated $ADMIN_HTACCESS for admin protection"

# Generate installation instructions
cat > "INSTALLATION_INSTRUCTIONS.txt" << EOF
========================================
XXMXLI SERVER-SIDE IP BLOCKING SETUP
========================================

🚀 INSTALLATION STEPS:

1. BACKUP YOUR CURRENT .htaccess:
   cp .htaccess .htaccess.backup

2. ADD BLOCKING RULES TO YOUR MAIN .htaccess:
   cat $OUTPUT_HTACCESS >> .htaccess

3. INSTALL ADMIN PROTECTION:
   cp $ADMIN_HTACCESS admin/.htaccess

4. CREATE BLOCKED PAGE:
   Create a file called 'blocked.html' in your root directory

5. TEST THE SETUP:
   - Check that your site still loads normally
   - Verify blocked IPs get 403 errors
   - Test admin access works

⚠️  IMPORTANT NOTES:
- This blocks $HIGH_PRIORITY_COUNT of your highest-priority IPs at server level
- Remaining IPs are still handled by your client-side system
- Monitor your server logs for blocked attempts
- Adjust IP ranges based on your legitimate user base

📊 MONITORING:
- Blocked attempts logged to: logs/xxmxli_blocked.log
- Check regularly: tail -f logs/xxmxli_blocked.log

🆘 EMERGENCY DISABLE:
If you get locked out, remove the blocking rules from .htaccess
or add your IP to the trusted list.

EOF

echo ""
echo "🎯 SUMMARY:"
echo "==========="
echo "✅ Generated server-side blocking for $HIGH_PRIORITY_COUNT high-priority IPs"
echo "✅ Created admin area protection rules"
echo "✅ Generated installation instructions"
echo ""
echo "📁 FILES CREATED:"
echo "- $OUTPUT_HTACCESS (main blocking rules)"
echo "- $ADMIN_HTACCESS (admin protection)"
echo "- INSTALLATION_INSTRUCTIONS.txt (setup guide)"
echo ""
echo "⚡ NEXT STEPS:"
echo "1. Review the generated files"
echo "2. Follow INSTALLATION_INSTRUCTIONS.txt"
echo "3. Test thoroughly before deploying"
echo ""
echo "🛡️  Your site will have REAL server-side IP blocking after installation!"
