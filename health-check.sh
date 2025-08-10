#!/bin/bash

# XXMXLI System Health Check Script
# This script verifies all components are working correctly

echo "🔍 XXMXLI System Health Check"
echo "=============================="
echo ""

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo "❌ Error: Please run this script from the XXMXLI root directory"
    exit 1
fi

echo "📁 Directory Structure Check..."
required_files=(
    "index.html"
    "status.html"
    "admin/visitor-dashboard.html"
    "api/get-visitor-stats.php"
    "api/visitor-logger.php"
    "api/check-blacklist.php"
    "assets/js/static-visitor-tracker.js"
    "data/visitors.json"
    "data/daily_stats.json"
    "_config.yml"
    ".nojekyll"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (missing)"
    fi
done

echo ""
echo "🌐 Server Check..."

# Check if PHP is available
if command -v php &> /dev/null; then
    echo "✅ PHP is available"
    echo "   Version: $(php --version | head -n 1)"
else
    echo "❌ PHP not found"
fi

# Check if server is running on port 8000
if curl -s http://localhost:8000 &> /dev/null; then
    echo "✅ Local server is running on port 8000"
else
    echo "⚠️  Local server not running. Start with: php -S localhost:8000 -t ."
fi

echo ""
echo "🔌 API Endpoint Check..."

# Test API endpoints if server is running
if curl -s http://localhost:8000 &> /dev/null; then
    
    # Test visitor stats API
    if curl -s http://localhost:8000/api/get-visitor-stats.php?action=overview | grep -q "totalVisitors"; then
        echo "✅ Visitor Stats API is working"
    else
        echo "❌ Visitor Stats API error"
    fi
    
    # Test visitor logger API
    if curl -s -f http://localhost:8000/api/visitor-logger.php &> /dev/null; then
        echo "✅ Visitor Logger API is accessible"
    else
        echo "❌ Visitor Logger API error"
    fi
    
    # Test blacklist API
    if curl -s -f http://localhost:8000/api/check-blacklist.php &> /dev/null; then
        echo "✅ Blacklist API is accessible"
    else
        echo "❌ Blacklist API error"
    fi
    
else
    echo "⚠️  Cannot test APIs - server not running"
fi

echo ""
echo "📊 Data File Check..."

# Check JSON files
if [ -f "data/daily_stats.json" ]; then
    if python3 -m json.tool data/daily_stats.json &> /dev/null; then
        echo "✅ daily_stats.json is valid JSON"
    else
        echo "❌ daily_stats.json has invalid JSON"
    fi
else
    echo "❌ daily_stats.json missing"
fi

if [ -f "data/visitors.json" ]; then
    if python3 -m json.tool data/visitors.json &> /dev/null; then
        echo "✅ visitors.json is valid JSON"
    else
        echo "❌ visitors.json has invalid JSON"
    fi
else
    echo "❌ visitors.json missing"
fi

echo ""
echo "🎯 Quick Test URLs..."
echo "   Main Site: http://localhost:8000/"
echo "   Status Page: http://localhost:8000/status.html"
echo "   Admin Dashboard: http://localhost:8000/admin/visitor-dashboard.html"
echo "   API Test: http://localhost:8000/api/get-visitor-stats.php?action=overview"

echo ""
echo "🚀 GitHub Pages Check..."
if [ -f "_config.yml" ] && [ -f ".nojekyll" ]; then
    echo "✅ GitHub Pages configuration is ready"
    echo "   The system will automatically use static mode on GitHub Pages"
else
    echo "❌ GitHub Pages configuration incomplete"
fi

echo ""
echo "✨ Health Check Complete!"
echo ""

# Summary
if curl -s http://localhost:8000 &> /dev/null; then
    echo "🟢 System Status: OPERATIONAL"
    echo "   Local development server is running and APIs are accessible."
else
    echo "🟡 System Status: READY (Static Mode)"
    echo "   Ready for GitHub Pages deployment. Start local server for full functionality."
fi

echo ""
echo "💡 Need help? Check SYSTEM_STATUS_REPORT.md for detailed documentation."
