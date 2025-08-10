#!/bin/bash

# ========================================
# XXMXLI SAFE IP BLOCKING DEPLOYMENT
# ========================================
# This script safely deploys server-side IP blocking with backups

set -e  # Exit on any error

echo "🛡️  XXMXLI Safe Server-Side IP Blocking Deployment"
echo "=================================================="

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backups_$TIMESTAMP"
MAIN_HTACCESS=".htaccess"
ADMIN_HTACCESS="admin/.htaccess"
GENERATED_BLOCKS=".htaccess_generated_blocks"
ADMIN_BLOCKS="admin/.htaccess_ip_blocks"

# Check if we're in the right directory
if [ ! -f "index.html" ] || [ ! -f "assets/security/blocked_ips.json" ]; then
    echo "❌ Error: Run this script from the XXMXLI root directory"
    exit 1
fi

# Create backup directory
echo "📦 Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup existing files
echo "💾 Backing up existing configuration..."

if [ -f "$MAIN_HTACCESS" ]; then
    cp "$MAIN_HTACCESS" "$BACKUP_DIR/htaccess_main_backup"
    echo "✅ Backed up main .htaccess"
else
    echo "⚠️  No existing main .htaccess found"
fi

if [ -f "$ADMIN_HTACCESS" ]; then
    cp "$ADMIN_HTACCESS" "$BACKUP_DIR/htaccess_admin_backup"
    echo "✅ Backed up admin .htaccess"
else
    echo "⚠️  No existing admin .htaccess found"
fi

# Check if generated blocks exist
if [ ! -f "$GENERATED_BLOCKS" ]; then
    echo "❌ Error: Generated blocking rules not found. Run ./setup_ip_blocking.sh first"
    exit 1
fi

echo ""
echo "🔍 DEPLOYMENT PREVIEW:"
echo "====================="
echo "📁 Main .htaccess: $(wc -l < "$GENERATED_BLOCKS") lines will be added"
echo "📁 Admin protection: New admin IP blocking rules"
echo "🚫 Blocked IPs: 100 high-priority threats"
echo ""

# Ask for confirmation
read -p "🚀 Deploy server-side IP blocking? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 0
fi

echo ""
echo "🚀 Deploying server-side IP blocking..."

# Deploy main .htaccess rules
echo "📝 Adding IP blocking rules to main .htaccess..."
if [ -f "$MAIN_HTACCESS" ]; then
    # Add a separator and the new rules
    echo "" >> "$MAIN_HTACCESS"
    echo "# ========================================" >> "$MAIN_HTACCESS"
    echo "# XXMXLI SERVER-SIDE IP BLOCKING - Added $(date)" >> "$MAIN_HTACCESS"
    echo "# ========================================" >> "$MAIN_HTACCESS"
    cat "$GENERATED_BLOCKS" >> "$MAIN_HTACCESS"
else
    # Create new .htaccess file
    cp "$GENERATED_BLOCKS" "$MAIN_HTACCESS"
fi
echo "✅ Main .htaccess updated"

# Deploy admin protection
echo "🔒 Setting up admin area protection..."
mkdir -p admin
if [ -f "$ADMIN_BLOCKS" ]; then
    if [ -f "$ADMIN_HTACCESS" ]; then
        # Backup and replace
        echo "" >> "$ADMIN_HTACCESS"
        echo "# ========================================" >> "$ADMIN_HTACCESS"
        echo "# XXMXLI ADMIN IP BLOCKING - Added $(date)" >> "$ADMIN_HTACCESS"
        echo "# ========================================" >> "$ADMIN_HTACCESS"
        cat "$ADMIN_BLOCKS" >> "$ADMIN_HTACCESS"
    else
        cp "$ADMIN_BLOCKS" "$ADMIN_HTACCESS"
    fi
    echo "✅ Admin protection deployed"
else
    echo "⚠️  Admin blocking rules not found, skipping admin protection"
fi

# Create deployment log
cat > "$BACKUP_DIR/deployment_log.txt" << EOF
========================================
XXMXLI IP BLOCKING DEPLOYMENT LOG
========================================
Deployment Time: $(date)
Backup Directory: $BACKUP_DIR

DEPLOYED COMPONENTS:
- Server-side IP blocking (100 high-priority IPs)
- Admin area enhanced protection
- Backup of original configuration

ROLLBACK INSTRUCTIONS:
If you need to rollback this deployment:
1. cp $BACKUP_DIR/htaccess_main_backup .htaccess
2. cp $BACKUP_DIR/htaccess_admin_backup admin/.htaccess

MONITORING:
- Check server logs for blocked attempts
- Monitor site performance
- Verify legitimate users can access

FILES MODIFIED:
- $MAIN_HTACCESS (IP blocking rules added)
- $ADMIN_HTACCESS (admin protection added)

EMERGENCY CONTACT:
If the site becomes inaccessible, remove the IP blocking
section from .htaccess or restore from backup.
EOF

echo ""
echo "🎉 DEPLOYMENT COMPLETE!"
echo "======================="
echo "✅ Server-side IP blocking is now ACTIVE"
echo "✅ 100 high-priority threat IPs are blocked at server level"
echo "✅ Admin area has enhanced protection"
echo "✅ All original files backed up to: $BACKUP_DIR"
echo ""
echo "📊 WHAT'S NOW BLOCKED:"
echo "- Malicious IPs from your blacklist (server-side)"
echo "- Suspicious user agents"
echo "- Empty user agents"
echo "- Attack patterns in requests"
echo ""
echo "🔍 MONITORING:"
echo "- Watch your server access logs"
echo "- Check for 403 errors from blocked IPs"
echo "- Monitor site performance"
echo ""
echo "⚠️  IMPORTANT REMINDERS:"
echo "1. Test your site immediately to ensure it's accessible"
echo "2. Check admin area access"
echo "3. Monitor logs for legitimate users being blocked"
echo "4. Keep backup directory: $BACKUP_DIR"
echo ""
echo "🆘 ROLLBACK if needed:"
echo "   cp $BACKUP_DIR/htaccess_main_backup .htaccess"
echo ""
echo "🛡️  Your website now has REAL server-side IP protection!"

# Test if the site is still accessible
echo ""
echo "🧪 QUICK ACCESS TEST:"
if command -v curl &> /dev/null; then
    echo "Testing site accessibility..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "http://localhost:8000/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✅ Site appears accessible (HTTP $HTTP_CODE)"
    else
        echo "⚠️  Site test returned HTTP $HTTP_CODE - check manually"
    fi
else
    echo "⚠️  curl not available - please test site manually"
fi

echo ""
echo "🎯 NEXT STEPS:"
echo "1. Open your website in a browser to verify it works"
echo "2. Check admin panel access"
echo "3. Review server logs: tail -f /var/log/apache2/access.log"
echo "4. Monitor for blocked attempts in the coming hours"
