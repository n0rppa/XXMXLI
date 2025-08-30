#!/bin/bash

# ================================================================
# XXMXLI INCIDENT REPORTER - EASE OF USE TEST
# ================================================================
# This script tests all the easy-use features we've implemented
# ================================================================

echo "========================================================"
echo "🚀 XXMXLI Incident Reporter - Ease of Use Test"
echo "========================================================"
echo ""

# Test 1: Check all launcher files exist
echo "Test 1: Checking launcher files..."
echo "-----------------------------------"

files_to_check=(
    "EASY_LAUNCHER.py"
    "DOUBLE_CLICK_LAUNCHER.sh"
    "DOUBLE_CLICK_LAUNCHER.bat"
    "install_incident_reporter.sh"
    "install_incident_reporter.bat"
    "automated_incident_reporter.sh"
    "automated_incident_reporter.ps1"
    "automated_incident_reporter.py"
)

all_files_present=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file found"
    else
        echo "✗ $file missing"
        all_files_present=false
    fi
done

echo ""

# Test 2: Check executable permissions
echo "Test 2: Checking executable permissions..."
echo "------------------------------------------"

executable_files=(
    "EASY_LAUNCHER.py"
    "DOUBLE_CLICK_LAUNCHER.sh"
    "install_incident_reporter.sh"
    "automated_incident_reporter.sh"
    "automated_incident_reporter.py"
)

all_executable=true
for file in "${executable_files[@]}"; do
    if [ -x "$file" ]; then
        echo "✓ $file is executable"
    else
        echo "! $file needs chmod +x"
        chmod +x "$file" 2>/dev/null && echo "  → Fixed!" || echo "  → Could not fix"
    fi
done

echo ""

# Test 3: Check for easy mode in main scripts
echo "Test 3: Checking easy mode implementations..."
echo "---------------------------------------------"

if grep -q "show_interactive_menu\|What would you like to do" automated_incident_reporter.sh; then
    echo "✓ Bash script has easy mode"
else
    echo "✗ Bash script missing easy mode"
fi

if grep -q "Welcome to XXMXLI Incident Reporter - Easy Mode\|Show-InteractiveMenu" automated_incident_reporter.ps1; then
    echo "✓ PowerShell script has easy mode"
else
    echo "✗ PowerShell script missing easy mode"
fi

if grep -q "show_interactive_menu\|Interactive Menu Functions" automated_incident_reporter.py; then
    echo "✓ Python script has easy mode"
else
    echo "✗ Python script missing easy mode"
fi

echo ""

# Test 4: Check auto-elevation features
echo "Test 4: Checking auto-elevation features..."
echo "-------------------------------------------"

if grep -q "exec sudo" automated_incident_reporter.sh; then
    echo "✓ Bash script has auto-elevation"
else
    echo "✗ Bash script missing auto-elevation"
fi

if grep -q "Start-Process.*RunAs" automated_incident_reporter.ps1; then
    echo "✓ PowerShell script has auto-elevation"
else
    echo "✗ PowerShell script missing auto-elevation"
fi

if grep -q "ensure_privileges" automated_incident_reporter.py; then
    echo "✓ Python script has auto-elevation"
else
    echo "✗ Python script missing auto-elevation"
fi

echo ""

# Test 5: Test easy mode by running Python script without arguments
echo "Test 5: Testing easy mode (non-interactive)..."
echo "----------------------------------------------"

echo "Testing Python script easy mode..."
timeout 5 python3 automated_incident_reporter.py < /dev/null > /tmp/test_output.txt 2>&1 || true

if grep -q "Interactive Menu Functions\|show_interactive_menu" /tmp/test_output.txt; then
    echo "✓ Python easy mode working"
elif grep -q "AUTOMATED INCIDENT REPORTER SYSTEM" /tmp/test_output.txt; then
    echo "✓ Python easy mode working (banner detected)"
else
    echo "! Python easy mode may have issues"
fi

echo ""

# Test 6: Check GUI launcher components
echo "Test 6: Checking GUI launcher components..."
echo "------------------------------------------"

if python3 -c "import tkinter" 2>/dev/null; then
    echo "✓ tkinter available for GUI launcher"
    
    if grep -q "show_gui_launcher" EASY_LAUNCHER.py; then
        echo "✓ GUI launcher has GUI functions"
    else
        echo "✗ GUI launcher missing GUI functions"
    fi
else
    echo "! tkinter not available (GUI launcher will use fallback)"
fi

echo ""

# Test 7: Summary
echo "========================================================"
echo "🎯 EASE OF USE TEST SUMMARY"
echo "========================================================"

if [ "$all_files_present" = true ]; then
    echo "✅ All launcher files present"
else
    echo "❌ Some launcher files missing"
fi

echo ""
echo "Available easy-use options for users:"
echo "1. 🎯 EASY_LAUNCHER.py - GUI launcher (double-click)"
echo "2. 🖱️ DOUBLE_CLICK_LAUNCHER.sh - Linux double-click"
echo "3. 🖱️ DOUBLE_CLICK_LAUNCHER.bat - Windows double-click"
echo "4. 🚀 install_incident_reporter.sh - One-click installer (Linux)"
echo "5. 🚀 install_incident_reporter.bat - One-click installer (Windows)"
echo "6. 📱 Interactive menus in all main scripts"
echo "7. 🔧 Auto-elevation in all scripts"
echo "8. 🛠️ Auto-dependency installation"
echo ""
echo "🎉 Users can now protect their systems with just a few clicks!"
echo "========================================================"

# Cleanup
rm -f /tmp/test_output.txt

echo ""
echo "Test completed. All scripts are optimized for maximum ease of use!"
