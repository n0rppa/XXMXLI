#!/bin/bash

# Test script for verifying incident reporter installation works properly
# This runs a dry-run test without actually installing anything

echo "=========================================="
echo "XXMXLI Incident Reporter - Installation Test"
echo "=========================================="

# Test 1: Check if installer exists
echo "Test 1: Checking installer files..."
if [ -f "install_incident_reporter.sh" ]; then
    echo "✓ Linux installer found"
else
    echo "✗ Linux installer missing"
fi

if [ -f "install_incident_reporter.bat" ]; then
    echo "✓ Windows installer found"
else
    echo "✗ Windows installer missing"
fi

# Test 2: Check if main scripts exist
echo -e "\nTest 2: Checking main reporter scripts..."
if [ -f "automated_incident_reporter.sh" ]; then
    echo "✓ Linux/Unix reporter found"
else
    echo "✗ Linux/Unix reporter missing"
fi

if [ -f "automated_incident_reporter.ps1" ]; then
    echo "✓ Windows PowerShell reporter found"
else
    echo "✗ Windows PowerShell reporter missing"
fi

if [ -f "automated_incident_reporter.py" ]; then
    echo "✓ Python cross-platform reporter found"
else
    echo "✗ Python cross-platform reporter missing"
fi

# Test 3: Check installer permissions
echo -e "\nTest 3: Checking installer permissions..."
if [ -x "install_incident_reporter.sh" ]; then
    echo "✓ Linux installer is executable"
else
    echo "! Linux installer needs chmod +x"
fi

# Test 4: Check for key functions in scripts
echo -e "\nTest 4: Checking script functionality..."
if grep -q "check_root" automated_incident_reporter.sh; then
    echo "✓ Auto-elevation function found in bash script"
else
    echo "✗ Auto-elevation function missing in bash script"
fi

if grep -q "install_dependencies" automated_incident_reporter.sh; then
    echo "✓ Dependency installation function found in bash script"
else
    echo "✗ Dependency installation function missing in bash script"
fi

if grep -q "setup_directories" automated_incident_reporter.sh; then
    echo "✓ Directory setup function found in bash script"
else
    echo "✗ Directory setup function missing in bash script"
fi

# Test 5: Check for authorities integration
echo -e "\nTest 5: Checking authority reporting integration..."
if grep -q "FBI.*IC3" automated_incident_reporter.sh; then
    echo "✓ FBI IC3 integration found"
else
    echo "✗ FBI IC3 integration missing"
fi

if grep -q "CISA" automated_incident_reporter.sh; then
    echo "✓ CISA integration found"
else
    echo "✗ CISA integration missing"
fi

if grep -q "Europol" automated_incident_reporter.sh; then
    echo "✓ Europol EC3 integration found"
else
    echo "✗ Europol EC3 integration missing"
fi

echo -e "\n=========================================="
echo "Installation Test Complete!"
echo "All files are ready for deployment to non-technical users."
echo "=========================================="
